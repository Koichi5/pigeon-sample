## 初めに
今回は Flutter とネイティブのプラットフォームとの通信を行うためのツールである Pigeon を用いて、以下の双方向のコードの呼び出しを行いたいと思います。
- Flutter から Swift の呼び出し
- Swift から Flutter の呼び出し

::: message
今回は Android 側の実装は扱いませんのでご了承ください。
:::

## 記事の対象者
+ Flutter 学習者
+ Flutter と Swift の連携について知りたい方
+ Method Channel 以外のプラットフォーム間の連携を試してみたい方

## 目的
今回の目的は Pigeon の使い方をある程度把握し、Flutter と Swift の間の通信をできるようにすることです。最終的にはネイティブに依存した機能を Swift で呼び出し、その結果を Flutter 側で実装したデータベースへの保存処理で保存するまでを行えるようにします。

なお、今回実装するコードは以下の GitHub で公開しているのでよろしければご参照ください。
https://github.com/Koichi5/pigeon-sample

## Pigeon とは
Pigeon の説明については [pub.dev](https://pub.dev/packages/pigeon) から以下を引用します。
> Pigeon is a code generator tool to make communication between Flutter and the host platform type-safe, easier, and faster.
>
> Pigeon removes the necessity to manage strings across multiple platforms and languages. It also improves efficiency over common method channel patterns. Most importantly though, it removes the need to write custom platform channel code, since pigeon generates it for you.
>
> （日本語訳）
> Pigeonは、Flutterとホストプラットフォーム間の通信を型安全にし、より簡単かつ迅速にするためのコード生成ツールです。
>
> Pigeonを使用することで、複数のプラットフォームや言語間で文字列を管理する必要がなくなります。また、一般的なメソッドチャネルパターンよりも効率が向上します。最も重要な点は、Pigeonがカスタムプラットフォームチャネルコードを自動生成してくれるため、自分でコードを書く必要がなくなることです。

要点をまとめると以下のようになるかと思います。
- Flutter と各プラットフォーム間を型安全に通信できるコード生成ツール
- 通信に文字列を用いる Method Channel よりも効率が向上する
- 各プラットフォームのコードを自動生成してくれる

一般的に Flutter と各プラットフォームとの通信に使用されている Method Channel では文字列で通信を行いますが、 Pigeon を使えば文字列以外の型でも型安全に通信でき、プラットフォーム側のコードも自動生成してくれるためより効率的に開発が行えることがわかります。

Method Channel に関しては以下の公式のドキュメントや過去の記事が比較対象として参考になるかと思います。
- [Writing custom platform-specific code](https://docs.flutter.dev/platform-integration/platform-channels)
- [【Flutter】FlutterからSwiftを呼び出す（CoreML）](https://zenn.dev/koichi_51/articles/812f7ed3fe492a)

## 実装
今回は Swift 側で iPhone のバッテリー残量や充電の接続状態を取得し、それを Firestore に保存する実装を Pigeon で行いたいと思います。
実装は以下の手順で行います。
1. 準備
2. Pigeon を用いたコード生成
3. Flutter 側の実装
4. Swift 側の実装

最終的には以下の動画のようにバッテリーのデータを取得し、Firestore にも保存できるようにしたいと思います。

https://youtube.com/shorts/wBURllYGPVg

### 1. 準備
まずは実装に必要な準備を行います。
以下の各パッケージの最新バージョンを `pubspec.yaml`に記述
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  pigeon: ^22.5.0
  cloud_firestore: ^5.4.4
  firebase_core: ^3.6.0
  flutter_hooks: ^0.20.5
  hooks_riverpod: ^2.6.0
  freezed_annotation: ^2.4.4
  gap: ^3.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.13
  freezed: ^2.5.7
```

または

以下をターミナルで実行
```
flutter pub add pigeon cloud_firestore firebase_core flutter_hooks hooks_riverpod freezed_annotation gap
flutter pub add -d build_runner freezed
```

次に Flutter と Firebase の連携を行います。
ここでは手順を省略しますが、 Cloud Firestore のデータの読み取りと書き込みが行えるような状態にしておきます。
なお、今回は Firestore へのデータ保存を行いますが、重要なのは Swift からも Flutter を呼び出せることを確認することであるため、別の実装に切り替えても問題ないかと思います。

これで準備は完了です。

### 2. Pigeon を用いたコード生成
次に Pigeon を用いたコード生成に移ります。
先述の通り、 Pigeon はコード生成ツールであり、特定のファイルをもとに各プラットフォームのコードを生成します。
lib ディレクトリの直下に `pigeons` ディレクトリを作成して、そこに `battery.dart` というファイルを作成します。作成した `battery.dart` を以下のように編集します。

```dart: lib/pigeons/battery.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/battery/battery.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Battery/Battery.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/Battery/Battery.g.swift',
  swiftOptions: SwiftOptions(),
))

class BatteryInfo {
  BatteryInfo({
    required this.batteryLevel,
    required this.batteryStatus,
    required this.source,
  });
  int batteryLevel;
  String batteryStatus;
  String source;
}

@HostApi()
abstract class BatteryHostApi {
  BatteryInfo getBatteryInfo();
}

@FlutterApi()
abstract class BatteryFlutterApi {
  void onBatteryInfoReceived(BatteryInfo batteryInfo);
}
```

それぞれ詳しくみていきます。

以下では**コードの自動生成に関する設定**を行なっています。
`dartOut` では Dart 側のコードを生成する場所を指定しています。
`kotlinOut`, `swiftOut` も同様で、各プラットフォームのコードをどこに出力するかを決めています。
また、今回は特に指定していませんが、 `dartOptions`, `kotlinOptions`, `swiftOptions` でそれぞれのコードを生成する際のオプションを設定できます。
```dart
@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/battery/battery.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Battery/Battery.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/Battery/Battery.g.swift',
  swiftOptions: SwiftOptions(),
))
```

以下では各プラットフォームで**共通して使用するクラスの定義**をしています。
Pigeon の生成元となるファイルで定義されたクラスなどは各プラットフォームのコードに変換されて自動生成されます。
今回は以下の三つのデータを持つ `BatteryInfo` を定義しています。
- iPhone のバッテリー残量：`batteryLevel`
- 充電の状態：`batteryStatus`
- どのプラットフォームから取得しているか：`source`
```dart
class BatteryInfo {
  BatteryInfo({
    required this.batteryLevel,
    required this.batteryStatus,
    required this.source,
  });
  int batteryLevel;
  String batteryStatus;
  String source;
}
```
:::message
Pigeon を用いたコード生成の元となるファイル（今回は `lib/pigeons/battery.dart`）に関して、「import に含めて良いのは `package:pigeon/pigeon.dart` のみである」という決まりがあり、他のパッケージを import した状態でコードを生成しようとするとエラーになります。
したがって、Freezed で生成したクラスなどの import はできなくなっているので注意が必要です。
:::

以下では `HostApi` アノテーションを使って、**Flutter 側から Host 側を呼び出す際に使用する関数**を定義しています。今回 Swift で実現したいことは、 iPhone のバッテリー残量と充電状況を取得することであるため、先ほど定義した `BatteryInfo` を返り値としてもつ `getBatteryInfo` を実装しています。
```dart
@HostApi()
abstract class BatteryHostApi {
  BatteryInfo getBatteryInfo();
}
```

以下では `FlutterApi` アノテーションを使って、 **Host 側から Flutter 側を呼び出す際に使用する関数**を定義しています。今回 Flutter で実現したいことは、バッテリー残量や充電状況を Firestore へ保存することであるため、 `onBatteryInfoReceived` を定義しています。
```dart
@FlutterApi()
abstract class BatteryFlutterApi {
  void onBatteryInfoReceived(BatteryInfo batteryInfo);
}
```

これで Pigeon のコード生成の元となる `battery.dart` の実装は完了です。
最後にコードの自動生成を行います。プロジェクトのルートディレクトリで以下のコマンドを実行します。
コマンドにあるように、先ほど作成したファイルのパスを Pigeon の input として渡しています。
これでこのパスにあるファイルをもとに Pigeon でコードの自動生成が行われます。
```
flutter pub run pigeon --input lib/pigeons/battery.dart
```

実際に生成されたコードは以下のようになっています。
生成されたコードの１行目にもありますが、生成されたコードを直接編集したとしても、再度コード生成を行うと編集した差分が消されてしまうため、生成されたコードを編集したい場合は生成元（今回は `lib/pigeons/battery.dart`）のファイルを編集します。
:::details Swift側
```swift: ios/Runner/Battery/Battery.g.dart
// Autogenerated from Pigeon (v22.5.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

