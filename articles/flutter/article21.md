## 初めに
今回は FlutterWeb で Google認証を行おうとした際に従来の方法ではサインインできなくなっていたため、この問題を解決していきたいと思います。

## 記事の対象者
+ Flutter 学習者
+ Flutter Web の開発を行っている方
+ Flutter Web で Googleサインインを実装している方

## 目的
今回は上記の通り、Google認証が FutterWeb でできなくなっていたため、それを解消していくことを目的とします。なお、問題が発生したパッケージは [google_sign_in パッケージ](https://pub.dev/packages/google_sign_in) の Webバージョンにあたる [google_sign_in_web](https://pub.dev/packages/google_sign_in_web)です。

また、発生したエラーは以下の通りです。
```
The `signIn` method is discouraged on the web because it can't reliably provide an `idToken`.
Use `signInSilently` and `renderButton` to authenticate your users instead.
Read more: https://pub.dev/packages/google_sign_in_web
The google_sign_in plugin `signIn` method is deprecated on the web, and will be removed in Q2 2024. Please use `renderButton` instead. See: https://pub.dev/packages/google_sign_in_web#migrating-to-v011-and-v012-google-identity-services
```

同様のエラーで実装方法のみを知りたい方は[実装](#実装)を見ていただければ良いかと思います。

## 問題の再現
### 各バージョン
+ Flutter 3.16.9
+ Dart version 3.2.6
+ google_sign_in: ^6.2.1
+ google_sign_in_web: ^0.12.3+2

### コード
ViewModel
```dart: sign_up/view_model.dart
part 'view_model.g.dart';

enum SignUpType {
  google,
  apple,
  email,
}

@riverpod
class SignUpViewModel extends _$SignUpViewModel {
  UserAuthRepo get userAuthRepo => ref.read(userAuthRepoProvider.notifier);

  @override
  void build() {}

  Future<void> signUp(SignUpType signUpType) async {  // 2
    switch (signUpType) {
      case SignUpType.google:
        await _signInWithGoogle().catchError((e) => throw e);
      case SignUpType.apple:
        await _signInWithApple().catchError((e) => throw e);
      case SignUpType.email:
        break;
    }
  }

  /// Google Sign In
  Future<void> _signInWithGoogle() async {  // 3
    final GoogleSignIn googleSignIn = GoogleSignIn();
    try {
      final GoogleSignInAccount? signInAccount = await googleSignIn.signIn();  // 4

      if (signInAccount == null) {
        throw ArgumentError('不明なエラーが発生しました\nアプリをもう一度起動させてから行ってください');
      }

      final GoogleSignInAuthentication signInAuthentication =
          await signInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: signInAuthentication.idToken,
        accessToken: signInAuthentication.accessToken,
      );

      await ref.read(firebaseAuthProvider).signInWithCredential(credential);  // 5
    } on Exception {
      rethrow;
    }
  }

  /// Apple Sign In のメソッドは省略
}
```

View
```dart: sign_up/view.dart
class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google サインイン'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await ref
                .read(signUpViewModelProvider.notifier)
                .signUp(SignUpType.google);  // 1
          },
          child: const Text('Google でサインイン'),
        ),
      ),
    );
  }
}
```

UI
![](https://storage.googleapis.com/zenn-user-upload/b42381153d2c-20240323.png)

コードにコメントアウトで番号を示している通り、処理の流れは以下のようになります。
1. ElevatedButton の onPressed で signUpViewModelProvider の signUp メソッドを実行
2. SignUpViewModel の signup メソッド
3. _signInWithGoogle メソッド
4. googleSignIn.signIn() メソッド
5. await ref.read(firebaseAuthProvider).signInWithCredential(credential) メソッド
   （FirebaseAuthのサインイン）

### エラー内容
目的の章でも提示しましたが、エラー内容を以下にも提示します。
このエラーが表示されて、Webの表示には何も変更が起こらず、サインインもできないような状態になります。
```
The `signIn` method is discouraged on the web because it can't reliably provide an `idToken`.
Use `signInSilently` and `renderButton` to authenticate your users instead.
Read more: https://pub.dev/packages/google_sign_in_web
The google_sign_in plugin `signIn` method is deprecated on the web, and will be removed in Q2 2024. Please use `renderButton` instead. See: https://pub.dev/packages/google_sign_in_web#migrating-to-v011-and-v012-google-identity-services
```

要約すると以下のようなことかと思います。
+ Web上でsignInメソッドの使用は推奨されない
+ idTokenを信頼性高く提供できないため、signInSilentlyとrenderButtonの使用が推奨される
+ signInメソッドは、2024年第2四半期に削除予定
+ signInの代わりにrenderButtonを使用すること

## 問題の背景
問題の背景を探るために、エラー文にも含まれていた [google_sign_in_web](https://pub.dev/packages/google_sign_in_web#migrating-to-v011-and-v012-google-identity-services) のリンクから調べてみました。

### 問題の原因
問題の原因は Google が「認証」と「認可」を分離するということでした。
[認証と認可](https://developers.google.com/identity/gsi/web/guides/migration?hl=ja#authentication_and_authorization)のページから引用すると以下のようになります。
> 認証はユーザーを識別するもので、一般的にユーザーの登録またはログインと呼ばれます。認可とは、データやリソースへのアクセス権を付与または拒否するプロセスです。たとえば、アプリがユーザーの Google ドライブにアクセスすることについてユーザーの同意を求めています。
>
> 以前の Google ログイン プラットフォーム ライブラリと同様に、新しい Google Identity Services ライブラリは、認証と認可の両方のプロセスをサポートするように構築されています。
>
> ただし、新しいライブラリでは 2 つのプロセスが分離され、デベロッパーが Google アカウントをアプリに統合する際の複雑さが軽減されます。

つまり、ユーザーを識別するユーザー登録やログインの処理である「認証」と、データやリソースへのアクセスを管理する「認可」の二つの処理が分離されるため、対応が必要であるとのことです。

google_sign_in_web のページに以下のような記述がありました。
> the current implementation of signIn (that does authorization and authentication) is no longer feasible on the web.

Google の「認証と認可」のページと合わせると、現状の signIn メソッドでは「認証」と「認可」を同時に実行するため、認証と認可の分離の観点から使用できないということのようです。

## 解決策
signIn メソッドを使用せずにサインインを実装するためにはどのようにすればよいでしょうか？
google_sign_in_web　のページに以下のような記述がありました。
> The solution to this is to migrate your custom "Sign In" buttons in the web to the Button Widget provided by this package: Widget renderButton().

「サインインボタンの移行を行うためには `renderButton` を使用しましょう」とのことでした。

調べてみると、 `renderButton` は google_sign_in_web パッケージの `GoogleSignInPlugin` から呼び出せることがわかりました。

## 実装
ここから問題解決のための実装に移ります。
先に改善後のコードを以下に提示します。
State
```dart: signup/state.dart
part 'state.freezed.dart';

@freezed
abstract class SignUpScreenState with _$SignUpScreenState {
  const factory SignUpScreenState({
    required GoogleSignInPlugin plugin,  // plugin のみを保持
  }) =  _SignUpScreenState;
}
```

ViewModel
```dart: signup/view_model.dart
part 'view_model.g.dart';

@riverpod
class SignUpViewModel extends _$SignUpViewModel {
  UserAuthRepo get userAuthRepo => ref.read(userAuthRepoProvider.notifier);
  late GoogleSignInPlugin plugin;  // GoogleSignInPlugin を遅延初期化

  @override
  FutureOr<SignUpScreenState> build() async {
    final plugin = await initGoogleSignInPlugin();
    return SignUpScreenState(plugin: plugin);  // plugin を含んだ State を返却
  }

  Future<GoogleSignInPlugin> initGoogleSignInPlugin() async {
    plugin = GoogleSignInPlugin();  // GoogleSignInPlugin のインスタンス化
    await plugin.init();
    await listenToUserDataEvents();
    return plugin;
  }

  // ユーザー情報の更新を監視
  Future<void> listenToUserDataEvents() async {
    plugin.userDataEvents?.listen((userData) async {  // ユーザー情報に変化があるかどうかを listen で監視
      if (userData == null) {  // データがない場合は何もしない
        return;
      }
      if (userData.idToken != null) {
        final signInTokenData = await plugin.getTokens(email: userData.email);

　　　　　　　　　　　　　　　　// FirebaseAuth サインイン
        await ref
            .read(firebaseAuthProvider)
            .signInWithCredential(
              GoogleAuthProvider.credential(
                idToken: userData.idToken,
                accessToken: signInTokenData.accessToken,
              ),
            )
            .then((value) {
          ref.invalidate(myAppViewModelProvider);
        });
      }
    });
  }
}
```

View
```dart: signup/view.dart
class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google サインイン'),
      ),
      body: state.when(
        error: (err, stack) => Center(
          child: Text(err.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        data: (data) => Center(
          child: data.plugin.renderButton(),
        ),
      ),
    );
  }
}
```

UI
![](https://storage.googleapis.com/zenn-user-upload/81b4e4dd803d-20240323.png)

コードに関して詳しくみていきます。

まずは State に関してです。
以下のコメントにもある通り、SignupScreen の State として、GoogleSignInPlugin の状態を保持する `plugin` のみを実装しました。
```dart: signup/state.dart
part 'state.freezed.dart';

@freezed
abstract class SignUpScreenState with _$SignUpScreenState {
  const factory SignUpScreenState({
    required GoogleSignInPlugin plugin,  // plugin のみを保持
  }) =  _SignUpScreenState;
}
```

次に ViewModel に関してです。
以下では、`late` で GoogleSignInPlugin を遅延初期化しています。
このあと build メソッドで初期化を行います。
```dart: signup/view_model.dart
late GoogleSignInPlugin plugin;  // GoogleSignInPlugin を遅延初期化
```

以下では build メソッドで、後述の `initGoogleSignInPlugin` の返り値を先程 `late` で定義した `plugin` に代入しています。
また、 build メソッドの返り値としては `plugin` を受け取った SignUpScreenState としています。
これで、View の方で read, watch された際に plugin を含む State を返却することができます。
```dart: signup/view_model.dart
@override
FutureOr<SignUpScreenState> build() async {
  final plugin = await initGoogleSignInPlugin();
  return SignUpScreenState(plugin: plugin);  // plugin を含んだ State を返却
}
```

以下では build メソッドで実行する `initGoogleSignInPlugin` を実装しています。
GoogleSignInPlugin をインスタンス化し、そのインスタンスに `.init()` を実行しています。
また、後述の `listenToUserDataEvents` を実行して、最終的には `plugin` を返却しています。
この処理をせずに GoogleSignInPlugin をしようとした場合は
```dart: signup/view_model.dart
Future<GoogleSignInPlugin> initGoogleSignInPlugin() async {
  plugin = GoogleSignInPlugin();  // GoogleSignInPlugin のインスタンス化
  await plugin.init();
  await listenToUserDataEvents();
  return plugin;
}
```

:::　details plugin.init() がない場合
GoogleSignInPlugin をインスタンス化した `plugin` に対して、 `.init()` 処理を行わずに使用しようとすると、以下のように、使用する前に初期化するように怒られます。
```
Bad state: GoogleSignInPlugin::init() or GoogleSignInPlugin::initWithParams() must
be called before any other method in this plugin.
```
:::

次に、以下のコードでは plugin のユーザー情報に更新があった際の処理を記述しています。
ユーザー情報に変化があり、かつ `idToken` がある場合は、以下の手順で処理を行なっています。
1. ユーザーデータの `email` から `GoogleSignInTokenData` を取得
2. `signInWithCredential` メソッドに取得した idToken, accessToken を渡してサインイン
3. FirebaseAuth の currentUser を保持している `myAppViewModelProvider` をinvalidate してリフレッシュ
```dart: signup/view_model.dart
// ユーザー情報の更新を監視
Future<void> listenToUserDataEvents() async {
  plugin.userDataEvents?.listen((userData) async {
    // ユーザー情報が取得できない場合は何もしない
    if (userData == null) {
      return;
    }
    if (userData.idToken != null) {
      final signInTokenData = await plugin.getTokens(email: userData.email);  // 1
      //  Firebase にログイン
      await ref
        .read(firebaseAuthProvider)
        .signInWithCredential(  // 2
          GoogleAuthProvider.credential(
            idToken: userData.idToken,
            accessToken: signInTokenData.accessToken,
          ),
        )
        .then((value) {
          ref.invalidate(myAppViewModelProvider);  // 3
        });
    }
  });
}
```

3番の処理に関して、今のプロジェクトでは、currentUser の状態をリフレッシュすることで、ユーザーのログイン状態もリフレッシュされ、ユーザーがログインしている場合にはホーム画面へ遷移するようになっているため、これでログイン後にホームへ進むことができます。
この辺りの実装は各プロジェクトで異なるかと思います。

最後にViewについてです。
`state` として、 `plugin` を含む `SignUpScreenState` を受けてとっています。
`plugin`　の初期化などを非同期で行う必要がある関係で、 `state` は Future型で返ってきます。したがって、 `state.when` で状態に合わせて表示させる Widget を変更しています。

`data.plugin.renderButton()` では、ドキュメントにあった `renderButton` を表示させており、Google のサインインボタンに関するデザインに沿ったものになっています。
```dart: signup/view.dart
class SignUpScreen extends ConsumerWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signUpViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google サインイン'),
      ),
      body: state.when(
        error: (err, stack) => Center(
          child: Text(err.toString()),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        data: (data) => Center(
          child: data.plugin.renderButton(),
        ),
      ),
    );
  }
}
```

::: details renderButton のスタイリング
`renderButton` は多少スタイルの変更を行うことも可能です。
実装を少しみてみると GSIButtonConfiguration型の `configuration` を渡せるようです。
```dart
Widget renderButton({GSIButtonConfiguration? configuration})
```

GSIButtonConfiguration　をみてみると以下のようになっています。
テーマや大きさ、テキスト、形などを調節できるようです。
```dart
(new) GSIButtonConfiguration GSIButtonConfiguration({
  GSIButtonType? type,
  GSIButtonTheme? theme,
  GSIButtonSize? size,
  GSIButtonText? text,
  GSIButtonShape? shape,
  GSIButtonLogoAlignment? logoAlignment,
  double? minimumWidth,
  String? locale,
})
```

type: GSIButtonType.icon,　（アイコンだけになる）
![](https://storage.googleapis.com/zenn-user-upload/aca6553c4431-20240323.png =400x)

theme: GSIButtonTheme.filledBlack,　（背景が黒になる）
![](https://storage.googleapis.com/zenn-user-upload/3869b7c6ec7b-20240323.png =400x)

size: GSIButtonSize.large, (ちょっと大きくなる... これだとわからない)
![](https://storage.googleapis.com/zenn-user-upload/0a05ffdf9814-20240323.png =400x)

text: GSIButtonText.signupWith, （文言を多少変更できる）
![](https://storage.googleapis.com/zenn-user-upload/e18b01d6ec69-20240323.png =400x)

shape: GSIButtonShape.pill, （丸角にできる）
![](https://storage.googleapis.com/zenn-user-upload/05abd5717eca-20240323.png =400x)

locale: 'en', （言語を変更できる）
![](https://storage.googleapis.com/zenn-user-upload/fc5e9187a9d5-20240323.png =400x)


変更できるプロパティが基本的には enum のみの指定で、[「Google でログイン」のブランドの取り扱いガイドライン](https://developers.google.com/identity/branding-guidelines?hl=ja)に指定されているような変更以外はできないようになっています。
:::

## まとめ
最後まで読んでいただいてありがとうございました。

今回は公式ドキュメントに対処法が書いてあったものの、具体的なサンプル等があまり多くなかったため、苦労しました。サインインの方法は今回の方法だけではないと思うので、実装の一例としてみていただけると幸いです。
誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/google_sign_in_web#migrating-to-v011-and-v012-google-identity-services

https://developers.google.com/identity/gsi/web/guides/migration?hl=ja#authentication_and_authorization

https://developers.google.com/identity/oauth2/web/guides/migration-to-gis?hl=ja

https://developers.google.com/identity/oauth2/web/guides/how-user-authz-works?hl=ja


