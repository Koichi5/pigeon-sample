## 初めに
今回は drift というパッケージを用いて、Flutterでローカルにデータを保存する実装を行いたいと思います。

## 記事の対象者
+ Flutter 学習者
+ ローカルにデータを保存する機能を実装したい方
+ shared_preference などの他の手段との比較を知りたい方（今後更新）

## 目的
今回は drift という Flutter のパッケージを使用して、データをローカルに保存する実装を行うことを目的とします。[Driftのページ](https://drift.simonbinder.eu/docs/getting-started/)を参考に、簡単なTODOアプリを作成できるまで理解を深めます。また、他のパッケージとの比較も行ってみたいと思います。

TODOアプリの完成イメージ
https://youtube.com/shorts/Rv9nD4Re-QI?feature=share

## drift とは
そもそも drift とは、Flutter, Dart のために作られた、SQLiteで構築されている、永続化ライブラリです。[パッケージのREADME](https://pub.dev/packages/drift) に詳しい説明があったので、要約すると以下のようになります。
1. 柔軟
  Drift は SQL と Dart の両方でクエリを書くことができ、結果をフィルタリングして並べ替えたり、結合を使って複数のテーブルに対してクエリを実行したりできる
<br>
2. 機能が豊富
  Driftはトランザクション、スキーマ移行、複雑なフィルターや式、一括更新や結合をサポート
<br>
3. モジューラー
  SQL ファイルの daos や import をサポートしているため、データベースコードをシンプルに保つことができる
<br>
4. 安全
  Drift はテーブルとクエリに基づいてタイプセーフなコードを生成し、クエリに間違いがあった場合はコンパイル時に間違いを発見する
 <br>
5. 高速
  Driftはスレッドサポートを持つ唯一の主要な永続化ライブラリ
<br>
6. クロスプラットフォーム
  Android、iOS、macOS、Windows、Linux、Webで動作

なお、上記は一部を抜粋したものなので、より詳しく知りたい方は[README](https://pub.dev/packages/drift)をご覧ください。


## 導入
以下のパッケージの最新バージョンを `pubspec.yaml`に記述
dependencies
+ [drift](https://pub.dev/packages/drift)
+ [sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs)
+ [path_provider](https://pub.dev/packages/path_provider)
+ [path](https://pub.dev/packages/path)

dev_dependencies
+ [build_runner](https://pub.dev/packages/build_runner)
+ [drift_dev](https://pub.dev/packages/drift_dev)

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  drift: ^2.15.0
  sqlite3_flutter_libs: ^0.5.20
  path_provider: ^2.1.2
  path: ^1.9.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  drift_dev: ^2.15.0
```

または

以下をターミナルで実行
```
flutter pub add drift sqlite3_flutter_libs path_provider path
flutter pub add -d drift_dev build_runner
```

## 実装
準備が完了したので、以下の手順でサンプルアプリを実装していきます。
1. データベースの定義
2. データベースを使用するための準備
3. データ操作を行う各関数の定義
4. 各関数の使用

### 1. データベースの定義
まずはTODOアプリを実装するために必要なデータベースの定義を行います。
プロジェクトの `lib`ディレクトリの直下に `database.dart` ファイルを作成します。
ここに Drift を用いたデータベースの定義をしていきます。
まずは以下のように記述してみましょう。
```dart: database.dart
import 'package:drift/drift.dart';

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}

@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {}
```

詳しくみていきましょう。
以下の部分では、TODOアプリに必要な TODO のデータを定義しています。
`Table` を引き継ぐことで Driftのデータであると認識されます。

`IntColumn`, `TextColumn` は名前の通り、Int, Text の列を表します。
例えば、「`id` の列は Int型のデータが入る必要がある」というふうに定義することができます。
また、以下のようなオプションを追加しています。
+ `autoIncrement()` ではpostgresSQLなどと同じように、自動的にIntを繰り上げてくれます。
+ `withLength()` ではデータとして格納できるテキストの長さを制限することができます。
+ `named()` では属性を呼び出す際に指定できる名前を設定することができます。
+ `nullable()` では属性を Null許容にすることができます。

```dart: database.dart
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}
```
:::message
`Table` を使用する際、`package:flutter/material.dart`, `package:flutter/cupertino.dart` からも同様の名前の Widget をインポートできるため、インポート元を間違えないよう注意しましょう。
:::

次に以下の部分では `DriftDatabase` アノテーションを用いて、 `AppDatabase` が Drift のデータベースであることを示し、そのデータとして、`TodoItems` のリストを指定しています。
```dart: database.dart
@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {}
```

データベースの定義が完了したら一度以下のどちらかのコードをターミナルで実行することでコードが生成されます。
なお、 後者を実行しておくと、コード生成に関わるファイルに変更があった場合には自動で検知して、ビルドランナーを走らせてくれるのでより便利かと思います。
```
dart run build_runner build
or
dart run build_runner watch
```

### 2. データベースを使用するための準備
次に、データベースを使用するために必要な準備を行います。
まずは `database.dart` の `AppDatabase` を以下のように変更しましょう。
```dart: database.dart
@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFloder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFloder.path, 'db.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
```

それぞれの実装を詳しくみてみます。
以下の部分では後述の `_openConnection` 関数をインスタンス化した際に実行しています。
また、スキーマのバージョンを管理する `schemaVersion` 変数も設けています。
```dart
@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}
```

以下の部分では多少複雑ですが、 `AppDatabase` がインスタンス化された時に実行される `_openConnection` 関数を実装しています。
```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFloder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFloder.path, 'db.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
```

それぞれステップに分けてみてみましょう。
まず、`LazyDatabase` は、実際にデータベースにアクセスが必要になるまでデータベースの開設を遅延させることができるもので、アプリケーションの起動速度を向上させたり、不要なリソースの使用を避けたりすることができます。

以下の部分では `getApplicationDocumentsDirectory` 関数を使用して、アプリケーションのドキュメントディレクトリのパスを取得しています。このディレクトリは、アプリケーションによって生成されたデータを保存するために使用されます。
また、取得したドキュメントディレクトリのパスとデータベースファイル名を組み合わせて、データベースファイルのフルパスを生成しています。
```dart
final dbFloder = await getApplicationDocumentsDirectory();
final file = File(p.join(dbFloder.path, 'db.sqlite'));
```

以下の部分ではユーザーの使用しているデバイスのプラットフォームを判別し、Androidの場合は古いバージョンの場合のエラー回避を行なっています。
```dart
if (Platform.isAndroid) {
  await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
}
```

以下の部分では、`getTemporaryDirectory` 関数を使用して一時ディレクトリのパスを取得し、`sqlite3.tempDirectory` にパスを指定しています。これにより、SQLiteが内部的に使用する一時ファイルの格納場所を指定しています。
```dart
final cachebase = (await getTemporaryDirectory()).path;
sqlite3.tempDirectory = cachebase;
```

最後に、以下の部分で `NativeDatabase.createInBackground` 関数を使用して、指定されたファイルパスに新しいSQLiteデータベースをバックグラウンドで作成し、それを返却しています。
```dart
return NativeDatabase.createInBackground(file);
```

次に `main.dart` で以下のような変更を加えます。
```dart: main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  runApp(
    MyApp(database: database),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.database});
  final AppDatabase database;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DriftSample(database: database),
    );
  }
}
```

`main` 関数が実行された時点で `AppDatabase` をインスタンス化し、 `MyApp`, `DriftSample` に渡しています。これで `DriftSample` でもデータベースにアクセスすることができるようになります。

なお、 `DriftSample` は以下のようにしています。
```dart: drift_sample.dart
class DriftSample extends StatelessWidget {
  const DriftSample({super.key, required this.database});

  final AppDatabase database;

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}
```

これで Drift のデータベースを使用する準備は完了です。

### 3. データ操作を行う各関数の定義
次にデータ操作を行う関数を定義していきます。
`database.dart` を以下のように変更します。
```dart: database.dart
import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:drift/drift.dart';

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}