import Foundation

#if os(iOS)
  import Flutter
#elseif os(macOS)
  import FlutterMacOS
#else
  #error("Unsupported platform.")
#endif

/// Error class for passing custom error details to Dart side.
final class PigeonError: Error {
  let code: String
  let message: String?
  let details: Any?

  init(code: String, message: String?, details: Any?) {
    self.code = code
    self.message = message
    self.details = details
  }

  var localizedDescription: String {
    return
      "PigeonError(code: \(code), message: \(message ?? "<nil>"), details: \(details ?? "<nil>")"
      }
}

private func wrapResult(_ result: Any?) -> [Any?] {
  return [result]
}

private func wrapError(_ error: Any) -> [Any?] {
  if let pigeonError = error as? PigeonError {
    return [
      pigeonError.code,
      pigeonError.message,
      pigeonError.details,
    ]
  }
  if let flutterError = error as? FlutterError {
    return [
      flutterError.code,
      flutterError.message,
      flutterError.details,
    ]
  }
  return [
    "\(error)",
    "\(type(of: error))",
    "Stacktrace: \(Thread.callStackSymbols)",
  ]
}

private func createConnectionError(withChannelName channelName: String) -> PigeonError {
  return PigeonError(code: "channel-error", message: "Unable to establish connection on channel: '\(channelName)'.", details: "")
}

