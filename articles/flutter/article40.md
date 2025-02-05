## 初めに
以下の記事では Navigator と Go Router を比較して簡単な画面遷移がどのように書けるかを学んできました。本記事では Go Router をタイプセーフで書くことができる Go Router Builder に関して学んでいきたいと思います。

https://zenn.dev/koichi_51/articles/50c553218ca938

## 記事の対象者
+ Flutter 学習者
+ Go Router を使いたい方
+ Go Router Builder を使いたい方

## 実装
### 導入
以下の三つのパッケージの最新バージョンを`pubspec.yaml`に記述
+ [go_router](https://pub.dev/packages/go_router)
+ [build_runner](https://pub.dev/packages/build_runner)
+ [go_router_builder](https://pub.dev/packages/go_router_builder)

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^12.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.6
  go_router_builder: ^2.3.4
```

または

以下をターミナルで実行
```
flutter pub add go_router
flutter pub add -d build_runner  go_router_builder
```

### 現在のコード
[こちら]()の記事では Go Router を使用していたため、以下のように `router.dart` の `GoRouter` に全てのルートを指定しています。
```dart: router.dart
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
        routes: [
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
        ],
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
:::details 全体のコード
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
    return MaterialApp.router(
      title: 'Go Router Sample',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
```

```dart: router.dart
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
        routes: [
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
        ],
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
            context.go('/detail/Koichi5/101');
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
            context.pop();
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
:::


### ルートの指定
まずは `HomeScreen` と `DetailScreen` のルートの実装を行いましょう。
※単純化のため `DetailScreen` を以下のように引数を持たない単純なページに変更しています。
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

`router.dart` を以下のように変更します。
```dart: router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_builder_sample/screens/detail_screen.dart';
import 'package:go_router_builder_sample/screens/home_screen.dart';

part 'router.g.dart';

final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: $appRoutes,
);

@TypedGoRoute<HomeRoute>(
    path: '/',
    routes: [
      TypedGoRoute<DetailRoute>(path: 'detail')
    ]
)
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class DetailRoute extends GoRouteData {
  const DetailRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DetailScreen();
}
```

`TypedGoRoute` アノテーションを使用することで、後述の処理で指定したルートが自動生成されます。あるページの子要素、入れ子になるページは `routes` に指定している点は Go Router と同じであると言えます。
`routes: $appRoutes` では後述の自動生成されたコードの中で`TypedGoRoute` アノテーションを用いて生成されたルートのリストが `appRoutes` という変数に格納されており、それが `routes` に指定されています。

:::details 上のコードと同じ Go Router のコード
```dart: router.dart
import 'package:go_router/go_router.dart';
import 'package:go_router_builder_sample/screens/detail_screen.dart';
import 'package:go_router_builder_sample/screens/home_screen.dart';

final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'home',
      path: '/',
      routes: [
        GoRoute(
          path: 'detail',
          builder: (context, state) {
            return const DetailScreen();
          },
        ),
      ],
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
```
:::

<br>
そして以下のコードを実行することで、ルートのコードが自動生成されます。
```
flutter pub run build_runner build --delete-conflicting-outputs
```

自動生成されたコードを見てみると、以下のように `go` `push` `pushReplacement` のほかに`location` として今のパスを取得できるような変数も生成されていることがわかります。
```dart: router.g.dart
extension $HomeRouteExtension on HomeRoute {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  String get location => GoRouteData.$location(
        '/',
      );

  void go(BuildContext context) => context.go(location);

  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  void replace(BuildContext context) => context.replace(location);
}
```

画面遷移を行いたいときは以下のように遷移先のルートを指定して `go` で遷移することができます。
```dart: home_screen.dart
const DetailRoute.go(context);
```

エラーがなくなった段階で実際に動かしてみると、遷移先として戻るボタンがある `DetailScreen`に遷移することがわかります。


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

Go Router
```dart: router.dart
GoRoute(
  name: 'detail',
  path: 'detail',
  builder: (context, state) => DetailScreen(
    userName: state.extra as String,
  ),
),
```
```dart: home_screen.dart
context.go('/detail', extra: 'Koichi5');
```

Go Router では、`router.dart` で `DetailScreen` に渡す引数を state.extra で指定し、実際に遷移する処理では `extra`プロパティに渡したい値を指定していました。

Go Router Builder
```diff dart: router.dart
class DetailRoute extends GoRouteData {
  const DetailRoute(
+ {required this.userName}
  );

+ final String userName;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DetailScreen(
+       userName: userName
      );
}
```
`DetailRoute` の方で `userName` という変数名で String 型の入力を受け付け、それを `DetailScreen` に代入するように変更します。

ここで重要なのは、先ほど定義した `TypedGoRoute<DetailRoute>(path: 'detail')` は変更する必要ないという点です。

再度以下のビルドランナーを実行してルートの内容を更新します。
```
flutter pub run build_runner build --delete-conflicting-outputs
```

遷移したいページで以下のように遷移先のページの引数に渡したい値を代入して遷移すれば画像のように遷移先のページで変数を使うことができます。
```dart: home_screen.dart
const DetailRoute(userName: 'Koichi5').go(context);
```

![throw_params](https://storage.googleapis.com/zenn-user-upload/0593a1c3d0d6-20231029.png =250x)

なお、遷移する際のページのルートは以下のようになっています。
```
going to /detail?user-name=Koichi5
```
`userName`としてキャメルケースだった変数名は`user-name`というケバブケースに変更されていました。


### 値渡し②
Go Router
```dart: router.dart
GoRoute(
  name: 'detail',
  path: 'detail/:user_name,
  builder: (context, state) {
    final userName = state.pathParameters['user_name'];
    return DetailScreen(
      userName: userName!,
    );
  },
),
```
```dart: detail_screen.dart
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.userName});

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
      ),
      body: Center(
        child: Text(
          "Hello $userName !",
        ),
      ),
    );
  }
}
```
```dart: home_screen.dart
context.go('/detail/Koichi5');
```
Go Router では以上のように、GoRouteのパスに`:変数名`を入れることで値を渡すこともできました。
パスとして渡された変数を取り出すためには `state.pathParameters['user_name']` のように state.pathParameters で一致する変数名を代入すれば取り出すことができました。

Go Router Builder
```dart: router.dart
TypedGoRoute<DetailRoute>(path: 'detail/:userName')
```
Go Router Builder では、先ほどの「値渡し①」の変更に加え、`router.dart`の値を受け取りたい側のページのパスに、`DetailRoute` の `userName` のように同じ変数を `:変数名`として指定することで、以下のように受け取る変数をパスに含める形で渡すことができます。
```
going to /detail/Koichi5
```

:::details この時の関連コード
```dart: router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_builder_sample/screens/detail_screen.dart';
import 'package:go_router_builder_sample/screens/home_screen.dart';

part 'router_builder.g.dart';

final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: $appRoutes,
);

@TypedGoRoute<HomeRoute>(
    path: '/', routes: [TypedGoRoute<DetailRoute>(path: 'detail/:userName')])
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class DetailRoute extends GoRouteData {
  const DetailRoute(this.userName);

  final String userName;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DetailScreen(userName: userName);
}
```

```dart: detail_screen.dart
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.userName,
  });

  final String userName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
      ),
      body: Center(
        child: Text(
          "Hello $userName !",
        ),
      ),
    );
  }
}
```

```dart: home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router_builder_sample/router_builder.dart';

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
            const DetailRoute('Koichi5').go(context);
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
このコードでは単一のパラメーターしか受け取っていないため、問題ありませんが、複数のパラメーターをパスに含める場合はパラメーターを受け取る `DetailRoute` に関しては required をつけて受け取る変数名を明示した方が良いかと思います。
:::

### 値渡し③
`extra` を使った値渡しも実装することができます。
```dart: router.dart
class DetailRoute extends GoRouteData {
  const DetailRoute({required this.userName, this.$extra});

  final String userName;
  final int? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DetailScreen(userName: userName, extra: $extra);
}
```
```dart: detail_screen.dart
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.userName,
    this.extra
  });

  final String userName;
  final int? extra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
      ),
      body: Center(
        child: Text(
          "Hello $userName ! \n Your ID is $extra !"
        ),
      ),
    );
  }
}
```
```dart: home_screen.dart
const DetailRoute(userName: 'Koichi5', $extra: 101).go(context);
```

以上のように `router.dart` で `$extra` という名前のパラメータを引数と指定することで、以下の画像のようにパラメータを渡すことができます。
![throw_variables_with_extra](https://storage.googleapis.com/zenn-user-upload/17b5ddbe7419-20231029.png =250x)

ただ、この時の注意点としてルートの表示が以下のようになり、パラメータが渡されていることがわかりにくいという点があるので、注意しましょう。
```
going to /detail/Koichi5
```

### 複数値渡し
パスパラメータ、クエリパラメータ、extra の三つを組み合わせた値渡しを実装してみます。
以下のように `DetailRoute` でそれぞれパスパラメータの `userName`、クエリパラメータの `userAge`、extra の `$extra` を受け取るようにします。
```dart: router.dart
@TypedGoRoute<HomeRoute>(
    path: '/', routes: [TypedGoRoute<DetailRoute>(path: 'detail/:userName')])
