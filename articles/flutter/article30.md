## 初めに
今回は [shared_preferences](https://pub.dev/packages/shared_preferences) を使ってローカルにデータを保存する実装を行います。

## 記事の対象者
+ Flutter 学習者
+ ローカルにデータを保存する実装を行いたい方
+ 他のローカルデータベースとの違いを知りたい方

## 目的
今回は先述の通り、 shared_preferences を用いてローカルへのデータを保存する実装を行うことを目的とします。また、この記事では以下のような実装も行います。
+ 様々な型のデータを扱う実装
+ ライトモード / ダークモードの切り替え

## shared_preferences とは
[公式ドキュメント](https://pub.dev/packages/shared_preferences)をみると以下のような記述がありました。
> 単純なデータ（iOSとmacOSのNSUserDefaults、AndroidのSharedPreferencesなど）のためのプラットフォーム固有の永続ストレージをラップします。データは非同期にディスクに永続化される可能性があり、復帰後に書き込みがディスクに永続化される保証はないため、このプラグインは重要なデータの保存には使用しないでください。
サポートされているデータ型は int、double、bool、String、List<String> です。

つまり、以下の点を押さえておく必要がありそうです。
+ 単純なデータを永続ストレージに保存することができる
+ iOS、macOS では NSUserDefaults、Android では SharedPreferences を使用している
+ データの書き込みがディスクに永続化される保証がないため、重要なデータの保存には使用しないこと

[flutter_secure_storage の記事](https://zenn.dev/koichi_51/articles/cb9b899ae47c7f) を振り返り、比較すると以下のようになるかと思います。

共通点
+ key-value 形式でデータを保存すること

相違点
+ iOS の保存先に関して、shared_preferences では NSUserDefaults、 flutter_secure_storage では Keychain
+ Android の保存先に関して、shared_preferences では SharedPreferences、flutter_secure_storage では Keystore
+  shared_preferences では int, double なども保存できるのに対して、flutter_secure_storage では基本的には String で保存する
+ iOS に関して、shared_preferences ではアプリが削除されたら、登録されていたデータも削除されるのに対して、flutter_secure_storage ではアプリ削除後もデータが残る

データの保存先が二つのパッケージで異なるため、その影響でデータの破棄のタイミングなどに違いがあります。また、flutter_secure_storage では比較的安全にデータを格納できるという点でも異なります。

## 導入
[shared_preferences パッケージ](https://pub.dev/packages/shared_preferences) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.2.2
```

または

以下をターミナルで実行
```
flutter pub add shared_preferences
```

## 実装
以下の順番で実装を進めていきます。
1. 様々な型のデータを扱う実装
2. ライトモード / ダークモードの切り替え実装

### 1. 様々な型のデータを扱う実装
この章では、 shared_preferences で以下の型のデータを扱います。
+ String
+ int
+ double

実装は以下の手順で進めます。
1. データ構造の定義
2. shared_preferences に保存する Notifier の作成
3. main.dart の変更
4. UI で shared_preferences の内容を保存する UI の作成

#### 1. データ構造の定義
まずは `user.dart` に以下のような `User` クラスを作成します。
この章では、 `name`, `height`, `age` を shared_preferences に保存する実装を行います。
```dart: user.dart
class User {
  final String name;
  final double height;
  final int age;

  User({
    required this.name,
    required this.height,
    required this.age,
  });
}
```

#### 2. shared_preferences に保存する Notifier の作成
次に、データの保存や取得を行うための Notifier を作成します。
今回は簡単な例のため、 StateNotifier で作成します。
コードは以下の通りです。
```dart
const userNicknameKey = 'user_nickname';
const userHeightKey = 'user_height';
const userAgeKey = 'user_age';

final sharedPreferencesProvider =
    StateNotifierProvider<SharedPreferencesController, User>((ref) {
  return SharedPreferencesController();
});

class SharedPreferencesController extends StateNotifier<User> {
  SharedPreferencesController()
      : super(
          User(
            name: '',
            height: 0.0,
            age: 0,
          ),
        ) {
    _loadUser();
  }

  Future<User> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedUserNickname = prefs.getString(userNicknameKey);
    final loadedUserHeight = prefs.getDouble(userHeightKey);
    final loadedUserAge = prefs.getInt(userAgeKey);

    print('load user fired');
    state = User(
      name: loadedUserNickname ?? '',
      height: loadedUserHeight ?? 0.0,
      age: loadedUserAge ?? 0,
    );
    return User(
      name: loadedUserNickname ?? '',
      height: loadedUserHeight ?? 0.0,
      age: loadedUserAge ?? 0,
    );
  }

  Future<void> setValue({required String key, required Object value}) async {
    final prefs = await SharedPreferences.getInstance();
    final valueType = value.runtimeType;
    switch (valueType) {
      case String:
        await prefs.setString(key, value as String);
        break;
      case int:
        await prefs.setInt(key, value as int);
        break;
      case double:
        await prefs.setDouble(key, value as double);
        break;
      case bool:
        await prefs.setBool(key, value as bool);
        break;
      case const (List<String>):
        await prefs.setStringList(key, value as List<String>);
        break;
      default:
        print("Unsupported type");
        break;
    }
  }

  Future<T?> getValue<T>({required String key}) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.get(key) as T;
    final type = value.runtimeType;
    print('value: $value, type: $type');
    return value;
  }
}

```

それぞれ詳しくみていきます。

以下の部分では、それぞれの値を shared_preferences に保存する際のキーを指定しています。
これらのキーは他の Widget でも使用するためグローバルに定義しておきます。
本来であれば、キーを管理するための Provider を作るべきかと思います。
```dart
const userNicknameKey = 'user_nickname';
const userHeightKey = 'user_height';
const userAgeKey = 'user_age';
```

以下のコードでは、 shared_preferences に保存されているデータをロードする処理を記述しています。
`SharedPreferences.getInstance` は非同期処理で記述するので、Future 関数として、User を返すようにしています。
また、`getString`, `getDouble`, `getInt` など適切な型に合わせてデータを取得しています。
```dart
Future<User> _loadUser() async {
  final prefs = await SharedPreferences.getInstance();
  final loadedUserNickname = prefs.getString(userNicknameKey);
  final loadedUserHeight = prefs.getDouble(userHeightKey);
  final loadedUserAge = prefs.getInt(userAgeKey);

  print('load user fired');
  state = User(
    name: loadedUserNickname ?? '',
    height: loadedUserHeight ?? 0.0,
    age: loadedUserAge ?? 0,
  );
  return User(
    name: loadedUserNickname ?? '',
    height: loadedUserHeight ?? 0.0,
    age: loadedUserAge ?? 0,
  );
}
```

以下では shared_preferences にデータを保存する関数を実装しています。
Object 型で `value` を受け取り、 `value.runtimeType` でそれぞれの型を判別しています。
そして、それぞれの型に応じて `setString`, `setInt` などの関数を実行しています。
```dart
Future<void> setValue({required String key, required Object value}) async {
  final prefs = await SharedPreferences.getInstance();
  final valueType = value.runtimeType;
  switch (valueType) {
    case String:
      await prefs.setString(key, value as String);
      break;
    case int:
      await prefs.setInt(key, value as int);
      break;
    case double:
      await prefs.setDouble(key, value as double);
      break;
    case bool:
      await prefs.setBool(key, value as bool);
      break;
    case const (List<String>):
      await prefs.setStringList(key, value as List<String>);
      break;
    default:
      print("Unsupported type");
      break;
  }
}
```

以下では、 shared_preferences にあるデータを取得するための関数を実装しています。
`get` メソッドに `key` を引数として渡すことで、対応する `value` を返却しています。
```dart
Future<T?> getValue<T>({required String key}) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.get(key) as T;
  final type = value.runtimeType;
  print('value: $value, type: $type');
  return value;
}
```

これでデータを操作するための Notifier は作成完了です。

#### 3. main.dart の変更
次に `main.dart` を以下のように変更します。
次の章から `SharedPreferencesSample` を変更していきます。
```dart: main.dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: const SharedPreferencesSample(),
    );
  }
}
```

#### 4. UI で shared_preferences の内容を保存する UI の作成
最後に、shared_preferences にデータを保存、取得するための UI を作成します。
先程 `MaterialApp` の `home` に指定した `SharedPreferencesSample` でデータの操作を行います。
コードは以下のようになります。
```dart: shared_preferences_sample.dart
class SharedPreferencesSample extends ConsumerWidget {
  const SharedPreferencesSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userNicknameController = TextEditingController();
    final userHeightController = TextEditingController();
    final userAgeController = TextEditingController();

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
                  controller: userNicknameController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '身長',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 0.5,
                        style: BorderStyle.none,
                      ),
                    ),
                  ),
                  controller: userHeightController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '年齢',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 0.5,
                        style: BorderStyle.none,
                      ),
                    ),
                  ),
                  controller: userAgeController,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        final doubleHeight =
                            double.parse(userHeightController.text);
                        final intAge = int.parse(userAgeController.text);
                        ref.read(sharedPreferencesProvider.notifier).setValue(
                              key: userNicknameKey,
                              value: userNicknameController.text,
                            );
                        ref
                            .read(sharedPreferencesProvider.notifier)
                            .setValue(key: userHeightKey, value: doubleHeight);
                        ref
                            .read(sharedPreferencesProvider.notifier)
                            .setValue(key: userAgeKey, value: intAge);
                      },
                      child: const Text(
                        'データ保存',
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        ref.watch(sharedPreferencesProvider.notifier).getValue(
                              key: userNicknameKey,
                            );
                        ref.watch(sharedPreferencesProvider.notifier).getValue(
                              key: userHeightKey,
                            );
                        ref.watch(sharedPreferencesProvider.notifier).getValue(
                              key: userAgeKey,
                            );
                      },
                      child: const Text(
                        'データ取得',
                      ),
                    ),
                  ],
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

