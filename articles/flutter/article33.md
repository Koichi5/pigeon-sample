## 初めに
今回は device_info_plus というパッケージを使用して、デバイスの情報を取得する実装を行います。

## 記事の対象者
+ Flutter 学習者
+ ユーザーのデバイスの情報を取得したい方
+ デバイスごとの処理を実装したい方

## 目的
上記の通り、ユーザーが使用しているデバイスの情報を取得することを目的としています。
具体的な使用用途としては、エラーが起こった際に使用していた端末の情報を保存することや、OSのバージョンに応じて処理を変更することなどが挙げられます。
以下のようにデバイスの情報を表示させることを完成イメージとしています。

![](https://storage.googleapis.com/zenn-user-upload/5b6095546ae1-20240206.png =250x)

## 導入
[device_info_plus](https://pub.dev/packages/device_info_plus) パッケージの最新バージョンを `pubspec.yaml`に記述
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  device_info_plus: ^9.1.2
```

または

以下をターミナルで実行
```
flutter pub add device_info_plus
```

## 実装
実装は以下の手順で行います。
1. main.dartの変更
2. デバイス情報を取得するための Provider を作成
3. デバイスの情報を表示させる

### 1. main.dartの変更
まずは `main.dart` を以下のように変更します。
今回は Riverpod を使用するため、 `MyApp` を `ProviderScope` で囲んでおきます。
```dart: main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/device_info_plus/view/device_info_plus_sample.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DeviceInfoPlusSample(),
    );
  }
}
```

### 2. デバイス情報を取得するための Provider を作成
次に `device_info_plus_provider.dart` で以下のように記述します。
```dart: device_info_plus_provider.dart
import 'dart:developer';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_info_plus_provider.g.dart';

@riverpod
class DeviceInfoPlusController extends _$DeviceInfoPlusController {
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  @override
  Future<Map<String, dynamic>> build() async {
    final deviceData = await initPlatformState();
    return deviceData;
  }

