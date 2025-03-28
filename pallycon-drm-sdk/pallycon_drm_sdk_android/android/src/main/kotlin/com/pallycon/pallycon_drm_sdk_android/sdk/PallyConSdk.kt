package com.pallycon.pallycon_drm_sdk_android.sdk

import DownloadProgressEvent
import PallyConEvent
import android.content.Context
import androidx.media3.common.C
import com.google.gson.Gson
import com.pallycon.pallycon_drm_sdk_android.db.DatabaseManager
import com.pallycon.pallycon_drm_sdk_android.models.*
import com.pallycon.widevine.exception.PallyConException
import com.pallycon.widevine.exception.PallyConLicenseServerException
import com.pallycon.widevine.model.ContentData
import com.pallycon.widevine.model.DownloadState
import com.pallycon.widevine.model.PallyConDrmConfigration
import com.pallycon.widevine.model.PallyConEventListener
import com.pallycon.widevine.sdk.PallyConWvSDK
import com.pallycon.widevine.track.PallyConDownloaderTracks
import kotlinx.coroutines.*


class PallyConSdk(val context: Context) {
    companion object {
        private var instance: PallyConSdk? = null

        fun getInstance(context: Context): PallyConSdk {
            if (instance == null) {
                instance = PallyConSdk(context)
            }
            return instance!!
        }
    }

    private var pallyConEvent: PallyConEvent? = null
    private var progressEvent: DownloadProgressEvent? = null

    private var siteId: String? = null
    private val wvSDKList = mutableMapOf<String, PallyConWvSDK>()
    private val contentDataList = mutableListOf<ContentData>()

    private val listener: PallyConEventListener = object : PallyConEventListener {
        override fun onCompleted(contentData: com.pallycon.widevine.model.ContentData) {
            instance?.pallyConEvent?.sendPallyConEvent(
                contentData,
                EventType.Completed,
                "download completed"
            )
        }

        override fun onProgress(
            contentData: com.pallycon.widevine.model.ContentData,
            percent: Float,
            downloadedBytes: Long,
        ) {
            instance?.progressEvent?.sendProgressEvent(contentData, percent, downloadedBytes)
        }

        override fun onStopped(contentData: com.pallycon.widevine.model.ContentData) {
            instance?.pallyConEvent?.sendPallyConEvent(contentData, EventType.Stop, "download stop")
        }

        override fun onRestarting(contentData: com.pallycon.widevine.model.ContentData) {
            print("onRestarting")
        }

        override fun onRemoved(contentData: com.pallycon.widevine.model.ContentData) {
            instance?.pallyConEvent?.sendPallyConEvent(
                contentData,
                EventType.Removed,
                "downloaded content is removed"
            )
        }

        override fun onPaused(contentData: com.pallycon.widevine.model.ContentData) {
            contentDataList.forEach { content ->
                instance?.pallyConEvent?.sendPallyConEvent(
                    content,
                    EventType.Paused,
                    "download paused"
                )
            }
        }

        override fun onFailed(
            contentData: com.pallycon.widevine.model.ContentData,
            e: PallyConException?,
        ) {
            when (e) {
                is PallyConException.ContentDataException ->
                    instance?.pallyConEvent?.sendPallyConEvent(
                        contentData,
                        EventType.ContentDataError,
                        e.msg
                    )

                is PallyConException.DrmException ->
                    instance?.pallyConEvent?.sendPallyConEvent(contentData, EventType.DrmError, e.msg)

                is PallyConException.DownloadException ->
                    instance?.pallyConEvent?.sendPallyConEvent(
                        contentData,
                        EventType.DownloadError,
                        e.msg
                    )

                is PallyConException.NetworkConnectedException ->
                    instance?.pallyConEvent?.sendPallyConEvent(
                        contentData,
                        EventType.NetworkConnectedError,
                        e.msg
                    )

                is PallyConException.DetectedDeviceTimeModifiedException ->
                    instance?.pallyConEvent?.sendPallyConEvent(
                        contentData,
                        EventType.DetectedDeviceTimeModifiedError,
                        e.msg
                    )

                is PallyConException.MigrationException ->
                    instance?.pallyConEvent?.sendPallyConEvent(
                        contentData,
                        EventType.MigrationError,
                        e.msg
                    )
                is PallyConException.PallyConLicenseCipherException ->
                    instance?.pallyConEvent?.sendPallyConEvent(
                        contentData,
                        EventType.LicenseCipherError,
                        e.msg
                    )
                else ->
                    instance?.pallyConEvent?.sendPallyConEvent(
                        contentData, EventType.UnknownError,
                        e?.msg ?: "unknown error"
                    )
            }
        }

        override fun onFailed(
            contentData: com.pallycon.widevine.model.ContentData,
            e: PallyConLicenseServerException?,
        ) {
            e?.let {
                instance?.pallyConEvent?.sendPallyConEvent(
                    contentData, EventType.LicenseServerError,
                    it.message(), it.errorCode().toString()
                )
            }
        }
    }

