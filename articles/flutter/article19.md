## 初めに
今回はFlutterでユニットテストのテストコードを書いてみます。

## 記事の対象者
+ Flutter 学習者
+ Flutter でテストコードを書いてみたい方
+ Flutter で Firestore の処理を含むテストを行いたい方

## 目的
今回はユニットテストを書いていきたいと思います。
最終的にはFirestoreのモックを含むテストを実装してみたいと思います。
今回実装したコードは以下のリポジトリで確認できます。
https://github.com/Koichi5/flutter_unit_test_app

## ユニットテスト（単体テスト）
ユニットテスト（単体テスト）に関しては[Unit Testing Principles, Practices, and Patterns](https://www.manning.com/books/unit-testing)（日本語版：[単体テストの考え方 / 使い方](https://book.mynavi.jp/ec/products/detail/id=134252)）の内容を引用してみたいと思います。

### ユニットテストとは
> 単体テストとして定義されるテストには次に挙げる3つの重要な性質がすべて備えられていることになります。つまり、自動化されていて、次の3つの性質を全て備えるものが単体テストとなるのです：
> ・「単体（unit）と呼ばれる少量のコードを検証する」
> ・実行時間が短い
> ・隔離された状態で実行される（単体テストの考え方 / 使い方: p28）

### ユニットテストの目的
> 単体テストをすることで何を成し遂げたいのでしょうか？その答えは、ソフトウェア開発プロジェクトの成長を持続可能なものにする、ということです。（単体テストの考え方 / 使い方: p7）

## 導入
以下のパッケージの最新バージョンを `pubspec.yaml`に記述
今回は RiverpodGenerator 等を使用していますが、これらを使用しない場合は導入は必要ありません。
dependencies
+ [riverpod](https://pub.dev/packages/riverpod)
+ [riverpod_annotation](https://pub.dev/packages/riverpod_annotation)
+ [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
+ [freezed_annotation](https://pub.dev/packages/freezed_annotation)
+ [cloud_firestore](https://pub.dev/packages/cloud_firestore)
+ [firebase_core](https://pub.dev/packages/firebase_core)
+ [fake_cloud_firestore](https://pub.dev/packages/fake_cloud_firestore)

dev_dependencies
+ [riverpod_generator](https://pub.dev/packages/riverpod_generator)
+ [build_runner](https://pub.dev/packages/build_runner)
+ [freezed](https://pub.dev/packages/freezed)
+ [json_serializable](https://pub.dev/packages/json_serializable)

また、`dev_dependencies` に `flutter_test` が追加されている必要があります。

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  flutter_riverpod: ^2.5.1
  freezed_annotation: ^2.4.1
  cloud_firestore: ^4.17.2
  firebase_core: ^2.30.1
  fake_cloud_firestore: ^2.5.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
```

または

以下をターミナルで実行
```
flutter pub add riverpod riverpod_annotation flutter_riverpod freezed_annotation cloud_firestore firebase_core fake_cloud_firestore
flutter pub add -d build_runner riverpod_generator build_runner freezed json_serializable
```

## 実装
以下の手順でテストコードの実装を進めていきたいと思います。
1. Counter のユニットテスト
2. User モデルのユニットテスト
3. User Repository のユニットテスト

### 1. Counter のユニットテスト
まずは flutter create でアプリを作成したときに表示されるデフォルトの Counter のテストコードを書いてみたいと思います。なお、テストしやすいように Counter のロジックを分離してから実装します。
以下がUIとロジックのコードになります。
```dart: my_home_page.dart
import 'package:flutter/material.dart';
import 'package:testing_app/domain/counter.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  // ignore: library_private_types_in_public_api
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final Counter counter = Counter();

  void _incrementCounter() {
    setState(() {
      counter.incrementCounter();
    });
  }

  void _decrementCounter() {
    setState(() {
      counter.decrementCounter();
    });
  }

  void _resetCounter() {
    setState(() {
      counter.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '${counter.count}',
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () {
                      _incrementCounter();
                    },
                    child: const Text('+')),
                ElevatedButton(
                    onPressed: () {
                      _decrementCounter();
                    },
                    child: const Text('-')),
                ElevatedButton(
                    onPressed: () {
                      _resetCounter();
                    },
                    child: const Text('reset')),
              ],
            )
          ],
        ),
      ),
    );
  }
}
```

```dart: counter.dart
class Counter {
  int _counter = 0;

  int get count => _counter;

  void incrementCounter() {
    _counter++;
  }

  void decrementCounter() {
    _counter--;
  }

  void reset() {
    _counter = 0;
  }
}
```

これで実行するとボタンを押すとカウントのプラス、マイナス、リセットが行えるようになります。

次にテストコードが以下になります。
```dart: counter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/domain/counter.dart';

void main() {
  late Counter counter;

  setUp(() {
    counter = Counter();
  });

  group('Counter Class -', () {
    test(
        'Counter Class が初期化された時、count の値は 0 である',
        () {
      final val = counter.count;
      expect(val, 0);
    });

    test(
        'Counter Class の incrementCounter が呼び出された時、count の値は 1 である',
        () {
      counter.incrementCounter();
      final val = counter.count;

      equals(val, 1);
    });

    test(
        'Counter Class の decrementCounter が呼び出された時、count の値は 1 である',
        () {
      counter.decrementCounter();
      final val = counter.count;

      equals(val, -1);
    });

    test(
        'Counter Class の reset が呼び出された時、count の値は 0 である',
        () {
      counter.reset();

      final val = counter.count;

      equals(val, 0);
    });
  });
}
```

テストコードに関してそれぞれ見ていきます。

以下の部分ではテスト対象である `Counter` の初期化を行なっています。
テストコード内では `setUp` を実行することができ、 `setUp` の中に書かれたコードは各テストケースの実行前に毎回実行されます。以下では各テストケースの実行前に毎回 `Counter` が初期化されるようになっています。
```dart: counter.dart
late Counter counter;

setUp(() {
  counter = Counter();
});
```

ちなみに、`setUpAll` という関数も設けられていますが、 `setUp` 関数が各テストケースが実行される前に毎回実行されるのに対し、`setUpAll` は全てのテストケースの前に一回だけ実行されるようになります。
具体的には以下のような違いがあります。
```dart
setUp(() {
  print('setUp')
});

test('test1', (){
  print('test1')
});

test('test2', (){
  print('test1')
});

test('test3', (){
  print('test1')
});

// setUp -> test1 -> setUp -> test2 -> setUp -> test3

setUpAll(() {
  print('setUpAll')
});

test('test1', (){
  print('test1')
});

test('test2', (){
  print('test1')
});

test('test3', (){
  print('test1')
});

// setUpAll -> test1 -> test2 -> test3
```

以下の部分ではテストの説明にもある通り、 `Counter` が初期化された段階で `count` の値が 0 になっていることを確認しています。
`test` 関数では第一引数にテストの説明文、第二引数にテスト内で実行するテスト内容を記述します。
`expect` では第一引数には `actual` として実際のデータ、第二引数には `matcher` として、実際のデータがどのような値になっているべきかという条件文を入れます。
```dart: counter_test.dart
test(
  'Counter Class が初期化された時、count の値は 0 である',
  () {
    final val = counter.count;
    expect(val, 0);
  }
);
```

上記の `expect`は以下のように書き換えることができ、「実際のデータは 0 と同じである」と読み取ることができます。
```dart
expect(val, equals(0));
```

以下のコードでは `incrementCounter`, `decrementCounter`, `reset` 関数のテストを行なっています。基本的なテスト手法は先ほどのテストケースと同じです。
```dart: counter_test.dart
test(
  'Counter Class の incrementCounter が呼び出された時、count の値は 1 である',
  () {
    counter.incrementCounter();
    final val = counter.count;

    equals(val, 1);
});

test(
  'Counter Class の decrementCounter が呼び出された時、count の値は 1 である',
  () {
     counter.decrementCounter();
     final val = counter.count;

     equals(val, -1);
});

test(
  'Counter Class の reset が呼び出された時、count の値は 0 である',
  () {
    counter.reset();
    final val = counter.count;

    equals(val, 0);
});
```

実際にテストを実行する際はVSCodeの場合、以下の画像の四角で囲まれたボタンを押すことで実行できます。今回のは `group` を使って `Counter` のテストケースを全てまとめているため、赤色の四角で示されている `group` の横のボタンを押すと全てのテストケースを実行できます。

個別のテストケースを実行したい場合は青色の四角で囲まれた、それぞれのテストケースの横のボタンを押すとそれぞれで実行できます。
![](https://storage.googleapis.com/zenn-user-upload/9841f0bd2234-20240506.png)

先ほどのコードで実行すると全てのテストケースが問題なく実行されるかと思います。

仮に「初期化の際に count の値は 0 である」というテストケースに関して、以下のように `expect` を 1 に変更して実行すると以下のようなエラーになります。
```dart: counter_test.dart
test(
  'Counter Class が初期化された時、count の値は 0 である',
  () {
    final val = counter.count;
    expect(val, 1);  // 1 に変更
});
```

エラー内容
```
Expected: <1>
  Actual: <0>
```

このように実際の値と期待していた値が異なる場合はテストケースが失敗になるため、コードの問題を早く見つけることができます。

### 2. User モデルのユニットテスト
先ほどの章では class のユニットテストを行いましたが、次は freezed で生成されたモデルのテストを行いたいと思います。
テスト対象のコードは以下の通りです。
`email`, `name`, `id`, `website` の四つの属性を持つシンプルな User モデルを対象とします。
```dart: user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'entity.freezed.dart';
part 'entity.g.dart';

@freezed
abstract class User with _$User {
  const factory User({
    required String email,
    required String name,
    required int id,
    required String website,
  }) = _User;

  const User._();

  factory User.fromJson(Map<String, dynamic> json) =>
      _$UserFromJson(json);

  static String get collectionName => 'users';
}
```

テストコードは以下の通りです。
```dart: user_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/domain/user/entity.dart';

void main() {
  test('User model test', () {
    const user = User(
      email: 'sample@email.com',
      name: 'user-name',
      id: 1,
      website: 'https://website.com',
    );

    expect(user.email, equals('sample@email.com'));
    expect(user.name, equals('user-name'));
    expect(user.id, equals(1));
    expect(user.website, equals('https://website.com'));
  });
}
```

先ほどのテストより少しシンプルかと思います。
`User`のそれぞれのプロパティに値を入れて正常な値が代入されているかをテストしています。

### 3. User Repository のユニットテスト
最後に先ほど作成、テストした `User` データを含む User Repository のテストを実装したいと思います。なお、この章ではUIの具体的な実装は行わず、 User Repository のテストのみに焦点を当てて実装を行います。
今回テスト対象とする User Repository のコードは以下です。
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_app/domain/repository/db_manager.dart';
import 'package:testing_app/domain/user/entity.dart';
import 'package:testing_app/providers/firebase_provider.dart';

part 'repo.g.dart';

@riverpod
class UserRepo extends _$UserRepo {
  FirebaseFirestore get db => ref.read(firestoreProvider);
  DbManager get dbManager => ref.read(dbManagerProvider.notifier);

  CollectionReference<User> get collection =>
      db.collection(User.collectionName).withConverter<User>(
            fromFirestore: (snapshot, _) => User.fromJson(snapshot.data()!),
            toFirestore: (data, _) => data.toJson(),
          );

  @override
  void build() {}

  Future<String> save({
    required String email,
    required String name,
    required int id,
    required String website,
  }) async {
    final doc = collection.doc();
    final user = User(email: email, name: name, id: id, website: website);

    return doc.set(user, SetOptions(merge: true)).then((value) => doc.id);
  }

  Future<String> update({
    required String userId,
    required String email,
    required String name,
    required int id,
    required String website,
  }) async {
    final doc = collection.doc(userId);
    final user = User(email: email, name: name, id: id, website: website);

    return doc.set(user, SetOptions(merge: true)).then((value) => doc.id);
  }

  Future<User> fetchUserById(String userId) async =>
      collection.doc(userId).get().then((value) {
        if (value.data() == null) {
          throw Error();
        }
        return value.data()!;
      });

  Future<void> deleteUser(String userId) async =>
      collection.doc(userId).delete();

  Query<User> _query({required bool descending}) {
    final query = collection
        .orderBy('id', descending: descending);
    return query;
  }

  Future<List<User>> fetchAllUserList({required bool descending}) async =>
      dbManager.getAllData(_query(descending: descending));

  Future<List<User>> fetchLocalUserList({required bool descending}) async =>
      dbManager.getLocalData(_query(descending: descending));

  Stream<DocumentSnapshot<User>> streamUser(String userId) =>
      collection.doc(userId).snapshots();
}
```

また、User Repository の実装に必要なそれぞれのProviderの実装は以下のようになっています。
`firestoreProvider` では基本的には `FirebaseFirestore` のインスタンスを返却しています。

```dart: firebase_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_provider.g.dart';

@Riverpod(keepAlive: true)
FirebaseFirestore firestore(FirestoreRef ref) {
  final db = FirebaseFirestore.instance;
  if (db.settings.persistenceEnabled == false) {
    db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
  return db;
}
```

また、`DbManager` ではデータ配列の並び替えやローカルからの取得、通常のデータ取得などを行なっています。
```dart: db_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'db_manager.g.dart';

@Riverpod(keepAlive: true)
class DbManager extends _$DbManager {
  @override
  void build() {}

  Future<List<T>> getLocalData<T>(Query<T> query) async => query
      .get(const GetOptions(source: Source.cache))
      .then((value) => value.docs.map((e) => e.data()).toList());

  Future<List<T>> getAllData<T>(
    Query<T> query,
  ) async =>
      _getQuery(query).then((query) async {
        final result = await query.get();
        return result;
      }).then((value) async {
        final data = await getLocalData(query);
        return data;
      });

  Future<Stream<QuerySnapshot<T>>> streamLatestData<T>(
    Query<T> query,
  ) async =>
      _getQuery(query).then((query) => query.snapshots());

  Future<Query<T>> _getQuery<T>(
    Query<T> query,
  ) async =>
      query.limit(1).get(const GetOptions(source: Source.cache)).then(
            (value) => value.docs.isEmpty
                ? query
                : query.endAtDocument(value.docs.first),
          );
}
```

Repository のテストでは、実際の Repository ではなく、FakeRepository を使用するようにします。今回は `FakeUserRepo` と `FakeDbManager` の二つを作成しています。
`FakeUserRepo` のコードはそれぞれ以下の通りです。
```dart: fake_user_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:testing_app/domain/user/entity.dart';

import '../../db_manager/fake_repo/fake_db_manager.dart';

part 'fake_repo.g.dart';

@riverpod
class FakeUserRepo extends _$FakeUserRepo {
  late FakeFirebaseFirestore instance;
  late FakeDbManager fakeDbManager;

  @override
  void build() {
    instance = FakeFirebaseFirestore();
    fakeDbManager = FakeDbManager();
  }

  CollectionReference<User> get collection =>
      instance.collection(User.collectionName).withConverter<User>(
            fromFirestore: (snapshot, _) => User.fromJson(snapshot.data()!),
            toFirestore: (data, _) => data.toJson(),
          );

  Future<String> save({
    required String email,
    required String name,
    required int id,
    required String website,
  }) async {
    final doc = collection.doc();
    final user = User(email: email, name: name, id: id, website: website);

    return doc.set(user, SetOptions(merge: true)).then((value) => doc.id);
  }

  Future<String> update({
    required String userId,
    required String email,
    required String name,
    required int id,
    required String website,
  }) async {
    final doc = collection.doc(userId);
    final user = User(email: email, name: name, id: id, website: website);

    return doc.set(user, SetOptions(merge: true)).then((value) => doc.id);
  }

  Future<User> fetchUserById(String userId) async =>
      collection.doc(userId).get().then((value) {
        if (value.data() == null) {
          throw Error();
        }
        return value.data()!;
      });

  Future<void> deleteUser(String userId) async =>
      collection.doc(userId).delete();

  Query<User> query({required bool descending}) {
    final query = collection.orderBy('id', descending: descending);
    return query;
  }

  Future<List<User>> fetchAllUserList({required bool descending}) async =>
      fakeDbManager.getAllData(query(descending: descending));

  Future<List<User>> fetchLocalUserList({required bool descending}) async =>
      fakeDbManager.getLocalData(query(descending: descending));

  Stream<DocumentSnapshot<User>> streamUser(String userId) =>
      collection.doc(userId).snapshots();
}
```

`FakeUserRepo` に関してもとの `UserRepo` と比較して変更した点は以下のコードです。
`FakeFirebaseFirestore` と `FakeDbManager` を遅延初期化しています。
`FakeFirebaseFirestore` は Firestore のテストをする際に使用するパッケージであり、Firestore の挙動を再現するために使用します。

```dart
  late FakeFirebaseFirestore instance;
  late FakeDbManager fakeDbManager;

  @override
  void build() {
    instance = FakeFirebaseFirestore();
    fakeDbManager = FakeDbManager();
  }
```

`FakeDbManager` のコードは以下の通りです。
```dart: fake_db_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'fake_db_manager.g.dart';

@Riverpod(keepAlive: true)
class FakeDbManager extends _$FakeDbManager {
  @override
  void build() {}

  Future<List<T>> getLocalData<T>(Query<T> query) async => query
      .get(const GetOptions(source: Source.cache))
      .then((value) => value.docs.map((e) => e.data()).toList());

  Future<List<T>> getAllData<T>(
    Query<T> query,
  ) async =>
      _getQuery(query).then((query) async {
        final result = await query.get();
        return result;
      }).then((value) async {
        final data = await getLocalData(query);
        return data;
      });

  Future<Stream<QuerySnapshot<T>>> streamLatestData<T>(
    Query<T> query,
  ) async =>
      _getQuery(query).then((query) => query.snapshots());

  Future<Query<T>> _getQuery<T>(
    Query<T> query,
  ) async =>
      query.limit(1).get(const GetOptions(source: Source.cache)).then(
            (value) => value.docs.isEmpty
                ? query
                : query.endAtDocument(value.docs.first),
          );
}
```

これで準備は完了です。

テストコードは以下の通りです。
```dart: user_repo_test.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/domain/user/entity.dart';

import '../db_manager/fake_repo/fake_db_manager.dart';
import 'fake_repo/fake_repo.dart';

void main() {
  group('Fake User Repo --', () {
    late FakeUserRepo repo;
    late FakeFirebaseFirestore fakeFirebaseFirestore;
    late FakeDbManager fakeDbManager;
    late User expectedUser;
    late List<User> expectedUserList;

    setUp(() {
      fakeFirebaseFirestore = FakeFirebaseFirestore();
      fakeDbManager = FakeDbManager();
      repo = FakeUserRepo()
        ..instance = fakeFirebaseFirestore
        ..fakeDbManager = fakeDbManager;
    });

    setUpAll(() {
      expectedUser = const User(
        email: 'email',
        name: 'name',
        id: 1,
        website: 'website',
      );

      expectedUserList = const [
        User(
          email: 'email1',
          name: 'name1',
          id: 1,
          website: 'website1',
        ),
        User(
          email: 'email2',
          name: 'name2',
          id: 2,
          website: 'website2',
        ),
        User(
          email: 'email3',
          name: 'name3',
          id: 3,
          website: 'website3',
        ),
      ];
    });

    test('UserRepo に関して、ユーザーを正しい内容で保存できる', () async {
      final userId = await repo.save(
        email: expectedUser.email,
        name: expectedUser.name,
        id: expectedUser.id,
        website: expectedUser.website,
      );

      final savedUser =
          await fakeFirebaseFirestore.collection('users').doc(userId).get();
      final data = savedUser.data() ?? {};

      expect(User.fromJson(data), equals(expectedUser));
    });

    test('UserRepo に関して、保存したユーザーをIDで取得できる', () async {
      final userRef = await fakeFirebaseFirestore
          .collection('users')
          .add(expectedUser.toJson());

      final savedUser = await repo.fetchUserById(userRef.id);

      expect(savedUser, equals(expectedUser));
    });

    test('UserRepo に関して、追加したユーザーを監視して正しい個数だけ取得できる', () async {
      final collectionRef = fakeFirebaseFirestore.collection('users');
      final snapshots = collectionRef.snapshots();
      await collectionRef.add(expectedUser.toJson());
      await Future.delayed(const Duration(milliseconds: 300));

      snapshots.listen(expectAsync1((snap) {
        expect(snap.size, equals(1));
      }));
    });

    test('UserRepo に関して、ユーザーのデータをN個追加して、監視、取得するとN個だけ取得できる', () async {
      const dataLength = 10;
      final collectionRef = fakeFirebaseFirestore.collection('users');
      final snapshots = collectionRef.snapshots();
      for (int i = 0; i < dataLength; i++) {
        await collectionRef.add(expectedUser.toJson());
      }
      await Future.delayed(const Duration(milliseconds: 300));

      snapshots.listen(expectAsync1((snap) {
        expect(snap.size, equals(dataLength));
      }));
    });

    test('UserRepo に関して、複数のユーザーのデータを保存して、正しいデータの個数を取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchAllUserList(descending: false);
      expect(fetchedUserList.length, equals(3));
    });

    test('UserRepo に関して、複数のユーザーのデータを保存して、正しいデータを昇順で取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchAllUserList(descending: false);
      for (int i = 0; i < fetchedUserList.length; i++) {
        expect(fetchedUserList[i], expectedUserList[i]);
      }
    });

    test('UserRepo に関して、複数のユーザーのデータを保存して、正しいデータを降順で取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchAllUserList(descending: false);
      for (int i = fetchedUserList.length; i < fetchedUserList.length; i--) {
        expect(fetchedUserList[i], expectedUserList[i]);
      }
    });

    test('UserRepo に関して、複数のユーザーのデータを保存して、ローカルから正しいデータの個数を取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchLocalUserList(descending: false);
      expect(fetchedUserList.length, equals(3));
    });

    test('UserRepo に関して、複数のユーザーのデータを保存して、ローカルから正しいデータを昇順で取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchLocalUserList(descending: false);
      for (int i = 0; i < fetchedUserList.length; i++) {
        expect(fetchedUserList[i], expectedUserList[i]);
      }
    });

    test('UserRepo に関して、複数のユーザーのデータを保存して、ローカルから正しいデータを降順で取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchLocalUserList(descending: false);
      for (int i = fetchedUserList.length; i < fetchedUserList.length; i--) {
        expect(fetchedUserList[i], expectedUserList[i]);
      }
    });

    test('UserRepo に関して、ユーザーのデータを更新すると、更新した結果が反映されている', () async {
      const updatedUser = User(
        email: 'updated-email',
        name: 'updated-name',
        id: 1,
        website: 'updated-website',
      );

      final userRef = await fakeFirebaseFirestore
          .collection('users')
          .add(expectedUser.toJson());

      await repo.update(
        userId: userRef.id,
        email: updatedUser.email,
        name: updatedUser.name,
        id: updatedUser.id,
        website: updatedUser.website,
      );

      final savedUser =
          await fakeFirebaseFirestore.collection('users').doc(userRef.id).get();
      final data = savedUser.data() ?? {};

      expect(User.fromJson(data), equals(updatedUser));
    });

    test('UserRepo に関して、ユーザーを追加した後削除すると、当該ユーザーが削除されている', () async {
      final userRef = await fakeFirebaseFirestore
          .collection('users')
          .add(expectedUser.toJson());

      await repo.deleteUser(userRef.id);

      final savedUser =
          await fakeFirebaseFirestore.collection('users').doc(userRef.id).get();

      expect(savedUser.exists, equals(false));
    });
  });
}
```

コードが長いので、それぞれ分けて詳しく見ていきます。

まずは以下のセットアップの部分です。
`FakeUserRepo`, `FakeFirebaseFirestore`, `FakeDbManager` に関しては、遅延初期化を行い、`setUp` 処理でそれぞれインスタンス化しています。
`expectedUser`, `expectedUserList` は、テストで使用する User データであり、一つの User データとリスト形式の User データを用意しています。これらはテスト実行前に一度だけ呼ばれる `setUpAll` のなかで定義されています。
```dart
    late FakeUserRepo repo;
    late FakeFirebaseFirestore fakeFirebaseFirestore;
    late FakeDbManager fakeDbManager;
    late User expectedUser;
    late List<User> expectedUserList;

    setUp(() {
      fakeFirebaseFirestore = FakeFirebaseFirestore();
      fakeDbManager = FakeDbManager();
      repo = FakeUserRepo()
        ..instance = fakeFirebaseFirestore
        ..fakeDbManager = fakeDbManager;
    });
    setUpAll(() {
      expectedUser = const User(
        email: 'email',
        name: 'name',
        id: 1,
        website: 'website',
      );

      expectedUserList = const [
        User(
          email: 'email1',
          name: 'name1',
          id: 1,
          website: 'website1',
        ),
        User(
          email: 'email2',
          name: 'name2',
          id: 2,
          website: 'website2',
        ),
        User(
          email: 'email3',
          name: 'name3',
          id: 3,
          website: 'website3',
        ),
      ];
    });
```

次に以下の部分です。
テストの説明文にもある通り、ユーザーが正しい内容で保存できるかどうかを調べるためのテストケースです。具体的には、`FakeUserRepo` の `save` 関数のテストになります。
テスト対象以外の関数の影響を排除するために、`save` 以外は `fakeFirebaseFirestore` のコレクションに直接アクセスする形で取得しています。
```dart
    test('UserRepo に関して、ユーザーを正しい内容で保存できる', () async {
      final userId = await repo.save(
        email: expectedUser.email,
        name: expectedUser.name,
        id: expectedUser.id,
        website: expectedUser.website,
      );

      final savedUser =
          await fakeFirebaseFirestore.collection('users').doc(userId).get();
      final data = savedUser.data() ?? {};

      expect(User.fromJson(data), equals(expectedUser));
    });
```

次に以下の部分です。
以下では保存したユーザーをIDで取得するテストケースです。
こちらもテスト対象である `fetchUserById` 関数以外は直接保存するようにしています。
```dart
    test('UserRepo に関して、保存したユーザーをIDで取得できる', () async {
      final userRef = await fakeFirebaseFirestore
          .collection('users')
          .add(expectedUser.toJson());

      final savedUser = await repo.fetchUserById(userRef.id);

      expect(savedUser, equals(expectedUser));
    });
```

次に以下の部分です。
以下では保存されたユーザーのデータを Stream 型で正しく取得できるかどうかを検証しています。
今回のテスト対象である `FakeUserRepo` には含まれていませんが、Stream で取得する処理のテストの例として実装しています。
```dart
    test('UserRepo に関して、追加したユーザーを監視して正しい個数だけ取得できる', () async {
      final collectionRef = fakeFirebaseFirestore.collection('users');
      final snapshots = collectionRef.snapshots();
      await collectionRef.add(expectedUser.toJson());
      await Future.delayed(const Duration(milliseconds: 300));

      snapshots.listen(expectAsync1((snap) {
        expect(snap.size, equals(1));
      }));
    });
```

次に以下の部分です。
以下では、複数のユーザーデータを保存して、保存されたデータを取得する際に正しいデータの数だけ取得できているかをテストしています。
具体的には `fetchAllUserList` 関数のテストを行なっています。
`expectedUserList` に含まれる3つの User データをそれぞれ追加して、 `fetchAllUserList` で取得したときに正常に取得できているかをテストしています。
```dart
    test('UserRepo に関して、複数のユーザーのデータを保存して、正しいデータの個数を取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchAllUserList(descending: false);
      expect(fetchedUserList.length, equals(3));
    });
```

次に以下の部分です。
以下では保存されたデータを `fetchAllUserList` 関数を用いて昇順で取得し、それぞれのデータの内容が `fetchedUserList` の User データを一致しているかどうかをテストしています。
```dart
    test('UserRepo に関して、複数のユーザーのデータを保存して、正しいデータを昇順で取得できる', () async {
      for (final user in expectedUserList) {
        await fakeFirebaseFirestore.collection('users').add(user.toJson());
      }
      final fetchedUserList = await repo.fetchAllUserList(descending: false);
      for (int i = 0; i < fetchedUserList.length; i++) {
        expect(fetchedUserList[i], expectedUserList[i]);
      }
    });
```

また、これ以外に `fetchAllUserList` 関数で降順で取得した時のテストケース、`fetchLocalUserList` 関数でデータを取得した時のテストケースを実装していますが、書き方や処理内容は似ているため省略します。

次に以下の部分についてです。
以下では、ユーザーのデータを更新したときに正常に更新されているかどうかをテストしています。
具体的には、一度追加されたデータに関して `update` を実行して、変更内容が反映されているかどうかをテストしています。他のテストケース同様、`update` 以外の処理ではコレクションに直接アクセスするようにしています。
```dart
    test('UserRepo に関して、ユーザーのデータを更新すると、更新した結果が反映されている', () async {
      const updatedUser = User(
        email: 'updated-email',
        name: 'updated-name',
        id: 1,
        website: 'updated-website',
      );

      final userRef = await fakeFirebaseFirestore
          .collection('users')
          .add(expectedUser.toJson());

      await repo.update(
        userId: userRef.id,
        email: updatedUser.email,
        name: updatedUser.name,
        id: updatedUser.id,
        website: updatedUser.website,
      );

      final savedUser =
          await fakeFirebaseFirestore.collection('users').doc(userRef.id).get();
      final data = savedUser.data() ?? {};

      expect(User.fromJson(data), equals(updatedUser));
    });
```

最後に以下の部分です。
以下では追加されたユーザーデータを削除したときに、正常にデータが削除されているかどうかをテストしています。具体的には `delete` 関数を用いてデータの削除を行い、作成した時と同様のパスにアクセスしたときにデータが残っていないかどうかをテストしています。

```dart
    test('UserRepo に関して、ユーザーを追加した後削除すると、当該ユーザーが削除されている', () async {
      final userRef = await fakeFirebaseFirestore
          .collection('users')
          .add(expectedUser.toJson());

      await repo.deleteUser(userRef.id);

      final savedUser =
          await fakeFirebaseFirestore.collection('users').doc(userRef.id).get();

      expect(savedUser.exists, equals(false));
    });
  });
```

以上の実装でテストケースを実行するとそれぞれパスするかと思います。
少し条件を変更するなどしてテストケースが失敗するかどうかも見ておく必要があるかと思います。

今回紹介できなかったRiverpodの `ProviderContainer` や `overrides` を使ったテスト、`mockito` を用いたテストに関しても今後実装を進めていく中で必要になった場面で共有したいと思います。

## まとめ
最後まで読んでいただいてありがとうございました。

今回は Flutter のユニットテストについて触れました。
今までテスト無しの実装をする場面が非常に多く、今回テストに触れたことで「どのようなコードがテストしやすいか」「どこでコードを分割すべきか」など考えることができました。

自分自身もテストコードを書き始めたばかりなので、誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://youtu.be/mxTW020pyuc

https://riverpod.dev/ja/docs/cookbooks/testing

https://zenn.dev/ncdc/articles/flutter_unit_test