それぞれ詳しくみていきます。

以下では、ユーザーのニックネームなどを入力するテキストフィールドのコントローラーを定義しています。
```dart
final userNicknameController = TextEditingController();
final userHeightController = TextEditingController();
final userAgeController = TextEditingController();
```

以下では shared_preferences にデータを保存するボタンを実装してます。
Notifier で定義した `setValue` で key と value を指定して保存しています。
```dart
ElevatedButton(
  onPressed: () {
    final doubleHeight = double.parse(userHeightController.text);
    final intAge = int.parse(userAgeController.text);
    ref.read(sharedPreferencesProvider.notifier).setValue(
      key: userNicknameKey,
      value: userNicknameController.text,
    );
    ref.read(sharedPreferencesProvider.notifier).setValue(
      key: userHeightKey,
      value: doubleHeight
    );
    ref.read(sharedPreferencesProvider.notifier).setValue(
      key: userAgeKey,
      value: intAge
    );
  },
  child: const Text(
    'データ保存',
  ),
),
```

以下では Notifier の `getValue` 関数で値の取得を行なっています。
`getValue` 関数の中には、 `setValue` で指定したキーを入れることでキーと対になっている値を取得することができます。
`getValue` 関数の中には `print` があり、それぞれの `value` と型をコンソールに出力するようになっています。
```dart
ElevatedButton(
  onPressed: () {
    ref.watch(sharedPreferencesProvider.notifier).getValue(
      key: userNicknameKey,
    );
    ref.watch(sharedPreferencesProvider.notifier).getValue(
      key: userHeightKey,
    );
    ref.watch(sharedPreferencesProvider.notifier).getValue(
      key: userAgeKey,
    );
  },
  child: const Text(
    'データ取得',
  ),
),
```

