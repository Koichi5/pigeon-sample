## 初めに
今回はGo Router Builder を使って、ボトムナビゲーションバーの画面遷移を実装したいと思います。今までは、Navigator と Riverod で実装していましたが、Go Router Builder を用いた実装に変更していきます。

## 記事の対象者
+ Flutter 学習者
+ Go Router, Go Router Builder を学習したい方
+ Go Router Builder をプロジェクトに導入したい方

## 目的
以下の動画のように、ボトムナビゲーションバーのナビゲーションを、Go Router Builder を用いて実装できるようになることを目的としています。

https://youtube.com/shorts/YP5k1Ut5kSE

## 意義
そもそもなぜ Go Router や Go Router Builder を使用するのかを多少理解する必要があるかと思います。今まで Navigator を用いた画面遷移を実装してきたため、Go Router, Go Router Builder に切り替えるためにはそれなりの労力がかかり、理由がなければモチベーションも湧かないかと思うためです。
主なメリットとしては[こちら](https://zenn.dev/k_kawasaki/articles/2cee32fc8a907d)の記事で書かれている通り、以下の五つが大きいかと思います。

+ アプリ全体のルーティングを1つのファイルにまとめることができる
+ 画面遷移のアニメーションをまとめることができる
+ 遷移時の処理がすっきりする
+ ボトムナビゲーションバーの出し入れを簡単にできる
+ 条件に応じてリダイレクトをかけれる

また、Flutter の画面遷移が Navigatior 1.0 から Navigator 2.0 へ移行し、それに対応するために制作されたパッケージが go_router, go_router におけるルーティングをタイプセーフに扱うために制作されたパッケージが go_router_builder であると言えます。

Navigator 1.0 は命令的であるのに対して Navigator 2.0 は宣言的であると言われています。
Navigator 1.0 においては、`push(), pop()` など命令的な API で Navigator の history, stack を操作するようにしています。一方で Navigator 2.0 においては、アプリの状態を反映して宣言的に再構築できるようになっています。これにより複数のページをプッシュまたはポップしたり、現在のページの下にあるページを削除したりすることも可能になっています。

Navigator 2.0 に関しては、[こちら](https://zenn.dev/ntaoo/articles/6641e846765da1)の記事がわかりやすかったです。

## 導入
以下の三つのパッケージの最新バージョンを `pubspec.yaml`に記述
+ [go_router](https://pub.dev/packages/go_router)
+ [build_runner](https://pub.dev/packages/build_runner)
+ [go_router_builder](https://pub.dev/packages/go_router_builder)
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^12.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.2.1
  go_router_builder: ^2.4.0
```

または

以下をターミナルで実行
```
flutter pub add go_router
flutter pub add -d build_runner go_router_builder
```

## MyApp の変更
### 変更前
```dart: main.dart
class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Quiz-app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        fontFamily: "Noto Sans JP",
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        fontFamily: "Noto Sans JP",
      ),
    );
  }
}
```
通常の `MaterialApp` を使用しています。
通常モードとダークモードでカラースキームを切り替えたり、フォントの指定をしたりしています。

### 変更後
```diff dart: main.dart
+ final rotuerProvider = Provider<GoRouter>(
+   (ref) {
+     return GoRouter(
+       debugLogDiagnostics: true,
+       routes: $appRoutes,
+     );
+   },
+ );

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
+   final router = ref.watch(rotuerProvider);
    return MaterialApp.router(       // router を追加
      title: 'Quiz-app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        fontFamily: "Noto Sans JP",
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        fontFamily: "Noto Sans JP",
      ),
+     routerConfig: router,
    );
  }
}
```

まずは、`rotuerProvider` として、GoRouter を返り値にもつ Provider を作成しています。
`debugLogDiagnostics` を `true` にすることで、シミュレータなどで画面遷移を行った際に、どのルートにいるかなど詳細な情報がコンソールに出力されるようになります。
また、`routes` に指定している `$appRoutes` はこれから自動生成するルートをまとめたものになるので、現状ではエラーになっているかと思います。

そして、作成した `rotuerProvider` を読み取り、`MaterialApp.router` の中で `routeConfig` に指定します。
こうすることで、MaterialApp 全体でルートを読み込むことができるようになります。

## routes の設定
routes はアプリケーションのルーティングを全て一つのファイルにまとめるため、非常に長くなります。以下の５つのセクションに分けて解説していきます。
1. 各キーの設定
2. タブのルート設定
3. StatefulShellRouteData の設定
4. 各タブのデータの設定
5. 各画面のルート設定

### 各キーの設定
```dart routes.dart
// 各ページの import

