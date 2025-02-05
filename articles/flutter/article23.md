## 初めに
今回は Flutter 3.19 で使用できるようになった [google_generative_ai パッケージ](https://pub.dev/packages/google_generative_ai) で Gemini を使ってみたいと思います。

## 記事の対象者
+ Flutter 学習者
+ アプリに生成AIを導入したい方

## 目的
今回は先述の通り [google_generative_ai パッケージ](https://pub.dev/packages/google_generative_ai) を用いて Gemini をアプリ内で使用できるようにしたいと思います。最終的には以下のようなチャットアプリを実装してみます。

https://youtube.com/shorts/ePBFQFHcUUc?feature=share

:::message
なお、[google_generative_ai パッケージ](https://pub.dev/packages/google_generative_ai)に以下のような記述がありました。

> Using the Google AI SDK for Dart (Flutter) to call the Google AI Gemini API directly from your app is recommended for prototyping only. If you plan to enable billing, we strongly recommend that you use the SDK to call the Google AI Gemini API only server-side to keep your API key safe. You risk potentially exposing your API key to malicious actors if you embed your API key directly in your mobile or web app or fetch it remotely at runtime.
>
> 日本語訳
> Google AI SDK for Dart（Flutter）を使用して、アプリケーションから直接Google AI Gemini APIを呼び出すことは、プロトタイピングのためにのみ推奨されます。課金を有効にする予定の場合、APIキーを安全に保つために、SDKを使用してサーバーサイドからのみGoogle AI Gemini APIを呼び出すことを強く推奨します。モバイルアプリやWebアプリにAPIキーを直接埋め込んだり、実行時にリモートからAPIキーを取得したりすると、悪意のあるアクターにAPIキーが露呈するリスクがあります。

つまり、以下のことが言えるかと思います。
+ APIキーが外部に流出するリスクを考慮すると、アプリケーションから直接Google AI Gemini APIを呼び出すことはプロトタイピングのみで推奨され、プロダクション環境では推奨されない
+ 実際のプロダクトで使用する場合はサーバーサイドからGoogle AI Gemini API を呼び出す方が良い

使用場面については細かく考えて実装する必要があるようです。
:::

## 導入
### Flutter, Dart のバージョン更新
Gemini を使用するためには flutter 3.19以上である必要があるため、`flutter upgrade` を実行してバージョンを更新しておく必要があります。
今回の実装時のバージョンは以下のとおりです。
+ Flutter version 3.20.0-2.0.pre.4 on channel master
+ Dart version 3.4.0

### パッケージの導入
[google_generative_ai パッケージ](https://pub.dev/packages/google_generative_ai) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  google_generative_ai: ^0.2.2
```

または

以下をターミナルで実行
```
flutter pub add google_generative_ai
```

## 実装
今回は以下の手順で実装を進めていきます。
1. APIキーの作成
2. APIキーの保存
3. 環境変数を使用する準備
4. main.dart で実行
5. チャットUIを実装

### 1. APIキーの作成
まずは [Google AI Studio](https://aistudio.google.com/app/apikey) にアクセスして、 Get API key > Create API Key で APIキーを発行します。
APIキーが発行できたら安全に控えておきましょう。

### 2. APIキーの保存
次に APIキーを保存します。
キーを保存する方法は .env ファイルを使用する方法や dart-define で保存する方法などがあるかと思います。

今回は .envファイルを使用してキーの保存を行います。
アプリのルートディレクトリに `.env` ファイルを作成して、以下のようにします。
```env
API_KEY = [YOUR_API_KEY]
```

次に Gitの管理から外すために `.gitignore` ファイルに `.env` を追加しておきましょう。
これで保存は完了です。

### 3. 環境変数を使用する準備
次に先程の `.env` ファイルに保存した `API_KEY` を使用するためにパッケージを導入します。
今回は環境変数の管理に [flutter_dotenv パッケージ](https://pub.dev/packages/flutter_dotenv) を使用します。
`pubspec.yaml`に以下を追加

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_dotenv: ^5.1.0
```

またはターミナルで以下を実行しましょう。

```
flutter pub add flutter_dotenv
```

### 4. main.dart で実行
次に main.dart で正常に Gemini にアクセスできるか試してみます。
コードは以下の通りです。
```dart: main.dart
Future main() async {
  await dotenv.load(fileName: ".env").then((value) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null) {
      log('No \$API_KEY environment variable');
      exit(1);
    }

    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
    final content = [Content.text('Write a story about a magic backpack')];
    final response = await model.generateContent(content);
    log(response.text ?? 'No response text');
  });
}
```

`main.dart` に `runApp` を書かないのは非常に違和感がありますが、それぞれ詳しくみていきます。

以下では dotenv で `.env`ファイルを非同期処理で読み込んでいます。
`apiKey` が null の場合はエラーを出力するようにしています。
```dart
await dotenv.load(fileName: ".env").then((value) async {
  final apiKey = dotenv.env['API_KEY'];
  if (apiKey == null) {
    log('No \$API_KEY environment variable');
  }
```

次に以下のコードではモデルの読み込み、質問内容の定義、レスポンスの取得、表示を行っています。
`GenerativeModel` には `model` で `gemini-pro` を指定し、`apiKey` に envファイルから読み込んだキーを渡しています。
`Content.text` では公式サンプルにあるテキストを指定しています。
`model.generateContent` では先程のモデルに対してコンテンツを生成するように指示しており、非同期処理で `response` に代入しています。

```dart
final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
final content = [Content.text('Write a story about a magic backpack')];
final response = await model.generateContent(content);
log(response.text ?? 'No response text');
```

これで実行すると以下のような文章が出力されました。
```
In the quaint town of Willow Creek, nestled amidst rolling hills and whispering willows, there lived a curious young girl named Anya. With a heart filled with imagination and a thirst for adventure, Anya embarked on an extraordinary journey that would forever alter the course of her life.

One fateful evening, as she rummaged through the dusty attic of her grandmother's cottage, Anya stumbled upon a forgotten backpack tucked away in a musty corner. Its faded leather had a patina of time, and an intricate symbol was etched into its worn surface.

As Anya lifted the backpack, an ethereal glow enveloped her. To her astonishment, the symbol on the leather shimmered with an iridescent blue light, and the backpack whispered a gentle, enchanting melody. With trembling hands, she unzipped it, revealing a spacious interior filled with an assortment of extraordinary items.

// 日本語訳
ウィロークリークの風光明媚な町に、アニャという好奇心旺盛な若い女の子が住んでいました。
彼女は想像力に満ち、冒険への渇望を胸に、人生の進路を永遠に変える非凡な旅に出ました。

運命的な夕方、彼女は祖母のコテージのほこりっぽい屋根裏部屋を漁っているとき、
忘れ去られたバックパックをかび臭い隅に隠されているのを見つけました。
その色あせた革には時間の風合いがあり、擦り減った表面には複雑なシンボルが刻まれていました。

アニャがバックパックを持ち上げると、幽玄な光が彼女を包み込みました。
彼女は驚愕しましたが、革の上のシンボルが虹色の青い光で輝き、バックパックが優しい、
魅惑的なメロディを囁きました。
震える手でそれを開けると、様々な非凡なアイテムで満たされた広々とした内部が現れました。
```

「a magic backpack」に関するストーリとして良い物語が生成されているように思います。

ChatGPT に評価してもらうと以下のような好意的な評価が返ってきました。
```
この物語は、魔法のバックパックを中心に展開する冒険物語の要素を巧みに取り入れています。
アニャのキャラクターがどのようにこのバックパックと関わっていくのか、
そしてそれが彼女の人生にどのような変化をもたらすのかについて、読者の好奇心を刺激します。
```

### 5. チャットUIを実装
次は Gemini とチャットできるようなUIを作成していきます。
チャットの実装は以下の手順で進めます。
1. Geminiを管理する Provider の作成
2. チャットを管理する Provider の作成
3. UIに反映

#### 1. Geminiを管理する Provider の作成
まずは Geminiを管理するための Provider を作成していきます。
コードは以下の通りです。

```dart: main.dart
Future main() async {
  await dotenv.load(fileName: ".env");

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GeminiSample(),
    );
  }
}
```
```dart: gemini_provider.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gemini_provider.g.dart';

@riverpod
class GeminiController extends _$GeminiController {
  @override
  void build() {}

  GenerativeModel loadModel() {
    var apiKey = dotenv.get('API_KEY');
    return GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
  }
}
```

それぞれ詳しくみていきます。

`main.dart` では `.env` ファイルを読み込む処理のみを行っています。
```dart: main.dart
await dotenv.load(fileName: ".env");
```

次に `GeminiController` です。今回は Riverpod Generator を用いて実装しています。
以下では先程読み込んだ `.env` ファイルからAPIキーを取得し、それを元にモデルを返却しています。
```dart
var apiKey = dotenv.get('API_KEY');
return GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
```

#### 2. チャットを管理する Provider の作成
次にチャットを管理する Provider の作成です。

今回は以下の二つのパッケージを主に使用してチャットのUIを作成していきます。
`pubspeck.yaml` にそれぞれ追加しておきましょう。
+ [flutter_chat_ui](https://pub.dev/packages/flutter_chat_ui)
+ [flutter_chat_types](https://pub.dev/packages/flutter_chat_types)

チャットを管理する `ChatController` のコードは以下の通りです。
```dart: chat_provider.dart
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sample_flutter/gemini/providers/gemini_provider.dart';

part 'chat_provider.g.dart';

@Riverpod(dependencies: [GeminiController])
class ChatController extends _$ChatController {
  late final ChatSession chat;
  static const gemini = types.User(id: 'gemini');
  static const me = types.User(id: 'me');

  @override
  List<types.Message> build() {
    final model = ref.read(geminiControllerProvider.notifier).loadModel();
    chat = model.startChat();
    return [];
  }

  void addMessage({required types.User author, required String text}) {
    final timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    final message =
        types.TextMessage(author: author, id: timeStamp, text: text);
    state = [message, ...state];
  }

  Future<void> ask({required String question}) async {
    final content = Content.text(question);
    try {
      addMessage(author: me, text: question);
      final response = await chat.sendMessage(content);
      final message = response.text ?? 'Retry later';
      addMessage(author: gemini, text: message);
    } on Exception {
      addMessage(author: gemini, text: 'Retry later');
    }
  }
}
```

それぞれ詳しくみていきます。

以下では Riverpod アノテーションの `dependencies` に先程作成した `GeminiController` を追加しておくことで `ChatController` の中でも Gemini の操作を行えるようにしています。
```dart
@Riverpod(dependencies: [GeminiController])
```

以下では `ChatSession` の遅延初期化とチャットユーザーの定義をしています。
`flutter_chat_ui` では `ChatSession` にメッセージを追加していくことでチャットのUIを構築していきます。今回はGeminiとの対話なので、`gemini`, `me` の二つのユーザーを用意しています。
```dart
late final ChatSession chat;
static const gemini = types.User(id: 'gemini');
static const me = types.User(id: 'me');
```

以下では `ChatController` のビルドメソッド内で Gemini のモデルの読み込みとチャットの開始を実装しています。 `model.startChat()`の返り値は `ChatSession`型なので、遅延初期化した `chat` に当てはめることができます。
また、ビルドメソッドの返り値に `List<types.Message>` を指定することで、`ChatController` の `state` としてメッセージのリストを扱うことができます。
```dart
List<types.Message> build() {
  final model = ref.read(geminiControllerProvider.notifier).loadModel();
  chat = model.startChat();
  return [];
}
```

以下ではメッセージを追加する関数を実装しています。
メッセージの送り主とメッセージ内容を受け取り、`types.TextMessage` に渡しています。
また、`types.TextMessage` の id には現在時刻を文字列にして渡しています。

そして、`message` を `state` に追加することで全体のチャットにメッセージを追加できるようになります。
```dart
void addMessage({required types.User author, required String text}) {
  final timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
  final message = types.TextMessage(author: author, id: timeStamp, text: text);
  state = [message, ...state];
}
```

最後に以下で Gemini に質問する実装を行なっています。
以下の手順でチャットの操作を行なっています。
1. `question` として質問内容を受け取り、送り主が自分であるメッセージとして質問内容を追加
2. `chat.sendMessage` で Gemini に質問を投げかけてレスポンスを取得
3. レスポンスの内容をメッセージに追加
```dart
Future<void> ask({required String question}) async {
  final content = Content.text(question);
  try {
    addMessage(author: me, text: question);
    final response = await chat.sendMessage(content);
    final message = response.text ?? 'Retry later';
    addMessage(author: gemini, text: message);
  } on Exception {
    addMessage(author: gemini, text: 'Retry later');
  }
}
```

これでチャットを管理する Provider の作成は完了です。
`ChatController` の内部では Gemini の操作も行っているため、UI側からは `ChatController` のみを操作だけでよくなっています。

#### 3. UIに反映
最後にチャットのUIを作成していきます。
コードは以下の通りです。
```dart: gemini_sample.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:sample_flutter/gemini/providers/chat_provider.dart';

class GeminiSample extends ConsumerWidget {
  const GeminiSample({super.key});
  static const me = types.User(id: 'me');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatControllerProvider);
    return Scaffold(
      body: Chat(
        user: me,
        messages: messages,
        onSendPressed: (a) {
          ref.read(chatControllerProvider.notifier).ask(question: a.text);
        },
      ),
    );
  }
}
```

以下の部分では、`chatControllerProvider` のビルドメソッドの返り値を `messages` に代入しています。これでメッセージに変更、追加があった際には状態を更新することができます。
```dart
final messages = ref.watch(chatControllerProvider);
```

以下の部分ではチャットのUIを実装しています。
`messages` に `chatControllerProvider` で管理しているメッセージのリストを渡しています。
また、`onSendPressed` で名前の通りメッセージが送信された時の処理を実装しており、今回はメッセージを受け取って `chatControllerProvider` の `ask` に渡すことで Gemini に質問する形になっています。
```dart
Chat(
  user: me,
  messages: messages,
  onSendPressed: (a) {
    ref.read(chatControllerProvider.notifier).ask(question: a.text);
  },
),
```

これで実行してみると以下の動画のようにうまく質問に答えられていることがわかります。

https://youtube.com/shorts/ePBFQFHcUUc?feature=share

今回のコードは以下の GitHub にまとめています。よろしければご覧ください。

https://github.com/Koichi5/sample-flutter/tree/feature/gemini

## まとめ
最後まで読んでいただいてありがとうございました。

今回は Flutter で Gemini を扱う実装を行いました。
今までAPIは公開されていたかと思いますが、pub.devにパッケージとして公開されたことでより Flutter 側から使用しやすくなったかと思います。
flutter_chat_ui も合わせて使用することで非常に手軽に Gemini とのチャットが実装できました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/google_generative_ai

https://zenn.dev/ispec_inc/articles/creating-chat-app-with-google-ai-dart-sdk

https://zenn.dev/daichiyasuda/articles/flutter-gemini-20240219
