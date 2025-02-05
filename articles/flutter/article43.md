## 初めに
権限（permission）関係で色々実装することがあったので、まとめてみたいと思います。
今回は以下の権限の要求についてまとめていきたいと思います。
+ 位置情報
+ 音声
+ カメラ
+ 写真

## 記事の対象者
+ Flutter 学習者
+ アプリのリリースを目指す方
+ 権限が必要な機能を実装したい方

## 実装
### 導入
[permission_handlerパッケージ](https://pub.dev/packages/permission_handler)の最新バージョンを `pubspec.yaml` に追記します。
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  permission_handler: ^10.4.3
```

### 設定の変更
Android の設定
```xml: android/app/src/main/AndroidManifest.xml
    <!-- Permissions options for the `location` group -->
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />

    <!-- Permissions options for the `microphone` or `speech` group -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />

    <!-- Permissions options for the `camera` group -->
    <uses-permission android:name="android.permission.CAMERA"/>
```

iOS の設定
```txt: ios/Podfile
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
    config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',

        ## dart: [PermissionGroup.location, PermissionGroup.locationAlways, PermissionGroup.locationWhenInUse]
        'PERMISSION_LOCATION=1',

	## dart: PermissionGroup.microphone
        'PERMISSION_MICROPHONE=1',

	## dart: PermissionGroup.camera
        'PERMISSION_CAMERA=1'

	## dart: PermissionGroup.photos
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

```plist: ios/Runner/Info.plist
	<!-- Permission options for the `location` group -->
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>Need location when in use</string>
    <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
    <string>Always and when in use!</string>
    <key>NSLocationUsageDescription</key>
    <string>Older devices need location.</string>
    <key>NSLocationAlwaysUsageDescription</key>
    <string>Can I have location always?</string>

        <!-- Permission options for the `microphone` group -->
    <key>NSMicrophoneUsageDescription</key>
    <string>microphone</string>

        <!-- Permission options for the `camera` group -->
    <key>NSCameraUsageDescription</key>
    <string>camera</string>

        <!-- Permission options for the `photos` group -->
    <key>NSPhotoLibraryUsageDescription</key>
    <string>photos</string>
```

### 位置情報
位置情報権限のリクエスト実装
```dart: location_permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

enum LocationPermissionStatus { granted, denied, permanentlyDenied, restricted }

class LocationPermissionsHandler {
  Future<bool> get isGranted async {
    final status = await Permission.location.status;
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return false;
      default:
        return false;
    }
  }

  Future<bool> get isAlwaysGranted {
    return Permission.locationAlways.isGranted;
  }

  Future<LocationPermissionStatus> request() async {
    final status = await Permission.location.request();
    switch (status) {
      case PermissionStatus.granted:
        return LocationPermissionStatus.granted;
      case PermissionStatus.denied:
        return LocationPermissionStatus.denied;
      case PermissionStatus.limited:
      case PermissionStatus.permanentlyDenied:
        return LocationPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return LocationPermissionStatus.restricted;
      default:
        return LocationPermissionStatus.denied;
    }
  }
}
```

### 音声
音声のリクエスト実装
```dart: microphone_permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

enum MicrophonePermissionStatus {
  granted,
  denied,
  restricted,
  limited,
  permanentlyDenied
}

class MicrophonePermissionsHandler {
  Future<bool> get isGranted async {
    final status = await Permission.microphone.status;
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return false;
      default:
        return false;
    }
  }

  Future<MicrophonePermissionStatus> request() async {
    final status = await Permission.microphone.request();
    switch (status) {
      case PermissionStatus.granted:
        return MicrophonePermissionStatus.granted;
      case PermissionStatus.denied:
        return MicrophonePermissionStatus.denied;
      case PermissionStatus.limited:
        return MicrophonePermissionStatus.limited;
      case PermissionStatus.restricted:
        return MicrophonePermissionStatus.restricted;
      case PermissionStatus.permanentlyDenied:
        return MicrophonePermissionStatus.permanentlyDenied;
      default:
        return MicrophonePermissionStatus.denied;
    }
  }
}
```

### カメラ
カメラのリクエスト実装
```dart: camera_permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

enum CameraPermissionStatus {
  granted,
  denied,
  restricted,
  limited,
  permanentlyDenied
}

class CameraPermissionsHandler {
  Future<bool> get isGranted async {
    final status = await Permission.camera.status;
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return false;
      default:
        return false;
    }
  }

  Future<CameraPermissionStatus> request() async {
    final status = await Permission.camera.request();
    switch (status) {
      case PermissionStatus.granted:
        return CameraPermissionStatus.granted;
      case PermissionStatus.denied:
        return CameraPermissionStatus.denied;
      case PermissionStatus.limited:
        return CameraPermissionStatus.limited;
      case PermissionStatus.restricted:
        return CameraPermissionStatus.restricted;
      case PermissionStatus.permanentlyDenied:
        return CameraPermissionStatus.permanentlyDenied;
      default:
        return CameraPermissionStatus.denied;
    }
  }
}
```

### 写真
写真のリクエスト実装
```dart: photo_permission_handler.dart
import 'package:permission_handler/permission_handler.dart';

enum PhotoPermissionStatus { granted, denied, permanentlyDenied, restricted }

class PhotoPermissionsHandler {
  Future<bool> get isGranted async {
    final status = await Permission.photos.status;
    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        return true;
      case PermissionStatus.denied:
      case PermissionStatus.permanentlyDenied:
      case PermissionStatus.restricted:
        return false;
      default:
        return false;
    }
  }

  Future<PhotoPermissionStatus> request() async {
    final status = await Permission.photos.request();
    switch (status) {
      case PermissionStatus.granted:
        return PhotoPermissionStatus.granted;
      case PermissionStatus.denied:
        return PhotoPermissionStatus.denied;
      case PermissionStatus.limited:
      case PermissionStatus.permanentlyDenied:
        return PhotoPermissionStatus.permanentlyDenied;
      case PermissionStatus.restricted:
        return PhotoPermissionStatus.restricted;
      default:
        return PhotoPermissionStatus.denied;
    }
  }
}
```

### リクエストを出す
```dart: home_screen.dart
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      // リクエストを出す処理
      LocationPermissionsHandler().request();
      return null;
    }, []);
    return Scaffold(
      appBar: AppBar(title: const Text("ホーム")),
      body: Center(
        child: Text("ホーム"),
      ),
    );
  }
}
```
`useEffect` などでリクエストの処理を実装することで、特定の画面が表示された時に権限のダイアログを出すことができます。

## まとめ
最後まで読んでいただいてありがとうございました。
今回は権限のダイアログの実装を行いました。
アプリをリリースするときなどにはほぼ必ず実装が必要になる機能なので、スムーズに実装できるようになると開発の効率化にもつながるかと思います。

### 参考
https://pub.dev/packages/permission_handler

https://github.com/Baseflow/flutter-permission-handler/blob/main/permission_handler/example/android/app/src/main/AndroidManifest.xml

https://github.com/Baseflow/flutter-permission-handler/blob/main/permission_handler/example/ios/Runner/Info.plist