private func isNullish(_ value: Any?) -> Bool {
  return value is NSNull || value == nil
}

private func nilOrValue<T>(_ value: Any?) -> T? {
  if value is NSNull { return nil }
  return value as! T?
}

/// Generated class from Pigeon that represents data sent in messages.
struct BatteryInfo {
  var batteryLevel: Int64
  var batteryStatus: String
  var source: String



  // swift-format-ignore: AlwaysUseLowerCamelCase
  static func fromList(_ pigeonVar_list: [Any?]) -> BatteryInfo? {
    let batteryLevel = pigeonVar_list[0] as! Int64
    let batteryStatus = pigeonVar_list[1] as! String
    let source = pigeonVar_list[2] as! String

    return BatteryInfo(
      batteryLevel: batteryLevel,
      batteryStatus: batteryStatus,
      source: source
    )
  }
  func toList() -> [Any?] {
    return [
      batteryLevel,
      batteryStatus,
      source,
    ]
  }
}

private class BatteryPigeonCodecReader: FlutterStandardReader {
  override func readValue(ofType type: UInt8) -> Any? {
    switch type {
    case 129:
      return BatteryInfo.fromList(self.readValue() as! [Any?])
    default:
      return super.readValue(ofType: type)
    }
  }
}

private class BatteryPigeonCodecWriter: FlutterStandardWriter {
  override func writeValue(_ value: Any) {
    if let value = value as? BatteryInfo {
      super.writeByte(129)
      super.writeValue(value.toList())
    } else {
      super.writeValue(value)
    }
  }
}

private class BatteryPigeonCodecReaderWriter: FlutterStandardReaderWriter {
  override func reader(with data: Data) -> FlutterStandardReader {
    return BatteryPigeonCodecReader(data: data)
  }

  override func writer(with data: NSMutableData) -> FlutterStandardWriter {
    return BatteryPigeonCodecWriter(data: data)
  }
}

class BatteryPigeonCodec: FlutterStandardMessageCodec, @unchecked Sendable {
  static let shared = BatteryPigeonCodec(readerWriter: BatteryPigeonCodecReaderWriter())
}

/// Generated protocol from Pigeon that represents a handler of messages from Flutter.
protocol BatteryHostApi {
  func getBatteryInfo() throws -> BatteryInfo
}

