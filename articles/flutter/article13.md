## 初めに
今回は Flutter においてスマホ、タブレット、端末の向きによってデザインを変更したいときなどに使える判定方法を簡単に共有したいと思います。
レスポンシブ対応が必要になったタイミングで実装した内容をメモ書き程度に残しておきたいと思います。

## 記事の対象者
+ Flutter 学習者
+ Flutter でレスポンシブ対応をしたい方

## 目的
今回は上記の通り、スマホ、タブレット、端末の向きでデザインを変更したいときなどに使える方法を共有したいと思います。少なくとも iPhone、iPad とそれぞれの縦横の判定まではできるようになることが今回の目的となります。最終的には以下の動画のように各デバイスで縦横判定ができるような実装を行いたいと思います。

iPhone
https://youtu.be/HzifnAmTE7A

iPad
https://youtu.be/ardiI4MwbSc

## 実装
実装は以下の手順で進めていきたいと思います。
1. ブレイクポイントの作成
2. 各デバイスの種類と向きの定義
3. 判定する関数、ビューの作成
4. Riverpod を用いた場合の例

:::message
今回は iPhone15, iPad Pro(11-inch) のシミュレーターを用いて検証しました。
その他のデバイスで端末や向きの判定を正確に行いたい場合はそれぞれ数値を調節するなどしていただけると幸いです。
:::

### 1. ブレイクポイントの作成
まずはスマホかタブレットかを判定するためのブレイクポイントを作成していきます。
コードは以下の通りです。
```dart
enum Breakpoint {
  small,
  large;

  double get width {
    switch (this) {
      case Breakpoint.small:
        return 680;
      case Breakpoint.large:
        return 1048;
    }
  }
}
```
扱いやすいように enum で定義しておいて、 width のみを持つようにしておきます。

### 2. 各デバイスの種類と向きの定義
次に各デバイスの種類と向きを定義していきます。
コードは以下の通りです。
```dart
enum DeviceType {
  phonePortrait,
  phoneLandscape,
  tabletPortrait,
  tabletLandscape,
}

extension DeviceTypeExtension on DeviceType {
  String get name {
    switch (this) {
      case DeviceType.phonePortrait:
        return 'iPhone 縦向き';
      case DeviceType.phoneLandscape:
        return 'iPhone 横向き';
      case DeviceType.tabletPortrait:
        return 'iPad 縦向き';
      case DeviceType.tabletLandscape:
        return 'iPad 横向き';
    }
  }
}
```

`name` にもある通り以下の4種類のタイプを enum として定義しておきます。
+ iPhone 縦向き
+ iPhone 横向き
+ iPad 縦向き
+ iPad 横向き

### 3. 判定する関数、ビューの作成
次にデバイスの種類と向きを判定するための関数とビューを作成していきます。
コードは以下の通りです。
```dart
class ResponsiveSample extends StatelessWidget {
  const ResponsiveSample({super.key});

  DeviceType getDeviceTypeByMediaQuery(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final isTablet = isPortrait &&
            MediaQuery.of(context).size.width > Breakpoint.small.width ||
        !isPortrait &&
            MediaQuery.of(context).size.width > Breakpoint.large.width;

    if (isTablet) {
      return isPortrait
          ? DeviceType.tabletPortrait
          : DeviceType.tabletLandscape;
    } else {
      return isPortrait ? DeviceType.phonePortrait : DeviceType.phoneLandscape;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceType = getDeviceTypeByMediaQuery(context);

    String type;
    switch (deviceType) {
      case DeviceType.phonePortrait:
        type = deviceType.name;
        break;
      case DeviceType.phoneLandscape:
        type = deviceType.name;
        break;
      case DeviceType.tabletPortrait:
        type = deviceType.name;
        break;
      case DeviceType.tabletLandscape:
        type = deviceType.name;
        break;
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'レスポンシブ対応',
        ),
      ),
      body: Center(
        child: Text(
          type,
        ),
      ),
    );
  }
}
```

それぞれ詳しくみていきます。
まずはデバイスの種類や向きを判定する関数を見ていきます。

`isPortrait` では `MediaQuery` から `orientation` を取得して、その値が縦向きかどうかで bool を保持しています。
`isTablet` では画面の幅と縦向きかどうかを合わせてデバイスの種類を判定しています。
条件が多少複雑になっていますが、これは「iPhone横向き」と「iPad縦向き」の判定が混ざってしまって正常に判定できない問題を解消するためです。

```dart
DeviceType getDeviceTypeByMediaQuery(BuildContext context) {
  final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
  final isTablet = isPortrait && MediaQuery.of(context).size.width > Breakpoint.small.width ||
    !isPortrait && MediaQuery.of(context).size.width > Breakpoint.large.width;

  if (isTablet) {
    return isPortrait
      ? DeviceType.tabletPortrait
      : DeviceType.tabletLandscape;
  } else {
    return isPortrait ? DeviceType.phonePortrait : DeviceType.phoneLandscape;
  }
}
```

次はビューの方のコードを見ていきます。
以下では先ほど定義していた `getDeviceTypeByMediaQuery` 関数から `deviceType` を定義しており、その値を元に switch 文で `type` の内容を変更しています。
```dart
final deviceType = getDeviceTypeByMediaQuery(context);

String type;
switch (deviceType) {
  case DeviceType.phonePortrait:
    type = deviceType.name;
    break;
  case DeviceType.phoneLandscape:
    type = deviceType.name;
    break;
  case DeviceType.tabletPortrait:
    type = deviceType.name;
    break;
  case DeviceType.tabletLandscape:
    type = deviceType.name;
    break;
}
```