@DriftDatabase(tables: [TodoItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Stream<List<TodoItem>> watchTodoItems() {
    return (select(todoItems)).watch();
  }

  Future<List<TodoItem>> get allTodoItems => select(todoItems).get();

  Future<int> addTodoItem(
      {required String title, required String content, int? category}) {
    return into(todoItems).insert(
      TodoItemsCompanion(
        title: Value(title),
        content: Value(content),
        category: Value(category),
      ),
    );
  }

  Future<int> updateTodoItems(
      {required TodoItem todoItem,
      required String title,
      required String content}) {
    return (update(todoItems)..where((tbl) => tbl.id.equals(todoItem.id)))
        .write(
      TodoItemsCompanion(
        title: Value(title),
        content: Value(content),
      ),
    );
  }

  Future<void> deleteTodoItem(TodoItem todoItem) {
    return (delete(todoItems)..where((tbl) => tbl.id.equals(todoItem.id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFloder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFloder.path, 'db.sqlite'));
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
```

それぞれの関数を詳しくみていきます。
以下の関数では全てのTodoを Stream型で取得しています。
SQLのSELECT文と同様に、`select` でデータベースを指定し、`watch` で常にそのデータの変更を監視することができます。 `watchTodoItems` では監視している状態を返り値としています。
```dart
Stream<List<TodoItem>> watchTodoItems() {
  return (select(todoItems)).watch();
}
```

以下の関数では全てのTodoを取得しています。
`select` でデータベースを指定し、`get` でデータを取得しています。
```dart
Future<List<TodoItem>> get allTodoItems => select(todoItems).get();
```

以下の関数ではTodoを追加する処理を記述しています。
SQLのINSERT文と同様に、`into` で追加先のデータベースを指定し、`insert` で追加するTodoの内容を指定しています。
```dart
Future<int> addTodoItem(
      {required String title, required String content, int? category}) {
  return into(todoItems).insert(
    TodoItemsCompanion(
      title: Value(title),
      content: Value(content),
      category: Value(category),
    ),
  );
}
```

以下の関数ではTodoを変更する処理を記述しています。
`update`関数の引数として `todoItems` を受け取ることで、Todoの変更を表し、さらに `where` でIDが一致するTodoを見つけ出しています。そして、`write` で新たに書き換えたい内容を記述しています。
```dart
Future<int> updateTodoItems(
  {required TodoItem todoItem,
  required String title,
  required String content}) {
    return (update(todoItems)..where((tbl) => tbl.id.equals(todoItem.id)))
        .write(
      TodoItemsCompanion(
        title: Value(title),
        content: Value(content),
    ),
  );
}
```

以下の関数ではTodoを削除する処理を記述しています。
`delete` 関数で todoItems の中から、受け取った todoItem のIDと同じものを見つけ出し、削除しています。
```dart
Future<void> deleteTodoItem(TodoItem todoItem) {
  return (delete(todoItems)..where((tbl) => tbl.id.equals(todoItem.id))).go();
}
```

全ての関数が追加できたら `flutter pub run build_runner build` を実行しておきましょう。
これでデータを操作する各関数の実装は完了です。

### 4. 各関数の使用
これまででデータを操作するための関数の実装は完了したので、実際に画面で使用してみます。
ステップ２で作成していた `DriftSample` を以下のように変更します。
```dart: drift_sample.dart
import 'package:flutter/material.dart';
import 'package:sample_flutter/drift/database.dart';

class DriftSample extends StatelessWidget {
  DriftSample({super.key, required this.database});

  final AppDatabase database;
  final TextEditingController addTitleController = TextEditingController();
  final TextEditingController addContentController = TextEditingController();

  final TextEditingController updateTitleController = TextEditingController();
  final TextEditingController updateContentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
        actions: [
          IconButton(
            onPressed: () {
              showAddTodoDialog(context);
            },
            icon: const Icon(
              Icons.add,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder(
                stream: database.watchTodoItems(),
                builder: (BuildContext context,
                    AsyncSnapshot<List<TodoItem>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.data![index].title,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                Text(snapshot.data![index].content),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    showUpdateTodoDialog(
                                      context: context,
                                      oldTodoItem: snapshot.data![index],
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.edit,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    showDeleteTodoDialog(
                                        context: context,
                                        todoItem: snapshot.data![index]);
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showAddTodoDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "Todoの情報を入力",
            style: TextStyle(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "タイトル"),
                controller: addTitleController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "詳細"),
                controller: addContentController,
              )
            ],
          ),
          actions: [
            TextButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                database.addTodoItem(
                  title: addTitleController.text,
                  content: addContentController.text,
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showUpdateTodoDialog(
      {required BuildContext context, required TodoItem oldTodoItem}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "変更するTodoの情報を入力",
            style: TextStyle(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "タイトル"),
                controller: updateTitleController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "詳細"),
                controller: updateContentController,
              )
            ],
          ),
          actions: [
            TextButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                database.updateTodoItems(
                  todoItem: oldTodoItem,
                  title: updateTitleController.text,
                  content: updateContentController.text,
                );
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void showDeleteTodoDialog(
      {required BuildContext context, required TodoItem todoItem}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: const Text(
            "このTodoを削除しますか？",
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () async {
                database.deleteTodoItem(todoItem);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
```
かなり量が多いので、データ操作に関わる部分を抽出してみていきます。
まず、以下の部分については、Todoに関するデータの変更を監視している結果を返している `database.watchTodoItems()` を `StreamBuilder` で読み込んでいます。
そして、読み込んだデータのタイトルと説明文を表示させています。
Stream型で取得、表示させているので、Todoのデータに変更があった場合は直ちにその変更が反映されるようになっています。
```dart
StreamBuilder(
  stream: database.watchTodoItems(),
  builder: (BuildContext context,
  AsyncSnapshot<List<TodoItem>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView.builder(
      itemCount: snapshot.data!.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    snapshot.data![index].title,
                    style: const TextStyle(fontSize: 18),
                  ),
                  Text(snapshot.data![index].content),
                ],
              ),
```

次に、以下の部分では、`showAddTodoDialog` 関数の中で、Todoを追加するための処理を記述しています。今回は `TextEditingController` の `text` をそのまま参照する形で、追加するTodoのタイトルと説明文を取得してきています。
```dart
TextButton(
  child: const Text("OK"),
  onPressed: () async {
    database.addTodoItem(
      title: addTitleController.text,
      content: addContentController.text,
    );
    Navigator.pop(context);
  },
),
```

次に以下の部分では、 `showUpdateTodoDialog` 関数の中で、Todoを更新するための処理を記述しています。現在選択しているTodoを `oldTodoItem` として渡し、新しく設定するタイトルと説明文も渡すことで、 `oldTodoItem` のIDが参照され、内容が更新されるようになっています。
```dart
TextButton(
  child: const Text("OK"),
  onPressed: () async {
    database.updateTodoItems(
      todoItem: oldTodoItem,
      title: updateTitleController.text,
      content: updateContentController.text,
    );
    Navigator.pop(context);
  },
),
```

最後に以下の部分では、 `showDeleteTodoDialog` 関数の中で、Todoを削除するための処理を記述しています。updateの場合と同様に現在選択しているTodoを渡すことで削除しています。
```dart
TextButton(
  child: const Text("OK"),
  onPressed: () async {
    database.deleteTodoItem(todoItem);
    Navigator.pop(context);
  },
),
```

実行してみると、以下の動画のように問題なくTodoの操作ができていることがわかります。
https://youtube.com/shorts/Rv9nD4Re-QI?feature=share

## まとめ
最後まで読んでいただいてありがとうございました。
簡単なデータの操作であれば手軽に行えるパッケージだと感じました。
今後 SharedPreference などと比較してメリット・デメリットなども考えられたらと思います。
誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/drift

https://drift.simonbinder.eu/docs/getting-started/

https://blog.flutteruniv.com/flutter-drift/