/// Generated setup class from Pigeon to handle messages through the `binaryMessenger`.
class BatteryHostApiSetup {
  static var codec: FlutterStandardMessageCodec { BatteryPigeonCodec.shared }
  /// Sets up an instance of `BatteryHostApi` to handle messages through the `binaryMessenger`.
  static func setUp(binaryMessenger: FlutterBinaryMessenger, api: BatteryHostApi?, messageChannelSuffix: String = "") {
    let channelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
    let getBatteryInfoChannel = FlutterBasicMessageChannel(name: "dev.flutter.pigeon.pigeon_sample.BatteryHostApi.getBatteryInfo\(channelSuffix)", binaryMessenger: binaryMessenger, codec: codec)
    if let api = api {
      getBatteryInfoChannel.setMessageHandler { _, reply in
        do {
          let result = try api.getBatteryInfo()
          reply(wrapResult(result))
        } catch {
          reply(wrapError(error))
        }
      }
    } else {
      getBatteryInfoChannel.setMessageHandler(nil)
    }
  }
}
/// Generated protocol from Pigeon that represents Flutter messages that can be called from Swift.
protocol BatteryFlutterApiProtocol {
  func onBatteryInfoReceived(batteryInfo batteryInfoArg: BatteryInfo, completion: @escaping (Result<Void, PigeonError>) -> Void)
}
class BatteryFlutterApi: BatteryFlutterApiProtocol {
  private let binaryMessenger: FlutterBinaryMessenger
  private let messageChannelSuffix: String
  init(binaryMessenger: FlutterBinaryMessenger, messageChannelSuffix: String = "") {
    self.binaryMessenger = binaryMessenger
    self.messageChannelSuffix = messageChannelSuffix.count > 0 ? ".\(messageChannelSuffix)" : ""
  }
  var codec: BatteryPigeonCodec {
    return BatteryPigeonCodec.shared
  }
  func onBatteryInfoReceived(batteryInfo batteryInfoArg: BatteryInfo, completion: @escaping (Result<Void, PigeonError>) -> Void) {
    let channelName: String = "dev.flutter.pigeon.pigeon_sample.BatteryFlutterApi.onBatteryInfoReceived\(messageChannelSuffix)"
    let channel = FlutterBasicMessageChannel(name: channelName, binaryMessenger: binaryMessenger, codec: codec)
    channel.sendMessage([batteryInfoArg] as [Any?]) { response in
      guard let listResponse = response as? [Any?] else {
        completion(.failure(createConnectionError(withChannelName: channelName)))
        return
      }
      if listResponse.count > 1 {
        let code: String = listResponse[0] as! String
        let message: String? = nilOrValue(listResponse[1])
        let details: String? = nilOrValue(listResponse[2])
        completion(.failure(PigeonError(code: code, message: message, details: details)))
      } else {
        completion(.success(Void()))
      }
    }
  }
}
```
:::


:::details Flutter側
```dart: lib/battery/battery.g.dart
// Autogenerated from Pigeon (v22.5.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, prefer_null_aware_operators, omit_local_variable_types, unused_shown_name, unnecessary_import, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;

import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';

PlatformException _createConnectionError(String channelName) {
  return PlatformException(
    code: 'channel-error',
    message: 'Unable to establish connection on channel: "$channelName".',
  );
}

List<Object?> wrapResponse({Object? result, PlatformException? error, bool empty = false}) {
  if (empty) {
    return <Object?>[];
  }
  if (error == null) {
    return <Object?>[result];
  }
  return <Object?>[error.code, error.message, error.details];
}

class BatteryInfo {
  BatteryInfo({
    required this.batteryLevel,
    required this.batteryStatus,
    required this.source,
  });

  int batteryLevel;

  String batteryStatus;

  String source;

  Object encode() {
    return <Object?>[
      batteryLevel,
      batteryStatus,
      source,
    ];
  }

  static BatteryInfo decode(Object result) {
    result as List<Object?>;
    return BatteryInfo(
      batteryLevel: result[0]! as int,
      batteryStatus: result[1]! as String,
      source: result[2]! as String,
    );
  }
}


class _PigeonCodec extends StandardMessageCodec {
  const _PigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is int) {
      buffer.putUint8(4);
      buffer.putInt64(value);
    }    else if (value is BatteryInfo) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129:
        return BatteryInfo.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

class BatteryHostApi {
  /// Constructor for [BatteryHostApi].  The [binaryMessenger] named argument is
  /// available for dependency injection.  If it is left null, the default
  /// BinaryMessenger will be used which routes to the host platform.
  BatteryHostApi({BinaryMessenger? binaryMessenger, String messageChannelSuffix = ''})
      : pigeonVar_binaryMessenger = binaryMessenger,
        pigeonVar_messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
  final BinaryMessenger? pigeonVar_binaryMessenger;

  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  final String pigeonVar_messageChannelSuffix;

