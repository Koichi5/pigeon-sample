## 初めに
今回は Firebase の Cloud Functions（以下 Functions） を用いて指定したメールアドレスに任意の内容のメールを送れるような機能を実装してみたいと思います。
メールを送信する機能を実装する機会があり、今後も実装することがあると思うので備忘録として残しておきます。

## 記事の対象者
+ Flutter 学習者
+ Functions でメール送信処理を実装をしたい方

## 目的
今回の目的は上記の通り Functions でメールを送信できるようにすることが目的です。
最終的には以下の動画のようにメールを送れるようにします。

https://youtu.be/RN-RNGE3L1Y

## 準備
準備は以下の３つがあります
1. Functions 側の準備
2. Flutter 側の準備
3. Google アカウントの準備

### 1. Functions 側の準備
Functions 側の準備は以下です。
1. Firebase のプロジェクト作成
2. Flutter と Firebase プロジェクトの連携
3. Functions の有効化

Functions のセットアップは以下の記事が参考になるかと思います。
なお、今回は Functions 以外は使用しないため、Firebase Auth などの有効化は不要です。

https://zenn.dev/koichi_51/articles/d5e17ed74f13ef

### 2. Flutter 側の準備
次に Flutter 側で必要なパッケージの準備を行います。
以下のパッケージの最新バージョンを `pubspec.yaml`に記述します。
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_hooks: ^0.20.5
  gap: ^3.0.1

  # Firebase
  firebase_core: ^3.6.0
  cloud_functions: ^5.1.3
```

または以下のコマンドをターミナルで実行します。
```
flutter pub add flutter_hooks gap firebase_core cloud_functions
```

### 3. Google アカウントの準備
最後に、今回の実装では2段階認証が完了したGoogleアカウントとその[アプリパスワード](https://support.google.com/accounts/answer/185833?hl=ja)が必要になるので取得してファイルに追加しておきます。

メールの送信元に設定したい Google アカウントで以下にアクセスします。
https://myaccount.google.com/apppasswords

ログインすると以下のような画面になるかと思います。「アプリ名」は特に指定はないため適当なものを入力して、「作成」を押します。
![](https://storage.googleapis.com/zenn-user-upload/dba83f6e1367-20241027.png)

するとパスワードが表示されるので、それをメモしてエディタに戻ります。

Flutter と Firebase の連携を行い、 Functions を有効化するとルートディレクトリに `functions` ディレクトリが作成されているかと思います。 Functions に関する編集はこのディレクトリ内で行います。
`functions` ディレクトリに `.env` ファイルを作成し、以下のように編集します。
```ts: functions/.env
MAIL_ACCOUNT = "{メール送信元にしたいGoogleアカウントのメールアドレス}"
MAIL_PASSWORD = "{メモしたアプリパスワード}"
```

GitHub等でコード管理を行う場合は作成した `.env` を `.gitignore` に追加しておきます。

これで準備は完了です。

## 実装
次にそれぞれの実装に入っていきます。
実装は大まかに以下の手順で進めていきます。
1. Functions 側の実装
2. Flutter 側の実装

### 1. Functions 側の実装
まずは Functions 側の実装です。
コードの実装に入る前に、今回 Functions 側で使用するモジュールなどを確認しておきます。

#### Nodemailer とは
今回は [Nodemailer](https://nodemailer.com/)というモジュールを使用します。

Nodemailer については以下を引用します。
> Nodemailer is a module for Node.js applications that allows easy email sending. The project started in 2010 when there were few reliable options for sending email messages, and today, it is the default solution for most Node.js users.
>
> To send an email, follow these steps:
> 1. Create a Nodemailer transporter using either SMTP or another transport method
> 2. Set up your message options (who sends what to whom)
> 3. Deliver the message using the sendMail() method of your transporter
>
> （日本語訳）
> Nodemailerは、Node.jsアプリケーション向けのモジュールで、簡単にメールを送信できるようにします。このプロジェクトは2010年に始まり、当時は信頼できるメール送信オプションがほとんどなかったため、今日ではほとんどのNode.jsユーザーにとって標準的なソリューションとなっています。
>
> メールを送信するには、次の手順に従います。
>
> 1. SMTPまたは他のトランスポート方法を使用してNodemailerのトランスポーターを作成する
> 2. メッセージオプションを設定する（誰が、何を、誰に送るか）
> 3. トランスポーターのsendMail()メソッドを使ってメッセージを送信する

今回はこの Nodemailer の Gmail を使ってメール送信を実装していきます。

メール送信のためのSTMP(Simple Mail Transfer Protocol)を提供しているサービスは Gmail 以外にも以下のようなものがありました。メールの開封率をはじめとするデータ管理など様々な機能の提供の有無や送信数の制限の有無などの違いもあるので、それぞれの要件に応じて使い分けられたら良いと思います。

- [SendGrid](https://sendgrid.kke.co.jp/)
- [Mailtrap](https://mailtrap.io/)
- [Mailgun](https://www.mailgun.com/)

#### Functions のバージョン
また、筆者の手元の Functions 側のそれぞれのバージョンは以下のようになっています。
- Node: 18
- firebase: 10.8.0
- firebase-admin: 12.7.0
- firebase-functions: 6.1.0
- nodemailer: 6.9.15

<br/>
それではコードを見ていきます。今回は TypeScript でメール送信機能を実装していきます。
`functions/src` ディレクトリの配下に `email` ディレクトリを作成し、その中に `sendEmail.ts` を作成します。

作成した `sendEmail.ts` ファイルを以下のように変更します。
```ts: functions/src/email/sendEmail.ts
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { createTransport, Transporter } from "nodemailer";

