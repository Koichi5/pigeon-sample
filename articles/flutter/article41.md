## 初めに
Flutterを始めてから画面遷移に関してはずっとNavigatorを使ってきていたのですが、最近 Go Router の学習を始めました。
Navigator は初め記述方法を覚えるコストがあるものの、アプリ開発をしていれば幾度となく画面遷移の処理を書くことになるので、自然と書き方を覚えていきます。覚えてしまえば直感的に書けるので特に不便は感じていなかったのですが、これを機に Go Router と比較してみたいと思います。

Go Router に触れた後は Go Router Builder にも触れる予定なので、よろしければそちらも併せてご覧ください。

## 記事の対象者
+ Flutter 学習者
+ Go Routerを使いたい方

## 実装
### 導入
[go_router](https://pub.dev/packages/go_router)パッケージの最新バージョンを `pubspec.yaml`に記述
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^12.0.1
```

または

以下をターミナルで実行
```
flutter pub add go_router
```

### ルートの指定
`router.dart`という名前のファイルを作成して、その中に GoRoute の定義をまとめます。
```dart: router.dart
import 'package:go_router/go_router.dart';
import 'package:go_router_builder_sample/screens/about_screen.dart';
import 'package:go_router_builder_sample/screens/home_screen.dart';
import 'package:go_router_builder_sample/screens/setting_screen.dart';

final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: [
    GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const HomeScreen()),
    GoRoute(
        name: 'about',
        path: '/about',
        builder: (context, state) => const AboutScreen()),
    GoRoute(
        name: 'setting',
        path: '/setting',
        builder: (context, state) => const SettingScreen()),
  ],
);
```
上のコードのように遷移させたいページのルートを指定し、それを `router` 変数としてグローバルに定義することで他のクラス内でも `router` を使うことができます。

:::details  debugLogDiagnostics: true
`debugLogDiagnostics: true,`とすることで以下のように、登録されているすべてのルートと遷移した際にどのルートに遷移したかがデバッグコンソールに表示されます。
```
[GoRouter] Full paths for routes:
             => /
             => /about
             => /setting
           known full paths for route names:
             home => /
             about => /about
             setting => /setting
[GoRouter] setting initial location null
[GoRouter] Using MaterialApp configuration
[GoRouter] going to /about
[GoRouter] going to /setting
[GoRouter] going to /
[GoRouter] going to /about
```
:::

:::details  initialLocation: '/'
`initialLocation: '/'` のように指定すると、指定されたパスにあるページが最初に表示されるようになります。例えば、`initialLocation: '/about'` とすると `AboutScreen` が初めに表示されるようになります。
なお、initialLocation を指定しなかった場合はパスが `/` になっているものが自動的に一番初めに表示されるページになります。
:::

上の `HomeScreen` 、 `AboutScreen`、`SettingScreen` は以下のように指定しておきます。
```dart: home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
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
            "Go To About Screen",
          ),
        ),
      ),
    );
  }
}
```

```dart: about_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/setting');
          },
          child: const Text(
            'Go To Setting Screen',
          ),
        ),
      ),
    );
  }
}

```

```dart: setting_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setting')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/');
          },
          child: const Text(
            'Go To Home Screen',
          ),
        ),
      ),
    );
  }
}
```
各ページには次のページへ進むためのボタンが設けられており、`HomeScreen` → `AboutScreen` → `SettingScreen`の順番に遷移するようになっています。

### main.dart の変更
ルートの指定はできましたが、このままでは指定したルートを使うことはできません。
最後に `main.dart`を以下のように変更することでルートを使えるようになります。
```dart: main.dart
import 'package:flutter/material.dart';
import 'package:go_router_builder_sample/router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(     // MaterialApp.routerなので注意
      title: 'Go Router Sample',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 以下３行を追加
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
```

### Navigator.push
先ほどのコードでも示した通り、以下のコードが Navigator と go router を使用した場合に同じような動作になります。

Navigator
```dart: home_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AboutScreen(),
  ),
);
```

go router
```dart: home_screen.dart
context.go('/about');
```
以上のように `context.go('遷移先のパス')` として遷移先のパスを引数に入れることで画面遷移を実装することができます。

ただ、go router で遷移した場合には以下のように「戻るボタン」が表示されないという違いがあります。これについては後述します。

| Navigator.push | go_router |
| ---- | ---- |
| ![Navigator.push](https://storage.googleapis.com/zenn-user-upload/6e2b126496be-20231028.png =250x) | ![go_router](https://storage.googleapis.com/zenn-user-upload/1d7a0504da00-20231028.png =250x) |

### Navigator.pop
Navigator
```dart: about_screen.dart
Navigator.pop(context);
```

go router
```dart: about_screen.dart
context.pop();
```

`Navigator.pop(context)` に関してはそのまま実行してもエラーは起きませんが、`context.pop()` を実行すると以下のエラーが出力されます。
```
GoError (GoError: There is nothing to pop)
```
エラー内容としては書いてある通りで、popするものがないとのことです。
このエラーの原因は、popされる予定だったスクリーンはどのスクリーンの子要素、つまり入れ子ではないために起こっています。
ここで現在の `router.dart` に以下のような `DetailScreen` を追加してみましょう。

```diff dart: router.dart
import 'package:go_router/go_router.dart';
import 'package:go_router_builder_sample/screens/about_screen.dart';
import 'package:go_router_builder_sample/screens/detail_screen.dart';
import 'package:go_router_builder_sample/screens/home_screen.dart';
import 'package:go_router_builder_sample/screens/setting_screen.dart';