part 'routes.g.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _categoryListNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'categoryListNav');
final GlobalKey<NavigatorState> _reviewNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'reviewNav');
final GlobalKey<NavigatorState> _originalQuestionListNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'originalQuestionListNav');
final GlobalKey<NavigatorState> _settingNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settingNav');
```

今回 Go Router Builder を導入しようとしているアプリには、以下の四つのタブを設けています。

| categoryList | review | originalQuestion | setting |
| ---- | ---- | ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/9cd2e540a9ae-20231222.png =150x) | ![](https://storage.googleapis.com/zenn-user-upload/8804ca8d5b52-20231222.png =150x) | ![](https://storage.googleapis.com/zenn-user-upload/4d814baa7db5-20231222.png =150x)| ![](https://storage.googleapis.com/zenn-user-upload/dc9b3724f5eb-20231222.png =150x)  |

それぞれのタブを個別に認識できるように `GlobalKey` を作成しています。
また、それらのタブを管理するための `rootNavigatorKey` も作成しています。
これらのキーを後述のルーティング設定でそれぞれのタブに割り当てていきます。

### タブのルート設定
次にタブで表示させるページのルート設定をしていきます。
コードとしては以下のようになります。
```dart: routes.dart
@TypedStatefulShellRoute<MyShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<BranchCategoryListData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CategoryListRoute>(
          path: '/',
          routes: [
            TypedGoRoute<CategoryDetailRoute>(
              path: 'detal',
              routes: [
                TypedGoRoute<QuizListRoute>(
                  path: 'quiz-list',
                  routes: [
                    TypedGoRoute<QuizResultRoute>(
                      path: 'quiz-result',
                      routes: [
                        TypedGoRoute<RetryQuizRoute>(
                          path: 'retry-quiz',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<BranchReviewData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ReviewRoute>(
          path: '/review',
          routes: [
            TypedGoRoute<WeakQuestionListRoute>(
              path: 'weak-quesiton-list',
              routes: [
                TypedGoRoute<WeakQuestionQuizRoute>(
                  path: 'weak-question-quiz',
                ),
              ],
            ),
            TypedGoRoute<QuizHistoryRoute>(
              path: 'quiz-history',
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<BranchOriginalQuestionListData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<OriginalQuestionListRoute>(
          path: '/original-question-quiz',
          routes: [
            TypedGoRoute<OriginalQuestionQuizRoute>(
                path: 'original-question-quiz'),
            TypedGoRoute<OriginalQuestionSetRoute>(
              path: 'original-question-set',
            ),
            TypedGoRoute<OriginalQuestionQuizResultRoute>(
              path: 'quiz-result',
              routes: [
                TypedGoRoute<OriginalQuestionRetryQuizRoute>(
                  path: 'retry-quiz',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<BranchSettingData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingRoute>(
          path: '/setting',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<DictionaryRoute>(
              path: 'dictionary',
            ),
          ],
        ),
      ],
    ),
  ],
)
```
タブページの画面遷移を Go Router Builder で実装する際には、`TypedStatefulShellRoute` アノテーションを使用します。

上記のコードは自身のアプリの場合なので、抽象化すると以下のようになるかと思います。
```dart: routes.dart
@TypedStatefulShellRoute(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch< 一つ目のタブのデータ >(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute< 一つ目のタブで最初に開かれるページ >(
          path: '一つ目のタブで最初に開かれるページのパス',
          routes: [
	    // 一つ目のタブの配下のページのルート
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch< 二つ目のタブのデータ >(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute< 二つ目のタブで最初に開かれるページ >(
          path: ' 二つ目のタブで最初に開かれるページのパス ',
          routes: [
	    // 二つ目のタブの配下のページのルート
          ],
        ),
      ],
    ),
    //  三、四つ目のタブのルート実装
  ],
)
```
それぞれのタブは `branches` というプロパティの中で管理されます。
`branches` は `TypedStatefulShellBranch` のリストで、それぞれのタブのデータが格納されます。`branches` のリストの順番で右から実装されるので、`TypedStatefulShellBranch` の順番にも注意して実装しましょう。

また、それぞれの branch の一番上位のルートに関しては `/` から始まる必要があります。
以下のコードを見ると、`/setting` というルートの下に `dictionary` というルートのページがあることがわかります。
```dart
TypedStatefulShellBranch<BranchSettingData>(
    routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingRoute>(
            path: '/setting',
	    routes: <TypedRoute<RouteData>>[
	        TypedGoRoute<DictionaryRoute>(
	            path: 'dictionary',
		),
            ],
        ),
    ],
),
```
`branch` の一番上位のルートが `/` から始まる文字列でなかった場合、以下のエラーになるので、このエラーが出た時にはまずは `branch` のルートを確認してみましょう。
```
Failed assertion: line 40 pos 18: 'route.path.startsWith('/')': top-level path must start with "/"
```
<br>

::: details TypedStatefulShellRoute と TypedShellRoute の比較
StatefulShellRoute の公式ドキュメントに以下のような記述がありました。
「making it possible to build an app with stateful nested navigation. This is convenient when for instance implementing a UI with a BottomNavigationBar, with a persistent navigation state for each tab.」

簡単にまとめると、StatefulShellRoute ではそれぞれのタブにおける状態を永続化させることができ、BottomNavigationBar のようなUIの実装に便利であるとのことです。TypedStatefulShellRoute は StatefulShellRoute をタイプセーフに記述するものであるため、TypedStatefulShellRoute にも同様のことが言えるかと思います。

「それぞれのタブにおける状態の永続化」について詳しく掘り下げます。
以下の動画では、一度復習タブの「履歴」の上部タブを選択した後、カテゴリ一覧のタブに移り、再度復習タブに戻っても「履歴」のタブが開かれたままになっています。これは他のタブに写ったとしてもそのタブの状態が保持されていることを意味しています。
これが「それぞれのタブにおける状態の永続化」と言えます。

https://youtube.com/shorts/v6WJcW3-ws4

:::

### StatefulShellRouteData の設定
次にタブページを制御するページのを制作していきます。
コードは以下のようになります。
```dart
class MyShellRouteData extends StatefulShellRouteData {
  const MyShellRouteData();

  static final GlobalKey<NavigatorState> $navigatorKey = rootNavigatorKey;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return navigationShell;
  }

  static const String $restorationScopeId = 'restorationScopeId';

  static Widget $navigatorContainerBuilder(BuildContext context,
      StatefulNavigationShell navigationShell, List<Widget> children) {
    return HomeScreen(
      navigationShell: navigationShell,
      children: children,
    );
  }
}
```
`$navigatorContainerBuilder` に関しては、生成された `routes.g.dart` の方で`navigatorContainerBuilder: MyShellRouteData.$navigatorContainerBuilder,` とされており、`$navigatorContainerBuilder` をもとにタブページが構築されていることがわかります。

また、`HomeScreen` は以下のようになっています。
`navigationShell` は `currentIndex` として現在選択されているタブのインデックスを保持しています。それらをもとに表示させるページを変えることができます。
```dart: home.dart
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({
    super.key,
    required this.navigationShell,
    required this.children,
  });

  final StatefulNavigationShell navigationShell;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
        body: BranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: children,
        ),
        bottomNavigationBar: BottomNavBar(
          navigationShell: navigationShell,
        ),
  }
}

class BranchContainer extends StatelessWidget {
  const BranchContainer(
      {super.key, required this.currentIndex, required this.children});

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
        children: children.mapIndexed(
      (int index, Widget child) {
        if (index == currentIndex) {
          return _branchNavigatorWrapper(index, child);
        } else {
          return const SizedBox();
        }
      },
    ).toList());
  }

  Widget _branchNavigatorWrapper(int index, Widget navigator) => IgnorePointer(
        ignoring: index != currentIndex,
        child: TickerMode(
          enabled: index == currentIndex,
          child: navigator,
        ),
      );
}

class BottomNavBar extends HookConsumerWidget {
  BottomNavBar({super.key, required this.navigationShell});

  final Map<String, IconData> bottomContentList = {
    "ホーム": Icons.home,
    "復習": Icons.star,
    "追加": Icons.add,
    "設定": Icons.settings,
  };

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BottomNavyBar(
      items: _buildBottomNavyBarItems(context),
      selectedIndex: navigationShell.currentIndex,
      onItemSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
    );
  }

  List<BottomNavyBarItem> _buildBottomNavyBarItems(BuildContext context) {
    return bottomContentList.entries.map((entry) {
      return BottomNavyBarItem(
        title: Text(entry.key),
        icon: Icon(entry.value),
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.inversePrimary,
      );
    }).toList();
  }
}
```
今までは Riverpod の `StateProvider` で現在選択されているタブのインデックスを保持していましたが、Riverpod Generator で `StateProvider` が用意されておらず、直接値を変更することが推奨されていないことを考えると、Go Router Builder の `navigationShell` にインデックスを保持してもらえることはメリットであると言えます。

### 各タブのデータの設定
次に各タブのデータを設定していきます。
コードは以下のようになります。
```dart: routes.dart
class BranchCategoryListData extends StatefulShellBranchData {
  const BranchCategoryListData();

  static final GlobalKey<NavigatorState> $navigatorKey =
      _categoryListNavigatorKey;
}

class BranchReviewData extends StatefulShellBranchData {
  BranchReviewData();

  static final GlobalKey<NavigatorState> $navigatorKey = _reviewNavigatorKey;
  static const String $restorationScopeId = 'restorationScopeId';
}

class BranchOriginalQuestionListData extends StatefulShellBranchData {
  BranchOriginalQuestionListData();

  static final GlobalKey<NavigatorState> $navigatorKey =
      _originalQuestionListNavigatorKey;
  static const String $restorationScopeId = 'restorationScopeId';
}

class BranchSettingData extends StatefulShellBranchData {
  BranchSettingData();

  static final GlobalKey<NavigatorState> $navigatorKey = _settingNavigatorKey;
  static const String $restorationScopeId = 'restorationScopeId';
}
```

一つのタブの実装は以下のようになっています。
タブのデータは `StatefulShellBranchData` で指定できます。
そして、それぞれのタブで事前に作成した `GlobalKey` を割り当てています。
`GlobalKey` を割り当てることでそれぞれのタブを判別できるようになります。

```dart
class BranchCategoryListData extends StatefulShellBranchData {
  const BranchCategoryListData();

  static final GlobalKey<NavigatorState> $navigatorKey =
      _categoryListNavigatorKey;
}
```

### 各画面のルート設定
最後に各ページのルートデータを設定していきます。
一つのページのルートデータは基本的に以下のような形になります。
```dart
class CategoryListRoute extends GoRouteData {
  const CategoryListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
        key: state.pageKey, child: const CategoryListScreen());
  }
}
```
`NoTransitionPage` は go_router パッケージ内の `CustomTransitionPage` を継承しています。説明としては「Custom transition page with no transition.」とありました。

`CustomTransitionPage` をみてみると `transitionsBuilder` `transitionDuration` などがあり、どのように遷移するかを指定できるようでした。

ただ、今回使用するのは `NoTransitionPage` であり、プロパティには `transitionsBuilder` `transitionDuration` などがなかったので、画面遷移の方法を指定することができないということかと思います。

`NoTransitionPage` の `child` として各ページを指定することでルートデータが設定できます。

また、以下のページのように、`$extra` として型を指定して受け取ることで、遷移先のページに値を渡すことができます。渡す値は自作の型の値でも可能です。ただ、複数の値を渡すことはパスパラメータを併用する以外にはできないかと思うので、複数渡したい値がある場合は一つのクラスにまとめた方が良いかと思います。
```dart: routes.dart
class QuizResultRoute extends GoRouteData {
  const QuizResultRoute({required this.$extra});

  final QuizResult $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: QuizResultScreen(
        result: $extra,
      ),
    );
  }
}
```

実際に `QuizResultScreen` に渡す値は以下のように複数の値を受け取っていました。
今考えると、どの問題を受けたかを表す `takenQuestions` や答えがあっていたかを表す `answerIsCorrectList` も全てクイズの結果である `result` にまとめられるし、分ける理由もないかと思ったので、一つにまとめました。
結果として可読性もコードの意味の整合性も上がったかと思います。

#### 改善前
```dart
class QuizResultScreen extends HookConsumerWidget {
  const QuizResultScreen(
      {required this.result,
      required this.takenQuestions,
      required this.answerIsCorrectList,
      required this.questionList,
      Key? key})
      : super(key: key);

  final List<int> takenQuestions;
  final List<bool> answerIsCorrectList;
  final List<Question> questionList;
```

#### 改善後
```dart
class QuizResultScreen extends HookConsumerWidget {
  const QuizResultScreen({required this.result, Key? key}) : super(key: key);

  final QuizResult result;
```

<br>
::: details routes.dart の全コード
```dart
part 'routes.g.dart';

// 1. 各キーの設定
final rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _categoryListNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'categoryListNav');
final GlobalKey<NavigatorState> _reviewNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'reviewNav');
final GlobalKey<NavigatorState> _originalQuestionListNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'originalQuestionListNav');
final GlobalKey<NavigatorState> _settingNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'settingNav');