class HomeRoute extends GoRouteData {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class DetailRoute extends GoRouteData {
  const DetailRoute({required this.userName, this.userAge, this.$extra});

  final String userName;
  final int? userAge;
  final int? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      DetailScreen(userName: userName, userAge: userAge, extra: $extra);
}
```

`DetailScreen` では先ほど指定した三つの変数を受け取るようにします。
```dart: detail_screem.dart
import 'package:flutter/material.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen(
      {super.key, required this.userName, this.userAge, this.extra});

  final String userName;
  final int? userAge;
  final int? extra;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detail"),
      ),
      body: Center(
        child: Text("Hello $userName ! \n Your Age is $userAge! \n Your ID is $extra !"),
      ),
    );
  }
}
```

遷移元の `HomeScreen` では以下のように三つの引数を渡して遷移します。
```dart: home_screen.dart
const DetailRoute(userName: 'Koichi5', userAge: 20, $extra: 101).go(context);
```

ビルドランナーを実行して、ビルドすると以下の画像のように三つのパラメータが `DetailScreen` に渡されていることがわかります。
![mixed_params](https://storage.googleapis.com/zenn-user-upload/d961caff4fad-20231029.png =250x)

なお、遷移する際のパスは以下のようになります。
```
going to /detail/Koichi5?user-age=20
```
パスパラメータは正確にパスに組み込まれています。
クエリパラメータはパスの後ろに `?` がついた形でケバブケースで代入されています。
extra はパスには含まれませんが、値は渡されています。


### エラー
エラーが発生した時に遷移するページを指定することもできます。
```dart: error_screen.dart
import 'package:flutter/material.dart';

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key, required this.error});

  final Exception error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('エラー'),
      ),
      body: Center(
          child: Column(
        children: [
          Text(
            error.toString(),
          ),
          const Text('申し訳ありませんが、もう一度お試しください')
        ],
      )),
    );
  }
}
```

```diff dart: router.dart
final router = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: $appRoutes,
+ errorBuilder: (context, state) => ErrorRoute(error: state.error!).build(context, state),
);

