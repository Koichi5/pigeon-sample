## 初めに
今回は ObjectBox というパッケージを使用して、Flutterでローカルにデータを保存する実装を行いたいと思います。また、他のローカルデータベースの比較も行いたいと思います。

## 記事の対象者
+ Flutter 学習者
+ ローカルにデータを保存する実装を行いたい方
+ 他のローカルデータベースとの比較を知りたい方

## 目的
今回は先述の通り ObjectBox パッケージでローカルにデータを保存する実装を行うことを目的とします。
[Driftで実装した記事](https://zenn.dev/koichi_51/articles/ed03537e816166) と仕様がほぼ同じになっていますが、最終的には以下の動画のように簡単なTodoアプリを作成できるところまで実装します。

https://youtube.com/shorts/JG45KwOraHM?feature=share

## ObjectBox とは
[公式ドキュメント](https://pub.dev/packages/objectbox)によると、ObjectBox は「Dartオブジェクトをクロスプラットフォームアプリケーションに保存するデータベースである」とされています。
特徴として以下の以下の9つが挙げられています。
1. 超高速
   - SQLite の10倍高速である
<br>
2. ACID準拠
   - トランザクション処理における原子性(A)、一貫性(C)、独立性(I)、および耐久性(D)を持つ
<br>
3. クロスプラットフォーム
   - Android、iOS、macOS、Linux、Windowsに対応
<br>
4. スケーラブル
   - アプリに合わせて成長し、何百万ものオブジェクトを簡単に処理
<br>
5. NoSQL
   - 行や列はなく、純粋な Dart オブジェクトのみを使用
<br>
6. リレーション
   - オブジェクトリンクリレーションシップに対応
<br>
7. クエリ
   - リレーション間でも、必要に応じてデータをフィルタリング
<br>
8. スキーマの移行
   - モデルを変更するだけでスキーマの移行が可能
<br>
9. データ同期
    - 必要なとき、必要な場所でのみデータを同期

## 導入
以下のパッケージの最新バージョンを `pubspec.yaml`に記述
dependencies
+ [objectbox](https://pub.dev/packages/objectbox)
+ [objectbox_flutter_libs](https://pub.dev/packages/objectbox_flutter_libs)

dev_dependencies
+ [build_runner](https://pub.dev/packages/build_runner)
+ [objectbox_generator](https://pub.dev/packages/objectbox_generator)

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  objectbox: ^2.4.0
  objectbox_flutter_libs: ^2.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.8
  objectbox_generator: ^2.4.0
```

または

以下をターミナルで実行
```
flutter pub add objectbox objectbox_flutter_libs
flutter pub add -d build_runner objectbox_generator
```

## 実装
実装は以下の手順で進めたいと思います。
1. データ構造の定義
2. データを変更する関数の定義
3. ObjectBox をアプリ全体で使用できるようにする
4. データの変更を行うUIを実装

### 1. データ構造の定義
まずはアプリで使用するデータの構造の定義を行います。
MVCモデルのModelの部分に当たります。
今回はTodoアプリを実装するので、`Todo`というデータを以下のように作成します。
`Entity`アノテーションを使うことでデータの定義を行うことができ、Freezedを使った時の場合と同じような書き方で定義することができます。
```dart: todo.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class Todo {
  Todo(
      {required this.title, required this.description, required this.priority});
  @Id()
  int id = 0;
  String title;
  String description;
  String priority;
}
```

なお、以下のように `id` を定義することで、`autoincrement`のような処理を記述しなくてもユニークな値を保持することができます。
```dart
@Id()
int id = 0;
```

データを定義した後は以下のコードを実行してコード生成を行いましょう。
```
flutter pub run build_runner build
```
正常に動作すれば `objectbox-model.json`, `objectbox.g.dart` などのファイルが生成されます。

::: details  Driftとの書き方の違い
Driftを用いた場合が以下のようなデータの定義であることを鑑みると、Freezedで定義するのと同じような書き方で書けることがわかります。
```dart: drift_data_sample.dart
class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  IntColumn get category => integer().nullable()();
}
```
:::

### 2. データを変更する関数の定義
次に `ObjectBox` としてデータを変更するための変数を定義します。
以下のように `object_box.dart` を作成します。
```dart: object_box.dart
class ObjectBox {
  late final Store store;
  late final Box<Todo> todoBox;

  ObjectBox._create(this.store) {
    todoBox = Box<Todo>(store);
  }

  static Future<ObjectBox> create() async {
    final store = await openStore();
    return ObjectBox._create(store);
  }

  void addTodo({required Todo todo}) {
    todoBox.put(todo);
  }

  Stream<List<Todo>> getStreamTodo() {
    final builder = todoBox.query().order(Todo_.title, flags: Order.descending);
    return builder.watch(triggerImmediately: false).map(
          (query) => query.find(),
        );
  }

  List<Todo> getAllTodo() {
    return todoBox.getAll();
  }

  List<Todo> getImportantTodo() {
    final query = todoBox.query(Todo_.priority.equals('1')).build();
    final result = query.find();
    query.close();
    return result;
  }

  void updateTodo(
      {required Todo oldtTodo,
      required String title,
      required String description,
      required String priority}) {
    final todo = todoBox.get(oldtTodo.id);
    if (todo != null) {
      todo.title = title;
      todo.description = description;
      todo.priority = priority;
      todoBox.put(todo);
    }
  }

  void deleteTodo({required Todo todo}) {
    todoBox.remove(todo.id);
  }

  void deleteAllTodo() {
    todoBox.removeAll();
  }
}
```

それぞれ詳しくみていきます。

以下のコードでは、`ObjectBox` のプライベートコンストラクタとして `_create` を定義してます。
また、コンストラクタの中で `Todo` を格納するための `Box` を初期化しています。
```dart
ObjectBox._create(this.store) {
  todoBox = Box<Todo>(store);
}
```

以下のコードでは、非同期処理の関数として `create` を定義し、 `openStore` 関数を実行しています。
`openStore` を実行することでデータを操作することができるようになります。
```dart
static Future<ObjectBox> create() async {
  final store = await openStore();
  return ObjectBox._create(store);
}
```

以下のコードでは、Todoを追加する処理を記述しています。
引数として追加したいTodoを受け取り、`todoBox` の `put` 関数の引数に渡すことでデータを簡単に追加することができます。
```dart
void addTodo({required Todo todo}) {
  todoBox.put(todo);
}
```

以下のコードではリスト形式の Todo を Stream 形式で返す関数を定義しています。
`order` で Todo をタイトルの順番に並び替え、`watch` でデータの変更を監視しています。
そして、監視しているデータを `map`, `find` を用いて返却しています。
なお、`triggerImmediately` を `true` にするとリッスンされた時にすぐにクエリを実行するようになります。
```dart
Stream<List<Todo>> getStreamTodo() {
  final builder = todoBox.query().order(Todo_.title, flags: Order.descending);
  return builder.watch(triggerImmediately: false).map(
    (query) => query.find(),
  );
}
```

以下のコードでは、全てのTodoを取得する関数を定義しています。
１行のコードで全てのデータを取得し、しかも Todo のリスト形式で返却してくれるのは非常に使いやすいです。
```dart
List<Todo> getAllTodo() {
  return todoBox.getAll();
}
```

以下のコードでは、`priority` が 1 である Todo のみに絞って検索し、結果を返却しています。
`query` の引数に条件文を入れることで、データをフィルタリングすることができます。
```dart
List<Todo> getImportantTodo() {
  final query = todoBox.query(Todo_.priority.equals('1')).build();
  final result = query.find();
  query.close();
  return result;
}
```

以下のコードでは Todo を更新するための関数を定義しています。
`get` 関数の引数に `oldTodo.id` を入れることで、IDに合致する Todo を取得しています。
取得した Todo の `title`, `description`, `priority` を新しい値に更新して、`put` 関数に渡すことでデータを更新することができます。
```dart
void updateTodo(
  {required Todo oldtTodo,
  required String title,
  required String description,
  required String priority}) {
    final todo = todoBox.get(oldtTodo.id);
    if (todo != null) {
      todo.title = title;
      todo.description = description;
      todo.priority = priority;
      todoBox.put(todo);
    }
}
```

以下のコードでは Todo を削除するための関数を定義しています。
`remove` 関数に Todo のIDを渡すことで、IDが合致する Todo を削除することができます。
```dart
void deleteTodo({required Todo todo}) {
  todoBox.remove(todo.id);
}
```

以下のコードではすべての Todo を全て削除するための関数を定義しています。
`removeAll` 関数の１行で全てのデータを削除することができます。
```dart
void deleteAllTodo() {
  todoBox.removeAll();
}
```

### 3. ObjectBox をアプリ全体で使用できるようにする
`main.dart` を以下のように変更しましょう。
```dart: main.dart
late ObjectBox objectbox;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.create();
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
    return MaterialApp(
      home: ObjectBoxSample(),
    );
  }
}
```

`late ObjectBox objectbox;` として先程作成した `ObjectBox` を遅延初期化しています。
また、`objectbox = await ObjectBox.create();` で `openStore()` などが実行され、データの操作が可能になります。

### 4. データの変更を行うUIを実装
最後に `ObjectBoxSample` として、データの変更を行うUIを実装します。
以下のようなコードになります。
```dart: object_box_sample.dart
class ObjectBoxSample extends ConsumerWidget {
  ObjectBoxSample({super.key});
  final TextEditingController addTitleController = TextEditingController();
  final TextEditingController addDescriptionController =
      TextEditingController();
  final TextEditingController addPriorityController = TextEditingController();

  final TextEditingController updateTitleController = TextEditingController();
  final TextEditingController updateDescriptionController =
      TextEditingController();
  final TextEditingController updatePriorityController =
      TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                stream: objectbox.getStreamTodo(),
                builder: (BuildContext context, snapshot) {
                  if (snapshot.data == null) {
                    return const Center(
                      child: Text('Todoがありません'),
                    );
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
                                Text(snapshot.data![index].description),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    showUpdateTodoDialog(
                                      context: context,
                                      oldTodo: snapshot.data![index],
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
                                        todo: snapshot.data![index]);
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
                controller: addDescriptionController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "優先度"),
                keyboardType: TextInputType.number,
                controller: addPriorityController,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                objectbox.addTodo(
                  todo: Todo(
                    title: addTitleController.text,
                    description: addDescriptionController.text,
                    priority: addPriorityController.text,
                  ),
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
      {required BuildContext context, required Todo oldTodo}) {
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
                controller: updateDescriptionController,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "優先度"),
                keyboardType: TextInputType.number,
                controller: updatePriorityController,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("キャンセル"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                objectbox.updateTodo(
                  oldtTodo: oldTodo,
                  title: updateTitleController.text,
                  description: updateDescriptionController.text,
                  priority: updatePriorityController.text,
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
      {required BuildContext context, required Todo todo}) {
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
              onPressed: () {
                objectbox.deleteTodo(todo: todo);
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

[こちらの記事](https://zenn.dev/koichi_51/articles/ed03537e816166)で紹介したUIと同じような機能ですが、実装を詳しくみていきましょう。

以下の部分では `StreamBuilder` の `stream` に、Todo を Stream型で取得する関数を定義し、取得したデータを `snapshot` として扱っています。
```dart
StreamBuilder(
  stream: objectbox.getStreamTodo(),
  builder: (BuildContext context, snapshot) {
```

以下の部分では `objectbox` で定義した `addTodo` 関数を使用しています。
`addTodo` 関数の引数として、追加する Todo の `title`, `description`, `priority` をテキストフィールドから渡しています。
```dart
objectbox.addTodo(
  todo: Todo(
    title: addTitleController.text,
    description: addDescriptionController.text,
    priority: addPriorityController.text,
  ),
);
```

以下の部分では、`objectbox` の `updateTodo` 関数を使用しています。
表示されている Todo を `oldTodo` として関数に渡し、新たな Todo の値も一緒に渡すことで Todo の更新を実装しています。
```dart
objectbox.updateTodo(
  oldtTodo: oldTodo,
  title: updateTitleController.text,
  description: updateDescriptionController.text,
  priority: updatePriorityController.text,
);
```

以下の部分では、`deleteTodo` 関数を使って、表示されている Todo を渡すことで、 Todo を削除するための実装をしています。
```dart
objectbox.deleteTodo(todo: todo);
```

上記のコードを実行すると、「目的」の章にもあった以下の動画のような挙動が実現できるかと思います。

https://youtube.com/shorts/JG45KwOraHM?feature=share

## まとめ
最後まで読んでいただいてありがとうございました。

ObjectBoxに関しては Freezed を用いて実装を行う際と同じような書き方でデータの定義やローカルのデータ操作ができることや、フィルタリング等も比較的簡単に実装できることなどからも使いやすいパッケージであると感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/objectbox

https://zenn.dev/pressedkonbu/articles/flutter-object-box

https://zenn.dev/flutteruniv_dev/articles/5d00ef980ac5ce

https://github.com/objectbox/objectbox-dart/tree/main/objectbox/example/flutter/objectbox_demo