  Future<BatteryInfo> getBatteryInfo() async {
    final String pigeonVar_channelName = 'dev.flutter.pigeon.pigeon_sample.BatteryHostApi.getBatteryInfo$pigeonVar_messageChannelSuffix';
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
      pigeonVar_channelName,
      pigeonChannelCodec,
      binaryMessenger: pigeonVar_binaryMessenger,
    );
    final List<Object?>? pigeonVar_replyList =
        await pigeonVar_channel.send(null) as List<Object?>?;
    if (pigeonVar_replyList == null) {
      throw _createConnectionError(pigeonVar_channelName);
    } else if (pigeonVar_replyList.length > 1) {
      throw PlatformException(
        code: pigeonVar_replyList[0]! as String,
        message: pigeonVar_replyList[1] as String?,
        details: pigeonVar_replyList[2],
      );
    } else if (pigeonVar_replyList[0] == null) {
      throw PlatformException(
        code: 'null-error',
        message: 'Host platform returned null value for non-null return value.',
      );
    } else {
      return (pigeonVar_replyList[0] as BatteryInfo?)!;
    }
  }
}

abstract class BatteryFlutterApi {
  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  void onBatteryInfoReceived(BatteryInfo batteryInfo);

  static void setUp(BatteryFlutterApi? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
    messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
          'dev.flutter.pigeon.pigeon_sample.BatteryFlutterApi.onBatteryInfoReceived$messageChannelSuffix', pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        pigeonVar_channel.setMessageHandler(null);
      } else {
        pigeonVar_channel.setMessageHandler((Object? message) async {
          assert(message != null,
          'Argument for dev.flutter.pigeon.pigeon_sample.BatteryFlutterApi.onBatteryInfoReceived was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final BatteryInfo? arg_batteryInfo = (args[0] as BatteryInfo?);
          assert(arg_batteryInfo != null,
              'Argument for dev.flutter.pigeon.pigeon_sample.BatteryFlutterApi.onBatteryInfoReceived was null, expected non-null BatteryInfo.');
          try {
            api.onBatteryInfoReceived(arg_batteryInfo!);
            return wrapResponse(empty: true);
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          }          catch (e) {
            return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }
}
```
:::

これで Pigeon のコード生成は完了です。

:::details 余談
先ほど実装した `@ConfigurePigeon` の内容は、コード生成の際のコマンドを以下のように変更することで同様の生成が行えます。ただ、コマンドで指定する場合は「複数人で開発する際に齟齬が生まれる可能性がある」といったデメリットがあるかと思います。
```
flutter pub run pigeon \
  --input lib/pigeons/battery.dart \
  --dart_out lib/app_usage_api.dart \
  --kotlin_out android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Battery/Battery.g.kt \
  --swift_out ios/Runner/Battery/Battery.g.swift
```
:::

### 3. Flutter 側の実装
Pigeon によるコードの自動生成が完了したら、いよいよ Flutter, Swift の両方での実装に入っていきます。
ただその前に、今回の実装したい機能の流れについてみておきます。
実装の流れは以下の図のようになっています。Flutter 側で実装するのは図の左半分になります。
![](https://storage.googleapis.com/zenn-user-upload/49925ba6d938-20241024.png)

処理の流れとしては①から④にかけて進みますが、Flutter, Swift と分けて進める場合はその順番では進まないため注意が必要です。
実装の順番に関してはわかりやすい順番で問題ないかと思います。

Flutter 側の実装は以下の手順で行います。
1. APIの実装
2. UIの実装
3. main.dart の編集

#### 1. APIの実装
まずはAPIの実装を行います。
battery.dart をもとに Pigeon で生成したコードを見ると、 `BatteryFlutterApi` の実装がされていることがわかります。生成されている `BatteryFlutterApi` には以下の二つの関数が用意されています。
- onBatteryInfoReceived
- setUp

`onBatteryInfoReceived` メソッドは先ほど実装した通りであり、SwiftからFirestoreへの保存処理の呼び出しがあった際に発火するメソッドになっています。
`setUp` は Swift 側からの処理の呼び出しを受け付けるためのメソッドです。

`BatteryFlutterApi` は abstracl class として実装されており、実際の処理の内容は追加する必要があります。したがって、`BatteryFlutterApi` を継承する `BatteryFlutterApiImpl` を作成して追加の実装を行います。

コードは以下の通りです。
`onBatteryInfoReceived` では Firestore へのデータの保存を行う `saveBatteryInfoToFirestore` を実行しています。
これで、Swift 側からデータ保存の呼び出しがあった際に、渡されたデータを Firestore へ保存できるようになります。
```dart: lib/battery/battery_flutter_api_impl.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pigeon_sample/battery/battery.g.dart';

class BatteryFlutterApiImpl extends BatteryFlutterApi {
  @override
  void onBatteryInfoReceived(BatteryInfo batteryInfo) {
    saveBatteryInfoToFirestore(batteryInfo: batteryInfo);
  }

  void saveBatteryInfoToFirestore({required BatteryInfo batteryInfo}) async {
    await FirebaseFirestore.instance.collection('battery_info').add({
      'batteryLevel': batteryInfo.batteryLevel,
      'batteryStatus': batteryInfo.batteryStatus,
      'source': batteryInfo.source,
      'timestamp': DateTime.now(),
    });
    debugPrint(
        'Battery level: ${batteryInfo.batteryLevel}, status: ${batteryInfo.batteryStatus} saved to Firestore.');
  }
}
```

#### 2. UIの実装
次にUIの実装を行います。
実装としてはシンプルで、ボタンを押すと iPhone のバッテリー残量と充電の状態が表示されるような画面です。
```dart: lib/battery/battery_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:pigeon_sample/battery/battery.g.dart';

class BatteryScreen extends HookWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final batteryLevel = useState('Unknown battery level.');
    final batteryStatus = useState('Unknown battery status.');

    Future<void> getBatteryInfo() async {
      try {
        final api = BatteryHostApi();
        final result = await api.getBatteryInfo();
        batteryLevel.value = '${result.batteryLevel} % .';
        batteryStatus.value = result.batteryStatus;
      } on PlatformException catch (e) {
        batteryLevel.value = "Failed to get battery level: ${e.message}.";
        batteryStatus.value = "Failed to get battery status: ${e.message}.";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(batteryLevel.value),
            const Gap(8),
            Text(batteryStatus.value),
            const Gap(16),
            ElevatedButton(
              onPressed: getBatteryInfo,
              child: const Text('Get Battery Info'),
            ),
          ],
        ),
      ),
    );
  }
}
```

以下の部分で `BatteryHostApi` を使って `getBatteryInfo` を実行して結果を取得しています。
今は Swift 側の実装ができていないため例外が投げられるかと思いますが、Swift 側でバッテリーに関するデータが取得できれば返り値に `BatteryInfo` が渡されるようになります。
```dart
Future<void> getBatteryInfo() async {
  try {
    final api = BatteryHostApi();
    final result = await api.getBatteryInfo();
    batteryLevel.value = '${result.batteryLevel} % .';
    batteryStatus.value = result.batteryStatus;
  } on PlatformException catch (e) {
    batteryLevel.value = "Failed to get battery level: ${e.message}.";
    batteryStatus.value = "Failed to get battery status: ${e.message}.";
  }
}
```

これでUIの実装は完了です。

#### 3. main.dart の編集
最後に `mian.dart` の編集に移ります。
`main.dart` では Firebase の初期化と `BatteryFlutterApi` のセットアップを行います。
コードは以下の通りです。
```dart: lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // BatteryFlutterApiのセットアップ
  BatteryFlutterApi.setUp(BatteryFlutterApiImpl());
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Level App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BatteryScreen()
    );
  }
}
```

`setUp` メソッドは Pigeon で `@FlutterApi` アノテーションをつけたAPIに対して自動的に生成されるメソッドです。`@FlutterApi` アノテーションをつけるのは、 **Swift 側から Flutter のコードを呼び出す**場合です。

`setUp` メソッドの中身は以下のようになっています。
長くて複雑に見えますが、やっていることは以下の三つの集約されます。
- Method Channel の設定
- メッセージの受信を監視
- メッセージを受け取ってAPIに実装された関数を実行
```dart
static void setUp(BatteryFlutterApi? api, {BinaryMessenger? binaryMessenger, String messageChannelSuffix = '',}) {
  messageChannelSuffix = messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
  {
    final BasicMessageChannel<Object?> pigeonVar_channel = BasicMessageChannel<Object?>(
        'dev.flutter.pigeon.pigeon_sample.BatteryFlutterApi.onBatteryInfoReceived$messageChannelSuffix', pigeonChannelCodec,
        binaryMessenger: binaryMessenger);
    if (api == null) {
      pigeonVar_channel.setMessageHandler(null);
    } else {
      pigeonVar_channel.setMessageHandler((Object? message) async {
        assert(message != null,
        'Argument for dev.flutter.pigeon.pigeon_sample.BatteryFlutterApi.onBatteryInfoReceived was null.');
        final List<Object?> args = (message as List<Object?>?)!;
        final BatteryInfo? arg_batteryInfo = (args[0] as BatteryInfo?);
        assert(arg_batteryInfo != null,
            'Argument for dev.flutter.pigeon.pigeon_sample.BatteryFlutterApi.onBatteryInfoReceived was null, expected non-null BatteryInfo.');
        try {
          api.onBatteryInfoReceived(arg_batteryInfo!);
          return wrapResponse(empty: true);
        } on PlatformException catch (e) {
          return wrapResponse(error: e);
        }          catch (e) {
          return wrapResponse(error: PlatformException(code: 'error', message: e.toString()));
        }
      });
    }
  }
}
```

再度 main.dart のコードを見てみると以下のようにしています。
`setUp` メソッドに対して先ほど実装した `BatteryFlutterApiImpl` を渡しています。
これでアプリが起動した段階で Method Channel が確立され、そのチャンネルのメッセージを監視し、`BatteryFlutterApiImpl` で実装した関数が実行されるようになります。

逆に `setUp` を忘れると Flutter と Swift を繋ぐ Method Channel が確立されないため、プラットフォーム間の通信ができなくなってしまいます。

```dart
BatteryFlutterApi.setUp(BatteryFlutterApiImpl());
```

これで Flutter 側の実装は完了です。

### 4. Swift 側の実装
次に Swift側の実装に移ります。
Swift の実装は以下の手順で行います。
1. APIの実装
2. AppDelegate.swift の編集

再度今回の実装の流れについてみておきます。
実装の流れは以下の図のようになっています。Swift 側で実装するのは図の右半分になります。
![](https://storage.googleapis.com/zenn-user-upload/49925ba6d938-20241024.png)

#### 1. APIの実装
battery.dart をもとに Pigeon で生成した Swift 側のコードを見ると、 `BatteryHostApi` の実装がされており、`getBatteryInfo` を持っていることがわかります。
Swift 側ではこの `getBatteryInfo` の詳細を実装する必要があります。
```swift: ios/Runner/Battery/Battery.g.swift
protocol BatteryHostApi {
  func getBatteryInfo() throws -> BatteryInfo
}
```

Flutter 側で `BatteryFlutterApi` を継承する `BatteryFlutterApiImpl` を実装したように、 Swift 側では `BatteryHostApi` を継承する `BatteryHostApiImpl` を実装します。
コードは以下の通りです。
```swift: ios/Runner/Battery/BatteryHostApiImpl.swift
 import Foundation

 enum BatteryError: Error {
     case unavailable
 }

