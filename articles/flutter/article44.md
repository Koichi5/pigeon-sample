## 初めに
Flutter のアプリ開発で go_router パッケージを使用する機会があったので、簡単な使い方をまとめておきます。今後学習を進めるにつれて更新していきたいと思います。
より詳しく解説したものを公開したので以下の記事もご覧ください。

https://zenn.dev/koichi_51/articles/50c553218ca938

## 実装
### 導入
[go_router パッケージ](https://pub.dev/packages/go_router)の最新バージョンを `pubspec.yaml`に記述します。
```yaml: pubspec.yaml
  go_router: ^10.1.0
```

### ルートの指定
```dart: main.dart
import 'package:go_router/go_router.dart';

final router = GoRouter(routes: [
  GoRoute(
      name: 'default',
      path: '/',
      builder: (context, state) => const HomeScreen()),
  GoRoute(
      name: 'about',
      path: '/about',
      builder: (context, state) => const AboutScreen()),
]);
```
上のコードのように遷移させたいページのルートを指定し、それを `router` 変数としてグローバルに定義します。
グローバルに定義することで他のクラス内でも `router` を使うことができます。

上の `HomeScreen` と `AboutScreen` は以下のように指定しておきます。
```dart: home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends HookWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
          child: ElevatedButton(
        onPressed: () {
          context.go('/about');
        },
        child: const Text(
          "To About screen",
        ),
      )),
    );
  }
}
```

```dart: about_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends HookWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
        leading: IconButton(
          onPressed: () {
            context.go('/');
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: const Center(
        child: Text("About"),
      ),
    );
  }
}
```

`HomeScreen` では `AboutScreen` に遷移するボタンを、`AboutScreen` には `HomeScreen`に戻るためのボタンを設置しています。

実行した結果は以下のようになります。
![](https://storage.googleapis.com/zenn-user-upload/7583513f22e2-20230825.gif =250x)

## まとめ
最後まで読んでいただきありがとうございました。

今回は Navigator における push と pop に当たるような簡単な実装のみでしたが、今後学習する機会があればどんどん内容を追加して理解を深めていきたいと思います。

### 参考
https://pub.dev/packages/go_router