    fun setPallyConEvent(pallyConEvent: PallyConEvent?) {
        this.pallyConEvent = pallyConEvent

//        wvSDKList.entries.firstOrNull()?.let { (_, sdk) ->
//            sdk.setPallyConEventListener(listener)
//        }
    }

    fun setDownloadProgressEvent(downloadProgressEvent: DownloadProgressEvent?) {
        this.progressEvent = downloadProgressEvent
    }

    fun initialize(siteId: String) {
        this.siteId = siteId

//        PallyConWvSDK.removePallyConEventListener(listener)
        PallyConWvSDK.addPallyConEventListener(listener)
        loadDownloaded()
    }

    fun release() {
        PallyConWvSDK.removePallyConEventListener(listener)
        wvSDKList.forEach { sdk ->
            sdk.value.release()
        }
        contentDataList.clear()
    }

    private fun loadDownloaded() {
        if (contentDataList.isEmpty()) {
            if (siteId == null) {
                return
            }
            val db = DatabaseManager.getInstance(context)
            contentDataList.addAll(db.getContents(siteId!!))
            contentDataList.forEach() { contentData ->
                contentData.contentId?.let {
                    wvSDKList[it] = PallyConWvSDK.createPallyConWvSDK(
                        context,
                        contentData
                    )
                }
//                if (contentData.contentId == null && contentData.url != null) {
//                    val key = contentData.url + "_haveTo"
//                    wvSDKList[key] = PallyConWvSDK.createPallyConWvSDK(
//                        context,
//                        contentData
//                    )
//                } else if (contentData.contentId != null) {
//                    wvSDKList[contentData.contentId!!] = PallyConWvSDK.createPallyConWvSDK(
//                        context,
//                        contentData
//                    )
//                }
            }
        }

//        wvSDKList.entries.firstOrNull()?.let { (_, sdk) ->
//            sdk.setPallyConEventListener(listener)
//        }
    }

    private fun saveDownloadedContent() {
        siteId?.let {
            DatabaseManager.getInstance(context).setContents(it, contentDataList)
        }
    }

    suspend fun getObjectForContent(config: PallyConContentConfiguration): String {
        return suspendCancellableCoroutine<String> { continuation ->
            if (wvSDKList[config.contentId] != null && config.contentUrl != null) {
                wvSDKList[config.contentId]!!.updateSecure({
                    print("update secure time")
                    val index =
                        contentDataList.indices.find { contentDataList[it].url == config.contentUrl }
                    if (index != null) {
                        val gson = Gson().toJson(contentDataList[index])
                        continuation.resume(gson, null)
                    } else {
                        continuation.resume(config.contentUrl!!, null)
                    }
                }, { e ->
                    pallyConEvent?.sendPallyConEvent(
                        config.contentId,
                        config.contentUrl,
                        EventType.DetectedDeviceTimeModifiedError,
                        e.msg
                    )
                    continuation.resume("", null)
                })
            } else {
                // streaming
                val contentData = createContentData(config)
                val gson = Gson().toJson(contentData)
                continuation.resume(gson, null)
            }
        }
    }

    fun getDownloadState(config: PallyConContentConfiguration): String {
        var stateString = "NOT"
        wvSDKList[config.contentId]?.let {
            val state = it.getDownloadState()
            stateString = when (state) {
                DownloadState.DOWNLOADING, DownloadState.RESTARTING -> DownloadState.DOWNLOADING.toString()
                DownloadState.COMPLETED -> DownloadState.COMPLETED.toString()
                DownloadState.PAUSED, DownloadState.STOPPED -> DownloadState.PAUSED.toString()
                else -> DownloadState.NOT.toString()
            }
        }

        return stateString
    }