// 以下の ErrorRoute を追加
class ErrorRoute extends GoRouteData {
  ErrorRoute({required this.error});

  final Exception error;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ErrorScreen(error: error);
}
```

以上のように `ErrorScreen` とそれに対応する `ErrorRoute` を作成し、`GoRouter` の `errorBuilder` に渡すとエラーが発生した時に指定した `ErrorScreen` に遷移させることができます。

今でもルーティングに関してエラーが発生した場合は、その原因と元のページに戻るための導線が用意されているのですが、UXとしては最低限のものになるかと思うので、`ErrorRoute` を設けてUXの損失を最小限にすることは良いことと言えるのではないでしょうか？

## 使ってみて感じたこと
Go Router と Go Router Builder 両方を使ってみてのメリットとデメリットを感じたまままとめます。

メリット
+ ルーティングを一つのファイルにまとめて管理できる
+ ルートを指定してしまえば遷移の記述が楽
+ redirect が標準で実装されているため、アップデート後の画面表示や未ログイン時の実装が簡単にできそう（これから追加実装するかもしれません）

デメリット
+ スクリーン数の少ないアプリでは逆に手間が増えるかもしれない
+ NavigatorではUIのコードを読んでいて、遷移先のページを確認したい時には command を押したままコードをクリックすれば確認できたが、Go Router、Go Router Builder ではルーティングが分離されているため確認できない（細かいところですが...）
+ 独自でカスタムした型を簡単に次のページに渡すことができない

## まとめ
最後まで読んでいただいてありがとうございました。
特に Go Router Builder に関してはまだまだ変化が激しいパッケージかと思うので、これからも定期的にアップデートできたらと思います。
触れ始めて日が浅いのでもっと良い実装方法等あればご指摘いただければ幸いです。


### 参考
https://pub.dev/packages/go_router_builder

https://zenn.dev/flutteruniv_dev/articles/20220801-135028-flutter-go-router-builder