async function sendEmailWithTransporter(
  transporter: Transporter,
  mailOptions: {
    from: string;
    to: string;
    subject: string;
    text: string;
  }
): Promise<void> {
  try {
    const info = await transporter.sendMail(mailOptions);
    console.log("Successfully sent email:", info.response);
  } catch (error) {
    console.error("Failed to send email:", error);
    throw new HttpsError("internal", "Failed to send email.");
  }
}

export const sendEmail = onCall(async (request) => {
  const { subject, text, to } = request.data;

  // リクエストデータのバリデーション
  if (!subject || !text || !to) {
    throw new HttpsError(
      "invalid-argument",
      "Subject, text, and to fields are required."
    );
  }

  // 環境変数からメールアカウント情報を取得
  const { MAIL_ACCOUNT: mail, MAIL_PASSWORD: password } = process.env;

  // 環境変数のチェック
  if (!mail || !password) {
    console.error("Missing MAIL_ACCOUNT or MAIL_PASSWORD environment variables.");
    throw new HttpsError("internal", "Email configuration is not properly set.");
  }

  // メール送信オプションの設定
  const mailOptions = {
    from: mail,
    to: to,
    subject: subject,
    text: text,
  };

  // メールトランスポーターの作成
  const transporter = createTransport({
    service: "gmail",
    auth: {
      user: mail,
      pass: password,
    },
  });

  // メールの送信
  await sendEmailWithTransporter(transporter, mailOptions);
});
```

それぞれ詳しくみていきます。

以下では `nodemailer` の `transporter` でメールを送信するためのメソッドを定義しています。
`mailOptions` として送信元( `from` )、送信先( `to` )、件名( `subject` )、内容( `text` )を受け取り、それを `sendMail` メソッドに渡すことでメールの設定をして送信することができます。これらの処理を非同期で行うようにしています。
送信に失敗した場合はエラーを返すようにしています。
```ts
async function sendEmailWithTransporter(
  transporter: Transporter,
  mailOptions: {
    from: string;
    to: string;
    subject: string;
    text: string;
  }
): Promise<void> {
  try {
    const info = await transporter.sendMail(mailOptions);
    console.log("Successfully sent email:", info.response);
  } catch (error) {
    console.error("Failed to send email:", error);
    throw new HttpsError("internal", "Failed to send email.");
  }
}
```

以下では `sendEmail` を実装して `export` をつけることで外部でも参照できるようにしています。関数は Functions の第二世代の `onCall` を使用しており、これから実装する Flutter 側のコードから呼び出された段階で発火します。
`request` には 送信先( `to` )、件名( `subject` )、内容( `text` ) が含まれており、それぞれのパラメータが `request` に含まれない場合はエラーを投げるようにしています。
```ts
export const sendEmail = onCall(async (request) => {
  const { subject, text, to } = request.data;

  // リクエストデータのバリデーション
  if (!subject || !text || !to) {
    throw new HttpsError(
      "invalid-argument",
      "Subject, text, and to fields are required."
    );
  }
```

:::details Functions の第二世代
Functions の第二世代の `onCall` の実装に関しては以下が参考になるかと思います。

https://firebase.google.com/docs/functions/callable?hl=ja&gen=2nd

https://zenn.dev/koichi_51/articles/d5e17ed74f13ef
:::

以下では先ほどの「準備」の章で設定した `.env` ファイルから「メールアドレス」と「アプリパスワード」を取得しています。また、どちらかの変数が取得できない場合はエラーが出力されるようにしています。
```ts
// 環境変数からメールアカウント情報を取得
const { MAIL_ACCOUNT: mail, MAIL_PASSWORD: password } = process.env;

// 環境変数のチェック
if (!mail || !password) {
  console.error("Missing MAIL_ACCOUNT or MAIL_PASSWORD environment variables.");
  throw new HttpsError("internal", "Email configuration is not properly set.");
}
```

以下ではメール送信のオプションとトランスポーターの作成、メールの送信を行なっています。
Nodemailer モジュールに用意されている `createTransport` でトランスポーターを作成しています。`user`, `pass` にはそれぞれ `.env` ファイルから取得した値を割り当てています。
`sendEmailWithTransporter` は先ほど定義した通りで、これで渡したオプションに応じてメールを送信できることができます。
```ts
// メール送信オプションの設定
const mailOptions = {
  from: mail,
  to: to,
  subject: subject,
  text: text,
};

// メールトランスポーターの作成
const transporter = createTransport({
  service: "gmail",
  auth: {
    user: mail,
    pass: password,
  },
});

// メールの送信
await sendEmailWithTransporter(transporter, mailOptions);
```

これで `sendEmail` メソッドの実装は完了です。

最後に関数のデプロイを行います。
Functions では `functions/src/index.ts` に含まれる関数をデプロイします。
したがって、先ほど作成した `sendEmail` メソッドを `functions/src/index.ts` に追加する必要があります。

`index.ts` を以下のように変更します。
ここでは Firebase の初期化と `sendEmail` を行なっています。
```ts: functions/src/index.ts
import * as admin from "firebase-admin";

admin.initializeApp();
export { sendEmail } from "./email/sendEmail";
```

以下のコマンドを実行してエラーが出力されなければ、デプロイは完了です。
```
firebase deploy --only functions
```

### 2. Flutter 側の実装
次に Flutter 側の実装に移ります。
Flutter 側の実装は以下の手順で進めます。
1. Usecase の作成
2. Screen の作成
3. main.dart の編集

#### 1. Usecase の作成
まずは先ほど作成した Functions と Flutter の繋ぎ込みを行います。
今回はメールの送信を行う単体のUsecaseを作成します。
コードは以下の通りです。
```dart: lib/usecase/send_email_usecase.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class SendEmailUsecase {
  SendEmailUsecase();

  Future<void> call({
    required String subject,
    required String text,
    required String to,
  }) async {
    try {
      final data = {
        'subject': subject,
        'text': text,
        'to': to,
      };
      debugPrint('Email data: $data');
      await FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('sendEmail')
          .call(data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Failed to send email: ${e.code} - ${e.message}');
      debugPrint('Details: ${e.details}');
      rethrow;
    }
  }
}
```

それぞれ詳しく見ていきます。

以下ではメールを送信するための `SendEmailUsecase` を定義して、非同期で処理を行う `call` メソッドのみを定義しています。
`call` メソッドは件名( `subject` )、内容( `text` ) 、送信先( `to` )を受け取れるようにしています。
```dart
class SendEmailUsecase {
  SendEmailUsecase();

  Future<void> call({
    required String subject,
    required String text,
    required String to,
  }) async {
```

以下では引数で受け取った件名、内容、送信先を `data` として定義しています。
`FirebaseFunctions.instanceFor(region: 'us-central1')` では Functions のリージョンを指定しています。指定せずに `FirebaseFunctions.instance` としても問題ないかと思います。
`.httpsCallable('sendEmail').call(data)` では先ほど Functions 側で実装した `sendEmail` のメソッド名を指定して、件名などのオプションを含む `data` を渡しています。

また、エラーが発生した場合はキャッチして出力するようにしています。
```dart
try {
  final data = {
    'subject': subject,
    'text': text,
    'to': to,
  };
  debugPrint('Email data: $data');
  await FirebaseFunctions.instanceFor(region: 'us-central1')  // リージョン指定
      .httpsCallable('sendEmail')                             // メソッド名指定
      .call(data);                                            // data を渡す
} on FirebaseFunctionsException catch (e) {
  debugPrint('Failed to send email: ${e.code} - ${e.message}');
  debugPrint('Details: ${e.details}');
  rethrow;
}
```

これで Usecase の作成は完了です。

#### 2. Screen の作成
次にメールの作成を行う Screen を作成します。
コードは以下の通りです。
3つのテキストフィールドと送信ボタンで構成されているシンプルなページです。
```dart: lib/screens/send_email_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:tocsa_business_logic/usecase/send_email_usecase.dart';

class SendEmailScreen extends HookWidget {
  const SendEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sendEmailUsecase = SendEmailUsecase();
    final subjectController = useTextEditingController();
    final textController = useTextEditingController();
    final toController = useTextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: const Text('メール送信'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                label: Text('件名'),
              ),
            ),
            const Gap(16),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                label: Text('本文'),
              ),
            ),
            const Gap(16),
            TextField(
              controller: toController,
              decoration: const InputDecoration(
                label: Text('送信先メールアドレス'),
              ),
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: () async {
                await sendEmailUsecase(
                  subject: subjectController.text,
                  text: textController.text,
                  to: toController.text,
                );
              },
              child: const Text('送信'),
            ),
          ],
        ),
      ),
    );
  }
}
```

必要な部分をかいつまんで見ていきます。

以下では `sendEmailUsecase` で先ほど定義したメール送信のためのユースケースを読み込んでいます。
また、件名、内容、送信先のテキストの状態を `useTextEditingController` で保持しています。
```dart
final sendEmailUsecase = SendEmailUsecase();
final subjectController = useTextEditingController();
final textController = useTextEditingController();
final toController = useTextEditingController();
```

以下では「送信」ボタンを実装しており、`sendEmailUsecase` にそれぞれの項目を渡すことでメールの送信処理が行われるようにしています。
```dart
ElevatedButton(
  onPressed: () async {
    await sendEmailUsecase(
      subject: subjectController.text,
      text: textController.text,
      to: toController.text,
    );
  },
  child: const Text('送信'),
),
```

これで Screen の実装は完了です。

#### 3. main.dart の編集
最後に `main.dart` で以下の項目が設定されていることを確認します。
- Firebase の初期化処理
- SendEmailScreen を home に指定
```dart: lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SendEmailScreen(),
    );
  }
}
```

上記の実装で実行すると以下の動画のように、任意のメールアドレスに対して任意の内容のメールを送信できるかと思います。

https://youtu.be/RN-RNGE3L1Y

## まとめ
最後まで読んでいただいてありがとうございました。

今回は Functions でメールを送信する実装を行いました。
便利なモジュールのおかげで比較的手軽に実装することができました。

今回は Usecase として呼び出す形で実装しましたが、 Cloud Firestore のコレクションを監視して、特定のコレクションにデータが追加された段階で発火するというような実装でも扱いやすいかと思いました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://nodemailer.com/

https://dev.classmethod.jp/articles/nodemailer-gmail/

https://www.isoroot.jp/blog/6491/

https://zenn.dev/miyassie/articles/d8b7076ef8fa58