最後に表示部分を見ていきます。
コードは以下の通りです。
以下では先ほど定義した `type` をテキストとして表示しています。
これで各デバイス、向きに応じて表示が切り替わるようになるかと思います。
```dart
return Scaffold(
  appBar: AppBar(
    title: const Text(
      'レスポンシブ対応',
    ),
  ),
  body: Center(
    child: Text(
      type,
　　　　　　　　　　　　style: const TextStyle(fontSize: 25),
    ),
  ),
);
```

上記のコードで実行すると、「目的」の章にある動画ように iPhone, iPad 両方でデバイスの種類と向きの判定ができるかと思います。

iPhone
https://youtu.be/HzifnAmTE7A

iPad
https://youtu.be/ardiI4MwbSc

### 4. Riverpod を用いた場合の例
デバイスの種類と向きを判定する実装は今までの章で完了しましたが、この章では Riverpod を用いた場合の実装も行いたいと思います。
Riverpod を用いた実装は以下の手順で行います。
1. Provider の作成
2. ビューの変更

#### 1. Provider の作成
まずはデバイスの種類と向きを取得する関数を Provider として切り出して作成します。
コードは以下の通りです。
基本的には先ほどの章で実装した `getDeviceTypeByMediaQuery` と同じで、 `DeviceType` を返り値として返すようにしています。一点変更した点として、 `orientation` を呼び出し元から受け取るように変更しています。これは画面の向きの切り替えが起こった際にその変化を感知して内容を更新するために変更しています。
```dart
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sample_flutter_stable/responsive/responsive_sample.dart';

part 'get_device_type_provider.g.dart';

@riverpod
DeviceType getDeviceTypeByMediaQuery(
  GetDeviceTypeByMediaQueryRef ref,
  BuildContext context,
  Orientation orientation,
) {
  final isPortrait = orientation == Orientation.portrait;
  final isTablet = isPortrait &&
          MediaQuery.of(context).size.width > Breakpoint.small.width ||
      !isPortrait && MediaQuery.of(context).size.width > Breakpoint.large.width;
  if (isTablet) {
    return isPortrait ? DeviceType.tabletPortrait : DeviceType.tabletLandscape;
  } else {
    return isPortrait ? DeviceType.phonePortrait : DeviceType.phoneLandscape;
  }
}
```

#### 2. ビューの変更
次にビューの変更を行います。
コードは以下の通りです。

基本的には前の章の実装と同じですが、 `OrientationBuilder` でデバイスの向きである `orientation` を取得して、先ほど定義した `getDeviceTypeByMediaQueryProvider` に渡しています。
```dart
class ResponsiveSample extends ConsumerWidget {
  const ResponsiveSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final deviceType = ref.watch(
          getDeviceTypeByMediaQueryProvider(
            context,
            orientation,
          ),
        );
        String type = deviceType.name;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'レスポンシブ対応',
            ),
          ),
          body: Center(
            child: Text(
              type,
              style: const TextStyle(fontSize: 25),
            ),
          ),
        );
      },
    );
  }
}
```

上記の実装で、前の章と同じような挙動になるかと思います。

:::details orientation を渡さない実装
上記の実装では `getDeviceTypeByMediaQuery` に `orientation` を渡して実装しました。
その理由としては上述の通り、画面の向きが変更されたことを検知するためです。

他の実装例として、以下のコードのように build メソッド内で `MediaQuery.of(context)` を `getDeviceTypeByMediaQueryProvider` に渡すことで、 `orientation` を用いずに画面の向きに応じて動的に表示する内容を変更することができます。

```dart
class ResponsiveSample extends ConsumerWidget {
  const ResponsiveSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaQuery = MediaQuery.of(context);
    final deviceType = ref.watch(getDeviceTypeByMediaQueryProvider(mediaQuery));
    String type = deviceType.name;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'レスポンシブ対応',
        ),
      ),
      body: Center(
        child: Text(
          type,
          style: const TextStyle(fontSize: 25),
        ),
      ),
    );
  }
}
```

```dart
@riverpod
DeviceType getDeviceTypeByMediaQuery(GetDeviceTypeByMediaQueryRef ref, MediaQueryData mediaQuery) {
  final isPortrait = mediaQuery.orientation == Orientation.portrait;
  final isTablet = isPortrait &&
          mediaQuery.size.width > Breakpoint.small.width ||
      !isPortrait && mediaQuery.size.width > Breakpoint.large.width;
  if (isTablet) {
    return isPortrait ? DeviceType.tabletPortrait : DeviceType.tabletLandscape;
  } else {
    return isPortrait ? DeviceType.phonePortrait : DeviceType.phoneLandscape;
  }
}
```
:::

## まとめ
最後まで読んでいただいてありがとうございました。

今回は iPhone, iPad などでレスポンシブ対応を行う方法を簡単に共有しました。
今回紹介した方法以外にも `device_info_plus` パッケージを用いる方法などがありましたが、今回はパッケージなどは使用せずに実現できる方法を検討し実装しました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://zenn.dev/r0227n/articles/02475c6a6c8c9d

https://www.kamo-it.org/blog/flutter-orientation-builder/