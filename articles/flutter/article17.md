## 初めに
今回は Flutter の開発において普段利用しているVSCodeのスニペットの内容を簡単に共有します。

## 記事の対象者
+ Flutter 学習者
+ 効率的に Flutter での開発を行いたい方

:::message
今回はVSCodeのスニペットを使用するため、その他のエディタでは設定できない可能性がありますので、ご注意ください。
:::

## 目的
すでに利用されている方もいるかと思いますが、今回は Flutter 開発で活用できるスニペットを共有することで、頻繁に利用するコードを登録しておき、ゼロから書くより効率的に開発できるようにすることを目的とします。

## 準備
まずは VSCode で Flutter のプロジェクトを開きます。
一度設定したスニペットは VSCode を使用する限りどのプロジェクトでも使用できるため、ここで開くプロジェクトは特に制限はありません。
![](https://storage.googleapis.com/zenn-user-upload/55a804811951-20240520.png)

次に上部のバーに `> Snippets: Configure User Snippets` と入力し、サジェストに出てきた項目を押します。この時、`>` が抜けてしまうとサジェストに表示されないため注意してください。

![](https://storage.googleapis.com/zenn-user-upload/6e58961947f6-20240520.png)

次にどのスニペットを作成するか聞かれるので、 `dart.json(Dart)` を押します。
![](https://storage.googleapis.com/zenn-user-upload/67e679516ce3-20240520.png)

すると、`dart.json` というファイルが開かれた状態になります。
ここでスニペットを作成することができます。

## スニペット編集
準備が整ったのでスニペットを編集していきます。

### StatelessWidget の実装例
まずは `StatelessWidget` のスニペットを作成してみたいと思います。
実は、`StatelessWidget` や `StatefullWidget` のスニペットはすでに用意されているものがありますが、スニペットを試す例として実装してみます。
すでにスニペットを使用している方は読み飛ばしてください。
スニペットのコードは以下の通りです。
```json: dart.json
{
	"stateless_widget": {
		"prefix": "snippets_stateless_widget",
		"body": [
			"import 'package:flutter/material.dart';",
			"",
			"class ${1:MyWidget} extends StatelessWidget {",
			"  const ${1:MyWidget}({super.key});",
			"",
			"  @override",
			"  Widget build(BuildContext context) {",
			"    return const ${2:Placeholder()};",
			"  }",
			"}"
		],
	},
}
```

`dart.json` の変更内容を保存して、dart ファイルで `snippets_stateless_widget` と入力して Enter を押すと以下のようなコードが記述されます。
そして、コードが記述された状態のまま文字を打ち込むと `MyWidget` の部分が打ち込んだ文字に変更されます。
さらに、Tabキーを押すと、カーソルが `Placeholder()` に移動して、そこでも内容を変更することができます。
```dart
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
```

具体的な手順として以下の手順を実行した場合、記述されるコードは以下のようなものになります。
1. dartファイルで `snippets_stateless_widget` と入力して Enter
2. `SampleWidget` と入力して Tab キーを押下
3. `Scaffold()` と入力

```dart
import 'package:flutter/material.dart';

class SampleWidget extends StatelessWidget {
  const SampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
```

このように非常に少ないステップで利用頻度の高いコードを簡単に記述できるようになります。
スニペットの挙動がわかったところで、作成した `dart.json` の内容を少し詳しくみていきます。

以下の部分では、 `dart.json` 内でそれぞれのスニペットを区別するための名前を定義しています。
他のスニペットと被らない名前にする必要があります。
```json: dart.json
"stateless_widget": {
```

以下ではスニペットの `prefix` を指定しています。この `prefix` に指定されている文字列を dartファイル内で入力することで、登録されているスニペットを呼び出すことができます。
```json: dart.json
"prefix": "snippets_stateless_widget",
```

以下ではスニペットが呼び出された時に実際に記述されるコードの内容を定義しています。
`${1:MyWidget}` となっている部分では、呼び出した際に一番初めにカーソルが当たるようになります。また、コードの初期値として `MyWidget` が割り当てられるようになっています。
`${2:Placeholder()}` となっている部分では、Tabキーが押された時にカーソルが当たるようになります。初期値として `Placeholder()` が割り当てられています。
```json: dart.json
"body": [
    "import 'package:flutter/material.dart';",
    "",
    "class ${1:MyWidget} extends StatelessWidget {",
    "  const ${1:MyWidget}({super.key});",
    "",
    "  @override",
    "  Widget build(BuildContext context) {",
    "    return const ${2:Placeholder()};",
    "  }",
    "}"
],
```

### その他の実装例
次に筆者が利用しているスニペットの実装例を提示します。

実装例は以下の通りです。
+ Riverpod Generator
  - Provider
  - FutureProvider
  - StreamProvider
  - Notifier
  - AsyncNotifier
+ Freezed
  - Freezed
  - Freezed（ファイル名から作成）
+ Riverpod, Hooks
  - ConsumerWidget
  - HookWidget
  - HookConsumerWidget

なお、以下の例では全てのスニペットに関して、全て `main.dart` ファイルで実行しています。
したがって、ファイル名を元にコードを生成するスニペットの場合は `main.dart` を元に生成されます。
また、スニペットの実行にあたって、生成内容に必要なパッケージのパスも含まれているため、`riverpod_annotation` や `flutter_hooks` などのパッケージがプロジェクトに含まれていない場合はエラーになるので、ご注意ください。

#### Provider
```json: dart.json
	"provider_gen": {
		"prefix": "snippets_provider_gen",
		"body": [
			"import 'package:riverpod_annotation/riverpod_annotation.dart';",
			"",
			"part '${TM_FILENAME_BASE}.g.dart';",
			"",
			"@riverpod",
			"void ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/lowcase}${3:/upcase}/g}Controller(${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g}ControllerRef ref) {",
			"  return null;",
			"}"
		],
	},
```

```dart: main.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

@riverpod
void mainController(MainControllerRef ref) {
  return null;
}
```

上記の Provider はファイル名をもとに生成しており、生成された Provider は必ず `〇〇Controller` という名前になるようにしています。
必要に応じて自分で入力するように変更したり、`Controller` の部分を削除したりして使いやすいように変更してください。

#### FutureProvider
```json: dart.json
	"future_provider_gen": {
		"prefix": "snippets_future_provider_gen",
		"body": [
			"import 'package:riverpod_annotation/riverpod_annotation.dart';",
			"",
			"part '${TM_FILENAME_BASE}.g.dart';",
			"",
			"@riverpod",
			"Future<void> ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/lowcase}${3:/upcase}/g}Controller(${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g}ControllerRef ref) async {",
			"  return null;",
			"}"
		],
	},
```

`main.dart` ファイルで `snippets_future_provider_gen` と入力して Enter を押すと以下のように FutureProvider のテンプレートが生成されます。
```dart: main.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

@riverpod
Future<void> mainController(MainControllerRef ref) async {
  return null;
}
```

#### StreamProvider
```json: dart.json
	"stream_provider_gen": {
		"prefix": "snippets_stream_provider_gen",
		"body": [
			"import 'package:riverpod_annotation/riverpod_annotation.dart';",
			"",
			"part '${TM_FILENAME_BASE}.g.dart';",
			"",
			"@riverpod",
			"Stream<void> ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/lowcase}${3:/upcase}/g}Controller(${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g}ControllerRef ref) async* {",
			"  yield null;",
			"}"
		],
	},
```

`main.dart` ファイルで `snippets_stream_provider_gen` と入力して Enter を押すと以下のように StreamProvider のテンプレートが生成されます。

```dart: main.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

@riverpod
Stream<void> mainController(MainControllerRef ref) async* {
  yield null;
}
```

#### Notifier
```json: dart.json
	"notifier_gen": {
		"prefix": "snippets_notifier_gen",
		"body": [
			"import 'package:riverpod_annotation/riverpod_annotation.dart';",
			"",
			"part '${TM_FILENAME_BASE}.g.dart';",
			"",
			"@riverpod",
			"class ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g} extends _$${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g} {",
			"",
			"  @override",
			"  void build () {}",
			"}"
		],
	},
```

`main.dart` ファイルで `snippets_notifier_gen` と入力して Enter を押すと以下のように Notifier のテンプレートが生成されます。

```dart: main.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

@riverpod
class Main extends _$Main {

  @override
  void build () {}
}
```

#### AsyncNotifier
```json: dart.json
	"async_notifier_gen": {
		"prefix": "snippets_async_notifier_gen",
		"body": [
			"import 'package:riverpod_annotation/riverpod_annotation.dart';",
			"",
			"part '${TM_FILENAME_BASE}.g.dart';",
			"",
			"@riverpod",
			"class ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g} extends _$${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g} {",
			"",
			"  @override",
			"  FutureOr<void> build () async {}",
			"}"
		],
	},
```

`main.dart` ファイルで `snippets_async_notifier_gen` と入力して Enter を押すと以下のように AsyncNotifier のテンプレートが生成されます。

```dart: main.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'main.g.dart';

@riverpod
class Main extends _$Main {

  @override
  FutureOr<void> build () async {}
}
```

#### Freezed
```json: dart.json
	"freezed": {
		"prefix": "snippets_freezed",
		"body": [
			"import 'package:freezed_annotation/freezed_annotation.dart';",
			"",
			"part '${TM_FILENAME_BASE}.freezed.dart';",
			"part '${TM_FILENAME_BASE}.g.dart';",
			"",
			"@freezed",
			"abstract class ${3:${2/(?:^|-|_|\\.)(\\w)/${1:/upcase}/g}} with _$${3:${2/(?:^|-|_|\\.)(\\w)/${1:/upcase}/g}} {",
			"    const factory ${3:${2/(?:^|-|_|\\.)(\\w)/${1:/upcase}/g}}({",
			"      required String ${2/(?:^|-|_|\\.)(\\w)/${1:/downcase}${2:/upcase}/g}Id,",
			"    }) = _${3:${2/(?:^|-|_|\\.)(\\w)/${1:/upcase}/g}};",
			"",
			"    const ${3:${2/(?:^|-|_|\\.)(\\w)/${1:/upcase}/g}}._();",
			"",
			"    factory ${3:${2/(?:^|-|_|\\.)(\\w)/${1:/upcase}/g}}.fromJson(Map<String, dynamic> json) => _$${3:${2/(?:^|-|_|\\.)(\\w)/${1:/upcase}/g}}FromJson(json);",
			"}",
			""
		],
	},
```

`main.dart` ファイルで `snippets_freezed` と入力し、コードが生成された後 `Sample` と入力することで、`Sample` クラスを作成しています。
```dart: main.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main.freezed.dart';
part 'main.g.dart';

@freezed
abstract class Sample with _$Sample {
    const factory Sample({
      required String SampleId,
    }) = _Sample;

    const Sample._();

    factory Sample.fromJson(Map<String, dynamic> json) => _$SampleFromJson(json);
}
```


#### Freezed（ファイル名から作成）
```json: dart.json
	"freezed_file_name": {
		"prefix": "snippets_freezed_file_name",
		"body": [
			"import 'package:freezed_annotation/freezed_annotation.dart';",
			"",
			"part '${TM_FILENAME_BASE}.freezed.dart';",
			"part '${TM_FILENAME_BASE}.g.dart';",
			"",
			"@freezed",
			"abstract class ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g} with _$${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g} {",
			"    const factory ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g}({",
			"        required String ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/lowcase}${3:/upcase}/g}Id,",
			"    }) = _${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g};",
			"",
			"    const ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g}._();",
			"",
			"    factory ${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g}.fromJson(Map<String, dynamic> json) => _$${TM_FILENAME_BASE/((^[a-z])|_([a-z]))/${2:/upcase}${3:/upcase}/g}FromJson(json);",
			"}",
			""
		],
	},
```

`main.dart` ファイルで `snippets_freezed_file_name` と入力することでファイル名から以下のようなクラスを生成することができます。
```dart: main.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'main.freezed.dart';
part 'main.g.dart';

@freezed
abstract class Main with _$Main {
    const factory Main({
        required String mainId,
    }) = _Main;

    const Main._();

    factory Main.fromJson(Map<String, dynamic> json) => _$MainFromJson(json);
}
```

#### ConsumerWidget
```json: dart.json
	"consumer_widget": {
		"prefix": "snippets_consumer_widget",
		"body": [
			"import 'package:flutter/material.dart';",
			"import 'package:flutter_riverpod/flutter_riverpod.dart';",

			"",
			"class ${1:MyWidget} extends ConsumerWidget {",
			"  const ${1:MyWidget}({super.key});",
			"",
			"  @override",
			"  Widget build(BuildContext context, WidgetRef ref) {",
			"    return const ${2:Placeholder()};",
			"  }",
			"}"
		  ],
	},
```

`main.dart` で `snippets_consumer_widget` と入力し、コードが生成されたら、`SampleWidget` として Widget名を入力し、Tabキーを押してから `Scaffold()` と入力すると以下のようになります。
```dart: main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SampleWidget extends ConsumerWidget {
  const SampleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold();
  }
}
```

#### HookWidget
```json: dart.json
	"hook_widget": {
		"prefix": "snippets_hook_widget",
		"body": [
			"import 'package:flutter/material.dart';",
			"import 'package:flutter_hooks/flutter_hooks.dart';",
			"",
			"class ${1:MyWidget} extends HookWidget {",
			"  const ${1:MyWidget}({super.key});",
			"",
			"  @override",
			"  Widget build(BuildContext context) {",
			"    return const ${2:Placeholder()};",
			"  }",
			"}"
		  ],
	},
```

`main.dart` で `snippets_hook_widget` と入力し、コードが生成されたら、`SampleWidget` として Widget名を入力し、Tabキーを押してから `Scaffold()` と入力すると以下のようになります。

```dart: main.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SampleWidget extends HookWidget {
  const SampleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
```

#### HookConsumerWidget
```json: dart.json
	"hook_consumer_widget": {
		"prefix": "snippets_hook_consumer_widget",
		"body": [
			"import 'package:flutter/material.dart';",
			"import 'package:flutter_hooks/flutter_hooks.dart';",
			"import 'package:hooks_riverpod/hooks_riverpod.dart';",
			"",
			"class ${1:MyWidget} extends HookConsumerWidget {",
			"  const ${1:MyWidget}({super.key});",
			"",
			"  @override",
			"  Widget build(BuildContext context, WidgetRef ref) {",
			"",
			"    useEffect(() {}, const []);",
			"",
			"    return const ${2:Placeholder()};",
			"  }",
			"}"
		  ],
	},
```

`main.dart` で `snippets_hook_consumer_widget` と入力し、コードが生成されたら、`SampleWidget` として Widget名を入力し、Tabキーを押してから `Scaffold()` と入力すると以下のようになります。

```dart: main.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SampleWidget extends HookConsumerWidget {
  const SampleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    useEffect(() {}, const []);

    return const Scaffold();
  }
}
```

以上です。

今回はスニペットを呼び出す際に他のコードと混同しないように `prefix` に `snippets_` をつけることで区別していましたが、慣れてくると無くして使用しても良いかなと思いました。

## まとめ
最後まで読んでいただいてありがとうございました。

個人的な感想ですが、スニペットを利用するメリットとデメリットは以下のようになるかと思います。

メリット
+ 頻繁に使用するコードを効率的に書くことができるようになる
+ 開発チーム内で共有すれば、コードの書き方がある程度共通化できる
+ 適切に運用することでタイプミスを減らすことができる

デメリット
+ スニペット自体の記法の学習コストがかかる
+ スニペット自体が間違っていた時にスニペット自体と生成されたコードの修正コストがかかる
+ 通常のコードの書き方を忘れてしまい、他のエディタを使用するなどでスニペットが使用できなくなった時に困る可能性がある
+ ChatGPT などに聞けばある程度スニペットが書けるため、完全に理解せずとも使えてしまう

自分自身でもまだ理解が浅い部分もあるので、誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

今回紹介したスニペット以外にも [VSCodeのドキュメント](https://code.visualstudio.com/docs/editor/userdefinedsnippets) でより詳しくまとめてあったので、より深く知りたい方はご覧ください。

### 参考

https://zenn.dev/miz_dev/articles/157a7aaad0bdcf

https://code.visualstudio.com/docs/editor/userdefinedsnippets