これで、データを保存した後にアプリをリスタートしても、「データを取得」ボタンを押せば値が保存されているかと思います。

### 2. ライトモード / ダークモードの切り替え実装
#### 完成イメージ
この章では、以下の動画のようにライトモードとダークモードを切り替え、かつ shared_preferences に選択されているモードを記録することで、アプリを再起動してもモードが保持されるような実装を行います。

https://youtube.com/shorts/hzE7wi-KyyI

#### 実装手順
このような実装を行うために、以下のような手順で進めます。
+ ThemeModeController の作成
+ main.dart の変更
+ モードを切り替えるUIを作成

#### ThemeModeController の作成
まずは、shared_preferences にモードに関するデータを保存し、再度取得できるような `ThemeModeController` を作成します。
コードは以下の通りです。
```dart: theme_mode_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController();
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  static const String themeModeKey = 'theme_mode';

  ThemeModeController() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedMode = prefs.getString(themeModeKey);
    if (loadedMode != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.toString().split('.').last == loadedMode,
        orElse: () => ThemeMode.system,
      );
    }
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await prefs.setString(themeModeKey, newMode.toString().split('.').last);
    print('new mode : $newMode');
    state = newMode;
  }
}
```

それぞれ詳しくみていきます。

以下の部分では、 shared_preferences から `themeModeKey` と一対一で保存されているモードのデータを取得し、それを全体の `state` としています。
この `_loadThemeMode` 関数は `ThemeModeController` が読み込まれた時に実行されるため、モードを反映させたい画面に移った段階で、shared_preferences に保存されているモードに関するデータを `state` に代入することができます。
また、print文で shared_preferences に保存されているモードを出力しています。
```dart
Future<void> _loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final loadedMode = prefs.getString(themeModeKey);
  print('loaded mode : $loadedMode');
  if (loadedMode != null) {
    state = ThemeMode.values.firstWhere(
      (mode) => mode.toString().split('.').last == loadedMode,
      orElse: () => ThemeMode.system,
    );
  }
}
```

