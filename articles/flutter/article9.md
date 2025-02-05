## 初めに
今回は Flutter で Cloud Functions を使った実装を行いたいと思います。
最終的には、 Cloud Firestore や Firebase Auth との連携も行います。

## 記事の対象者
+ Flutter 学習者
+ Cloud Functions を触ってみたい方

## 目的
今回は上記の通り Flutter で Cloud Functions に触れることを目的とします。
シンプルな実装から Firestore, Firebase Auth との連携まで行います。
最終的には簡単なメモアプリを作成できるまで実装していきます。

## Cloud Functions について
### 概要
[Cloud Functions の概要](https://cloud.google.com/functions/docs/concepts/overview?hl=ja)には以下のような記述があります。
> Google Cloud Functions は、クラウドサービスの構築と接続に使用するサーバーレスのランタイム環境です。Cloud Functions を使用すると、クラウドのインフラストラクチャやサービスで生じたイベントに関連付けられた、単一目的の関数を作成できます。対象のイベントが発生すると、Cloud Functions がトリガーされ、コードがフルマネージドの環境で実行されます。インフラストラクチャをプロビジョニングする必要はなく、サーバーの管理に悩まされることもありません。
>
> Cloud Functions の関数は、さまざまなサポート対象のプログラミング言語を使用して作成できます。サポートされているいずれかの標準的なランタイム環境で関数を実行すると、環境に依存することなく簡単にローカルテストを実施できます。

まとめると以下のようなサービスと言えます。
- クラウドサービスに使用するサーバーレスのランタイム環境
- イベントに関連づけられた関数の作成が可能
- サーバーの管理が必要ない

[Cloud Functions for Firebase](https://firebase.google.com/docs/functions/?hl=ja) や [Cloud Functions と Firebase](https://firebase.google.com/docs/functions/functions-and-firebase?hl=ja) には以下のような記述があります。
> Cloud Functions for Firebase はサーバーレス フレームワークで、Firebase の機能と HTTPS リクエストによってトリガーされたイベントに応じて、バックエンドコードを自動的に実行できます。
JavaScript または TypeScript コードは Google のクラウドに保存され、マネージド環境で実行されます。独自のサーバーを管理およびスケーリングする必要はありません。

> モバイルアプリまたはモバイル ウェブアプリを構築するデベロッパーは、Cloud Functions for Firebase を使ったほうが便利です。モバイル デベロッパーは、Firebase を使用して、アナリティクス、認証、Realtime Database といった、モバイル中心のフルマネージド サービスすべてにアクセスできます。Cloud Functions は、サーバー側コードの追加により Firebase 機能の動作を拡張させて接続する方法を提供することで、サービスを向上させます。
>
> Firebase デベロッパーは、支払いの処理や SMS メッセージの送信などのタスクについて、外部サービスと簡単に統合できます。また、処理が重すぎてモバイル デバイスには含められないカスタム ロジックや、サーバー上に置いてセキュリティを確保する必要があるカスタム ロジックでも含めることができます。一般的な統合の事例については、Cloud Functions で可能な処理を参照してください。 フル機能のバックエンドを必要とする場合は、Google Cloud Platform の強力な機能へのゲートウェイとして Cloud Functions を利用できます。

今回使用するのは Cloud Functions for Firebase であり、非常にざっくりまとめると以下のようなことが言えます。
- Firebaseの機能などを利用でき、バックエンドのコードを自動的に実行できる
- モバイルアプリを構築する際は Cloud Functions for Firebase を使った方が良い
- 処理が重すぎるロジックなどをサーバー側においてセキュリティを確保できる

### 第1世代、第2世代の違い
Cloud Functions を使用する前に確認しておきたい点が一点あります。それが「第1世代と第2世代の違い」についてです。
以下の三つのドキュメントをもとにまとめると下のようなことが言えるかと思います。
- [Cloud Functions と Cloud Run: それぞれの使いどころ](https://cloud.google.com/blog/ja/products/serverless/cloud-run-vs-cloud-functions-for-serverless)
- [Cloud Functions バージョンの比較](https://firebase.google.com/docs/functions/version-comparison?hl=ja)
- [Cloud Functions is now Cloud Run functions](https://cloud.google.com/blog/products/serverless/google-cloud-functions-is-now-cloud-run-functions?hl=en)

#### まとめ
- Cloud Functions には、Cloud Functions（第1世代）と Cloud Functions（第2世代）という**2種類のプロダクトバージョン**がある
- 第2世代は、**Cloud Run と Eventarc をベース**にした新しいバージョンで、機能が強化されている
- 第1世代の関数と第2世代の関数は同じソースファイルで**共存可能**
- 第1世代の関数は引き続き利用可能

#### この記事の方針
この記事では初めの方の章では第1世代、第2世代両方の Functions の実装を行い、メインでは第2世代の Functions を使用したいと思います。
その根拠としては、[Cloud Functions バージョンの比較](https://firebase.google.com/docs/functions/version-comparison?hl=ja)のページに以下のような記述があるためです。
> 可能な限り、新しい関数には Cloud Functions（第2世代）を選択することをおすすめします。


#### その他参考
- [比較表](https://cloud.google.com/functions/docs/concepts/version-comparison?hl=ja#comparison-table)
- [Cloud Functions（第2世代）の新機能](https://cloud.google.com/functions/docs/concepts/version-comparison?hl=ja#new-in-2nd-gen)

## 準備
今回は新たにFlutterプロジェクトを作成してから実装を進めていきます。
準備は以下の手順で進めていきます。
1. Flutterプロジェクトの作成
2. Firebaseプロジェクトの作成
3. Functions の設定
4. Firestore, FirebaseAuth の設定

### 1. Flutterプロジェクトの作成、設定
まずは Flutter のプロジェクトを作成していきます。
VSCodeで上部のバーに `> Flutter: New Project` を入力します。
その後以下の手順で新たに Flutterプロジェクトが作成できるかと思います。
`Application` > プロジェクトの作成場所の設定 > プロジェクト名の設定

筆者は「functions_sample」という名前のプロジェクトを作成しました。
これで Flutterプロジェクトの作成は完了です。

次に Flutter プロジェクトに必要な設定を行います。
今回使用する以下のパッケージの最新バージョンを `pubspec.yaml` に追加していきます。
dependences
+ [firebase_core](https://pub.dev/packages/firebase_core)
+ [cloud_functions](https://pub.dev/packages/cloud_functions)
+ [firebase_auth](https://pub.dev/packages/firebase_auth)
+ [cloud_firestore](https://pub.dev/packages/cloud_firestore)
+ [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
+ [riverpod_annotation](https://pub.dev/packages/riverpod_annotation)
+ [hooks_riverpod](https://pub.dev/packages/hooks_riverpod)
+ [flutter_hooks](https://pub.dev/packages/flutter_hooks)
+ [freezed_annotation](https://pub.dev/packages/freezed_annotation)
+ [intl](https://pub.dev/packages/intl)
+ [gap](https://pub.dev/packages/gap)

dev_dependencies
+ [build_runner](https://pub.dev/packages/build_runner)
+ [riverpod_generator](https://pub.dev/packages/riverpod_generator)
+ [freezed](https://pub.dev/packages/freezed)
+ [json_serializable](https://pub.dev/packages/json_serializable)

`pubspec.yaml` は以下のようになっています。
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  # firebase
  firebase_core: ^3.3.0
  cloud_functions: ^5.0.4
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1

  # riverpod
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.5.2

  flutter_hooks: ^0.20.5
  freezed_annotation: ^2.4.4
  intl: ^0.19.0
  gap: ^3.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
```

これで Flutter の設定は完了です。

### 2. Firebaseプロジェクトの作成、設定
次に Firebase プロジェクトの作成を行います。
[Firebaseの公式サイト](https://firebase.google.com/?hl=ja)の「Go to console」を選択して「プロジェクトを作成」を選択します。

プロジェクト名を設定して、 Flutter のアイコンを選択すると以下のような画面になると思うので指示に従って先程作成した Flutter プロジェクトのディレクトリでコマンドを実行していきます。
![](https://storage.googleapis.com/zenn-user-upload/64669655448d-20240827.png)

これで Firebase プロジェクトの作成は完了です。

今回は Android のエミュレータを用いて実装を行うので、 Android 側の設定を済ませておきます。
プロジェクトの設定 > マイアプリ > Android アプリ > google_services.json からJSONファイルをダウンロードします。
そしてダウンロードしたファイルを作成した Flutter アプリのディレクトリの以下に配置します。（既にある場合は置き換えます）
android > app > google_services.json

これで Android 向けの Firebase の設定は完了です。

### 3. Functions の設定
次に Functions の設定を行なっていきます。
Firebase のコンソールから Functions のセクションをタップして利用を開始します。
なお、 Functions を使用するためには Firebase のプランを Spark プランから Blazeプランに引き上げる必要があります。

請求先のアカウントを設定して、プランの引き上げを行います。プランは従量課金制であるため課金したくない場合は予算を0円にしておくことで警告がメールで送られるようになります。

これでコンソールでの設定は完了です。

次に作成した Flutter プロジェクトのディレクトリで以下のコマンドを実行します。
```
firebase init functions
```

その後いくつか質問されるので答えていきます。

新規でプロジェクトを作成するか、すでに作成されているプロジェクトを使用するかを聞かれるので、 `Use an existing project` を選択して、先程作成した Firebase のプロジェクトを選択します。

次に Cloud Functions の処理を書く際にどの言語を使用するか聞かれるので、今回は `TypeScript` としておきます。

次に ESLint を使用するか聞かれるので、 `No` としておきます。
デフォルトだと Yes になっているので、これはどちらでも良いかもしれません。

次に必要な依存関係をインストールするか聞かれるので、 `Yes` としておきます。

これで `Firebase initialization complete!` と表示されていれば必要な設定は完了です。

### 4. Firestore, FirebaseAuth の設定
次に Firestore, FirebaseAuth の設定を行います。
以下のような設定をしておきます。
- Firestore
  モード：テストモード
  ロケーション： asia-northeast1

- FirebaseAuth
  ログイン方法：匿名

これで Firestore, FirebaseAuth の設定は完了です。

## 実装
次に実装に入っていきます。
実装は大きく分けて以下の手順で進めていきます。
1. Hello World の呼び出し
2. メモアプリの作成

### 1. Hello World の呼び出し
ここでは簡単な処理を Functions で実装して、 Flutter 側から呼び出すまでを行いたいと思います。
以下の手順で進めていきます。
1. Functions のコード編集
2. Functions の権限設定
3. Flutter側のコード編集

#### 1. Functions のコード編集
[第1世代、第2世代の違い - まとめ](#%E3%81%BE%E3%81%A8%E3%82%81) の章で紹介した通り、現在 Cloud Functions には第1世代と第2世代のバージョンがあります。この章ではその両方の実装を行い書き方の違いなどをみていきます。

Functions の処理の変更は ルートディレクトリ > functions > src > index.ts で行います。
コードは以下の通りです。
```ts: index.ts
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
const functions = require("firebase-functions");

// onCall
exports.helloWorldOnCallV1 = functions.https.onCall(() => {
  try {
    return { result: "Hello World (V1) !" };
  } catch (error) {
    console.error("Error in helloWorldOnCallV1:", error);
    throw functions.https.HttpsError(
      "internal",
      "An unexpected error occurred"
    );
  }
});

export const helloWorldOnCallV2 = onCall({}, (_) => {
  try {
    return { result: "Hello World (V2 onCall) !" };
  } catch (error) {
    console.error("Error in helloWorldOnCallV2:", error);
    throw new HttpsError("internal",
      "An unexpected error occurred");
  }
});

// onRequest
exports.helloWorldOnRequestV1 = functions.https.onRequest(
  (req: any, res: any) => {
    try {
      res.status(200).json({ result: "Hello world (V1 onRequest) !" });
    } catch (error) {
      console.error("Error in helloWorldOnRequestV1:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);

export const helloWorldOnRequestV2 = onRequest({}, (req, res) => {
  try {
    res.status(200).json({ result: "Hello world (V2 onRequest) !" });
  } catch (error) {
    console.error("Error in helloWorldOnRequestV2:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});
```

上記のコードでは onCall と onRequest の2種類の処理があります。
[Choosing Between onRequest and onCall in Firebase Functions: Deciding the Right Communication Method for Your Application](https://medium.com/@InspireTech/choosing-between-onrequest-and-oncall-in-firebase-functions-deciding-the-right-communication-22e908e0b89f) の記事を日本語訳して引用させていただくと以下のような特徴があります。


**onRequest**
- HTTP リクエストを直接処理したい場合に使用します。標準的な HTTP メソッド（GET、POST、PUT、DELETE）を使用して関数と対話する必要がある場合や、複雑なリクエスト/レスポンス構造を扱う必要がある場合に適しています
- onRequest では、HTTP リクエストとレスポンスオブジェクトを完全に制御でき、ヘッダー、クエリパラメータ、リクエストボディなどを処理するためのカスタムロジックを定義できます

**onCall**
- Firebase SDK の call() メソッドや、異なるプラットフォーム（iOS、Android、Web）用の Firebase クライアントライブラリなど、呼び出し可能なクライアントメソッドを介して関数を呼び出したい場合に使用します
- onCall 関数は、クライアントからサーバーサイドの機能を呼び出すための簡素化された便利な方法を提供します。関数の呼び出しは、クライアント側での通常の関数呼び出しに似ています

以上を踏まえた上でそれぞれ詳しくみていきます。

以下では第1世代の Funcions で `onCall` を用いた処理を記述しています。
第1世代の書き方では、 `functions.https.onCall` となっており、この `functions` は `const functions = require("firebase-functions");` のように定義しています。
この部分の書き方に応じて第1、第2世代を区別しています。

また、`onCall` の引数には関数を渡して、JSON形式の `result` として「Hello World (V1) !」という文字列を返却するようにしています。

エラーハンドリングとしては `HttpsError` でエラー文言を返すようにしています。

```ts
const functions = require("firebase-functions");

exports.helloWorldOnCallV1 = functions.https.onCall(() => {
  try {
    return { result: "Hello World (V1) !" };
  } catch (error) {
    console.error("Error in helloWorldOnCallV1:", error);
    throw functions.https.HttpsError(
      "internal",
      "An unexpected error occurred"
    );
  }
});
```

以下では第2世代の Funcions で `onCall` を用いた処理を記述しています。
第2世代の書き方では、 `onCall({}, (_) => {})` となっており、この `onCall` は以下のコードからもわかる通り、 `firebase-functions/v2` からインポートされています。

今回は指定していませんが、第一引数にはCORSを使用するかどうかなどの指定を入れることができます。
第二引数には関数を渡して、JSON形式の `result` として「Hello World (V2 onCall) !」という文字列を返却するようにしています。

エラーハンドリングとしては `HttpsError` でエラー文言を返すようにしています。
```ts
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";

export const helloWorldOnCallV2 = onCall({}, (_) => {
  try {
    return { result: "Hello World (V2 onCall) !" };
  } catch (error) {
    console.error("Error in helloWorldOnCallV2:", error);
    throw new HttpsError("internal",
      "An unexpected error occurred");
  }
});
```

以下では第1世代の Funcions で `onRequest` を用いた処理を記述しています。
第1世代の書き方では、 `functions.https.onRequest` となっており、この `functions` は `onCall` の場合と同様に `require("firebase-functions")` で定義したものを使用しています。

また、 `onRequest` では `req` と `res` を受け取り、レスポンスの `res` に対してステータスコード 200 の場合にはJSON形式の `result` として「Hello world (V1 onRequest) !」という文字列を返却するようにしています。
ステータスコード 500 の場合には Internal server error としてエラーを返しています。

```ts
const functions = require("firebase-functions");

exports.helloWorldOnRequestV1 = functions.https.onRequest(
  (req: any, res: any) => {
    try {
      res.status(200).json({ result: "Hello world (V1 onRequest) !" });
    } catch (error) {
      console.error("Error in helloWorldOnRequestV1:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);
```

以下では第2世代の Funcions で `onRequest` を用いた処理を記述しています。
第2世代の書き方では、 `onRequest({}, (req, res) => {})` となっており、この `onCall` は以下のコードからもわかる通り、 `firebase-functions/v2` からインポートされています。

`onCall` の場合と同様に、第一引数にはCORSを使用するかどうかなどの指定を入れることができます。また、第二引数では `req` と `res` を受け取り、レスポンスの `res` に対してステータスコード 200 の場合にはJSON形式の `result` として「Hello world (V2 onRequest) !」という文字列を返却するようにしています。
ステータスコード 500 の場合には Internal server error としてエラーを返しています。

```ts
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";

export const helloWorldOnRequestV2 = onRequest({}, (req, res) => {
  try {
    res.status(200).json({ result: "Hello world (V2 onRequest) !" });
  } catch (error) {
    console.error("Error in helloWorldOnRequestV2:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});
```

これで Functions 側の実装は完了です。
最後に実装した関数をデプロイする必要があります。
ターミナルで以下のコマンドを実行することで関数のデプロイが完了します。
```
firebase deploy --only functions
```

デプロイしようとしている関数に問題がある場合は以下のようなエラーメッセージが出力されるかと思います。その際はエラー文に従って関数を編集して再度デプロイします。
```
Error: Functions codebase could not be analyzed successfully. It may have a syntax or runtime error
```

以下のような文が表示されれば関数のデプロイは完了です。
```
✔  Deploy complete!
```

なお、実装した関数の数が多くなってきた場合は以下のようなコマンドにすることで更新する関数を絞ることができます。
```
firebase deploy --only functions:{関数名}
```

デプロイする際のコマンドは以下にまとまっていると思うので、詳しくはこちらをご覧ください
[関数を管理する](https://firebase.google.com/docs/functions/manage-functions?hl=ja&gen=2nd)

#### 2. Functions の権限設定
次に作成した関数を含む Functions の権限設定に移ります。
筆者はここで少し時間を取ってしまったので、詳しくみていきます。

まずは、 Firebase のプロジェクトから Functions のタブを開きます。
これから実装する関数や今回扱わない関数なども含まれているため関数の数が多いかと思いますが、以下の画像のような画面になるかと思います。
![](https://storage.googleapis.com/zenn-user-upload/2185136bea4f-20240828.png)

次に実装した関数の右端のメニューを開き、「使用状況の詳細な統計情報」を開きます。
すると以下では「helloWorldOnCallV2」関数を開いており、このような画面になるかと思います。
![](https://storage.googleapis.com/zenn-user-upload/b14337683bd6-20240828.png)

上記の画面で画面右側の「Cloud Runで表示」をタップすると以下のような画面になります。
![](https://storage.googleapis.com/zenn-user-upload/88ccc1453b79-20240828.png)

上記の画面で画面左上の「Cloud Run」の部分をタップすると以下のような画面になり、第2世代でデプロイした関数の一覧が確認できます。
![](https://storage.googleapis.com/zenn-user-upload/87cf3f38c83f-20240828.png)

次に以下のように関数を選択して、「権限」をタップします。
![](https://storage.googleapis.com/zenn-user-upload/28e41cfc25f6-20240828.png)

「権限」をタップすると以下のような画面になるかと思います。
ここで「プリンシパルを追加」をタップします。
![](https://storage.googleapis.com/zenn-user-upload/b5129e98349e-20240828.png)

ここで以下の画像のように、「新しいプリンシパル」に「allUsers」、「ロール」に「Cloud Run 起動元」を設定して保存します。
![](https://storage.googleapis.com/zenn-user-upload/768d761c555f-20240828.png)

この時、関数を一般に公開することを表すダイアログが表示されますが、許可して保存します。

なお、実際のプロダクトで使用する場合はプリンシパルに「allAuthenticatedUsers」とすることで FirebaseAuth に登録されているユーザーのみに対象を絞るなどの対処が必要になります。
今回はサンプルとして作成するので、「allUsers」としておきます。

この設定を行わずに第2世代の関数を実行しようとすると以下のようなエラーが出ることがあります。
```
Unhandled Exception: [firebase_functions/permission-denied] PERMISSION_DENIED
```

このような設定が必要であることは [呼び出しを認証する](https://cloud.google.com/functions/docs/securing/authenticating?hl=ja) のドキュメントに書かれており、第1世代の場合は「Cloud Functions 起動元」、第2世代の場合は「Cloud Run 起動元」の権限を付与する必要があります。これもそれぞれの世代でもとになっているサービスが変わったことが原因となっています。

これで Functions の権限設定は完了です。
これから作成する Functions に関しても権限設定に問題がないかみておく必要があります。

#### 3. Flutter側のコード編集
次に Flutter 側のコードを編集していきます。
コードは以下の通りです。
```dart: first_sample.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:gap/gap.dart';

class FirstSample extends HookConsumerWidget {
  const FirstSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helloWorldOnCallV1Result = useState('');
    final helloWorldOnCallV2Result = useState('');
    final helloWorldOnRequestV1Result = useState('');
    final helloWorldOnRequestV2Result = useState('');
    final functions = FirebaseFunctions.instance;

    Future<void> callHelloWorldOnCallV1() async {
      try {
        final HttpsCallable callable =
            functions.httpsCallable('helloWorldOnCallV1');
        final HttpsCallableResult result = await callable.call();

        final data = result.data;
        helloWorldOnCallV1Result.value = data['result'];

        debugPrint('結果: ${data['result']}');
      } catch (e) {
        debugPrint('エラー: $e');
      }
    }

    Future<void> callHelloWorldOnCallV2() async {
      try {
        final HttpsCallable callable =
            functions.httpsCallable('helloWorldOnCallV2');
        final HttpsCallableResult result = await callable.call();

        final data = result.data;
        helloWorldOnCallV2Result.value = data['result'];

        debugPrint('結果: ${data['result']}');
      } catch (e) {
        debugPrint('エラー: $e');
      }
    }

    Future<void> callHelloWorldOnRequestV1() async {
      try {
        final HttpsCallable callable =
            functions.httpsCallable('helloWorldOnRequestV1');
        final result = await callable.call();

        debugPrint('Raw result data: ${result.data}');

        if (result.data is Map<String, dynamic>) {
          helloWorldOnRequestV1Result.value = result.data['result'] as String;
          debugPrint('結果: ${helloWorldOnRequestV1Result.value}');
        } else if (result.data is String) {
          helloWorldOnRequestV1Result.value = result.data as String;
          debugPrint('結果 (直接文字列): ${helloWorldOnRequestV1Result.value}');
        } else {
          throw Exception(
              'Unexpected response format: ${result.data.runtimeType}');
        }
      } catch (e) {
        debugPrint('エラー: $e');
        helloWorldOnRequestV1Result.value = 'エラーが発生しました: $e';
      }
    }

    Future<void> callHelloWorldOnRequestV2() async {
      try {
        final HttpsCallable callable =
            functions.httpsCallable('helloWorldOnRequestV2');
        final result = await callable.call();

        debugPrint('Raw result data: ${result.data}');

        if (result.data is Map<String, dynamic>) {
          helloWorldOnRequestV2Result.value = result.data['result'] as String;
          debugPrint('結果: ${helloWorldOnRequestV2Result.value}');
        } else if (result.data is String) {
          helloWorldOnRequestV2Result.value = result.data as String;
          debugPrint('結果 (直接文字列): ${helloWorldOnRequestV2Result.value}');
        } else {
          throw Exception(
              'Unexpected response format: ${result.data.runtimeType}');
        }
      } catch (e) {
        debugPrint('エラー: $e');
        helloWorldOnRequestV2Result.value = 'エラーが発生しました: $e';
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('First Sample'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: callHelloWorldOnCallV1,
              child: const Text(
                'Hello World OnCall V1',
              ),
            ),
            const Gap(8),
            Text(helloWorldOnCallV1Result.value),
            const Gap(32),
            ElevatedButton(
              onPressed: callHelloWorldOnCallV2,
              child: const Text(
                'Hello World OnCall V2',
              ),
            ),
            const Gap(8),
            Text(helloWorldOnCallV2Result.value),
            const Gap(32),
            ElevatedButton(
              onPressed: callHelloWorldOnRequestV1,
              child: const Text(
                'Hello World OnRequest V1',
              ),
            ),
            const Gap(8),
            Text(helloWorldOnRequestV1Result.value),
            const Gap(32),
            ElevatedButton(
              onPressed: callHelloWorldOnRequestV2,
              child: const Text(
                'Hello World OnRequest V2',
              ),
            ),
            const Gap(8),
            Text(helloWorldOnRequestV2Result.value),
          ],
        ),
      ),
    );
  }
}
```

それぞれ詳しくみていきます。

以下ではそれぞれ Functions から返ってきた値を格納するための変数を `useState` で定義しています。
```dart
final helloWorldOnCallV1Result = useState('');
final helloWorldOnCallV2Result = useState('');
final helloWorldOnRequestV1Result = useState('');
final helloWorldOnRequestV2Result = useState('');
```

以下では第1世代の `onCall` である `helloWorldOnCallV1` を実行しています。
Flutter 側でパッケージとして追加している `FirebaseFunctions` には `httpsCallable` メソッドが用意されており、引数として Functions 側で設定した関数名を渡して `call()` を呼ぶことで関数を実行することができます。

今回はJSON形式で `result` というキーに対して文字列を渡す形で実装しているので、 `helloWorldOnCallV1Result.value` に対して `data['result']` を代入しています。
```dart
Future<void> callHelloWorldOnCallV1() async {
  try {
    final HttpsCallable callable =
        functions.httpsCallable('helloWorldOnCallV1');
    final HttpsCallableResult result = await callable.call();

    final data = result.data;
    helloWorldOnCallV1Result.value = data['result'];

    debugPrint('結果: ${data['result']}');
  } catch (e) {
    debugPrint('エラー: $e');
  }
}
```

Flutter 側での実装は第1世代と第2世代の関数で特に違いがないため、第2世代の onCall の解説は割愛します。

次に以下では第1世代の `onRequest` である `helloWorldOnRequestV1` を実行しています。
関数の呼び方は `onCall` の場合と同様に `httpsCallable` メソッドを用いて呼び出すことができます。
先程の Functions の実装では `result.data` にそのまま文字列が入る実装になっていたので以下のようになっています。この辺りの実装はまだ改善の余地があるかと思います。

```dart
Future<void> callHelloWorldOnRequestV1() async {
  try {
    final HttpsCallable callable =
        functions.httpsCallable('helloWorldOnRequestV1');
    final result = await callable.call();

    debugPrint('Raw result data: ${result.data}');

    if (result.data is Map<String, dynamic>) {
      helloWorldOnRequestV1Result.value = result.data['result'] as String;
      debugPrint('結果: ${helloWorldOnRequestV1Result.value}');
    } else if (result.data is String) {
      helloWorldOnRequestV1Result.value = result.data as String;
      debugPrint('結果 (直接文字列): ${helloWorldOnRequestV1Result.value}');
    } else {
      throw Exception(
          'Unexpected response format: ${result.data.runtimeType}');
    }
  } catch (e) {
    debugPrint('エラー: $e');
    helloWorldOnRequestV1Result.value = 'エラーが発生しました: $e';
  }
}
```

Flutter 側での実装は第1世代と第2世代の関数で特に違いがないため、第2世代の onRequest の解説は割愛します。

次に以下では、ボタンを押した際の処理として先ほど定義した `callHelloWorldOnCallV1` を実行しており、その結果をテキストとして表示しています。
このコード以下の他の場合においても同様にボタンを押した際に Functions の関数を実行し、返ってきた値を表示させています。
```dart
ElevatedButton(
  onPressed: callHelloWorldOnCallV1,
  child: const Text(
    'Hello World OnCall V1',
  ),
),
const Gap(8),
Text(helloWorldOnCallV1Result.value),
```

以上のコードで実行すると以下の動画のようにボタンを押した後に正常に値が返ってきて表示されることが確認できます。

https://youtube.com/shorts/YeJBuIKNApQ?feature=share

### 2. メモアプリの作成
次にメモアプリをサンプルとして作成したいと思います。
メモアプリの作成は以下の手順で進めていきます。
1. Functions のコード編集
2. Functions の権限設定
3. Flutter側のコード編集
4. Firestore での実装

#### 1. Functions のコード編集
まずは Functions 側のコードを編集していきます。
先ほどは ルートディレクトリ > functions > src > index.ts のファイルを直接編集しましたが、今度はわかりやすいように別のディレクトリで作業していきます。

ルートディレクトリ > functions > src のディレクトリに `notes` というディレクトリを作っておきます。ここにメモ（Note）のCRUD処理を記述していきます。なお、今回は Functions のうち第2世代の `onCall` を用いて実装していきます。

まずは notes ディレクトリに以下の四つのファイルを作成しておきます。
- addNote.ts
- getNotes.ts
- updateNote.ts
- deleteNote.ts

それぞれのファイルを追加して内容を追加していきます。

まずは `addNote.ts` です。
コードは以下の通りです。
```ts: addNote.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

const db = getFirestore();

export const addNote = onCall(async (request) => {
  const { title, content } = request.data;
  if (!title || !content) {
    throw new HttpsError("invalid-argument", "Title and content are required");
  }

  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = request.auth.uid;

  try {
    const userNotesCollectionRef = db.collection("userNotes").doc(userId).collection("notes");
    const now = Timestamp.now();

    const newNote = {
      title,
      content,
      createdAt: now,
      updatedAt: now
    };

    const docRef = await userNotesCollectionRef.add(newNote);

    return {
      success: true,
      noteId: docRef.id
    };
  } catch (error) {
    console.error("Failed to add note:", error);
    throw new HttpsError("internal", "Failed to add note");
  }
});
```

重要な部分を抜粋して見ていきます。

以下では `getFirestore()` を `db` という変数に割り当てています。
これで Functions から `db` を通して Firestore のデータベースにアクセスできるようになります。
```ts
const db = getFirestore();
```

以下では、 `request` から `title`, `content` を抜き出して、どちらかが存在しない場合はエラーを返すようにしています。 `onCall` の場合は関数の引数に指定した `request` からリクエストに対して付与されたデータにアクセスできます。
```ts
const { title, content } = request.data;
if (!title || !content) {
  throw new HttpsError("invalid-argument", "Title and content are required");
}
```

以下では `request.auth` が null の場合はエラーを返すようにしています。
これで FirebaseAuth で登録されていないユーザーからのリクエストにはエラーを返します。
また、`request.auth` が null 出ない場合はそのUIDを `userId` として保持しています。
```ts
if (!request.auth) {
  throw new HttpsError("unauthenticated", "User must be authenticated");
}

const userId = request.auth.uid;
```

以下では try 文の中でメモの追加処理を行なっています。
userNotes コレクション > ユーザーのUID > notes コレクション の配下にデータを格納します。
これによりユーザーごとのメモの保持が可能になります。

`add` メソッドの第一引数に追加したいデータを渡すことでデータの追加が可能です。
データを追加した後は JSON 形式で `success`, `noteId` を返却しています。
```ts
const userNotesCollectionRef = db.collection("userNotes").doc(userId).collection("notes");
const now = Timestamp.now();

const newNote = {
  title,
  content,
  createdAt: now,
  updatedAt: now
};

const docRef = await userNotesCollectionRef.add(newNote);

return {
  success: true,
  noteId: docRef.id
};
```

これでメモの追加処理の実装は完了です。

次は `getNotes.ts` です。
コードは以下の通りです。
```ts: getNotes.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

export const getNotes = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const userId = request.auth.uid;

  try {
    const userNotesCollectionRef = db.collection("userNotes").doc(userId).collection("notes");
    const snapshot = await userNotesCollectionRef.orderBy("createdAt", "desc").get();

    if (snapshot.empty) {
      return { notes: [] };
    }

    const notes = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        title: data.title,
        content: data.content,
        createdAt: data.createdAt.toDate().toISOString(),
        updatedAt: data.updatedAt ? data.updatedAt.toDate().toISOString() : null
      };
    });

    console.log('fetch notes:', notes);

    return { notes };
  } catch (error) {
    console.error("Failed to get notes:", error);
    throw new HttpsError("internal", "Failed to get notes");
  }
});
```

他のメソッドと重複していない以下の部分について見ていきます。
以下では追加処理の時と同じコレクションに対して `get` メソッドを実行することでデータの取得を行なっています。なお、`orderBy` に `createdAt`, `desc` を指定することでメモが作成された日時が新しい順に並べて取得することができます。

取得したデータを map メソッドで複数返却するようにしています。
```ts
const userNotesCollectionRef = db.collection("userNotes").doc(userId).collection("notes");
const snapshot = await userNotesCollectionRef.orderBy("createdAt", "desc").get();

if (snapshot.empty) {
  return { notes: [] };
}

const notes = snapshot.docs.map(doc => {
  const data = doc.data();
  return {
    id: doc.id,
    title: data.title,
    content: data.content,
    createdAt: data.createdAt.toDate().toISOString(),
    updatedAt: data.updatedAt ? data.updatedAt.toDate().toISOString() : null
  };
```

次は `updateNote.ts` です。
コードは以下の通りです。
```ts: updateNote.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

const db = getFirestore();

export const updateNote = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { noteId, title, content } = request.data;
  const userId = request.auth.uid;

  if (!noteId || !title || !content) {
    throw new HttpsError(
      "invalid-argument",
      "NoteId, title, and content are required"
    );
  }

  try {
    const noteRef = db.collection("userNotes").doc(userId).collection("notes").doc(noteId);

    const noteDoc = await noteRef.get();
    if (!noteDoc.exists) {
      throw new HttpsError("not-found", "Note not found");
    }

    await noteRef.update({
      title,
      content,
      updatedAt: FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    console.error("Failed to update note:", error);
    throw new HttpsError("internal", "Failed to update note");
  }
});
```

他のメソッドと重複していない以下の部分について見ていきます。
以下ではメモの変更を行なっています。`updateNote` ではメモのIDである `noteId` を受け取り、そのIDと合致するドキュメントを取得(get)、変更(update)しています。
```ts
const noteRef = db.collection("userNotes").doc(userId).collection("notes").doc(noteId);

const noteDoc = await noteRef.get();
if (!noteDoc.exists) {
  throw new HttpsError("not-found", "Note not found");
}

await noteRef.update({
  title,
  content,
  updatedAt: FieldValue.serverTimestamp(),
});

return { success: true };
```

最後は `deleteNote.ts` です。
コードは以下の通りです。
```ts: deleteNote.ts
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { getFirestore } from "firebase-admin/firestore";

const db = getFirestore();

export const deleteNote = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { noteId } = request.data;
  const userId = request.auth.uid;

  if (!noteId) {
    throw new HttpsError("invalid-argument", "NoteId is required");
  }

  try {
    const noteRef = db.collection("userNotes").doc(userId).collection("notes").doc(noteId);

    const noteDoc = await noteRef.get();
    if (!noteDoc.exists) {
      throw new HttpsError("not-found", "Note not found");
    }

    await noteRef.delete();

    return { success: true };
  } catch (error) {
    console.error("Failed to delete note:", error);
    throw new HttpsError("internal", "Failed to delete note");
  }
});
```

以下の部分で `noteId` をもとに削除するメモを取得(get)して削除(delete)しています。
```ts
const noteRef = db.collection("userNotes").doc(userId).collection("notes").doc(noteId);

const noteDoc = await noteRef.get();
if (!noteDoc.exists) {
  throw new HttpsError("not-found", "Note not found");
}

await noteRef.delete();

return { success: true };
```

これで CRUD処理の実装は完了です。

最後に `index.ts` を以下のように編集します。
先程までの実装では `index.ts` を直接編集していましたが、別のディレクトリでのファイルを import, export することで同じような実装が可能になります。
```diff ts: index.ts
import { onCall, onRequest, HttpsError } from "firebase-functions/v2/https";
+ const { initializeApp } = require("firebase-admin/app");
const functions = require("firebase-functions");

+ initializeApp();

+ // Notes
+ export { addNote } from "./notes/addNote";
+ export { updateNote } from "./notes/updateNote";
+ export { deleteNote } from "./notes/deleteNote";
+ export { getNotes } from "./notes/getNotes";

// onCall
exports.helloWorldOnCallV1 = functions.https.onCall(() => {
  try {
    return { result: "Hello World (V1) !" };
  } catch (error) {
    console.error("Error in helloWorldOnCallV1:", error);
    throw functions.https.HttpsError(
      "internal",
      "An unexpected error occurred"
    );
  }
});

export const helloWorldOnCallV2 = onCall({}, (_) => {
  try {
    return { result: "Hello World (V2 onCall) !" };
  } catch (error) {
    console.error("Error in helloWorldOnCallV2:", error);
    throw new HttpsError("internal",
      "An unexpected error occurred");
  }
});

// onRequest
exports.helloWorldOnRequestV1 = functions.https.onRequest(
  (req: any, res: any) => {
    try {
      res.status(200).json({ result: "Hello world (V1 onRequest) !" });
    } catch (error) {
      console.error("Error in helloWorldOnRequestV1:", error);
      res.status(500).json({ error: "Internal server error" });
    }
  }
);

export const helloWorldOnRequestV2 = onRequest({}, (req, res) => {
  try {
    res.status(200).json({ result: "Hello world (V2 onRequest) !" });
  } catch (error) {
    console.error("Error in helloWorldOnRequestV2:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});
```

ファイルの変更が完了したら以下のコマンドを実行して関数をデプロイしておきます。
```
firebase deploy --only functions
```

#### 2. Functions の権限設定
先程デプロイした関数の権限設定を行います。
この章で実装した関数は全て第2世代のものなので、 [2. Functions の権限設定](#2.-functions-%E3%81%AE%E6%A8%A9%E9%99%90%E8%A8%AD%E5%AE%9A) と同様の権限の設定を行います。

#### 3. Flutter側のコード編集
次に Flutter 側のコードの編集を行います。
Flutter 側の実装は以下の手順で進めていきます。
1. Model の定義
2. Repository層の実装
3. Service層の実装
4. UIの実装

**1. Model の定義**
まずは Model の定義を行います。
models ディレクトリ内で `note.dart` を作成して以下のようなコードにします。
メモではタイトルや内容、作成日時や変更日時を保持しておきます。
```dart: note.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'note.freezed.dart';
part 'note.g.dart';

@freezed
class Note with _$Note {
  const factory Note({
    required String id,
    required String title,
    required String content,
    required DateTime createdAt,
    DateTime? updatedAt,
  }) = _Note;

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
}
```

これで以下のコマンドを実行してモデルを作成します。
```
flutter pub run build_runner build --delete-conflicting-outputs
```

**2. Repository層の実装**
次に Repository層の実装を行います。
repositories ディレクトリを作成して以下のコードを追加していきます。

以下では `abstract` でメモを管理する Repository を作成しています。
Functions 側と対応するCRUD処理をそれぞれ用意しています。
```dart: note_repository.dart
import 'package:functions_sample/notes/models/note.dart';

abstract class NoteRepository {
  Future<List<Note>> getNotes();
  Future<String> addNote(String title, String content);
  Future<void> updateNote(String noteId, String title, String content);
  Future<void> deleteNote(String noteId);
}
```

以下では `mixin` として Functions のインスタンスを保持する `FunctionsAccessMixin` を定義しています。
```dart: functions_access_mixin.dart
import 'package:cloud_functions/cloud_functions.dart';

mixin FunctionsAccessMixin {
  FirebaseFunctions get functions => FirebaseFunctions.instance;
}
```

以下では `mixin` として FirebaseAuth のインスタンスと現在のユーザーを保持する `FirebaseAuthAccessMixin` を定義しています。
```dart
import 'package:firebase_auth/firebase_auth.dart';

mixin FirebaseAuthAccessMixin {
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
  User? get currentUser => firebaseAuth.currentUser;
}
```

以下では Functions を用いてメモの管理を行う `FunctionsNoteRepository` を定義しています。
先程作成した `NoteRepository` を継承し、`FunctionsAccessMixin` を with で使うことで、この `FunctionsNoteRepository` では `NoteRepository` で定義した関数と Functions のインスタンスを使用することができるようになります。

先程の実装と同様に `functions.httpsCallable('{関数名}').call()` で関数を呼ぶことができ、その結果を `Note` に変換することで、Flutter側で簡単に扱うことができるようになります。
```dart: functions_note_repository.dart
import 'package:flutter/foundation.dart';
import 'package:functions_sample/notes/models/note.dart';
import 'package:functions_sample/notes/repositories/mixin/functions_access_mixin.dart';
import 'package:functions_sample/notes/repositories/note_repository.dart';

class FunctionsNoteRepository extends NoteRepository with FunctionsAccessMixin {
  @override
  Future<List<Note>> getNotes() async {
    try {
      final result = await functions.httpsCallable('getNotes').call();
      final data = result.data;

      if (data is! Map<String, dynamic> || data['notes'] is! List) {
        debugPrint('Unexpected data structure: $data');
        return [];
      }

      final List<dynamic> notesData = data['notes'] as List<dynamic>;
      return notesData
          .map((noteData) {
            try {
              return Note(
                id: noteData['id'] as String,
                title: noteData['title'] as String,
                content: noteData['content'] as String,
                createdAt: DateTime.parse(noteData['createdAt'] as String),
                updatedAt: noteData['updatedAt'] != null
                    ? DateTime.parse(noteData['updatedAt'] as String)
                    : null,
              );
            } catch (e) {
              debugPrint('Error parsing note data: $noteData, Error: $e');
              return null;
            }
          })
          .where((note) => note != null)
          .cast<Note>()
          .toList();
    } catch (e) {
      debugPrint('Failed to get notes: $e');
      rethrow;
    }
  }

  @override
  Future<String> addNote(String title, String content) async {
    try {
      final result = await functions.httpsCallable('addNote').call({
        'title': title,
        'content': content,
      });

      if (result.data is! Map<String, dynamic> ||
          result.data['success'] != true ||
          result.data['noteId'] is! String) {
        throw Exception('Failed to add note: Invalid response');
      }

      return result.data['noteId'] as String;
    } catch (e) {
      debugPrint('Failed to add note: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateNote(String noteId, String title, String content) async {
    try {
      final result = await functions.httpsCallable('updateNote').call({
        'noteId': noteId,
        'title': title,
        'content': content,
      });

      if (result.data is! Map<String, dynamic> ||
          result.data['success'] != true) {
        throw Exception('Failed to update note: Invalid response');
      }
    } catch (e) {
      debugPrint('Failed to update note: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      final result = await functions.httpsCallable('deleteNote').call({
        'noteId': noteId,
      });

      if (result.data is! Map<String, dynamic> ||
          result.data['success'] != true) {
        throw Exception('Failed to delete note: Invalid response');
      }
    } catch (e) {
      debugPrint('Failed to delete note: $e');
      rethrow;
    }
  }
}
```

これで Repository層の実装は完了です。

**3. Service層の実装**
次は Service層の実装を行います。
コードは以下の通りです。

build メソッドでメモの取得を行なっていて、基本的には Repository層で定義した関数を実行しています。この `FunctionsNoteManager` の関数をUIから呼び出す形で使用します。
```dart
import 'package:functions_sample/notes/repositories/functions_note_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';

part 'functions_note_manager.g.dart';

@riverpod
class FunctionsNoteManager extends _$FunctionsNoteManager {
  final repository = FunctionsNoteRepository();
  @override
  FutureOr<List<Note>> build() => fetchNotes();

  Future<List<Note>> fetchNotes() async {
    return await repository.getNotes();
  }

  Future<void> addNote(String title, String content) async {
    await repository.addNote(title, content);
    ref.invalidateSelf();
  }

  Future<void> updateNote(String id, String title, String content) async {
    await repository.updateNote(id, title, content);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(String id) async {
    await repository.deleteNote(id);
    ref.invalidateSelf();
  }
}
```

**4. UIの実装**
次にUIの実装を行います。
UIの実装は以下の四つを行います。
- SignInScreen
- NoteListScreen
- NoteDetailScreen
- NoteEditScreen

それぞれコードは以下の通りです。
SignInScreen
```dart: sign_in_screen.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:functions_sample/notes/screens/note_list_screen.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('サインイン'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                await firebaseAuth.signInAnonymously();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NoteListScreen(),
                  ),
                );
              },
              child: const Text('サインイン'),
            ),
          ],
        ),
      ),
    );
  }
}
```

以下ではサインインボタンを実装しており、 `signInAnonymously` が実行されます。
このサインインでUIDが FirebaseAuth に保存されます。サインイン後に `NoteListScreen` に遷移するようにしています。
```dart
ElevatedButton(
  onPressed: () async {
    await firebaseAuth.signInAnonymously();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteListScreen(),
      ),
    );
  },
  child: const Text('サインイン'),
),
```

NoteListScreen
```dart: note_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functions_sample/notes/screens/note_detail_screen.dart';
import 'package:functions_sample/notes/screens/note_edit_screen.dart';
import 'package:functions_sample/notes/service/functions_note_manager.dart';

class NoteListScreen extends ConsumerWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsyncValue = ref.watch(functionsNoteManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Notes')),
      body: notesAsyncValue.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet'));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(note.title),
                subtitle: Text(note.content,
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NoteDetailScreen(note: note),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const NoteEditScreen()),
        ),
      ),
    );
  }
}
```

以下では先程定義した `firestoreNoteManagerProvider` のビルドメソッドの返り値、つまりメモを取得した結果を `notesAsyncValue` に格納しています。取得状況に応じて表示内容を切り替えています。
```dart
final notesAsyncValue = ref.watch(firestoreNoteManagerProvider);
```

NoteDetailScreen
```dart: note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:functions_sample/notes/screens/note_edit_screen.dart';
import 'package:functions_sample/notes/service/functions_note_manager.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../models/note.dart';

class NoteDetailScreen extends ConsumerWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await ref
                  .read(functionsNoteManagerProvider.notifier)
                  .deleteNote(note.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(8),
            Text(
              note.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Gap(32),
            Text(
              'Created',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(8),
            Text(
              formatDateTime(note.createdAt),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (note.updatedAt != null) ...[
              const Gap(32),
              Text(
                'Updated',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Gap(8),
              Text(
                formatDateTime(note.updatedAt!),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            const Gap(32),
            Text(
              'Content',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(8),
            Text(
              note.content,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

String formatDateTime(DateTime dateTime) {
  final formatter = DateFormat('yyyy年M月d日 HH:mm', 'ja_JP');
  return formatter.format(dateTime);
}
```

以下ではメモの編集、削除ボタンを設けています。
編集ボタンでは `NoteEditScreen` にメモを渡して遷移します。
削除ボタンでは `functionsNoteManagerProvider` で定義した削除するためのメソッドを実行しています。
```dart
IconButton(
  icon: const Icon(Icons.edit),
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => NoteEditScreen(note: note)),
  ),
),
IconButton(
  icon: const Icon(Icons.delete),
  onPressed: () async {
    await ref
        .read(functionsNoteManagerProvider.notifier)
        .deleteNote(note.id);
    Navigator.pop(context);
  },
),
```

NoteEditScreen
```dart: note_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:functions_sample/notes/service/functions_note_manager.dart';
import 'package:gap/gap.dart';
import '../models/note.dart';

class NoteEditScreen extends HookConsumerWidget {
  final Note? note;

  const NoteEditScreen({super.key, this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController(text: note?.title ?? '');
    final contentController = useTextEditingController(text: note?.content ?? '');

    useEffect(() {
      return () {
        titleController.dispose();
        contentController.dispose();
      };
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(note == null ? 'New Note' : 'Edit Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () async {
              if (note == null) {
                await ref.read(functionsNoteManagerProvider.notifier).addNote(
                      titleController.text,
                      contentController.text,
                    );
              } else {
                await ref
                    .read(functionsNoteManagerProvider.notifier)
                    .updateNote(
                      note!.id,
                      titleController.text,
                      contentController.text,
                    );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const Gap(16),
            SizedBox(
              height: 100,
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: null,
                expands: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

`NoteEditScreen` ではメモの新規作成画面と編集画面を共通化しています。
以下の部分では、引数としてメモを受け取っていない場合は新規作成画面であるため、 `functionsNoteManagerProvider` の `addNote` メソッドを実行し、メモを受け取っている場合は編集画面であるため、`updateNote` メソッドを実行しています。
```dart
IconButton(
  icon: const Icon(Icons.save),
  onPressed: () async {
    if (note == null) {
      await ref.read(functionsNoteManagerProvider.notifier).addNote(
            titleController.text,
            contentController.text,
          );
    } else {
      await ref
          .read(functionsNoteManagerProvider.notifier)
          .updateNote(
            note!.id,
            titleController.text,
            contentController.text,
          );
    }
    Navigator.pop(context);
  },
),
```

最後に `main.dart` でユーザーの有無によって表示させる画面を変更して実装完了です。
```dart: main.dart
class MyApp extends ConsumerWidget with FirebaseAuthAccessMixin {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: currentUser != null ? const NoteListScreen() : const SignInScreen(),
    );
  }
}
```

これで実装は完了です。
以上のコードで実行すると以下の動画のような挙動になり、正常にメモアプリとして動作するかと思います。

https://youtube.com/shorts/sI3O4wOw9zA

#### 4. Firestore での実装
ここからはおまけとして Firestore での実装も行いたいと思います。
コードはそれぞれ以下の通りです。
Mixin
```dart: firestore_access_mixin.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

mixin FirestoreAccessMixin {
  String? get userId => FirebaseAuth.instance.currentUser?.uid;

  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get notesCollection =>
      firestore.collection('userNotes').doc(userId).collection('notes');
}
```

Repository
```dart: firestore_note_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:functions_sample/notes/models/note.dart';
import 'package:functions_sample/notes/repositories/mixin/firestore_access_mixin.dart';
import 'package:functions_sample/notes/repositories/note_repository.dart';

class FirestoreNoteRepository extends NoteRepository with FirestoreAccessMixin {
  @override
  Future<List<Note>> getNotes() async {
    try {
      final querySnapshot =
          await notesCollection.orderBy('createdAt', descending: true).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Note(
          id: doc.id,
          title: data['title'] as String,
          content: data['content'] as String,
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          updatedAt: data['updatedAt'] != null
              ? (data['updatedAt'] as Timestamp).toDate()
              : null,
        );
      }).toList();
    } catch (e) {
      debugPrint('Failed to get notes: $e');
      rethrow;
    }
  }

  @override
  Future<String> addNote(String title, String content) async {
    try {
      final docRef = await notesCollection.add({
        'title': title,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Failed to add note: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateNote(String noteId, String title, String content) async {
    try {
      await notesCollection.doc(noteId).update({
        'title': title,
        'content': content,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Failed to update note: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    try {
      await notesCollection.doc(noteId).delete();
    } catch (e) {
      debugPrint('Failed to delete note: $e');
      rethrow;
    }
  }
}
```

Manager
```dart
import 'package:functions_sample/notes/repositories/firestore_note_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/note.dart';

part 'firestore_note_manager.g.dart';

@riverpod
class FirestoreNoteManager extends _$FirestoreNoteManager {
  final repository = FirestoreNoteRepository();
  @override
  FutureOr<List<Note>> build() => fetchNotes();

  Future<List<Note>> fetchNotes() async {
    return await repository.getNotes();
  }

  Future<void> addNote(String title, String content) async {
    await repository.addNote(title, content);
    ref.invalidateSelf();
  }

  Future<void> updateNote(String id, String title, String content) async {
    await repository.updateNote(id, title, content);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(String id) async {
    await repository.deleteNote(id);
    ref.invalidateSelf();
  }
}
```

Repository層で Firestore に直接アクセスしてデータの変更を行なっています。
このコードでUI側の `functionsNoteManagerProvider` を `firestoreNoteManagerProvider` に切り替えて実行することで Functions と Firestore を使い分けられるようになります。
また、挙動としても問題なく動作することがわかります。

上にあげたような構成であれば以下のようなケースにスムーズに対処できるかと思います。
- 開発が始まった段階では Flutter と Cloud Firestore を用いた開発を行なっていたが、チームメンバーが増えて、バックエンドと分けて Functions を用いた開発を行うようになった場合
- Cloud Firestore から別のサービスに切り替える必要がある際

以上です。

なお、今回実装した内容は以下のGitHubで公開しています。
まだまだ改善できる余地があると思うので、今後勉強したり新たな実装をしたりする段階で更新していこうと思います。
https://github.com/Koichi5/functions-sample

## まとめ
最後まで読んでいただいてありがとうございました。

今回は Flutter から Cloud Functions を呼び出す実装を行いました。
バックエンド側の知見がほとんどないため、今後の実装で随時更新していければと思います。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考


https://cloud.google.com/functions/docs/concepts/overview?hl=ja

https://firebase.google.com/docs/functions/?hl=ja

https://firebase.google.com/docs/functions/functions-and-firebase?hl=ja

https://cloud.google.com/blog/ja/products/serverless/cloud-run-vs-cloud-functions-for-serverless

https://firebase.google.com/docs/functions/version-comparison?hl=ja

https://cloud.google.com/blog/products/serverless/google-cloud-functions-is-now-cloud-run-functions?hl=en