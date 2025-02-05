## 初めに
今回は [flutter_secure_storage パッケージ](https://pub.dev/packages/flutter_secure_storage) を使用して、ローカルにデータを保存する実装を行いたいと思います。

## 記事の対象者
+ Flutter 学習者
+ ローカルにデータを保存する実装を行いたい方
+ 他のローカルデータベースとの比較を知りたい方

## 目的
今回は上記の通り、flutter_secure_storage を使ってモバイルのローカルにデータを保存する実装を行うことを目的とします。また、最終的には以下の動画のようにデータを作成、変更、削除できるような実装を行います。なお、動画ではリロードしたタイミングで「リロード」と表示させています。

https://youtube.com/shorts/MgPV2x11iX4

## flutter_secure_storage とは
flutter_secure_storage とは、公式ドキュメントによると「セキュアなストレージにデータを保存するためのAPIを提供する。iOSではKeychainが使われ、AndroidではKeyStoreベースのソリューションが使われる。」とされています。

SharedPreference などでもデータを保存できますが、SharedPreference では、iOS はNSUserDefaultsに、Android は SharedPreference にデータを保存します。
一方 flutter_secure_storage では、ドキュメントにある通り、iOS は Keychain に、Android は Keystore にデータを保存します。

iOS の Keychain では、[ドキュメント](https://support.apple.com/ja-jp/guide/security/secb0694df1a/web)によると、「キーチェーン項目は、表のキー（メタデータ）と行ごとのキー（秘密鍵）という2つの異なるAES-256-GCMキーを使用して暗号化されます。」とあり、暗号化されて格納されます。
Android の Keystore では、[ドキュメント](https://developer.android.com/training/articles/keystore?hl=ja)によると、「Android Keystore システムを使用すると、暗号鍵をコンテナ内に格納することで、デバイスからキーを抽出するのを難しくすることができます。」とあり、こちらも暗号鍵を格納することで、安全にデータを保存できるようにしています。

## 導入
[flutter_secure_storage パッケージ](https://pub.dev/packages/flutter_secure_storage) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_secure_storage: ^9.0.0
```

または

以下をターミナルで実行
```
flutter pub add flutter_secure_storage
```

:::message
今回は Riverpod generator を使用するため、周辺パッケージが追加されていない場合は以下のように追加してください。

```yaml: pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.10
  riverpod_annotation: ^2.3.4
  hooks_riverpod: ^2.4.10
  flutter_secure_storage: ^9.0.0

dev_dependencies:
  riverpod_generator: ^2.3.11
  build_runner: ^2.4.8
```

または

以下をターミナルで実行
```
flutter pub add flutter_riverpod riverpod_annotation hooks_riverpod flutter_secure_storage
flutter pub add -d riverpod_generator build_runner
```
:::

## 実装
実装は以下の流れで進めていきます。
1. データの操作を行うための Notifier を作成
2. main.dartの変更
3. データ操作を行うためのUI作成

### 1. データの操作を行うための Notifier を作成
まずは、データの操作を行う Notifier を Riverpod generator で作成していきます。
コードは以下のようになります。
```dart: flutter_secure_storage_provider.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'flutter_secure_storage_provider.g.dart';

@riverpod
class FlutterSecureStorageController extends _$FlutterSecureStorageController {
  late final FlutterSecureStorage storage;

  @override
  void build() {
    storage = const FlutterSecureStorage();
  }

  Future<void> setValue({required String key, required String value}) async {
    await storage.write(key: key, value: value);
  }

  Future<String?> getValue({required String key}) async {
    return await storage.read(key: key);
  }

  Future<Map<String, String>> getAllValue() async {
    return await storage.readAll();
  }

  Future<void> deleteValue({required String key}) async {
    await storage.delete(key: key);
  }

  Future<void> deleteAllValue() async {
    await storage.deleteAll();
  }
}
```

それぞれのコードを詳しくみていきます。

#### storage の遅延初期化と build メソッド
以下のコードでは、二つの実装をしています。
+ `FlutterSecureStorage` を遅延初期化で定義
+ build メソッド内で `FlutterSecureStorage` をインスタンス化

この実装により、 `storage` 変数にアクセスすれば、データの操作が行えるようになります。
```dart
late final FlutterSecureStorage storage;

@override
void build() {
  storage = const FlutterSecureStorage();
}
```

#### 値の保存
以下の部分では、値の保存を行う関数を実装しています。
このパッケージでは、「データの作成」と「データの更新」はともに `write` メソッドで実現できます。
また、 Drift や ObjectBox と異なり、Key-Value の一対一の関係でデータを保存するため、データ構造の定義などは必要なく。以下のように関数の中で `key`, `value` を受け取り、引数に渡すことで保存することができます。
```dart
Future<void> setValue({required String key, required String value}) async {
  await storage.write(key: key, value: value);
}
```

#### 値の取得
以下の部分では、値の取得を行う関数を実装しています。
このパッケージでは、「データの読み取り」は `read` メソッドで実現できます。
`key` を引数として渡すことで、それに対応する　　`value` を返却してくれます。
```dart
Future<String?> getValue({required String key}) async {
  return await storage.read(key: key);
}
```

#### 全ての値の取得
以下の部分では、全ての値の取得を行う関数を実装しています。
返却される値の型は、`Future<Map<String, String>>` であり、非同期で処理を行うことで、追加している全てのデータの `key` と `value` を `Map` 型で受け取ることができます。
```dart
Future<Map<String, String>> getAllValue() async {
  return await storage.readAll();
}
```

#### 値の削除
以下の部分では、値の削除を行う関数を実装しています。
`read` メソッドと同じように、`key` を引数として渡すことで、それに対応する `value` を削除することができます。
```dart
Future<void> deleteValue({required String key}) async {
  await storage.delete(key: key);
}
```

#### 全ての値の削除
以下の部分では、全ての値の削除を行う関数を実装しています。
`deleteAll` 関数を実行することで、保存されている全てのデータを削除することができます。
```dart
Future<void> deleteAllValue() async {
  await storage.deleteAll();
}
```

上記のような Notifier の定義ができたら、以下をターミナルで実行して、コードを生成しておきましょう。
```
flutter pub run build_runner build
```

### 2. main.dartの変更
次に、`main.dart` を以下のように変更しておきます。
今回は Riverpod generator を使用しているため、 `MyApp` を `ProviderScope` で囲んでおきます。また、`FlutterSecureStorageSample` でデータの操作を行うUIを作成します。
```dart: main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/flutter_secure_storage/view/flutter_secure_storage_sample.dart';

void main() {
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
      home: FlutterSecureStorageSample(),
    );
  }
}
```

### 3. データ操作を行うためのUI作成
最後に、データ操作を行うための実装を行います。
先程 `MyApp` の `home` に指定した `FlutterSecureStorageSample` を以下のようにします。
```dart: flutter_secure_storage_sample.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/flutter_secure_storage/provider/flutter_secure_storage_provider.dart';

class FlutterSecureStorageSample extends ConsumerWidget {
  const FlutterSecureStorageSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nicknameController = TextEditingController();
    final passwordController = TextEditingController();
    const userNicknameKey = 'user_nickname';
    const userPasswordKey = 'user_password';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('データ'),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: FutureBuilder<Map<String, String>>(
                  future: ref
                      .watch(flutterSecureStorageControllerProvider.notifier)
                      .getAllValue(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Text('データがありません');
                    }
                    final data = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        String key = data.keys.elementAt(index);
                        dynamic value = data[key];
                        return ListTile(
                          title: Text(key),
                          subtitle: Text(
                            value.toString(),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'ニックネーム',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 0.5,
                        style: BorderStyle.none,
                      ),
                    ),
                  ),
                  controller: nicknameController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'パスワード',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 0.5,
                        style: BorderStyle.none,
                      ),
                    ),
                  ),
                  controller: passwordController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(
                                flutterSecureStorageControllerProvider.notifier)
                            .setValue(
                              key: userNicknameKey,
                              value: nicknameController.text,
                            );
                      },
                      child: const Text(
                        'ニックネームを保存',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(
                                flutterSecureStorageControllerProvider.notifier)
                            .setValue(
                              key: userPasswordKey,
                              value: passwordController.text,
                            );
                      },
                      child: const Text(
                        'パスワードを保存',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(
                                flutterSecureStorageControllerProvider.notifier)
                            .deleteValue(key: userNicknameKey);
                      },
                      child: const Text(
                        'ニックネームを削除',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await ref
                            .read(
                                flutterSecureStorageControllerProvider.notifier)
                            .deleteValue(key: userPasswordKey);
                      },
                      child: const Text(
                        'パスワードを削除',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () async {
                    await ref
                        .read(flutterSecureStorageControllerProvider.notifier)
                        .deleteAllValue();
                  },
                  child: const Text(
                    '全データを削除',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

それぞれの実装を詳しくみていきます。

#### テキストフィールドのコントローラーとキーの定義
以下では、ニックネームとパスワードのテキストフィールドの内容を保持するコントローラーと、データを保存する際のキーを定義しています。
```dart
final nicknameController = TextEditingController();
final passwordController = TextEditingController();
const userNicknameKey = 'user_nickname';
const userPasswordKey = 'user_password';
```

#### FutureBuilder で表示
以下では、先程定義した Notifier の `getAllValue` メソッドを、 `FutureBuilder` の `future` に指定し、返り値を `snapshot` で管理しています。
`ListView.builder`, `ListTile` で取得したデータの `key` を `title`, `value` を `subtitle` に指定して表示しています。
```dart
FutureBuilder<Map<String, String>>(
  future: ref.watch(flutterSecureStorageControllerProvider.notifier)
            .getAllValue(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Text('データがありません');
    }
    final data = snapshot.data!;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: data.length,
      itemBuilder: (context, index) {
        String key = data.keys.elementAt(index);
        dynamic value = data[key];
        return ListTile(
          title: Text(key),
          subtitle: Text(
            value.toString(),
          ),
        );
      },
    );
  },
),
```

#### テキストフィールドの実装
以下ではニックネームのテキストフィールドを実装しています。
`controller` には先程定義した `nicknameController` を指定しています。
パスワードのテキストフィールドも同様です。
```dart
TextField(
  decoration: InputDecoration(
    hintText: 'ニックネーム',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(
        width: 0.5,
        style: BorderStyle.none,
      ),
    ),
  ),
  controller: nicknameController,
),
```

#### 値の保存
以下では `setValue` 関数にキーとテキストフィールドのコントローラーの値を渡すことで、データを保存しています。
パスワードについても同様の実装です。
```dart
ElevatedButton(
  onPressed: () async {
    await ref.read(flutterSecureStorageControllerProvider.notifier)
        .setValue(
          key: userNicknameKey,
          value: nicknameController.text,
        );
  },
  child: const Text(
    'ニックネームを保存',
  ),
),
```

#### 値の削除
以下では、`deleteValue` 関数にキーを渡すことで、データを削除しています。
パスワードについても同様の実装です。
```dart
ElevatedButton(
  onPressed: () async {
    await ref.read(flutterSecureStorageControllerProvider.notifier)
      .deleteValue(key: userNicknameKey);
  },
  child: const Text(
    'ニックネームを削除',
  ),
),
```

#### 全ての値の削除
以下では、`deleteAllValue` 関数で全ての値を削除しています。
```dart
ElevatedButton(
  onPressed: () async {
    await ref.read(flutterSecureStorageControllerProvider.notifier)
      .deleteAllValue();
  },
  child: const Text(
    '全データを削除',
  ),
),
```

これで、以下の動画のような実装ができるかと思います。

https://youtube.com/shorts/MgPV2x11iX4

## まとめ
最後まで読んでいただいてありがとうございました。

今回は flutter_secure_storage の実装を行いました。
key と value で簡単に値を保存、取得、削除できて、安全にデータの管理ができるため、非常に使いやすかったです。
一方で、複雑なデータの格納などはできないため、そのような場合には別のデータベースが必要です。 Stream 型を返り値にもつ関数が用意されていないことからも、頻繁に変更されるものではなく、また変更を監視するためのものでもないということがわかり、Drift や ObjectBox などのデータベースとは用途が異なることがわかります。
また、iOSに関して、アプリが削除されても flutter_secure_storage に保存されたデータは削除されないまま保持され、削除するためには別の施策が必要なようなので、その辺りも注意が必要であると感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/flutter_secure_storage

https://medium.com/@omer28gunaydin/flutter-secure-storage-f772186ac8d3

iOS Keychain
https://support.apple.com/ja-jp/guide/security/secb0694df1a/web

Android Keystore
https://developer.android.com/training/articles/keystore?hl=ja