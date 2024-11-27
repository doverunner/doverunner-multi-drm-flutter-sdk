import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pallycon_drm_sdk_android/pallycon_drm_sdk_android.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Android';
  var _pallyConDrmSdk = PallyConDrmSdkAndroid.shared;
  var config = PallyConContentConfiguration(
    "test_simple",
    "https://contents.pallycon.com/TEST/PACKAGED_CONTENT/TEST_SIMPLE/dash/stream.mpd",
    token: "eyJrZXlfcm90YXRpb24iOmZhbHNlLCJyZXNwb25zZV9mb3JtYXQiOiJvcmlnaW5hbCIsInVzZXJfaWQiOiJwYWxseWNvbiIsImRybV90eXBlIjoid2lkZXZpbmUiLCJzaXRlX2lkIjoiREVNTyIsImhhc2giOiJkNTBDSVVUS1RwRDl6T3dGaU9DSysrXC83Q3pLOStZN3NkcHFhUUppdDJWQT0iLCJjaWQiOiJUZXN0UnVubmVyIiwicG9saWN5IjoiOVdxSVdrZGhweFZHSzhQU0lZY25Kc2N2dUE5c3hndWJMc2QrYWp1XC9ib21RWlBicUkreGFlWWZRb2Nja3Z1RWZBYXFkVzVoWGdKTmdjU1MzZlM3bzhNczB3QXNuN05UbmJIUmtwWDFDeTEyTkhwMlZPN1pMeFJvZDhVdkUwZnBFbUpYOUpuRDh6ZktkdE9RWk9UYXljK280RzNCT0xmU29OaFpWbkIwUGxEbW1rVk5jbXpndko2YloxdXBudjFcLzJFM2lXZXd3eklTNFVOQlhTS21zVUFCZnBRQjg4Q2VJYlZSM0hKZWJvcEpwZG1DTFFvRmtCT09DQU9qWElBOUVHIiwidGltZXN0YW1wIjoiMjAyMi0xMC0xMVQwNzowMToxN1oifQ==",
    licenseUrl: "https://license-global.pallycon.com/ri/licenseManager.do/",
  );

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion = "None";
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      // await PallyConDrmSdkPlatform.instance.initialize();
      _pallyConDrmSdk.onPallyConEvent.listen((event) {
        setState(() {
          _platformVersion = event.eventType.toString();
        });
      }).onError((error) {
        print("aasdf");
      });

      _pallyConDrmSdk.onDownloadProgress.listen((event) {
        setState(() {
          _platformVersion = "download ${event.percent}";
        });
        print("${event.url}, ${event.percent}");
      });

      await _pallyConDrmSdk.initialize("DEMO");

    } catch(e) {
      _platformVersion = e.toString();
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> downloadContent() async {
    _pallyConDrmSdk.addStartDownload(config);
  }

  Future<void> getContent() async {
    final content = await _pallyConDrmSdk.getObjectForContent(config);
    final state = await _pallyConDrmSdk.getDownloadState(config);
    final needsMigration = await _pallyConDrmSdk.needsMigrateDatabase(config);
    final migrate = await _pallyConDrmSdk.migrateDatabase(config);
    final updateSecure = await _pallyConDrmSdk.updateSecureTime();
    final reDownload = await _pallyConDrmSdk.reDownloadCertification(config);
    print(content);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: ListView(
            children: [
              Text('Running on: $_platformVersion\n'),
              ElevatedButton( onPressed: () {
                downloadContent();
              }, child: Text('Download BUTTON'), ),
              ElevatedButton( onPressed: () {
                getContent();
              }, child: Text('Get BUTTON'), ),

            ],
          )
        ),
      ),
    );
  }
}