    fun addStartDownload(config: PallyConContentConfiguration) {
        val data = createContentData(config)

        if (!contentDataList.contains(data)) {
            contentDataList.add(data)
        }

        wvSDKList[config.contentId!!] = PallyConWvSDK.createPallyConWvSDK(
            context,
            data
        )

        wvSDKList[config.contentId]?.also { sdk ->
            sdk.updateSecure({
                print("update secure time")
            }, {
                print("failed update secure time. ${it.msg}")
            })

            sdk.getContentTrackInfo({ tracks ->
                saveDownloadedContent()
                downloadContent(config, tracks)
            }, { e ->
                when (e) {
                    is PallyConException.NetworkConnectedException ->
                        pallyConEvent?.sendPallyConEvent(
                            config.contentId,
                            config.contentUrl,
                            EventType.NetworkConnectedError,
                            e.msg
                        )

                    is PallyConException.ContentDataException ->
                        pallyConEvent?.sendPallyConEvent(
                            config.contentId,
                            config.contentUrl,
                            EventType.ContentDataError,
                            e.msg
                        )

                    else ->
                        pallyConEvent?.sendPallyConEvent(
                            config.contentId,
                            config.contentUrl,
                            EventType.DownloadError,
                            e.msg
                        )
                }
            })
        }
    }

    fun downloadContent(config: PallyConContentConfiguration, tracks: PallyConDownloaderTracks) {
        wvSDKList[config.contentId]?.also { sdk ->
            for (i in tracks.audio.indices) {
                tracks.audio[i].isDownload = true
            }
            for (i in tracks.text.indices) {
                tracks.text[i].isDownload = true
            }

            try {
                sdk.download(tracks)
            } catch (e: PallyConException.ContentDataException) {
                pallyConEvent?.sendPallyConEvent(
                    config.contentId,
                    config.contentUrl,
                    EventType.ContentDataError,
                    e.msg
                )
            } catch (e: PallyConException.DownloadException) {
                pallyConEvent?.sendPallyConEvent(config.contentId, config.contentUrl,
                    EventType.DownloadError, e.msg)
            }
        }
    }

    fun stopDownload(config: PallyConContentConfiguration) {
        val data = createContentData(config)

        wvSDKList[config.contentId]?.also { sdk ->
            sdk.stop()
        }
    }

    fun resumeAll() {
        for (sdk in wvSDKList.entries.iterator()) {
            sdk.value.resumeAll()
            break
        }
    }

    fun cancelAll() {
        pauseAll()
        for (sdk in wvSDKList.entries.iterator()) {
            val contentData = contentDataList.find { it.contentId == sdk.key }
            contentData?.url?.let {
                removeDownload(it, sdk.key)
            }
        }
    }

    fun pauseAll() {
        for (sdk in wvSDKList.entries.iterator()) {
            sdk.value.pauseAll()
            break
        }
    }

    fun removeDownload(url: String, contentId: String): Boolean {
        return if (wvSDKList.containsKey(contentId)) {
            try {
                wvSDKList[contentId]!!.remove()
                true
            } catch (e: PallyConException.ContentDataException) {
                pallyConEvent?.sendPallyConEvent(contentId, url, EventType.ContentDataError, e.msg)
                false
            } catch (e: PallyConException.DownloadException) {
                pallyConEvent?.sendPallyConEvent(contentId, url, EventType.DownloadError, e.msg)
                false
            }
        } else {
            false
        }
    }

    fun removeLicense(url: String, contentId: String): Boolean {
        return if (wvSDKList.containsKey(contentId)) {
            try {
                wvSDKList[contentId]!!.removeLicense()
                true
            } catch (e: PallyConException.ContentDataException) {
                pallyConEvent?.sendPallyConEvent(contentId, url, EventType.ContentDataError, e.msg)
                false
            } catch (e: PallyConException.DownloadException) {
                pallyConEvent?.sendPallyConEvent(contentId, url, EventType.DownloadError, e.msg)
                false
            }
        } else {
            false
        }
    }