// 2. タブのルート設定
@TypedStatefulShellRoute<MyShellRouteData>(
  branches: <TypedStatefulShellBranch<StatefulShellBranchData>>[
    TypedStatefulShellBranch<BranchCategoryListData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<CategoryListRoute>(
          path: '/',
          routes: [
            TypedGoRoute<CategoryDetailRoute>(
              path: 'detal',
              routes: [
                TypedGoRoute<QuizListRoute>(
                  path: 'quiz-list',
                  routes: [
                    TypedGoRoute<QuizResultRoute>(
                      path: 'quiz-result',
                      routes: [
                        TypedGoRoute<RetryQuizRoute>(
                          path: 'retry-quiz',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<BranchReviewData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<ReviewRoute>(
          path: '/review',
          routes: [
            TypedGoRoute<WeakQuestionListRoute>(
              path: 'weak-quesiton-list',
              routes: [
                TypedGoRoute<WeakQuestionQuizRoute>(
                  path: 'weak-question-quiz',
                ),
              ],
            ),
            TypedGoRoute<QuizHistoryRoute>(
              path: 'quiz-history',
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<BranchOriginalQuestionListData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<OriginalQuestionListRoute>(
          path: '/original-question-quiz',
          routes: [
            TypedGoRoute<OriginalQuestionQuizRoute>(
                path: 'original-question-quiz'),
            TypedGoRoute<OriginalQuestionSetRoute>(
              path: 'original-question-set',
            ),
            TypedGoRoute<OriginalQuestionQuizResultRoute>(
              path: 'quiz-result',
              routes: [
                TypedGoRoute<OriginalQuestionRetryQuizRoute>(
                  path: 'retry-quiz',
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<BranchSettingData>(
      routes: <TypedRoute<RouteData>>[
        TypedGoRoute<SettingRoute>(
          path: '/setting',
          routes: <TypedRoute<RouteData>>[
            TypedGoRoute<DictionaryRoute>(
              path: 'dictionary',
            ),
          ],
        ),
      ],
    ),
  ],
)

// 3. StatefulShellRouteData の設定
class MyShellRouteData extends StatefulShellRouteData {
  const MyShellRouteData();

  static final GlobalKey<NavigatorState> $navigatorKey = rootNavigatorKey;

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    return navigationShell;
  }

  static const String $restorationScopeId = 'restorationScopeId';

  static Widget $navigatorContainerBuilder(BuildContext context,
      StatefulNavigationShell navigationShell, List<Widget> children) {
    return HomeScreen(
      navigationShell: navigationShell,
      children: children,
    );
  }
}

// 4. 各タブのデータの設定
class BranchCategoryListData extends StatefulShellBranchData {
  const BranchCategoryListData();

  static final GlobalKey<NavigatorState> $navigatorKey =
      _categoryListNavigatorKey;
}

class BranchReviewData extends StatefulShellBranchData {
  BranchReviewData();

  static final GlobalKey<NavigatorState> $navigatorKey = _reviewNavigatorKey;
  static const String $restorationScopeId = 'restorationScopeId';
}

class BranchOriginalQuestionListData extends StatefulShellBranchData {
  BranchOriginalQuestionListData();

  static final GlobalKey<NavigatorState> $navigatorKey =
      _originalQuestionListNavigatorKey;
  static const String $restorationScopeId = 'restorationScopeId';
}

class BranchSettingData extends StatefulShellBranchData {
  BranchSettingData();

  static final GlobalKey<NavigatorState> $navigatorKey = _settingNavigatorKey;
  static const String $restorationScopeId = 'restorationScopeId';
}

// 5. 各画面のルート設定
class CategoryListRoute extends GoRouteData {
  const CategoryListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
        key: state.pageKey, child: const CategoryListScreen());
  }
}

class CategoryDetailRoute extends GoRouteData {
  const CategoryDetailRoute({required this.$extra});

  final Category $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: CategoryDetailScreen(
        category: $extra,
      ),
    );
  }
}

class QuizListRoute extends GoRouteData {
  const QuizListRoute({required this.$extra});

  final Category $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: QuizListScreen(
        category: $extra,
      ),
    );
  }
}

class QuizResultRoute extends GoRouteData {
  const QuizResultRoute({required this.$extra});

  final QuizResult $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: QuizResultScreen(
        result: $extra,
      ),
    );
  }
}

class RetryQuizRoute extends GoRouteData {
  const RetryQuizRoute({required this.$extra});

  final List<Question> $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: RetryQuizScreen(
        questionList: $extra,
      ),
    );
  }
}

class OriginalQuestionQuizRoute extends GoRouteData {
  const OriginalQuestionQuizRoute({required this.$extra});

  final List<Question> $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: OriginalQuestionQuizScreen(
        originalQuestionList: $extra,
      ),
    );
  }
}

class OriginalQuestionQuizResultRoute extends GoRouteData {
  const OriginalQuestionQuizResultRoute({required this.$extra});

  final QuizResult $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: QuizResultScreen(
        result: $extra,
      ),
    );
  }
}

class OriginalQuestionRetryQuizRoute extends GoRouteData {
  const OriginalQuestionRetryQuizRoute({required this.$extra});

  final List<Question> $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: RetryQuizScreen(
        questionList: $extra,
      ),
    );
  }
}

