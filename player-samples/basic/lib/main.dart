import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pallycon_drm_sdk/pallycon_drm_sdk.dart';
import 'dart:io' show Platform;

void main() => runApp(VideoApp());

class VideoApp extends StatefulWidget {
  @override
  _VideoAppState createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  static const siteId = "DEMO";
  static const inkaLicenseUrl =
      "https://license-global.pallycon.com/ri/licenseManager.do";
  static const content_android =
      "https://contents.pallycon.com/DEMO/app/big_buck_bunny/dash/stream.mpd";
  static const token_android =
      "eyJkcm1fdHlwZSI6IldpZGV2aW5lIiwic2l0ZV9pZCI6IkRFTU8iLCJ1c2VyX2lkIjoidGVzdFVzZXIiLCJjaWQiOiJkZW1vLWJiYi1zaW1wbGUiLCJwb2xpY3kiOiI5V3FJV2tkaHB4VkdLOFBTSVljbkp1dUNXTmlOK240S1ZqaTNpcEhIcDlFcTdITk9uYlh6QS9pdTdSa0Vwbk85c0YrSjR6R000ZkdCMzVnTGVORGNHYWdPY1Q4Ykh5c3k0ZHhSY2hYV2tUcDVLdXFlT0ljVFFzM2E3VXBnVVdTUCIsInJlc3BvbnNlX2Zvcm1hdCI6Im9yaWdpbmFsIiwia2V5X3JvdGF0aW9uIjpmYWxzZSwidGltZXN0YW1wIjoiMjAyMi0wOC0wM1QwMjo1NzowOVoiLCJoYXNoIjoiK2dmTkVMRXVoQ3lrTGZGS0FuMW0xcmVralI4elFqVVh1dGtXOG9tRTU1RT0ifQ==";
  static const content_ios =
      "https://contents.pallycon.com/DEMO/app/big_buck_bunny/hls/master.m3u8";
  static const token_ios =
      "eyJkcm1fdHlwZSI6IkZhaXJQbGF5Iiwic2l0ZV9pZCI6IkRFTU8iLCJ1c2VyX2lkIjoidGVzdFVzZXIiLCJjaWQiOiJkZW1vLWJiYi1zaW1wbGUiLCJwb2xpY3kiOiI5V3FJV2tkaHB4VkdLOFBTSVljbkp1dUNXTmlOK240S1ZqaTNpcEhIcDlFcTdITk9uYlh6QS9pdTdSa0Vwbk85c0YrSjR6R000ZkdCMzVnTGVORGNHYWdPY1Q4Ykh5c3k0ZHhSY2hYV2tUcDVLdXFlT0ljVFFzM2E3VXBnVVdTUCIsInJlc3BvbnNlX2Zvcm1hdCI6Im9yaWdpbmFsIiwia2V5X3JvdGF0aW9uIjpmYWxzZSwidGltZXN0YW1wIjoiMjAyMy0wMy0wN1QwNjoxNDo1OFoiLCJoYXNoIjoieDhycTR6VkMzelU1dXdEM3dYVHRlUkJRbTBtcVE1dE8yRUphZWhOV2luMD0ifQ==";

  static const platform = MethodChannel('com.pallycon/startActivity');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Demo',
      home: Scaffold(
        body: Center(
          child: MaterialButton(
            color: Colors.orange,
            onPressed: () => _startPlayer(),
            child: const Text("PLAY"),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _startPlayer() async {
    try {
      try {
        await PallyConDrmSdk.initialize(siteId);
      } on IllegalArgumentException catch (e) {
        print(e.message);
      } on PermissionRequiredException catch (e) {
        print(e.message);
      }

      PallyConContentConfiguration? config = null;
      if (Platform.isAndroid) {
        config = PallyConContentConfiguration("big_buck_bunny", content_android,
            token: token_android, licenseUrl: inkaLicenseUrl);
      } else {
        config = PallyConContentConfiguration("big_buck_bunny", content_ios,
            token: token_ios, licenseUrl: inkaLicenseUrl);
      }

      var object = await PallyConDrmSdk.getObjectForContent(config);

      final String result =
          await platform.invokeMethod('StartSecondActivity', object);

      debugPrint('Result: $result ');
    } on PlatformException catch (e) {
      debugPrint("Error: '${e.message}'.");
    }
  }
}