    suspend fun needsMigrateDatabase(config: PallyConContentConfiguration): Boolean {
        if (siteId == null) {
            print("initialize function must be executed first.")
            return false
        }

        if (wvSDKList.size != contentDataList.size) {
            return true
        }

        wvSDKList[config.contentId]?.let {
            return it.needsMigrateDownloadedContent()
        }

        return false
    }

    suspend fun migrateDatabase(config: PallyConContentConfiguration): Boolean {
        if (siteId == null) {
            print("initialize function must be executed first.")
            return false
        }

        if (contentDataList.size != wvSDKList.size) {
            for (i in 0..contentDataList.lastIndex) {
                if (contentDataList[i].contentId == null &&
                    contentDataList[i].url == config.contentUrl
                ) {
                    contentDataList[i].contentId = config.contentId
                }
            }
            saveDownloadedContent()
            release()
            loadDownloaded()
        }

        var isOK = true
        if (config.contentId == null) {
            return false
        }

        wvSDKList[config.contentId]?.let {
            isOK = it.migrateDownloadedContent(config.contentId!!, null)
        }

        return isOK
    }

    suspend fun reDownloadCertification(): Boolean {
        return suspendCancellableCoroutine<Boolean> { continuation ->
            if (wvSDKList.isNotEmpty()) {
                wvSDKList.entries.first().value.reProvisionRequest({
                    continuation.resume(true, null)
                }, { e ->
                    pallyConEvent?.sendPallyConEvent(
                        "",
                        wvSDKList.entries.first().key,
                        EventType.DrmError,
                        e.msg
                    )
                    continuation.resume(false, null)
                })
            } else {
                pallyConEvent?.sendPallyConEvent(
                    "",
                    "",
                    EventType.ContentDataError,
                    "No content has been downloaded."
                )
                continuation.resume(false, null)
            }
        }
    }

    suspend fun updateSecureTime(): Boolean {
        return suspendCancellableCoroutine<Boolean> { continuation ->
            if (wvSDKList.isNotEmpty()) {
                wvSDKList.entries.first().value.updateSecure({
                    continuation.resume(true, null)
                }, { e ->
                    pallyConEvent?.sendPallyConEvent(
                        wvSDKList.entries.first().key,
                        "",
                        EventType.DrmError,
                        e.msg
                    )
                    continuation.resume(false, null)
                })
            } else {
                pallyConEvent?.sendPallyConEvent(
                    "",
                    "",
                    EventType.ContentDataError,
                    "No content has been downloaded."
                )
                continuation.resume(false, null)
            }
        }
    }

    private fun createContentData(config: PallyConContentConfiguration): ContentData {
        if (siteId == null) {
            print("initialize function must be executed first.")
            return ContentData(
                contentId = config.contentId,
                url = config.contentUrl,
                drmConfig = null,
                cookie = config.contentCookie
            )
        }

        var contentHeaders: MutableMap<String?, String?>? = null
        if (config.contentHttpHeaders != null) {
            contentHeaders = config.contentHttpHeaders!!.toMutableMap()
        }

        var licenseHeaders: MutableMap<String?, String?>? = null
        if (config.licenseHttpHeaders != null) {
            licenseHeaders = config.licenseHttpHeaders!!.toMutableMap()
        }

        val cipherPath = if (config.licenseCipherTablePath != null &&
            config.licenseCipherTablePath!!.isNotEmpty()) {
            config.licenseCipherTablePath
        } else {
            null
        }

        val drmConfig = PallyConDrmConfigration(
            siteId = siteId!!,
            siteKey = null,
            token = config.token,
            customData = config.customData,
            httpHeaders = licenseHeaders,
            cookie = config.licenseCookie,
            licenseCipherPath = cipherPath,
            drmLicenseUrl = config.licenseUrl ?: "https://license-global.pallycon.com/ri/licenseManager.do",
            C.WIDEVINE_UUID
        )

        return ContentData(
            contentId = config.contentId,
            url = config.contentUrl,
            drmConfig = drmConfig,
            cookie = config.contentCookie,
            httpHeaders = contentHeaders
        )
    }
}