  Future<Map<String, dynamic>> initPlatformState() async {
    var deviceData = <String, dynamic>{};
    try {
      if (kIsWeb) {
        deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
        log('Hello Web User !');
      } else {
        deviceData = switch (defaultTargetPlatform) {
          TargetPlatform.android =>
            _readAndroidBuildData(await deviceInfoPlugin.androidInfo),
          TargetPlatform.iOS =>
            _readIosDeviceInfo(await deviceInfoPlugin.iosInfo),
          TargetPlatform.linux =>
            _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo),
          TargetPlatform.windows =>
            _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo),
          TargetPlatform.macOS =>
            _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo),
          TargetPlatform.fuchsia => <String, dynamic>{
              'Error:': 'Fuchsia platform isn\'t supported'
            }
        };
      }
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }
    return deviceData;
  }

  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    log('Hello Android User !');
    log(build.toString());
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'displaySizeInches':
          ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
      'displayWidthPixels': build.displayMetrics.widthPx,
      'displayWidthInches': build.displayMetrics.widthInches,
      'displayHeightPixels': build.displayMetrics.heightPx,
      'displayHeightInches': build.displayMetrics.heightInches,
      'displayXDpi': build.displayMetrics.xDpi,
      'displayYDpi': build.displayMetrics.yDpi,
      'serialNumber': build.serialNumber,
    };
  }

  Map<String, dynamic> _readIosDeviceInfo(IosDeviceInfo data) {
    log('Hello iOS User !');
    log(data.toString());
    return <String, dynamic>{
      'name': data.name,
      'systemName': data.systemName,
      'systemVersion': data.systemVersion,
      'model': data.model,
      'localizedModel': data.localizedModel,
      'identifierForVendor': data.identifierForVendor,
      'isPhysicalDevice': data.isPhysicalDevice,
      'utsname.sysname:': data.utsname.sysname,
      'utsname.nodename:': data.utsname.nodename,
      'utsname.release:': data.utsname.release,
      'utsname.version:': data.utsname.version,
      'utsname.machine:': data.utsname.machine,
    };
  }

  Map<String, dynamic> _readLinuxDeviceInfo(LinuxDeviceInfo data) {
    log('Hello Linux User !');
    log(data.toString());
    return <String, dynamic>{
      'name': data.name,
      'version': data.version,
      'id': data.id,
      'idLike': data.idLike,
      'versionCodename': data.versionCodename,
      'versionId': data.versionId,
      'prettyName': data.prettyName,
      'buildId': data.buildId,
      'variant': data.variant,
      'variantId': data.variantId,
      'machineId': data.machineId,
    };
  }

  Map<String, dynamic> _readWebBrowserInfo(WebBrowserInfo data) {
    log('Hello Web User !');
    log(data.toString());
    return <String, dynamic>{
      'browserName': data.browserName.name,
      'appCodeName': data.appCodeName,
      'appName': data.appName,
      'appVersion': data.appVersion,
      'deviceMemory': data.deviceMemory,
      'language': data.language,
      'languages': data.languages,
      'platform': data.platform,
      'product': data.product,
      'productSub': data.productSub,
      'userAgent': data.userAgent,
      'vendor': data.vendor,
      'vendorSub': data.vendorSub,
      'hardwareConcurrency': data.hardwareConcurrency,
      'maxTouchPoints': data.maxTouchPoints,
    };
  }

  Map<String, dynamic> _readMacOsDeviceInfo(MacOsDeviceInfo data) {
    log('Hello macOS User !');
    log(data.toString());
    return <String, dynamic>{
      'computerName': data.computerName,
      'hostName': data.hostName,
      'arch': data.arch,
      'model': data.model,
      'kernelVersion': data.kernelVersion,
      'majorVersion': data.majorVersion,
      'minorVersion': data.minorVersion,
      'patchVersion': data.patchVersion,
      'osRelease': data.osRelease,
      'activeCPUs': data.activeCPUs,
      'memorySize': data.memorySize,
      'cpuFrequency': data.cpuFrequency,
      'systemGUID': data.systemGUID,
    };
  }

  Map<String, dynamic> _readWindowsDeviceInfo(WindowsDeviceInfo data) {
    log('Hello Windows User !');
    log(data.toString());
    return <String, dynamic>{
      'numberOfCores': data.numberOfCores,
      'computerName': data.computerName,
      'systemMemoryInMegabytes': data.systemMemoryInMegabytes,
      'userName': data.userName,
      'majorVersion': data.majorVersion,
      'minorVersion': data.minorVersion,
      'buildNumber': data.buildNumber,
      'platformId': data.platformId,
      'csdVersion': data.csdVersion,
      'servicePackMajor': data.servicePackMajor,
      'servicePackMinor': data.servicePackMinor,
      'suitMask': data.suitMask,
      'productType': data.productType,
      'reserved': data.reserved,
      'buildLab': data.buildLab,
      'buildLabEx': data.buildLabEx,
      'digitalProductId': data.digitalProductId,
      'displayVersion': data.displayVersion,
      'editionId': data.editionId,
      'installDate': data.installDate,
      'productId': data.productId,
      'productName': data.productName,
      'registeredOwner': data.registeredOwner,
      'releaseId': data.releaseId,
      'deviceId': data.deviceId,
    };
  }
}
```

複雑に見えますが、各プラットフォームに対応する変数の定義のコードが非常に長くなっています。
詳しくみていきましょう。

以下の部分では、`DeviceInfoPlugin` をインスタンス化して、 `deviceInfoPlugin` 変数に代入しています。また、`build` メソッドの中で後述の `initPlatformState` メソッドを実行しています。
```dart
static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