class BatteryHostApiImpl: BatteryHostApi {
    private let flutterApi: BatteryFlutterApi

    init(binaryMessenger: FlutterBinaryMessenger) {
        self.flutterApi = BatteryFlutterApi(binaryMessenger: binaryMessenger)
    }

    func getBatteryInfo() throws -> BatteryInfo {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true

        // Battery Level
        let batteryLevel = Int64(device.batteryLevel * 100)

        // Battery Status
        let batteryStatus: UIDevice.BatteryState = device.batteryState
        var batteryStatusLabel = ""
        switch batteryStatus {
        case .unknown:
            batteryStatusLabel = "Unknown 🤔"
        case .unplugged:
            batteryStatusLabel = "Unplugged 🔌"
        case .charging:
            batteryStatusLabel = "Charging ⚡"
        case .full:
            batteryStatusLabel = "Full 🔋"
        @unknown default:
            batteryStatusLabel = "Unknown 🤔"
        }
        device.isBatteryMonitoringEnabled = false

        let batteryInfo = BatteryInfo(batteryLevel: batteryLevel, batteryStatus: batteryStatusLabel, source: "iOS")
        flutterApi.onBatteryInfoReceived(batteryInfo: batteryInfo) { result in
            switch result {
            case .success():
                print("Successfully sent battery info to Flutter")
            case .failure(let error):
                print("Error sending battery info to Flutter: \(error.localizedDescription)")
            }
        }

        return batteryInfo
    }
}
```

それぞれ詳しく見ていきます。

以下では初期化処理で `BatteryFlutterApi` を使用できるようにしています。
引数として渡している `FlutterBinaryMessenger` は Flutter とネイティブ間でバイナリメッセージを送受信するためのメッセンジャーであり、これを通じて Dart コードと各プラットフォームのコードの間で通信を行うことができます。
```swift
private let flutterApi: BatteryFlutterApi

