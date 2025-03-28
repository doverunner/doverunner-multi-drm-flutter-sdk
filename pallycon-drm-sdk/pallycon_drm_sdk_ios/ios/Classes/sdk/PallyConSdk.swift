import Foundation
import AVKit
import PallyConFPSSDK

struct DrmContent {
    let siteId: String
    let drmType: String
    var url: String
    var contentId: String
    var token: String
    var customData: String?
    var httpHeader: Dictionary<String, String>?
    var cookie: String?
    var appleCertUrl: String?
    var drmLicenseUrl: String?
    var downloadState: DownloadState = DownloadState.not
    var downloadPath: String

    init(siteId: String, url: String, contentId: String, path: String) {
        self.init(siteId: siteId, drmType: "", url: url, contentId: contentId,
                  token: "", customData: "", httpHeader: nil, cookie: "", drmLicenseUrl: "",
                  appleCertUrl: "",  downloadState: DownloadState.completed, path: path)
    }

    init(sitdeId: String, url: String, contentId: String, token: String) {
        self.init(siteId: sitdeId, drmType: "", url: url, contentId: contentId, token: token,
                  customData: "", httpHeader: nil, cookie: "", drmLicenseUrl: "",
                  appleCertUrl: "", downloadState: DownloadState.not, path: "")
    }

    init(siteId: String, drmType: String, url: String, contentId: String, token: String, customData: String?,
         httpHeader: Dictionary<String, String>?, cookie: String?, drmLicenseUrl: String?,
         appleCertUrl: String?, downloadState: DownloadState, path: String) {
        self.siteId = siteId
        self.drmType = drmType
        self.url = url
        self.contentId = contentId
        self.token = token
        self.customData = customData
        self.httpHeader = httpHeader
        self.cookie = cookie
        self.drmLicenseUrl = drmLicenseUrl
        self.appleCertUrl = appleCertUrl
        self.downloadState = downloadState
        self.downloadPath = path
    }

    func toPallyConConfig() -> String {

        let customData = self.customData ?? ""
        let drmLicenseUrl = self.drmLicenseUrl ?? ""

        let configString = "{\"drmConfig\":{\"siteId\":\"\(self.siteId)\",\"contentId\":\"\(self.contentId)\",\"drmLicenseUrl\":\"\(drmLicenseUrl)\",\"token\":\"\(self.token)\",\"customData\":\"\(customData)\"},\"url\":\"\(self.downloadPath)\"}"
        return configString
    }
}

class PallyConSdk: NSObject {
    static let shared = PallyConSdk()

    private var pallyConEvent: FlutterEventSink?
    private var progressEvent: FlutterEventSink?

    private var siteId: String = ""
    private var fpsSdk: PallyConFPSSDK?
    private var downloadTaskMap = [DownloadTask:DrmContent]()
    private var downloadedContentMap = [String:DrmContent]()

    static let baseDownloadURL: URL = URL(fileURLWithPath: NSHomeDirectory())

    public func setPallyConEventSink(eventSink: FlutterEventSink?) {
        self.pallyConEvent = eventSink
    }

    public func setDownloadProgress(eventSink: FlutterEventSink?) {
        self.progressEvent = eventSink
    }

    public func sendPallyConEvent(url: String, eventType: PallyConEventType, message: String, errorCode: String = "") {
        guard let event = pallyConEvent else {
            return
        }

        if (!Thread.isMainThread) {
            DispatchQueue.main.sync {
                event(
                    EventMessage(url: url, eventType: eventType, message: message, errorCode: errorCode).toMap()
                )
            }
        } else {
            event(
                EventMessage(url: url, eventType: eventType, message: message, errorCode: errorCode).toMap()
            )
        }
    }

    public func initialize(siteId: String) {
        self.siteId = siteId
        fpsSdk = PallyConFPSSDK()
    }

    public func release()  {

    }

    public func getObjectForContent(url: String, contentId: String, token: String?,
                                    customData: String?, httpHeaders: Dictionary<String, String>?,
                                    cookie: String?, drmLicenseUrl: String?, appleCertUrl: String?) -> String {
        if var drmContent = downloadedContentMap[url] {
            drmContent.contentId = contentId
            drmContent.drmLicenseUrl = drmLicenseUrl
            drmContent.token = token ?? ""
            drmContent.httpHeader = httpHeaders
            drmContent.cookie = cookie
            drmContent.customData = customData
            drmContent.appleCertUrl = appleCertUrl ?? ""
            downloadedContentMap[url] = drmContent
            return drmContent.toPallyConConfig()
        } else {
            // Streaming
            let strToken = token ?? ""
            let strCustomData = customData ?? ""
            let strDrmLicenseUrl = drmLicenseUrl ?? ""
            let configString = "{\"drmConfig\":{\"siteId\":\"\(self.siteId)\",\"contentId\":\"\(contentId)\",\"drmLicenseUrl\":\"\(strDrmLicenseUrl)\",\"token\":\"\(strToken)\",\"customData\":\"\(strCustomData)\"},\"url\":\"\(url)\"}"
            return configString
        }
    }