final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: [
    GoRoute(
        name: 'home',
        path: '/',
+       routes: [
+         GoRoute(
+           name: 'detail',
+           path: 'detail',
+           builder: (context, state) => const DetailScreen(),
+         )
+       ],
        builder: (context, state) => const HomeScreen()),
    GoRoute(
        name: 'about',
        path: '/about',
        builder: (context, state) => const AboutScreen()),
    GoRoute(
        name: 'setting',
        path: '/setting',
        builder: (context, state) => const SettingScreen()),
  ],
);
```
`GoRoute` の `routes` にさらに `GoRoute` を指定することで、そのルートの子要素、遷移先として新たなページのルートを指定することができます。

DetailScreen は以下のように AppBar のみの画面にしています。
```dart: detail_screen.dart
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
      ),
    );
  }
}
```

以下のように `HomeScreen` から `DetailScreen` に遷移するパスを指定すれば下の画像のように「戻るボタン」を持つ `DetailScreen` に遷移することができます。
```dart: home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static String get routeName => 'home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            context.go('/detail');
          },
          child: const Text(
            "Go To Detail Screen",
          ),
        ),
      ),
    );
  }
}
```
`HomeScreen` の入れ子としてルート指定された `DetailScreen`
![detail_screen](https://storage.googleapis.com/zenn-user-upload/7c439bee0537-20231028.png =250x)

### Navigator.pushNamed
Navigator
```dart: home_screen.dart
Navigator.pushNamed(context, '/detail');
```

go router
```dart: home_screen.dart
context.goNamed('detail');
```
`goNamed`でも階層で下にあるページに関しては「戻るボタン」がある状態で画面に遷移します。

### Navigator.pushReplacement
Navigator
```dart: home_screen.dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => const DetailScreen(),
  ),
);
```

go router
```dart: home_screen.dart
context.pushReplacement('/detail');
```
`pushReplacement`では現在のページを差し替える形で新たなページに遷移します。
この場合だと`HomeScreen`を差し替える形で`DetailScreen`に遷移します。
実際に`pushReplacement`で遷移すると、これ以上戻るページが存在しないため、以下の画像のように戻るボタンがない状態で遷移します。
![push_replacement](https://storage.googleapis.com/zenn-user-upload/a7e9741ff947-20231028.png =250x)

### 値渡し①
まずは `DetailScreen` で `userName` というString型の変数を受け取るように変更します。
```diff dart: detail_screen.dart
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
+   required this.userName,
  });

+ final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
      ),
+     body: Center(
+       child: Text(
+         "Hello $userName !",
+       ),
+     ),
    );
  }
}
```

Navigator
```dart: home_screen.dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DetailScreen(
      userName: 'Koichi5',
    ),
  ),
);
```

go router
```diff dart: router.dart
GoRoute(
  name: 'detail',
  path: 'detail',
  builder: (context, state) => DetailScreen(
+   userName: state.extra as String,
  ),
),
```
```dart: home_screen.dart
context.go('/detail', extra: 'Koichi5');
```

go router では、`router.dart` で `DetailScreen` に渡す引数を state.extra で指定し、実際に遷移する処理では `extra`プロパティに渡したい値を指定します。

両方とも以下のように遷移した先で受け取った値を使用することができます。
![throw_valiables](https://storage.googleapis.com/zenn-user-upload/943bae5157ec-20231029.png =250x)

### 値渡し②
```dart: router.dart
GoRoute(
  name: 'detail',
  path: 'detail/:user_name/:user_id',
  builder: (context, state) {
    final userName = state.pathParameters['user_name'];
    final userId = state.pathParameters['user_id'];
    return DetailScreen(
      userName: userName!,
      userId: int.parse(userId!),
    );
  },
),
```
```dart: detail_screen.dart
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.userName, required this.userId});

  final String userName;
  final int userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
      ),
      body: Center(
        child: Text(
          "Hello $userName ! \n Your ID is $userId.",
        ),
      ),
    );
  }
}
```
```dart: home_screen.dart
context.go('/detail/Koichi5/101');
```
以上のように、GoRouteのパスに`:変数名`を入れることで値を渡すこともできます。
パスとして渡された変数を取り出すためには `state.pathParameters['user_name']` のように state.pathParameters で一致する変数名を代入すれば取り出すことができます。
このような渡し方はユーザー固有の情報やリストの詳細情報などに使用されることが多いです。

本記事も `https://zenn.dev/articles/50c553218ca938/edit` という記事になっており、`articles` のIDとして`50c553218ca938` が与えられていると考えることができ、 GoRouteのパスに指定する方法はこれと似ていると言えます。

実行すると以下のようにユーザー名とIDが正確に渡せていることがわかります。
![path_params](https://storage.googleapis.com/zenn-user-upload/eedff4a294c9-20231029.png =250x)


## まとめ
最後まで読んでいただいてありがとうございました。
今回は Go Router を使った画面遷移が Navigator ではどれに当たるかに焦点を当てて比較してきました。Go Router をタイプセーフで使う Go Router Builder についても学習するつもりなので、よろしければそちらもご覧ください。


### 参考
https://pub.dev/packages/go_router

https://zenn.dev/channel/articles/af4ffd813b1424

https://zenn.dev/maropook/articles/7cfd45e4a93496