@override
Future<Map<String, dynamic>> build() async {
  final deviceData = await initPlatformState();
  return deviceData;
}
```

以下の部分では、`initPlatformState` として、 String と dynamic の Map型である `deviceData` 変数の定義をしています。 value の型が dynamic になっている理由としては、それぞれのプラットフォームにおける、デバイス名やIDなどが必ずしも一つの型に収まりきらないためです。

また、 `kIsWeb` のフラグを使って、デバイスがWebである場合を判別して、 `deviceData` にWebの情報を代入する処理を行なっています。
`log` を使ってVSCodeのコンソールにそれぞれのプラットフォームを出力するようにしていますが、これはわかりやすくするために追加しています。
```dart
Future<Map<String, dynamic>> initPlatformState() async {
  var deviceData = <String, dynamic>{};
  try {
    if (kIsWeb) {
      deviceData = _readWebBrowserInfo(await deviceInfoPlugin.webBrowserInfo);
      log('Hello Web User !');
    }
```

次に以下の部分では、各プラットフォームにおける情報を、 `defaultTargetPlatform` の値に応じて切り替えています。
```dart
deviceData = switch (defaultTargetPlatform) {
  TargetPlatform.android =>
            _readAndroidBuildData(await deviceInfoPlugin.androidInfo),
  TargetPlatform.iOS =>
            _readIosDeviceInfo(await deviceInfoPlugin.iosInfo),
  TargetPlatform.linux =>
            _readLinuxDeviceInfo(await deviceInfoPlugin.linuxInfo),
  TargetPlatform.windows =>
            _readWindowsDeviceInfo(await deviceInfoPlugin.windowsInfo),
  TargetPlatform.macOS =>
            _readMacOsDeviceInfo(await deviceInfoPlugin.macOsInfo),
  TargetPlatform.fuchsia => <String, dynamic>{
            'Error:': 'Fuchsia platform isn\'t supported'
  }
};
```

最後に以下の部分では、Android の場合に返却するデータを記述しています。
これより下のコードは、 iOS や Linux など、それぞれのプラットフォームの場合に返すデータが記述されています。
Android に関しては `serialNumber` などの情報も取得できるため、アカウントごとの処理ではなく、デバイスごとの処理を行いたい場合などに、シリアルナンバーが一致するかどうかといった判定も実装可能かと思います。
```dart
  Map<String, dynamic> _readAndroidBuildData(AndroidDeviceInfo build) {
    log('Hello Android User !');
    log(build.toString());
    return <String, dynamic>{
      'version.securityPatch': build.version.securityPatch,
      'version.sdkInt': build.version.sdkInt,
      'version.release': build.version.release,
      'version.previewSdkInt': build.version.previewSdkInt,
      'version.incremental': build.version.incremental,
      'version.codename': build.version.codename,
      'version.baseOS': build.version.baseOS,
      'board': build.board,
      'bootloader': build.bootloader,
      'brand': build.brand,
      'device': build.device,
      'display': build.display,
      'fingerprint': build.fingerprint,
      'hardware': build.hardware,
      'host': build.host,
      'id': build.id,
      'manufacturer': build.manufacturer,
      'model': build.model,
      'product': build.product,
      'supported32BitAbis': build.supported32BitAbis,
      'supported64BitAbis': build.supported64BitAbis,
      'supportedAbis': build.supportedAbis,
      'tags': build.tags,
      'type': build.type,
      'isPhysicalDevice': build.isPhysicalDevice,
      'systemFeatures': build.systemFeatures,
      'displaySizeInches':
          ((build.displayMetrics.sizeInches * 10).roundToDouble() / 10),
      'displayWidthPixels': build.displayMetrics.widthPx,
      'displayWidthInches': build.displayMetrics.widthInches,
      'displayHeightPixels': build.displayMetrics.heightPx,
      'displayHeightInches': build.displayMetrics.heightInches,
      'displayXDpi': build.displayMetrics.xDpi,
      'displayYDpi': build.displayMetrics.yDpi,
      'serialNumber': build.serialNumber,
    };
  }
```

### 3. デバイスの情報を表示させる
最後に取得したデバイスのデータを表示させてみたいと思います。
`device_info_plus_sample.dart` というファイルで以下のように実装しました。
基本的には裏側の処理で取得して条件分岐等で活用するイメージなので、UIに出すことは少ないかと思いますが、今回はわかりやすくするために、UIで実装します。
```dart: device_info_plus_sample.dart
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sample_flutter/device_info_plus/provider/device_info_plus_provider.dart';

class DeviceInfoPlusSample extends ConsumerWidget {
  const DeviceInfoPlusSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('デバイス情報'),
      ),
      body: FutureBuilder(
        future: ref
            .read(deviceInfoPlusControllerProvider.notifier)
            .initPlatformState(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final data = snapshot.data as Map<String, dynamic>;
          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              String key = data.keys.elementAt(index);
              return ListTile(
                title: Text(key),
                subtitle: Text(data[key].toString()),
              );
            },
          );
        },
      ),
    );
  }
}
```

以下の部分では、FutureBuilder を用いて、デバイスの情報を取得し、取得したデータを表示させています。
まずは `future` で `deviceInfoPlusControllerProvider` の `initPlatformState` 関数を渡して、 `snapshot` にデバイスの情報を流します。
そして、 `snapshot` のローディングが終了し、データが null でない時に、 `ListView.builder` でデバイスの情報の属性（systemNameなど）と属性の値（iOSなど）を表示させています。
```dart
FutureBuilder(
  future: ref
            .read(deviceInfoPlusControllerProvider.notifier)
            .initPlatformState(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.data == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    final data = snapshot.data as Map<String, dynamic>;
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        String key = data.keys.elementAt(index);
        return ListTile(
          title: Text(key),
          subtitle: Text(data[key].toString()),
        );
      },
    );
  },
),
```

上記のコードを実行してみると以下のように Simulator であっても正確にデバイスの情報を取得できていることが確認できるかと思います。
![](https://storage.googleapis.com/zenn-user-upload/5b6095546ae1-20240206.png =250x)

なお、Chromeの Simulator に切り替えて実行してみると、以下のように Chrome の情報を取得することができます。
![](https://storage.googleapis.com/zenn-user-upload/0238be13cad1-20240207.png)

## まとめ
最後まで読んでいただいてありがとうございました。

今回はデバイスの情報を取得する方法を簡単にまとめました。
`dart:io` から `Platform.isIOS` などを呼び出すことでプラットフォーム自体の判別は可能ですが、それ以上の詳しい情報を取得する際には必要になるパッケージだと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/device_info_plus