    public func getDownloadState(url: String) -> String {
        if let contentInfo = loadDownloadedContent(with: url, contentId: "") {
            downloadedContentMap[url] = contentInfo
            return DownloadState.completed.name
        }

        return DownloadState.not.name
    }

    public func addStartDownload(url: String, contentId: String, token: String?, customData: String?, httpHeaders: Dictionary<String, String>?, cookie: String?, drmLicenseUrl: String?, appleCertUrl: String?) {
//        sendPallyConEvent(url: url, eventType: PallyConEventType.complete, message: "Complete")
        for (task, downloadContent) in downloadTaskMap {
            print("download task \(downloadContent.contentId)")
            if downloadContent.url == url {
                print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
                task.resume()
                return
            }
        }

        guard let contentUrl:URL = URL(string: url) else {
            sendPallyConEvent(url: url, eventType: PallyConEventType.downloadError, message: "String to URL convert Error!", errorCode: "")
            return
        }

        let urlAsset = AVURLAsset(url: contentUrl)
        print("https://license-global.pallycon.com/ri/fpsKeyManager.do?siteId=\(siteId)")
        let drm_content = PallyConDrmConfiguration(avURLAsset: urlAsset,
                                                   contentId: contentId,
                                                   certificateUrl: "https://license-global.pallycon.com/ri/fpsKeyManager.do?siteId=\(siteId)",
                                                   authData: token,
                                                   delegate: self)
        guard let downloadTask = fpsSdk?.createDownloadTask(Content: drm_content, delegate: self) else {
            self.sendPallyConEvent(url: url, eventType: PallyConEventType.downloadError, message: "DownloadTask not Create! ", errorCode: "")
            return
        }

        let contentInfo = DrmContent(siteId: self.siteId, drmType: "", url: url, contentId: contentId,
                                     token: token!, customData: customData, httpHeader: httpHeaders,
                                     cookie: cookie, drmLicenseUrl: drmLicenseUrl,
                                     appleCertUrl: "", downloadState: DownloadState.not, path: "")
        downloadTaskMap[downloadTask] = contentInfo
        downloadTask.resume()
    }

    public func resumeAll() {
        for task in downloadTaskMap.keys {
            task.resume()
            downloadTaskMap[task]?.downloadState = DownloadState.downloading
        }
    }

    public func cancelAll() {
        for task in downloadTaskMap.keys {
            task.cancel()
            downloadTaskMap[task]?.downloadState = DownloadState.pause
        }
    }

    public func pauseAll() {
        for task in downloadTaskMap.keys {
            if downloadTaskMap[task]?.downloadState == DownloadState.downloading {
                task.cancel()
                downloadTaskMap[task]?.downloadState = DownloadState.pause
                self.sendPallyConEvent(url: downloadTaskMap[task]!.url,
                                       eventType: PallyConEventType.pause,
                                       message: "User Downloaded Content Pause")
            } else {
                task.resume()
                downloadTaskMap[task]?.downloadState = DownloadState.downloading
            }
        }
    }

    public func resumeDwonloadTask(_ contentId: String) {
        for (task, downloadContent) in downloadTaskMap {
            if downloadContent.contentId == contentId {
                task.resume()
                downloadTaskMap[task]?.downloadState = DownloadState.pause
                break
            }
        }
    }

    public func cancelDwonloadTask(_ contentId: String) {
        for (task, downloadContent) in downloadTaskMap {
            if downloadContent.contentId == contentId {
                task.cancel()
                downloadTaskMap[task]?.downloadState = DownloadState.pause
                break
            }
        }
    }

    public func removeDownload(url: String) {
        guard let downloadedContent = downloadedContentMap[url] else {
            return
        }
        self.deleteDowndloadedContent(for: downloadedContent)
        downloadedContentMap.removeValue(forKey: url)
        self.sendPallyConEvent(url: url, eventType: PallyConEventType.remove, message: "Remove Downloaded Content")
    }

