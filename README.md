# DoveRunner Multi-DRM Flutter SDK

`DoveRunner Multi-DRM Flutter SDK` (`Flutter SDK` for short) is a product that makes it easy to apply Widevine and FairPlay DRM when developing media service apps in a Flutter-based cross-platform application development environment. 
It supports streaming and downloading scenarios of content encrypted with Widevine and FairPlay DRM on Android and iOS apps developed with Flutter.

## Packages
```
DoveRunner DRM Flutter SDK
    |
    ├─ pallycon-drm-sdk     // DoveRunner DRM Flutter SDK
    |    ├─ pallycon_drm_sdk
    |    ├─ pallycon_drm_sdk_android
    |    ├─ pallycon_drm_sdk_interface
    |    └─ pallycon_drm_sdk_ios
    |
    └─ player-samples       // sample project
         ├─ advanced
         └─ basic
``` 


### pallycon-drm-sdk
- `pallycon-drm-sdk` is a SDK that provides an interface to use DoveRunner services in flutter.
  - Provides download and streaming playback functions on Android through `PallyCon Widevine Android SDK`.
  - Provides download and streaming playback functions on iOS through `PallyCon FPS iOS SDK`.
- For more details about `pallycon-drm-sdk`, please refer to the [README.md][1] file.


### player-samples
- `player-samples` is a sample project that allows you to learn how to use `pallycon_drm_sdk`.
  - advanced
    - Provides download and streaming playback functions
  - basic
    - Provides streaming playback functions

- For more details about `player-samples`, please refer to the [README.md][2] file in the advanced and basic folders.


[1]: ./pallycon-drm-sdk/README.md
[2]: ./player-samples/advanced/README.md
