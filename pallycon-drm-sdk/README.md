# PallyCon DRM SDK for flutter

**`PallyCon DRM SDK for flutter`** follows a federated architecture, which includes the following packages.
> In the trial account, you can freely test SDK products within the trial limit on the number of licenses issued. However, in order to apply the SDK to commercial services, you must apply for a plan that includes SDK usage rights when subscribing to PallyCon commercial plans.

This document describes the usage and API of **`pallycon_drm_sdk`**.
The example of **`pallycon_drm_sdk`** is available on [player-sample][9].

## **important**

> To develop using the SDK, you must first sign up for the [PallyCon Site][10] and obtain a **`Site ID`**.

## Packages

```
// flutter plugin for PallyCon Multi-DRM SDK
pallycon-drm-sdk
    |
    ├─ pallycon_drm_sdk
    ├─ pallycon_drm_sdk_android
    ├─ pallycon_drm_sdk_ios
    └─ pallycon_drm_sdk_interface
```

### 1. [`pallycon_drm_sdk`][1]
 - The package that faces the app. 
 - It's what users rely on to use the plugin in their projects. 
 - For usage details, refer to its [README.md][2] file.

### 2. [`pallycon_drm_sdk_android`][3]
 - This package holds the official Android implementation of the [pallycon_drm_sdk_interface][7] and adds Android support to the [pallycon_drm_sdk][1] package.
 - More information can be found in its [README.md][4] file.

### 3. [`pallycon_drm_sdk_ios`][5]
 - This package holds the official iOS implementation of the [pallycon_drm_sdk_interface][7] and adds iOS support to the [pallycon_drm_sdk][1] package.
 - More information can be found in its [README.md][6] file.

### 4. [`pallycon_drm_sdk_interface`][7]
 - This package defines the interface that all platform packages must implement to support the app-facing package.
 - Instructions on how to implement a platform package can be found in the [README.md][8] of the [pallycon_drm_sdk_interface][7] package.


## **support environment**

- Android 6.0 (API 23) & Android targetSdkVersion 34 or higher
- iOS 14.0 higher

Below are the Android and iOS properties required for **`pallycon_drm_sdk`** to work properly.

#### **Android**

- **compileSdkVersion**

  Make sure you set `compileSdkVersion` in "android/app/build.gradle".

  ```
  android {
    compileSdkVersion 34

    ...
  }
  ```

- **Permissions**

  Inside the SDK, the following 4 items are used in relation to user permission.

  ``` xml
  <!-- AndroidManifest.xml -->
  <uses-permission android:name="android.permission.INTERNET" />
  <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
  <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
  ```


#### **iOS**

- [cocoapods][11] is used as a library dependency manager in the Xcode project, so it must be installed on macOS.
  - cocoapods installation and usage are available on this [link][12].
  
- `pallycon_drm_sdk` does not support simulators on iOS. Please test on a real device.



[1]: ./pallycon_drm_sdk
[2]: ./pallycon_drm_sdk/README.md
[3]: ./pallycon_drm_sdk_android
[4]: ./pallycon_drm_sdk_android/README.md
[5]: ./pallycon_drm_sdk_ios
[6]: ./pallycon_drm_sdk_ios/README.md
[7]: ./pallycon_drm_sdk_interface
[8]: ./pallycon_drm_sdk_interface/README.md
[9]: ../player-samples
[10]: https://login.pallycon.com/
[11]: https://cocoapods.org/
[12]: https://guides.cocoapods.org/using/getting-started.html