    public func removeLicense(url: String) {
        guard let downloadedContent = downloadedContentMap[url] else {
            return
        }
        self.fpsSdk?.deleteLicense(ContentId: downloadedContent.contentId)
    }
}


extension PallyConSdk: PallyConFPSDownloadDelegate {
    func downloadContent(_ contentId: String, didStartDownloadWithAsset asset: AVURLAsset, subtitleDisplayName: String) {
        print("downloadContent : didStartDownloadWithAsset\(contentId) : \(subtitleDisplayName)")
        guard let downloadEvent = self.progressEvent else {
            print("downloadContent didStartDownloadWithAsset : downloadEvent")
            return
        }

        var contentUrl:String = ""
        for (downloadContent) in downloadTaskMap.values {
            if downloadContent.contentId == contentId {
                contentUrl = downloadContent.url
                break
            }
        }

        var event = Dictionary<String, Any>()
        event["url"] = contentUrl
        event["percent"] = 100
        event["downloadedBytes"] = 0

        //downloadEvent(event)
        //setDownloadProgress(eventSink: downloadEvent)
    }

    func downloadContent(_ contentId: String, didStopWithError error: Error?) {
        print("downloadContent : didStopWithError \(contentId)")
        var localPath: String?
        var stopError: Error?
        // send flutter Error
        if let error = error as? PallyConSDKException {
            switch error {
            case .DownloadUserCancel(let filePath):
                print("User Cancel Error \(filePath)")
                localPath = filePath
                stopError = error
                break
            case .DownloadUnknownError(let filePath):
                localPath = filePath
                stopError = error
                break
            case .DownloadDefaultError(let networkError, let filePath):
                print("didStopWithError error = \(networkError) \(filePath)")
                let alert = UIAlertController(title: "Download Failed", message: "If you want to download, please try again", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default))
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            default:
                print("Error: \(error). Unkown.")
                break
            }
        }

        var contentUrl:String = ""
        for (task, downloadContent) in downloadTaskMap {
            if downloadContent.contentId == contentId {
                contentUrl = downloadContent.url
                downloadTaskMap.removeValue(forKey: task)
                break
            }
        }
        // PallyCon SDK Error
        var message = ""
        if let error = error as? PallyConError {
            switch error {
            case .database(comment: let comment):
                message = comment
            case .server(errorCode: let errorCode, comment: let comment):
                message = "code : \(errorCode), comment: \(comment)"
            case .network(errorCode: let errorCode, comment: let comment):
                message = "code : \(errorCode), comment: \(comment)"
            case .system(errorCode: let errorCode, comment: let comment):
                message = "code : \(errorCode), comment: \(comment)"
            case .failed(errorCode: let errorCode, comment: let comment):
                message = "code : \(errorCode), comment: \(comment)"
            case .unknown(errorCode: let errorCode, comment: let comment):
                message = "code : \(errorCode), comment: \(comment)"
            case .invalid(comment: let comment):
                message = "comment: \(comment)"
            default:
                message = "comment: \(error)"
                break
            }

            self.sendPallyConEvent(url: contentUrl, eventType: PallyConEventType.unknownError,
                                   message: "download stop : \(String(describing: localPath)) \n\(message)",
                                   errorCode: "")
        } else {
            // 정상적으로 다운로드가 멈출 때
            self.sendPallyConEvent(url: contentUrl, eventType: PallyConEventType.pause,
                                   message: "user download stop : \(String(describing: localPath))",
                                   errorCode: "")
        }

    }

    func downloadContent(_ contentId: String, didFinishDownloadingTo location: URL) {
        print("downloadContent : didFinishDownloadingTo : \(location)")

        var contentUrl:String = ""
        for (task, downloadContent) in downloadTaskMap {
            if downloadContent.contentId == contentId {
                contentUrl = downloadContent.url
                self.saveDownloadedContent(for: downloadContent, location: location)
                downloadTaskMap.removeValue(forKey: task)
                break
            }
        }

        self.sendPallyConEvent(url: contentUrl, eventType: PallyConEventType.complete, message: "\(location.absoluteString)", errorCode: "")

        return
    }

    func downloadContent(_ contentId: String, didLoad timeRange: CMTimeRange, totalTimeRangesLoaded loadedTimeRanges: [NSValue], timeRangeExpectedToLoad: CMTimeRange) {
        //print("downloadContent : didFinishDownloadingTo : \(contentId)")
        guard let downloadEvent = self.progressEvent else {
            print("downloadContent didFinishDownloadingTo : downloadEvent fail")
              return
        }

        var contentUrl:String = ""
        for (task, downloadContent) in downloadTaskMap {
            if downloadContent.contentId == contentId {
                contentUrl = downloadContent.url
                downloadTaskMap[task]?.downloadState = DownloadState.downloading
                break
            }
        }

        var percentComplete:Double = 0.0
        for value in loadedTimeRanges {
            let loadedTimeRange : CMTimeRange = value.timeRangeValue
            percentComplete += CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }

        var event = Dictionary<String, Any>()
        event["url"] = contentUrl
        event["percent"] = (percentComplete*100)
        event["downloadedBytes"] = 0
        downloadEvent(event)
        self.setDownloadProgress(eventSink: downloadEvent)
        print("downloadContent : didFinishDownloadingTo : \(contentId) : \(percentComplete*100)")
    }
}