以下では、ライトモード / ダークモードを切り替えるための機能を実装しています。
現在の状態が `ThemeMode.light` がどうかで切り替えを行なっています。
そして、新しいモードを `setString` 関数に渡すことで shared_preferences に保存しています。
```dart
Future<void> toggle() async {
  final prefs = await SharedPreferences.getInstance();
  final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  await prefs.setString(themeModeKey, newMode.toString().split('.').last);
  print('new mode : $newMode');
  state = newMode;
}
```

#### main.dart の変更
次に、テーマを反映させるために `main.dart` を変更します。
コードは以下の通りです。
```dart: main.dart
void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: const SharedPreferencesSample(),
    );
  }
}
```

以下では、`themeModeProvider` を読み取った値を `themeMode` に代入し、それを `MaterialApp` の `themeMode` に代入しています。
`themeModeProvider` は初期化の時点で `_loadThemeMode` 関数が実行され、現在 shared_preferences に保存されているデータを返すため、アプリのモードに shared_preferences の値を反映することができます。

```dart
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: const SharedPreferencesSample(),
    );
```

#### モードを切り替えるUIを作成
最後にライトモード / ダークモードを切り替えるためのUIを作成します。
コードは以下の通りです。
```dart: shared_preferences_sample.dart
class SharedPreferencesSample extends ConsumerWidget {
  const SharedPreferencesSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: switchButton(ref),
      ),
    );
  }

  Widget switchButton(WidgetRef ref) {
    return IconButton(
      onPressed: () async {
        await ref.read(themeModeProvider.notifier).toggle();
      },
      icon: Icon(
        _getIconData(
          ref.watch(themeModeProvider),
        ),
      ),
    );
  }

  IconData _getIconData(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
      case ThemeMode.system:
      default:
        return Icons.smartphone_rounded;
    }
  }
}
```

以下のコードでは、ボタンが押された時に `themeModeProvider` で定義した `toggle` 関数を実行するようにしています。
また、 Icon に関しては、 `ref.watch(themeModeProvider)` の状態を渡し、その状態に応じて表示させるデータを変更しています。
```dart
Widget switchButton(WidgetRef ref) {
  return IconButton(
    onPressed: () async {
      await ref.read(themeModeProvider.notifier).toggle();
    },
    icon: Icon(
      _getIconData(
        ref.watch(themeModeProvider),
      ),
    ),
  );
}
```

これで実行すると以下の動画のようにライトモード / ダークモードが切り替わり、アプリを再起動しても設定が保持されているかと思います。

https://youtube.com/shorts/hzE7wi-KyyI

## まとめ
最後まで読んでいただいてありがとうございました。

flutter_secure_storage と同様に key と value を指定するだけでデータが保存できるため、非常に扱いやすいと感じました。一方でデータの安全性や複雑なデータは扱えないという点から使用すべきシーンは選べきだと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/shared_preferences

ダークモード実装
https://zenn.dev/chmod644/articles/baf559e46a0794
