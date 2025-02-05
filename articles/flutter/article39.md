# 初めに
今まで Flutter の状態管理に関しては Riverpod を使用していましたが、Riverpod Generator を使う流れも出てきているかと思うので、Riverpod Generator を軽く触ってみて学習内容を共有したいと思います。

# 記事の対象者
+ Flutter 学習者
+ Riverpod を使っている方
+ Riverpod Generator について知りたい方

# 実装
## 導入
以下のパッケージの最新バージョンを `pubspec.yaml`に記述
+ [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
+ [hooks_riverpod](https://pub.dev/packages/hooks_riverpod)
+ [riverpod_annotation](https://pub.dev/packages/riverpod_annotation)
+ [build_runner](https://pub.dev/packages/build_runner)
+ [riverpod_generator](https://pub.dev/packages/riverpod_generator)

```yaml: pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.1
  hooks_riverpod: ^2.4.5
  riverpod_annotation: ^2.1.6

dev_dependencies:
  build_runner: ^2.4.6
  riverpod_generator: ^2.3.3
```

または

以下をターミナルで実行
```
flutter pub add flutter_riverpod hooks_riverpod riverpod_annotation
flutter pub add -d build_runner riverpod_generator
```

## Provider
### 定義
まずは通常の Provider を Riverpod Generator を使って実装してみます。
Riverpod Generator を使うための準備として、以下のように riverpod_annotation のインポートと part の記述を行います。

```dart: hello_world_screen_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hello_world_screen_controller.g.dart';
```

上の例では「Hello World」という文字列を返すだけの Provider を作成するので、ファイル名は `hello_world_screen_controller` としています。

次に Provider の定義を行います。
```dart: hello_world_screen_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'hello_world_screen_controller.g.dart';

@riverpod
String helloWorldScreenController(HelloWorldScreenControllerRef ref) {
  return 'Hello World';
}
```

@riverpod アノテーションをつけることで後述のビルドランナーを実行した際に Provider が自動生成されるようになります。
`HelloWorldScreenControllerRef` に関してはメソッド名をアッパーキャメルケースにしてRefを加えたリファレンス名になります。
作成した Provider では単純に 「Hello World」という文字列を返しています。
この辺りは書き方として覚えて何度も使うしかないかもしれません。

最後に以下のようにビルドランナーを実行すれば Provider のコードが自動生成されます。
```
flutter pub run build_runner build --delete-conflicting-outputs
```

### 呼び出し
```dart: hello_world_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/views/hello_world_screen/providers/hello_world_screen_controller.dart';

class HelloWorldScreen extends ConsumerWidget {
  const HelloWorldScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerValue = ref.watch(helloWorldScreenControllerProvider);
    return Scaffold(
      appBar: AppBar(title: Text(controllerValue)),
      body: Center(child: Text(controllerValue)),
    );
  }
}
```

作成した Provider を呼び出す際は通常の Riverpod の Provider を呼び出す際と同様に watch や read で呼び出すことができます。

## FamilyProvider
### 定義
```dart: family_screen_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'family_screen_controller.g.dart';

@riverpod
int familyScreenController(FamilyScreenControllerRef ref, int num1, int num2) {
  return num1 + num2;
}
```
FamilyProvider では引数を受け取ることができます。
単純な Provider に引数として変数を入れるだけで、Riverpod Generator 側が自動的に判断して FamilyProvider を生成してくれます。
上の例では `num1`、`num2` の二つの int を受け取り、受け取った二つの数を足して返すようにしています。


### 呼び出し
```dart: family_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/views/family_screen/providers/family_screen_controller.dart';

class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const int num1 = 1;
    const int num2 = 10;
    final state = ref.watch(FamilyScreenControllerProvider(num1, num2));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('$num1 + $num2'),
            Text('result: ${state.toString()}')
          ],
        ),
      ),
    );
  }
}
```
上の例のように呼び出す際は通常の Provider 同様 watch、read で呼び出すことができます。
実行してみると以下のように足し算した結果が state として反映されていることがわかります。
![family_notifier_demo](https://storage.googleapis.com/zenn-user-upload/bb3e51ea2cf4-20231101.png =250x)

## FutureProvider
### 定義
```dart: future_screen_controller.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'future_screen_controller.g.dart';

@riverpod
Future<String> futureScreenController(FutureScreenControllerRef ref) async {
  const url = 'https://random-word-api.herokuapp.com/word';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    final randomWord = jsonResponse[0];

    return Future.delayed(const Duration(seconds: 1), () => randomWord);
  } else {
    print('Request failed with status: ${response.statusCode}');
  }
  return 'ERROR';
}
```
上のコードでは「Random Word API」を叩いてレスポンスをデコードして返しています。Future型の返り値を指定することで自動的に FutureProvider を生成することができます。
リファレンス名などの命名規則は先述の Provider と同様です。

### 呼び出し
```dart: future_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/views/future_screen/providers/future_screen_controller.dart';

class FutureScreen extends ConsumerWidget {
  const FutureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(futureScreenControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Future screen',
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            state.when(
              data: (data) => Text(data),
              error: (error, stackTrace) => Text(error.toString()),
              loading: () => const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
```
`final state = ref.watch(futureScreenControllerProvider);` として呼び出した場合、返り値の型は `AsyncValue<String>` となっています。
`state.when` で指定することで `data`、`error`、`loading` の三つの状態に分けることができます。

実際に実行してみると以下のように、ローディングとデータが表示されたときで表示が切り替わっていることがわかります。
![future_provider_demo](https://storage.googleapis.com/zenn-user-upload/149c7b7e0180-20231101.gif =250x)

## StreamProvider
### 定義
```dart: stream_screen_controller.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'stream_screen_controller.g.dart';

@riverpod
Stream<String> streamScreenController(StreamScreenControllerRef ref) async* {
  for (var i = 0; i < 10; i++) {
    const url = 'https://random-word-api.herokuapp.com/word';
    final response = await http.get(
      Uri.parse(url),
    );
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final output = jsonResponse[0] as String;
      yield output;
    }
  }
}
```
返り値をStream型にすることで Riverpod Generator 側が自動的に StreamProvider を生成してくれます。
コードの処理としては「Random Word API」を10回叩きその都度レスポンスの単語を返すという処理をしています。
なお、Streamの場合は `async` ではなく `async*`、`return` ではなく `yield` を使用する点に注意しましょう。

### 呼び出し
```dart: stream_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/views/stream_screen/providers/stream_screen_controller.dart';

class StreamScreen extends ConsumerWidget {
  const StreamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(streamScreenControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Stream Screen',
        ),
      ),
      body: Center(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          state.when(
            data: (data) => Text(data),
            error: (error, stackTrace) => Text(error.toString()),
            loading: () => const CircularProgressIndicator(),
          ),
        ],
      )),
    );
  }
}
```

`final state = ref.watch(streamScreenControllerProvider);` として呼び出した場合、返り値の型は `AsyncValue<String>` となっています。
`state.when` で指定することで FutureProvider と同様に `data`、`error`、`loading` の三つの状態に分けることができます。

実際に実行してみると以下のように表示されている単語が切り替わることがわかります。
![stream_provider_demo](https://storage.googleapis.com/zenn-user-upload/f346431f27e8-20231101.gif =250x)

## NotifierProvider
### 定義
```dart: notifier_screen_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notifier_screen_controller.g.dart';

@riverpod
class NotifierScreenController extends _$NotifierScreenController {
  @override
  int build() => 0;

  void increment() {
    state++;
  }

  void decrement() {
    state--;
  }
}
```

Notifier に関しては `_$NotifierScreenController` のように作成したい Provider名に `_$` をつけた形にします。
build メソッドでは Notifier で管理する値の型とその初期値を定義することができます。
上の例では管理する型は int、初期値は 0 にしています。

また、管理している状態には `state` でアクセスすることができ、上の例では値を１ずつ増加させる `increment` 関数と１ずつ減少させる `decrement` 関数を実装しています。

### 呼び出し
```dart: notifier_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/views/notifier_screen/providers/notifier_screen_controller.dart';

class NotifierScreen extends ConsumerWidget {
  const NotifierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notifierScreenControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stream Screen')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('$state', style: const TextStyle(fontSize: 20),)],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'increment',
            onPressed: () {
              ref.read(notifierScreenControllerProvider.notifier).increment();
            },
            child: const Icon(Icons.add),
          ),
          const SizedBox(
            width: 20,
          ),
          FloatingActionButton(
            heroTag: 'decrement',
            onPressed: () {
              ref.read(notifierScreenControllerProvider.notifier).decrement();
            },
            child: const Icon(Icons.remove),
          ),
        ],
      ),
    );
  }
}
```
管理している状態を呼び出す際は作成した NotifierProvider を watch、read することで現在の状態を呼び出すことができます。
NotifierProvider で作成した関数は watch、read で作成した NotifierProvider の `notifier` を読み取り、そこで実行したい関数を指定することで呼び出すことができます。

`NotifierScreen` をみると以下のようにうまく値が変動していることがわかります。
![notifier_provider_demo](https://storage.googleapis.com/zenn-user-upload/cf5ef4820fad-20231101.gif =250x)

## AsyncNotifierProvider
### 定義
```dart: async_notifier_screen_controller.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'async_notifier_screen_controller.g.dart';

@riverpod
class AsyncNotifierScreenController extends _$AsyncNotifierScreenController {
  @override
  Future<String> build() async {
    const url = 'https://random-word-api.herokuapp.com/word';
    final response = await http.get(
      Uri.parse(url),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final randomWord = jsonResponse[0];
      return randomWord;
    }
    return '';
  }

  Future<String> getNewWord() async {
    const url = 'https://random-word-api.herokuapp.com/word';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      final randomWord = jsonResponse[0];
      return randomWord;
    } else {
      print('Request failed with status: ${response.statusCode}');
    }
    return 'ERROR';
  }

  Future<void> setNewWord() async {
    state = const AsyncLoading();
    state = AsyncValue.data(await getNewWord());
  }

  void deleteWord() {
    state = const AsyncValue.data('');
  }
}
```
上記の例では FutureProviderと同様に「Random Word API」に対してリクエストを送り、レスポンスを表示させる処理を実装しています。NotifierProvider の実装との違いは `build` の返り値が `Future`型になっていることです。
返り値が `Future`型の場合は Riverpod Generator の方で自動的に AsyncNotifier を生成するようになっています。

その他のコードとしては、build の段階で「Random Word API」を叩いてレスポンスをデコードして返しています。
また、以下の三つの関数を実装しています。
+ `getNewWord`：新たな単語を取りに行く関数
+ `setNewWord`：新たな単語を取得してそれを反映させる
+ `deleteWord`：stateを空の文字列にすることで単語を消す

### 呼び出し
```dart: async_notifier_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/views/async_notifier_screen/providers/async_notifier_screen_controller.dart';

class AsyncNotifierScreen extends ConsumerWidget {
  const AsyncNotifierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(asyncNotifierScreenControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AsyncNotifier Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            state.when(
                data: (data) => Text(data),
                error: (error, stackTrace) => Text(error.toString()),
                loading: () => const CircularProgressIndicator())
          ],
        ),
      ),
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            label: const Icon(Icons.add),
            heroTag: 'get',
            onPressed: () {
              ref
                  .read(asyncNotifierScreenControllerProvider.notifier)
                  .setNewWord();
            },
          ),
          const SizedBox(
            width: 20,
          ),
          FloatingActionButton.extended(
            label: const Icon(Icons.delete),
            heroTag: 'delete',
            onPressed: () {
              ref
                  .read(asyncNotifierScreenControllerProvider.notifier)
                  .deleteWord();
            },
          ),
        ],
      ),
    );
  }
}
```

`final state = ref.watch(asyncNotifierScreenControllerProvider);` として呼び出した場合、返り値の型は `AsyncValue<String>` となっています。
`state.when` で指定することで FutureProvider と同様に `data`、`error`、`loading` の三つの状態に分けることができます。

`AsyncNotifierScreen` を実行すると以下のように API から単語を取得することができます。
![async_notifier_demo](https://storage.googleapis.com/zenn-user-upload/7be3bcaf7c88-20231101.gif =250x)


## まとめ
最後まで読んでいただいてありがとうございました。
今回はそれぞれの代表的な Provider を Riverpod Generator で生成して呼び出しまで実装してみました。まだ `keepAlive` など解説できていない部分もあるので、今後追加していきたいと思います。

### 参考
https://pub.dev/packages/riverpod_generator