class ReviewRoute extends GoRouteData {
  const ReviewRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(key: state.pageKey, child: const ReviewScreen());
  }
}

class WeakQuestionListRoute extends GoRouteData {
  const WeakQuestionListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: const WeakQuestionScreen(),
    );
  }
}

class WeakQuestionQuizRoute extends GoRouteData {
  const WeakQuestionQuizRoute({required this.$extra});

  final List<Question> $extra;

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: WeakQuestionQuizScreen(
        weakQuestionList: $extra,
      ),
    );
  }
}

class QuizHistoryRoute extends GoRouteData {
  const QuizHistoryRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: const QuizHistoryScreen(),
    );
  }
}

class OriginalQuestionListRoute extends GoRouteData {
  const OriginalQuestionListRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: const OriginalQuestionListScreen(),
    );
  }
}

class OriginalQuestionSetRoute extends GoRouteData {
  const OriginalQuestionSetRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: const OriginalQuestionSetScreen(),
    );
  }
}

class SettingRoute extends GoRouteData {
  const SettingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(key: state.pageKey, child: const SettingScreen());
  }
}

class DictionaryRoute extends GoRouteData {
  const DictionaryRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return NoTransitionPage(
      key: state.pageKey,
      child: const DictionaryScreen(),
    );
  }
}
```
:::

これで以下の動画のようにタブページにおける画面遷移を実装できるようになったかと思います。

https://youtube.com/shorts/YP5k1Ut5kSE

## まとめ
最後まで読んでいただいてありがとうございました。
一通りタブページの実装をしてみましたが、使い始めてまもなく、試用段階でもあるので、誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://zenn.dev/k_kawasaki/articles/2cee32fc8a907d

https://zenn.dev/ntaoo/articles/6641e846765da1

https://zenn.dev/flutteruniv_dev/articles/stateful_shell_route

https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html

https://pub.dev/documentation/go_router/latest/go_router/TypedShellRoute-class.html

https://github.com/flutter/packages/blob/main/packages/go_router_builder/example/lib/stateful_shell_route_example.dart