extension PallyConSdk: PallyConFPSLicenseDelegate {

    func license(result: PallyConResult) {
        print("---------------------------- License Result ")
        print("Content ID : \(result.contentId)")
        print("Key ID     : \(String(describing: result.keyId))")
        //print("Expiry Date: \(String(describing: result.offlineExpiry))")
        var message: String = ""
        if result.isSuccess == false {
             print("Error : \(String(describing: result.error?.localizedDescription))")
             if let error = result.error {
                  switch error {
                  case .database(comment: let comment):
                       print(comment)
                       message = comment
                  case .server(errorCode: let errorCode, comment: let comment):
                       print("code : \(errorCode), comment: \(comment)")
                       message = "code : \(errorCode), comment: \(comment)"
                  case .network(errorCode: let errorCode, comment: let comment):
                       print("code : \(errorCode), comment: \(comment)")
                       message = "code : \(errorCode), comment: \(comment)"
                  case .system(errorCode: let errorCode, comment: let comment):
                       print("code : \(errorCode), comment: \(comment)")
                       message = "code : \(errorCode), comment: \(comment)"
                  case .failed(errorCode: let errorCode, comment: let comment):
                       print("code : \(errorCode), comment: \(comment)")
                       message = "code : \(errorCode), comment: \(comment)"
                  case .unknown(errorCode: let errorCode, comment: let comment):
                       print("code : \(errorCode), comment: \(comment)")
                       message = "code : \(errorCode), comment: \(comment)"
                  case .invalid(comment: let comment):
                       print("comment: \(comment)")
                       message = "comment: \(comment)"
                  default:
                       print("comment: \(error)")
                       message = "comment: \(error)"
                      break
                  }
             }
        }
        self.sendPallyConEvent(url: result.contentId,
                               eventType: PallyConEventType.drmError,
                               message: message, errorCode: "")
    }
}


extension PallyConSdk {
    // managed download contents
    func loadDownloadedContent(with url: String, contentId: String ) -> DrmContent? {
        let userDefaults = UserDefaults.standard
        guard let localFileLocation = userDefaults.value(forKey: url) as? String else { return nil }

        let localFilePath = PallyConSdk.baseDownloadURL.appendingPathComponent(localFileLocation)
        print("\(localFilePath.absoluteString)")
        if FileManager.default.fileExists(atPath: localFilePath.path) {
            let drmContent = DrmContent(siteId: self.siteId, url: url, contentId: contentId, path: localFilePath.absoluteString)
            return drmContent
        }
        return nil
    }

    func saveDownloadedContent(for drmContent: DrmContent, location: URL) {
        downloadedContentMap[drmContent.url] = drmContent
        downloadedContentMap[drmContent.url]?.downloadState = DownloadState.completed
        let contentUrl =  PallyConSdk.baseDownloadURL.appendingPathComponent(location.relativePath)
        downloadedContentMap[drmContent.url]?.downloadPath = contentUrl.absoluteString
        let userDefaults = UserDefaults.standard
        userDefaults.set(location.relativePath, forKey: drmContent.url)
    }

    func deleteDowndloadedContent(for drmContent: DrmContent) {
        let userDefaults = UserDefaults.standard

        do {
            if let localFileLocation = userDefaults.value(forKey: drmContent.url) as? String {
                let localFileLocation = PallyConSdk.baseDownloadURL.appendingPathComponent(localFileLocation)
                try FileManager.default.removeItem(at: localFileLocation)
                userDefaults.removeObject(forKey: drmContent.url)

                self.removeLicense(url: drmContent.url)
            }
        } catch {
            print("An error occured deleting the file: \(error)")
        }
    }
}