init(binaryMessenger: FlutterBinaryMessenger) {
    self.flutterApi = BatteryFlutterApi(binaryMessenger: binaryMessenger)
}
```

以下では現在使用されているデバイスのバッテリー残量のパーセントと充電状況に応じたテキストを取得しています。`isBatteryMonitoringEnabled` を `true` にすることでバッテリーに関するデータを取得することができます。
```swift
let device = UIDevice.current
device.isBatteryMonitoringEnabled = true

// Battery Level
let batteryLevel = Int64(device.batteryLevel * 100)

// Battery Status
let batteryStatus: UIDevice.BatteryState = device.batteryState
var batteryStatusLabel = ""
switch batteryStatus {
case .unknown:
    batteryStatusLabel = "Unknown 🤔"
case .unplugged:
    batteryStatusLabel = "Unplugged 🔌"
case .charging:
    batteryStatusLabel = "Charging ⚡"
case .full:
    batteryStatusLabel = "Full 🔋"
@unknown default:
    batteryStatusLabel = "Unknown 🤔"
}
device.isBatteryMonitoringEnabled = false
```

以下では取得したバッテリー残量や充電の状況を `BatteryInfo` に入れて、 `onBatteryInfoReceived` メソッドに渡しています。
このメソッドが実行されることで Flutter 側へメッセージが送信され、先ほど実装した Firestore への保存処理が発火して、 `BatteryInfo` のデータが保存されます。
```swift
let batteryInfo = BatteryInfo(batteryLevel: batteryLevel, batteryStatus: batteryStatusLabel, source: "iOS")
flutterApi.onBatteryInfoReceived(batteryInfo: batteryInfo) { result in
    switch result {
    case .success():
        print("Successfully sent battery info to Flutter")
    case .failure(let error):
        print("Error sending battery info to Flutter: \(error.localizedDescription)")
    }
}
```

APIの実装は以上です。
UIに関しては Flutter 側で実装しているため、Swift 側での実装は必要ありません。
watchOS などの場合はターゲットを追加して、別途UIの作成が必要になるかと思います。

#### 2. AppDelegate.swift の編集
最後に `AppDelegate.swift` の編集を行います。
コードは以下の通りです。
```swift: ios/Runner/AppDelegate.swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    var flutterEngine: FlutterEngine?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // FlutterEngineを初期化
        flutterEngine = FlutterEngine(name: "MyFlutterEngine")
        flutterEngine?.run()

        GeneratedPluginRegistrant.register(with: flutterEngine!)

        // FlutterViewControllerをflutterEngineを使用して初期化
        let flutterViewController = FlutterViewController(engine: flutterEngine!, nibName: nil, bundle: nil)

        // windowを設定し、rootViewControllerにFlutterViewControllerを設定
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = flutterViewController
        self.window?.makeKeyAndVisible()

        // BatteryHostApiのセットアップ
        let batteryApi = BatteryHostApiImpl(binaryMessenger: flutterEngine!.binaryMessenger)
        BatteryHostApiSetup.setUp(binaryMessenger: flutterEngine!.binaryMessenger, api: batteryApi)

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

