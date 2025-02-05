## 初めに
今回は [webview_flutter](https://pub.dev/packages/webview_flutter) を使ってアプリ内でWebサイトを閲覧する実装を行います。

## 記事の対象者
+ Flutter 学習者
+ アプリ内でWebビューを作成したい方

## 目的
今回は上記の通り [webview_flutter](https://pub.dev/packages/webview_flutter) を使って、アプリ内でWebサイトを開けるような実装を行い、最終的には以下の動画のようにページを開けるようにしたいと思います。

https://youtube.com/shorts/8S2MvHdN3ik

## 導入
[webview_flutterパッケージ](https://pub.dev/packages/webview_flutter) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  webview_flutter: ^4.7.0
```

または

以下をターミナルで実行
```
flutter pub add webview_flutter
```

## 実装
今回は Flutter の公式サイトを読み込んで表示させる実装を行います。
コードは以下のようにします。基本的には [webview_flutter の pub.dev](https://pub.dev/packages/webview_flutter) のコードを変更したものになります。
```dart: webview_flutter_sample.dart
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewFlutterSample extends StatelessWidget {
  const WebviewFlutterSample({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..loadRequest(Uri.parse('https://flutter.dev'))
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            log('progress: $progress');
          },
          onPageStarted: (String url) {
            log('page started: $url');
          },
          onPageFinished: (String url) {
            log('page finished: $url');
          },
          onWebResourceError: (WebResourceError error) {
            log('error: $error');
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: WebViewWidget(
                controller: controller,
              ),
            ),
            SizedBox(
              height: 50,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () {
                        controller.goBack();
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () {
                        controller.goForward();
                      },
                      icon: const Icon(
                        Icons.arrow_forward_ios,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      onPressed: () {
                        controller.reload();
                      },
                      icon: const Icon(
                        Icons.replay,
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
```

それぞれ詳しくみていきます。

### コントローラーの定義
以下ではコントローラーの定義をしています。
`webview_flutter` では `WebViewWidget` に `controller` を渡すことで表示の設定を行います。
```dart
final controller = WebViewController()
```

### 初めに開くページの指定
以下では WebViewWidget で初めに開くページのURLを指定しています。
`loadRequest` 関数には Uri型の変数を渡す必要があり、今回は Flutter の公式サイトのURLを渡して、それをUriに変更しています。
```dart
..loadRequest(Uri.parse('https://flutter.dev'))
```

### JavaScript モードの設定
以下では JavaScript のモードを設定しています。
`JavaScriptMode` には `unrestricted` と `disabled` があり、`disabled`の場合には JavaScript の実行が制限されるため、通常の表示と異なる場合があります。
```dart
..setJavaScriptMode(JavaScriptMode.unrestricted)
```

### Webサイトの背景色の設定
以下ではWebサイトの背景色を設定しています。
今回は `Colors.black` にしているため、以下の画像のように、スクロールした際などに黒い背景色が見えるようになります。
```dart
..setBackgroundColor(Colors.black)
```
![](https://storage.googleapis.com/zenn-user-upload/f67b692c05cd-20240219.png =300x)

### ページのローディング中の処理
以下ではローディング中の処理の実装を行なっています。
今回は受け取った `progress` をログに出力しています。
```dart
onProgress: (int progress) {
  log('progress: $progress');
},
```

コンソールでは以下のようになります。
この `progress` に応じて表示を変更することもできるかと思います。
```dart
[log] progress: 10
[log] progress: 50
[log] progress: 90
[log] progress: 100
```

### ページ読み込み時、読み込み完了時の処理
以下ではページの読み込みが始まった時と読み込みが完了した時の処理を記述しています。
```dart
onPageStarted: (String url) {
  log('page started: $url');
},
onPageFinished: (String url) {
  log('page finished: $url');
},
```

先程のページのロード中の処理も含めて出力すると以下のようになります。
```dart
[log] progress: 10
[log] page started: https://flutter.dev/
[log] progress: 50
[log] progress: 90
[log] progress: 100
[log] page finished: https://flutter.dev/
```

### エラー時の処理
以下ではページの読み込みでエラーが発生した時の処理を記述しています。
```dart
onWebResourceError: (WebResourceError error) {
  log('error: $error');
},
```

### レスポンスごとの処理
以下ではレスポンスごとの処理を記述しています。
ページのURLが `https://www.youtube.com/` から始まる場合は `NavigationDecision.prevent` としています。このようにすることで、以下の動画のように YouTube に遷移しなくなります。
```dart
onNavigationRequest: (NavigationRequest request) {
  if (request.url.startsWith('https://www.youtube.com/')) {
    return NavigationDecision.prevent;
  }
  return NavigationDecision.navigate;
},
```

https://youtube.com/shorts/TrsrpWTmAjI?feature=share

### WebViewWidget の表示
以下では先述の通り `WebViewWidget` に `controller` を渡すことで WebView を表示しています。
```dart
Expanded(
  child: WebViewWidget(
    controller: controller,
  ),
),
```

### 戻るボタンの表示
以下ではページを閲覧して、前のページに戻りたい時に使用する「戻るボタン」を実装しています。
一つ前のページに戻るには `controller.goBack()` を実行すれば戻ることができます。
```dart
IconButton(
  onPressed: () {
    controller.goBack();
  },
  icon: const Icon(
    Icons.arrow_back_ios,
  ),
),
```

### 進むボタンの表示
以下では「戻るボタン」の逆で、「進むボタン」の実装をしています。
`controller.goForward()` で一つ次のページに進むことができます。
```dart
IconButton(
  onPressed: () {
    controller.goForward();
  },
  icon: const Icon(
    Icons.arrow_forward_ios,
  ),
),
```

### リロードボタンの表示
以下では「リロードボタン」を実装しています。
リロードは `controller.reload()` で実装できます。
```dart
IconButton(
  onPressed: () {
    controller.reload();
  },
  icon: const Icon(
    Icons.replay,
  ),
),
```

これで実装すると以下の動画のように実装することができます。

https://youtube.com/shorts/8S2MvHdN3ik

## まとめ
最後まで読んでいただいてありがとうございました。

今回は webview_flutter を使ってアプリ内で Webページを開く実装を簡単に行いました。
url_launcher などで外部サイトにアクセスするのではなく、アプリ内で実装することでアプリ独自の操作も可能になるので、便利なパッケージだと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/webview_flutter
