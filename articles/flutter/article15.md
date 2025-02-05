## 初めに
今回は Flutter で Supabase を使って簡単なTodoアプリを実装してみたいと思います。
実装に際して Supabase でできることや Flutter での実現方法などを共有できればと思います。

## 記事の対象者
+ Flutter 学習者
+ Flutter × Supabase で開発をしてみたい方
+ Supabase を使ってみたい方

## 紹介しないこと
+ PostgreSQL を用いた Supabase の実装
+ Supabase の網羅的なデータ操作

## 目的
今回は先述の通り、 Flutter × Supabase で簡単なアプリの実装を行います。
今回の一番大きな目的は Supabase の使い方やできることをある程度把握することです。
普段であれば開発の途中で必要になった知識や気になった部分の深掘りをして記事にまとめていますが、今回は純粋に Firebase 以外の BaaS をあまり使ったことがなかったので、使ってみようと思い実装しました。

最終的には以下の動画のように、データの追加、更新、削除だけでなくフィルタリングも行うようなTODOアプリを実装してみたいと思います。

https://youtube.com/shorts/g-j2q4vy7A8

今回の実装内容は以下のGitHubで公開しているので、よろしければそちらもご覧ください。
https://github.com/Koichi5/supabase_sample

## Supabase とは
[公式ページ](https://supabase.com/)からそのまま引用します。
> Supabase is an open source Firebase alternative.
Start your project with a Postgres database, Authentication, instant APIs, Edge Functions, Realtime subscriptions, Storage, and Vector embeddings.
>
> （日本語訳）
> Supabaseは、オープンソースのFirebase代替です。
Postgresデータベース、認証、インスタントAPI、エッジ関数、リアルタイム購読、ストレージ、およびベクトル埋め込みなどがプロジェクトで使用できます。

簡単にまとめると以下のようになるかと思います。
+ Firebase の代替案であること
+ PostgreSQL データベースが使用できること（Firebase は NoSQL）

## 導入
以下のパッケージの最新バージョンを `pubspec.yaml`に記述
dependencies
+ [supabase_flutter](https://pub.dev/packages/supabase_flutter)
+ [flutter_dotenv](https://pub.dev/packages/flutter_dotenv)
+ [riverpod_annotation](https://pub.dev/packages/riverpod_annotation)
+ [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
+ [hooks_riverpod](https://pub.dev/packages/hooks_riverpod)
+ [flutter_hooks](https://pub.dev/packages/flutter_hooks)
+ [freezed](https://pub.dev/packages/freezed)
+ [freezed_annotation](https://pub.dev/packages/freezed_annotation)
+ [gap](https://pub.dev/packages/gap)
+ [intl](https://pub.dev/packages/intl)

dev_dependencies

+ [build_runner](https://pub.dev/packages/build_runner)
+ [json_serializable](https://pub.dev/packages/json_serializable)
+ [riverpod_generator](https://pub.dev/packages/riverpod_generator)

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.5.4
  flutter_dotenv: ^5.1.0
  riverpod_annotation: ^2.3.5
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1
  hooks_riverpod: ^2.5.1
  flutter_hooks: ^0.20.5
  freezed: ^2.5.2
  freezed_annotation: ^2.4.1
  gap: ^3.0.1
  intl: ^0.19.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
```

または

以下をターミナルで実行
```
flutter pub add supabase_flutter flutter_dotenv riverpod_annotation flutter_riverpod hooks_riverpod flutter_hooks freezed freezed_annotation gap intl
flutter pub add -d build_runner json_serializable riverpod_generator
```

追加するパッケージがかなり多いですが、今回特に必要なのは `supabase_flutter` と `flutter_dotenv` の2つです。
`supabase_flutter` は名前の通り、 Flutter から Supabase にアクセスしてデータ保存などを行うためのパッケージです。今回は Auth などの実装はしないため、 Firebase に置き換えると `firebase_core` や `cloud_firestore` パッケージに当たるかと思います。
`flutter_dotenv` は環境変数などを格納する `.env` ファイルに書かれている内容をコードからアクセスできるようにするためのパッケージです。後述しますが、今回は Supabase の URL や Anon Key などを格納するために使用します。

## 実装
実装は以下の手順で進めていきたいと思います。
1. Supabase 側の準備
2. Flutter 側の準備
3. データクラスの作成
4. Repositoryの作成
5. UIの作成

### 1. Supabase 側の準備
まずは [Supabase のページ](https://supabase.com/) に移動します。
ページは以下のようになっています。
ここで「Start your project」を選択します。
![](https://storage.googleapis.com/zenn-user-upload/89885e8eb0a9-20240605.png)

新規登録などを済ませると以下のようになっているかと思います。（自分はすでに Sample プロジェクトがありますが、本来はありません。）
ここで「New project」を押して新たなプロジェクトを作成できます。
![](https://storage.googleapis.com/zenn-user-upload/2ed0daa11c23-20240605.png)

「New project」を押すと以下のようなページに遷移します。
ここでプロジェクトの組織やプロジェクト名、データベースのパスワードやデータベースの Region などを設定します。
![](https://storage.googleapis.com/zenn-user-upload/533fcaac5240-20240605.png)

これでプロジェクトの作成は完了です。

次にデータベースの設定に移ります。
データベースの設定をするためにサイドバーの「Table Editor」を押します。
![](https://storage.googleapis.com/zenn-user-upload/0894aae7adfc-20240605.png)

「Table Editor」を押すと以下のような画面に遷移します。
ここで「Create a new table」を押すとテーブルを作成することができます。
![](https://storage.googleapis.com/zenn-user-upload/f474456284e5-20240605.png)

今回はTODOアプリを作成するため、以下のような設定を行います。
PostgreSQLを実行してデータを作成することもできますが、今回はGUI上で設定を行います。
+ 「Name」を「todos」に設定
+ 「Enable Row Level Security (RLS)」のチェックを外す
+ 「Enable Realtime」にチェックをいれる
+ int8型の「id」を Primary に設定
+ timestamptz型の「created_at」を設定
+ text型の「title」を設定
+ text型の「description」を設定
+ bool型の「is_done」を Default Value 「FALSE」で設定
![](https://storage.googleapis.com/zenn-user-upload/344f578663f0-20240605.png)

これでデータベースの設定は完了です。

最後にキーの保存を行います。
ホームページの「Project Settings」を押します。
![](https://storage.googleapis.com/zenn-user-upload/2b6c7d6d7028-20240605.png)

「API」の項目をタップして「Project API keys」の中の「URL」と「anon　public」のキーをコピーして控えておきます。これらは Flutter側から Supabase に接続する際に使用します。（以下の画像では塗りつぶしています。）
![](https://storage.googleapis.com/zenn-user-upload/e26763256cfd-20240605.png)

これで Supabase 側の準備は完了です。

### 2. Flutter 側の準備
次に Flutter 側の準備を行います。
まずは環境変数の設定を行います。
プロジェクトの直下に `.env` ファイルを作成し、以下のように変更します。
先ほど Supabase の設定からコピーした `SUPABASE_URL` と `SUPABASE_ANONKEY` を追加します。
```env: .env
SUPABASE_URL='{YOUR_SUPABASE_URL}'
SUPABASE_ANONKEY='{YOUR_SUPABASE_ANONKEY}'
```

次に `.gitignore` ファイルに `.env` を追加します。
これで .envファイルがGitの管理下から外れるため、意図せず Supabase の URL や Anon Key が流出することを防ぐことができます。
```markdown: .gitignore
.env
```

次に `pubspec.yaml` の編集を行います。
ファイルの下部（画像を追加する時に指定する場所と同じ）に `assets` として `.env` を追加します。
```yaml: pubspec.yaml
flutter:
  uses-material-design: true

  assets:
    - .env
```

最後に `main.dart` の編集を行います。
コードは以下の通りです。
`dotenv.load` で `.env` ファイルを読み込み、そこから `SUPABASE_URL`, `SUPABASE_ANONKEY` を取りだし、 `Supabase.initialize` に渡すことで Supabase の初期化を行なっています。
また、今回は Riverpod を使うため、 `MyApp` を `ProviderScope` で囲んでいます。
```dart: main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANONKEY'),
  );
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

`MyApp` の内容は以下のようになっており、基本的にはプロジェクトが作成された時の状態です。
`home` に指定されている `TodoPage` は後々実装を進めていきます。
```dart: main.dart
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
      home: const TodoPage(),
    );
  }
}
```

これで Flutter 側の設定は完了です。

### 3. データクラスの作成
次にこのTODOアプリで使用するデータクラスの作成を行います。
コードは以下の通りです。
`Todo` は Supabase の GUI上で作成したものと同じプロパティに設定します。
`FilterCondition` は後述の Todo を絞り込む段階で使用します。
FirebaseのようなNoSQLの場合は `fromJson`, `toJson` も実装しますが、今回は簡単なアプリであることもあり、作成はしません。
```dart:todo.dart
class Todo {
  final int id;
  final String title;
  final String description;
  final String createdAt;
  final bool isDone;

  Todo({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.isDone,
  });
}
```

```dart: filter_condition.dart
class FilterCondition {
  final bool isFilteredByWeek;
  final bool isFilteredByTitle;
  final bool isOrderedByCreatedAt;
  final bool isLimited;
  final String? filterTitle;
  final String? filterTitleContain;
  final int? limitCount;

  FilterCondition({
    required this.isFilteredByWeek,
    required this.isFilteredByTitle,
    required this.isOrderedByCreatedAt,
    required this.isLimited,
    this.filterTitle,
    this.filterTitleContain,
    this.limitCount,
  });
}
```

これでデータクラスの作成は完了です。

### 4. Repositoryの作成
次に Flutter 側から Supabase のデータの読み取りや作成を行うRepositoryの作成を行います。
コードは以下の通りです。
```dart: supabase_repository.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'supabase_repository.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseRepository(SupabaseRepositoryRef ref) {
  return Supabase.instance.client;
}
```

```dart: todo_repository.dart
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_sample/models/filter_condition.dart';
import 'package:supabase_sample/repository/supabase_repository.dart';

part 'todo_repository.g.dart';

@Riverpod(keepAlive: true)
class TodoRepository extends _$TodoRepository {
  late final SupabaseClient supabaseClient;
  @override
  void build() {
    supabaseClient = ref.read(supabaseRepositoryProvider);
  }

  // リアルタイム取得
  SupabaseStreamBuilder? stream({
    required FilterCondition condition,
  }) {
    SupabaseStreamFilterBuilder query =
        supabaseClient.from('todos').stream(primaryKey: ['id']);

    // １週間前までのデータをフィルタリング
    if (condition.isFilteredByWeek) {
      final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
      final oneWeekAgoStr =
          DateFormat('yyyy-MM-ddTHH:mm:ss').format(oneWeekAgo);
      query =
          query.gt('created_at', oneWeekAgoStr) as SupabaseStreamFilterBuilder;
    }

    // タイトルが一致するもののみをフィルタリング
    if (condition.isFilteredByTitle) {
      query = query.eq('title', condition.filterTitle ?? '')
          as SupabaseStreamFilterBuilder;
    }

    // 作成日に応じて昇順、降順に並び替え
    if (condition.isOrderedByCreatedAt) {
      query = query.order('created_at', ascending: true)
          as SupabaseStreamFilterBuilder;
    } else {
      query = query.order('created_at', ascending: false)
          as SupabaseStreamFilterBuilder;
    }

    // 取得件数の制限
    if (condition.isLimited) {
      query = query.limit(condition.limitCount ?? 20)
          as SupabaseStreamFilterBuilder;
    }
    return query;
  }

  // 全データの取得
  Future<List<Map<String, dynamic>>> select() async {
    final data = await supabaseClient.from('todos').select();
    return data;
  }

  // データの追加
  Future<void> insert({
    required String title,
    required String description,
  }) async {
    await supabaseClient.from('todos').insert({
      'title': title,
      'description': description,
    });
  }

  // データの更新
  Future<void> update({
    required int todoId,
    required String title,
    required String description,
  }) async {
    await supabaseClient.from('todos').update({
      'title': title,
      'description': description,
    }).match({'id': todoId});
  }

  // データの追加 or 更新
  Future<void> upsert({
    int? todoId,
    required String title,
    required String description,
  }) async {
    await supabaseClient.from('todos').upsert({
      'id': todoId,
      'title': title,
      'description': description,
    });
  }

  // データの削除
  Future<void> delete({required int todoId}) async {
    await supabaseClient.from('todos').delete().match({'id': todoId});
  }
}
```

それぞれ詳しくみていきます。

まずは `supabase_repository.dart`です。
ここでは、 `SupabaseClient` を返す純粋な Provider を Riverpod Generator で作成しています。 また、 `keepAlive: true` にして dispose されないようにしておきます。
```dart: supabase_repository.dart
@Riverpod(keepAlive: true)
SupabaseClient supabaseRepository(SupabaseRepositoryRef ref) {
  return Supabase.instance.client;
}
```

:::details Firestoreの場合
Firestore だと以下のように、インスタンスを保持しておくのと同じイメージです。
```dart: firestore.dart
@Riverpod(keepAlive: true)
FirebaseFirestore firestore(FirestoreRef ref) {
  return FirebaseFirestore.instance;
}
```
:::

次に `todo_repository.dart`です。それぞれみていきます。

以下ではビルドメソッドで先ほど定義した `SupabseClient` を遅延初期化しています。
これで `TodoRepository` の中では `supabaseClient` にアクセスすることで、 Supabase のデータ操作が行えるようになります。
```dart
late final SupabaseClient supabaseClient;
@override
void build() {
  supabaseClient = ref.read(supabaseRepositoryProvider);
}
```

次にそれぞれのデータ操作についてみていきます。

#### リアルタイム取得
以下では Todo をリアルタイムで取得する `stream` を実装しています。
`from` でテーブル名（今回は `todos`）を指定し、そこから `stream` でリアルタイムにデータを取得できます。 また、`primaryKey` に `id` フィールドを指定しています。 `id` は Int型でかつ Autoincrement の設定になっているので、基本的に同じものが生成されることはありません。したがって、 `primaryKey` に指定されています。
```dart
// リアルタイム取得
SupabaseStreamBuilder? stream({
  required FilterCondition condition,
}) {
  SupabaseStreamFilterBuilder query = supabaseClient.from('todos').stream(primaryKey: ['id']);
```

#### 〇〇より大きいフィルタリング
以下では、先ほどの `stream` の中でフィルタリングを行なっています。
SupabaseStreamFilterBuilder型の `query` に対して、 `gt`メソッドを実行しています。
ソースコードにも書いてありますが、 `gt` は 「greater than」の意味であり、第一引数のカラムにおいて、第二引数よりも大きいものを取得できます。
以下のコードでは、`created_at`のカラムに含まれるデータのうち、その値が `oneWeekAgoStr` つまり１週間前の Datetime よりも大きいものを取得してきます。
つまり、１週間以内に作成されたものを取得してきます。
```dart
// １週間前までのデータをフィルタリング
if (condition.isFilteredByWeek) {
  final oneWeekAgo = DateTime.now().subtract(const Duration(days: 7));
  final oneWeekAgoStr = DateFormat('yyyy-MM-ddTHH:mm:ss').format(oneWeekAgo);
  query = query.gt('created_at', oneWeekAgoStr) as SupabaseStreamFilterBuilder;
}
```

今回は実装していませんが、大小のフィルタリングには表のようなフィルタリングもあります。
| メソッド | 意味 | 日本語での意味 | 記号 |
| ---- | ---- | ---- | ---- |
| gte() | greater than or equal | 以上 | >= |
| lt() | less than | より小さい | < |
| lte() | less than or equal | 以下 | <= |

#### 完全一致フィルタリング
以下では `eq` メソッドを実行しています。
`eq` は「equal」を示しており、第一引数に指定されたカラムのうち、第二引数の値に等しいもののみを取得します。この場合だと、`title` に指定されている文字列が `condition.filterTitle` として渡ってきた文字列と等しいもののみをフィルタリングしています。
```dart
// タイトルが一致するもののみをフィルタリング
if (condition.isFilteredByTitle) {
  query = query.eq('title', condition.filterTitle ?? '') as SupabaseStreamFilterBuilder;
}
```

#### 並び替え
以下では `order` メソッドを実行してデータの並び替えを行なっています。
`order` では、第一引数のカラムをもとに、昇順にするか降順にするかを指定できます。
以下の場合だと、`isOrderedByCreatedAt` が true の場合は昇順に、 false の場合は降順にしています。この辺りは firestore でも `orderBy` で似たような実装があるかと思います。
```dart
// 作成日に応じて昇順、降順に並び替え
if (condition.isOrderedByCreatedAt) {
  query = query.order('created_at', ascending: true) as SupabaseStreamFilterBuilder;
} else {
  query = query.order('created_at', ascending: false) as SupabaseStreamFilterBuilder;
}
```

#### 取得件数の制限
以下では `limit` メソッドを使ってデータの取得件数を制限しています。
また、制限がない場合は 20件のみに絞るようにしています。
この `limit` もfiresotreで同じような実装があるかと思います。
```dart
// 取得件数の制限
if (condition.isLimited) {
  query = query.limit(condition.limitCount ?? 20) as SupabaseStreamFilterBuilder;
}
```

絞り込みについては以上です。
このようにデータに対して細かく条件を絞り込んで取得することができます。

#### データの全取得
以下ではデータの全取得を行なっています。
`from` で取得する対象のテーブル名を指定し、 `select` メソッドで対象のテーブルに含まれるデータを全取得できます。
```dart
// 全データの取得
Future<List<Map<String, dynamic>>> select() async {
  final data = await supabaseClient.from('todos').select();
  return data;
}
```

#### データの追加
以下ではデータの追加を行なっています。
データの追加は `insert` メソッドで行うことができ、引数に追加したいデータを指定します。
今回は `created_at` はデフォルトで現在時刻、`is_done` はデフォルトで FALSE に指定しているため、 `title` と `description` のみを追加すれば、自動的に設定されるようになっています。
```dart
// データの追加
Future<void> insert({
  required String title,
  required String description,
}) async {
  await supabaseClient.from('todos').insert({
    'title': title,
    'description': description,
  });
}
```

#### データの更新
以下ではデータの更新を行なっています。
`update` メソッドでは、第一引数に更新後のデータを代入します。ただし、 `match` メソッドでどの Todo に対して更新をかけるかを指定する必要があります。
今回は primaryKey が id であるため、 `todoId` も一緒に受け取り、その id と一致する Todo に対して更新をかけています。
```dart
// データの更新
Future<void> update({
  required int todoId,
  required String title,
  required String description,
}) async {
  await supabaseClient.from('todos').update({
    'title': title,
    'description': description,
  }).match({'id': todoId});
}
```

#### データの追加 or 更新
以下ではデータの追加または更新を行なっています。
`upsert` メソッドは名前の通り、データの追加または更新を行うことができます。
具体的には、primaryKey である `id` をもとに、すでに同じ `id` のデータが存在する場合はその `id` の Todo を更新します。同じ `id` のデータが存在しない場合は新しい Todo としてデータを追加します。
```dart
// データの追加 or 更新
Future<void> upsert({
  int? todoId,
  required String title,
  required String description,
}) async {
  await supabaseClient.from('todos').upsert({
    'id': todoId,
    'title': title,
    'description': description,
  });
}
```

upsert に関しては以下の公式ドキュメントがわかりやすかったのでご参照ください。
https://supabase.com/docs/reference/dart/upsert

#### データの削除
以下ではデータの削除を行なっています。
`delete` メソッドでデータの削除を行うことができ、`update` の場合と同様に、 `match` メソッドに primaryKey である `id` を渡し、一致する id を持つ Todo を削除することができます。
```dart
// データの削除
Future<void> delete({required int todoId}) async {
  await supabaseClient.from('todos').delete().match({'id': todoId});
}
```

Repository の実装は以上になります。
今回実装したのは数あるメソッドのほんの一部であるため、詳しくは以下の公式ドキュメントをご覧ください。
様々なメソッドと共に「このデータの場合にこのメソッドを実行すると結果はどうなるのか？」といった実例が紹介されているので非常にイメージしやすいです。
https://supabase.com/docs/reference/dart/select

### 5. UIの作成
最後にUIの実装を行います。
コードは以下の通りです。
```dart: todo_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_sample/models/filter_condition.dart';
import 'package:supabase_sample/models/todo.dart';
import 'package:supabase_sample/repository/todo_repository.dart';
import 'package:supabase_sample/views/todo_detail_page.dart';

class TodoPage extends HookConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const limitCount = 3;
    final isFilteredByWeek = useState(false);
    final isFilteredByTitle = useState(false);
    final isLimited = useState(false);
    final isOrderedByCreatedAt = useState(false);
    final filterTitleController = useTextEditingController();
    final todoRepositoryNotifier = ref.read(todoRepositoryProvider.notifier);
    final todoStream = todoRepositoryNotifier.stream(
      condition: FilterCondition(
        isFilteredByWeek: isFilteredByWeek.value,
        isFilteredByTitle: isFilteredByTitle.value,
        isLimited: isLimited.value,
        isOrderedByCreatedAt: isOrderedByCreatedAt.value,
        filterTitle: filterTitleController.text,
        limitCount: limitCount,
      ),
    );
    TextEditingController titleController = TextEditingController();
    TextEditingController descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StatefulBuilder(
                  builder: (context, setState) {
                    return SimpleDialog(
                      title: const Text('フィルター'),
                      contentPadding: const EdgeInsets.all(24),
                      children: [
                        Column(
                          children: [
                            Row(
                              children: [
                                const Text('１週間前まで'),
                                const Spacer(),
                                Switch(
                                  value: isFilteredByWeek.value,
                                  onChanged: (value) {
                                    setState(
                                      () {
                                        isFilteredByWeek.value = value;
                                      },
                                    );
                                  },
                                )
                              ],
                            ),
                            const Gap(8),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('タイトル名（完全一致）'),
                                    if (isFilteredByTitle.value)
                                      SizedBox(
                                        width: 150,
                                        height: 50,
                                        child: TextField(
                                          controller: filterTitleController,
                                        ),
                                      ),
                                  ],
                                ),
                                const Spacer(),
                                Switch(
                                  value: isFilteredByTitle.value,
                                  onChanged: (value) {
                                    setState(
                                      () {
                                        isFilteredByTitle.value = value;
                                      },
                                    );
                                  },
                                )
                              ],
                            ),
                            const Gap(8),
                            Row(
                              children: [
                                const Text('作成日時 昇順'),
                                const Spacer(),
                                Switch(
                                  value: isOrderedByCreatedAt.value,
                                  onChanged: (value) {
                                    setState(
                                      () {
                                        isOrderedByCreatedAt.value = value;
                                      },
                                    );
                                  },
                                )
                              ],
                            ),
                            const Gap(8),
                            Row(
                              children: [
                                const Text('TODOを3つに絞る'),
                                const Spacer(),
                                Switch(
                                  value: isLimited.value,
                                  onChanged: (value) {
                                    setState(
                                      () {
                                        isLimited.value = value;
                                      },
                                    );
                                  },
                                )
                              ],
                            ),
                            const Gap(8),
                          ],
                        )
                      ],
                    );
                  },
                ),
              );
            },
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: todoStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('データが登録されていません'),
            );
          } else {
            final todos = snapshot.data!;
            return ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                DateTime createdAt = DateTime.parse(todos[index]['created_at']);
                String formattedCreatedAt =
                    DateFormat('yyyy年M月d日H時m分').format(createdAt);
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TodoDetailPage(
                          todo: Todo(
                            id: todos[index]['id'],
                            title: todos[index]['title'],
                            description: todos[index]['description'],
                            createdAt: todos[index]['created_at'],
                            isDone: todos[index]['is_done'],
                          ),
                        ),
                      ),
                    );
                  },
                  title: Text(todos[index]['title']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(todos[index]['description']),
                      Text(formattedCreatedAt),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              titleController.text = todos[index]['title'];
                              descriptionController.text =
                                  todos[index]['description'];
                              return SimpleDialog(
                                title: const Text('Edit Todo'),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                children: [
                                  const Gap(8),
                                  TextFormField(
                                    controller: titleController,
                                  ),
                                  const Gap(8),
                                  TextFormField(
                                    controller: descriptionController,
                                  ),
                                  const Gap(16),
                                  TextButton(
                                    onPressed: () async {
                                      await todoRepositoryNotifier.update(
                                        todoId: todos[index]['id'],
                                        title: titleController.text,
                                        description: descriptionController.text,
                                      );
                                      if (!context.mounted) return;
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Update'),
                                  ),
                                  const Gap(24),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.edit,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await todoRepositoryNotifier.delete(
                            todoId: todos[index]['id'],
                          );
                        },
                        icon: const Icon(
                          Icons.delete,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return SimpleDialog(
                title: const Text('Add Todo'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  TextFormField(
                    controller: titleController,
                  ),
                  TextFormField(
                    controller: descriptionController,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      await todoRepositoryNotifier.insert(
                        title: titleController.text,
                        description: descriptionController.text,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Add',
                    ),
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

```dart: todo_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:supabase_sample/models/todo.dart';

class TodoDetailPage extends ConsumerWidget {
  const TodoDetailPage({
    super.key,
    required this.todo,
  });

  final Todo todo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime createdAt = DateTime.parse(todo.createdAt);
    String formattedCreatedAt = DateFormat('yyyy年M月d日H時m分').format(createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              todo.title,
              style: const TextStyle(fontSize: 20),
            ),
            const Gap(8),
            Text(todo.description),
            const Gap(8),
            Text(formattedCreatedAt),
          ],
        ),
      ),
    );
  }
}
```

`todo_detail_page.dart` は前のページから Todo を受け取り、表示させているだけのページなので、解説は省きます。

`todo_page` についてより詳しくみていきます。

以下ではそれぞれのフィルタリングの際に使用する変数を定義しています。
Repository の方の `stream` に対してそれぞれフィルタリングをかけるかどうかを保持したり、フィルタリングに必要な変数を初めに定義しています。
```dart
const limitCount = 3;  // 取得件数の制限件数
final isFilteredByWeek = useState(false);  // １週間以内のデータに絞るかどうかのbool
final isFilteredByTitle = useState(false);  // タイトル完全一致で絞るかどうかのbool
final isLimited = useState(false);  // データの取得件数を制限するかどうかのbool
final isOrderedByCreatedAt = useState(false);  // 作成日の昇順で並び替えるかどうかのbool
final filterTitleController = useTextEditingController();  // タイトル完全一致で絞る場合のテキストコントローラー
```

次に以下では `todoRepositoryProvider` の取得と `stream` の取得を行なっています。
`stream`　に対して、それぞれのデータのフィルタリングを行うかどうかの情報を持つ `FilterCondition` を渡しています。
このデータを受け取った `todoRepositoryProvider` の `stream` で条件分岐を行い、フィルタリングを適用するかどうかを決定しています。
```dart
final todoRepositoryNotifier = ref.read(todoRepositoryProvider.notifier);
final todoStream = todoRepositoryNotifier.stream(
  condition: FilterCondition(
    isFilteredByWeek: isFilteredByWeek.value,
    isFilteredByTitle: isFilteredByTitle.value,
    isLimited: isLimited.value,
    isOrderedByCreatedAt: isOrderedByCreatedAt.value,
    filterTitle: filterTitleController.text,
    limitCount: limitCount,
  ),
);
```

以下では、AppBarの実装を行なっています。
`actions` にあるアイコンを押すことでダイアログが開き、そこでデータのフィルタリングの設定が行えるようにしています。
```dart
appBar: AppBar(
  title: const Text('Todo List'),
  actions: [
    IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setState) {
              return SimpleDialog(
                title: const Text('フィルター'),
```

以下ではデータを１週間前までのものに絞るかどうかの `Switch` を実装しています。
ここで先ほど `useState` で管理していた `isFilteredByWeek` の値を切り替えています。
```dart
Row(
  children: [
    const Text('１週間前まで'),
    const Spacer(),
    Switch(
      value: isFilteredByWeek.value,
      onChanged: (value) {
        setState(
          () {
            isFilteredByWeek.value = value;
          },
        );
      },
    )
  ],
),
```

Switch が押された後の処理の流れは以下の通りです。
`isFilteredByWeek` の切り替え
→ `FilterCondition` が変更され、データの絞り込み条件が変わる
→ Repository の `stream` の絞り込み条件が変わる
→ 変更を検知してデータが切り替わる

以下ではタイトル完全一致の絞り込みを行うかどうかを切り替える Switch と、Switch が On の場合にどのような文字列でテキストを絞り込むかの実装を行なっています。
データの流れとしては上の「１週間以内のデータで絞り込む」場合と同様であり、絞り込みを行うかどうかに加えて、どの文字列で絞り込むかも渡しています。
```dart
Row(
  children: [
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('タイトル名（完全一致）'),
        if (isFilteredByTitle.value)
          SizedBox(
            width: 150,
            height: 50,
            child: TextField(
              controller: filterTitleController,
            ),
          ),
        ],
      ),
      const Spacer(),
      Switch(
        value: isFilteredByTitle.value,
        onChanged: (value) {
          setState(
            () {
              isFilteredByTitle.value = value;
            },
          );
        },
      )
  ],
),
```

以下のフィルタリングのダイアログの実装は上記の二つのフィルタリングの実装とほぼ同じであるため、説明は省略します。

以下では Scaffold の body として `StreamBuilder` を指定しています。
`StreamBuilder` の `stream` に上で定義した `todoStream` を渡しています。
この `todoStream` には必要に応じてフィルタリングされたデータが流れ込み、フィルタリングの条件が変更されればそれに応じて表示するデータを変更するようになっています。
データを読み込み中のときは `CircularProgressIndicator` を、データが存在しない場合は「データが登録されていません」テキストを表示させています。
```dart
body: StreamBuilder<List<Map<String, dynamic>>>(
  stream: todoStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(
        child: Text('データが登録されていません'),
      );
    }
```

以下では Todo のデータが存在する場合の実装を行なっています。
`todos` として取得した stream をデータとして展開し、 `ListView.builder` に渡しています。
一つ一つの Todo データは `ListTile` に渡されます。
```dart
final todos = snapshot.data!;
  return ListView.builder(
    itemCount: todos.length,
    itemBuilder: (context, index) {
      DateTime createdAt = DateTime.parse(todos[index]['created_at']);
      String formattedCreatedAt = DateFormat('yyyy年M月d日H時m分').format(createdAt);
      return ListTile(
```

以下では `ListTile` がタップされた時の処理を記述しています。
タップされた場合は `TodoDetailPage` に Todo のデータを渡して遷移するようにしています。
```dart
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TodoDetailPage(
        todo: Todo(
          id: todos[index]['id'],
          title: todos[index]['title'],
          description: todos[index]['description'],
          createdAt: todos[index]['created_at'],
          isDone: todos[index]['is_done'],
        ),
      ),
    ),
  );
},
```

少し長いですが、以下では Todo の更新処理を記述しています。
編集アイコン（鉛筆のアイコン）が押された時にダイアログを表示し、ダイアログ内で `title`, `description` を編集できます。
編集が完了した後に「Update」ボタンを押すと、`todoRepositoryNotifier.update` が走ってデータが更新されます。
```dart
IconButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) {
        titleController.text = todos[index]['title'];
        descriptionController.text = todos[index]['description'];
        return SimpleDialog(
          title: const Text('Edit Todo'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            const Gap(8),
            TextFormField(
              controller: titleController,
            ),
            const Gap(8),
            TextFormField(
              controller: descriptionController,
            ),
            const Gap(16),
            TextButton(
              onPressed: () async {
                await todoRepositoryNotifier.update(
                  todoId: todos[index]['id'],
                  title: titleController.text,
                  description: descriptionController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
            const Gap(24),
          ],
        );
      },
    );
  },
  icon: const Icon(
    Icons.edit,
  ),
),
```

以下では削除アイコン（ゴミ箱ボタン）が押された時の処理を記述しています。
`todoRepositoryNotifier.delete` で、選択されている Todo の id を渡すことで、その Todo を削除することができます。
```dart
IconButton(
  onPressed: () async {
    await todoRepositoryNotifier.delete(
      todoId: todos[index]['id'],
    );
  },
  icon: const Icon(
    Icons.delete,
  ),
),
```

最後に、以下では Todo の追加処理を行なっています。
FloatingActionButtonを押すとダイアログが開き、`title`, `description` をそれぞれ編集して「Add」ボタンを押すと、`todoRepositoryNotifier.insert` が走り、入力したデータを持つ Todo が新たに作成されます。
```dart
floatingActionButton: FloatingActionButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Add Todo'),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          children: [
            TextFormField(
              controller: titleController,
            ),
            TextFormField(
              controller: descriptionController,
            ),
            ElevatedButton(
              onPressed: () async {
                await todoRepositoryNotifier.insert(
                  title: titleController.text,
                  description: descriptionController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              },
              child: const Text(
                'Add',
              ),
            ),
          ],
        );
      },
    );
  },
  child: const Icon(Icons.add),
),
```

以上でUIの作成も完了です。
これで実行すると以下のように動くかと思います。

https://youtube.com/shorts/g-j2q4vy7A8


## まとめ
最後まで読んでいただいてありがとうございました。

今回は Flutter で Supabase を使ってみました。

使ってみて特に感じたメリットは以下かと思います。
+ 導入が簡単であること
+ ドキュメントが非常に充実していること
+ PostgreSQLの強みが活かせる（データ検索や書き方について）
+ FreeプランでもAPIリクエストが無制限で無料

筆者は今まで基本的にNoSQLを中心に扱ってきましたが、今回 Supabase に触れてみて、簡単な実装であれば短時間でできたので、NoSQLに慣れていないメンバーがいる場合などは Supabase を導入した方がより開発がスムーズに進むかと思います。
また、複雑なフィルタリングを行う場合、今回実装したように絞り込み条件を重ねがけしてデータを取得できるので、比較的簡単に実装できるかと思いました。

一方で、今回は簡単なアプリだったので問題になりませんでしたが、NoSQL特にFirebaseの場合は Freezed でデータクラスと fromJson と toJson を定義しておけば比較的簡単にデータ操作ができるのに対し、Supabase ではデータ構造や変換に関して工夫する必要があると感じました。

今回紹介できなかった Auth などもあるので、次の実装の機会にまた共有できればと思います。
誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://supabase.com/docs/reference/dart/select

https://zenn.dev/flutteruniv_dev/articles/crud_with_supabase

https://zenn.dev/joo_hashi/articles/da265483f0073c