基本的にはコメントにある通りで、FlutterEngine を明示的に初期化してから実行しています。

なお、以下の部分で `BatteryHostApi` のセットアップを行っています。
Flutter 側の `main.dart` で設定を行なったのと同様で、`BatteryHostApiSetup` の `setUp` を実行して、引数に `BatteryHostApiImpl` を渡すことで、先ほど実装した `getBatteryInfo` が必要に応じて実行されるようになります。
```swift
let batteryApi = BatteryHostApiImpl(binaryMessenger: flutterEngine!.binaryMessenger)
BatteryHostApiSetup.setUp(binaryMessenger: flutterEngine!.binaryMessenger, api: batteryApi)
```

これで Swift 側も実装も完了です。
上記のコードで実行すると以下の動画のようにバッテリーのデータの取得とができ、Firestoreの `battery_info` コレクションにデータが保存されているかと思います。

https://youtube.com/shorts/wBURllYGPVg

なお、今回使用したコードは以下の GitHub で公開しているのでよろしければご参照ください。
https://github.com/Koichi5/pigeon-sample

## まとめ
最後まで読んでいただいてありがとうございました。

今回は Pigeon の使い方をまとめました。
他の記事では Flutter 側からネイティブを呼び出す実装が多く紹介されていましたが、逆にネイティブから Flutter を呼び出す場合もあると思うので、両方の実装に慣れておきたいところです。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/pigeon

https://zenn.dev/sasao/articles/7b3906ccd69021

https://qiita.com/glassmonkey/items/51d150da15ceeaea2960


