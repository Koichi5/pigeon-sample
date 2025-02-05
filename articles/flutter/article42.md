## 初めに
先日ハッカソン形式のインターンに参加した際に、Flutter × Firebase で Firestore からデータを取得する際、キャッシュを使用して Firestore の使用量を減らす方法を知り、それを自身のアプリでも応用してみたので、共有します。

## 記事の対象者
+ Flutter 学習者
+ Firebaseの使用量を抑えたい方
+ アプリのパフォーマンス改善をしたい方

## 実装
### 導入
今回はすでにFirestoreが導入されている状態を想定して進めていきます。

### 通常のデータ取得
今回は自分のアプリで `quiz` コレクションの中にある `question` コレクションからデータを取得する処理を例に取ります。

```dart: question_repository.dart
  Future<List<Question>> retrieveQuestionList({required Quiz quiz}) async {
    try {
      final snap = await _questionsCollection(quiz).get();
      return snap.docs.map((doc) => Question.fromDocument(doc)).toList();
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }
```
通常だと以上のように階層構造が上のコレクションの情報を参考にして（本来であればIDなどのみを渡すのが理想的かもしれませんが...）コレクションのパスから `get` メソッドでデータを取得します。
その後 freezed などを利用している場合は、取得したデータを `fromDocument` メソッドで任意の型に変換してそれを返します。

### キャッシュを使ったデータ取得
次にキャッシュを使用する場合の処理です。

```dart: question_repository.dart
  @override
  Future<List<Question>> fetchQuestionList({required Quiz quiz}) async {
    try {
      return await fetchQuery(quiz: quiz).then((ref) async => await ref
          .get()
          .then((value) async => await fetchLocalQuestionList(quiz: quiz)));
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }

  @override
  Future<List<Question>> fetchLocalQuestionList({required Quiz quiz}) async {
    final snap = await _questionsCollection(quiz)
        .get(const GetOptions(source: Source.cache));
    return snap.docs.map((doc) => Question.fromDocument(doc)).toList();
  }

  Future<Query<Question>> fetchQuery({required Quiz quiz}) async {
    DocumentSnapshot? lastDocRef;
    await _questionsCollection(quiz)
        .get(const GetOptions(source: Source.cache))
        .then((value) {
      if (value.docs.isNotEmpty) lastDocRef = value.docs.last;
    });

    Query<Question> ref = _questionsCollection(quiz).withConverter(
        fromFirestore: (snapshot, _) => Question.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson());
    if (lastDocRef != null) {
      ref = ref.startAtDocument(lastDocRef!);
    }
    return ref;
  }
}
```
多少長いので、以下の三つのメソッドに分割して詳しくみていきます。
+ fetchQuestionList
+ fetchLocalQuestionList
+ fetchQuery

#### fetchQuestionList
```dart
  @override
  Future<List<Question>> fetchQuestionList({required Quiz quiz}) async {
    try {
      return await fetchQuery(quiz: quiz).then((ref) async => await ref
          .get()
          .then((value) async => await fetchLocalQuestionList(quiz: quiz)));
    } on FirebaseException catch (e) {
      throw CustomException(message: e.message);
    }
  }
```
上記のコードでは、後述する `fetchQuery` と `fetchLocalQuestionList` メソッドを順次実行しています。それぞれのメソッドでエラーが発生した場合には Exception をして例外処理を実装しています。

#### fetchLocalQuestionList
```dart
  @override
  Future<List<Question>> fetchLocalQuestionList({required Quiz quiz}) async {
    final snap = await _questionsCollection(quiz)
        .get(const GetOptions(source: Source.cache));
    return snap.docs.map((doc) => Question.fromDocument(doc)).toList();
  }
```
このコードでは `get` メソッドの引数に `GetOptions(source: Source.cache)` を指定しています。こうすることでデータを取得する先をキャッシュに指定することができます。
取得したデータの扱いは通常の `get` メソッドと同様になります。

#### fetchQuery
```dart
  Future<Query<Question>> fetchQuery({required Quiz quiz}) async {
    DocumentSnapshot? lastDocRef;
    await _questionsCollection(quiz)
        .get(const GetOptions(source: Source.cache))
        .then((value) {
      if (value.docs.isNotEmpty) lastDocRef = value.docs.last;
    });

    Query<Question> ref = _questionsCollection(quiz).withConverter(
        fromFirestore: (snapshot, _) => Question.fromJson(snapshot.data()!),
        toFirestore: (data, _) => data.toJson());
    if (lastDocRef != null) {
      ref = ref.startAtDocument(lastDocRef!);
    }
    return ref;
  }
```
最後に `fetchQuery` です。このコードではまずキャッシュのデータを取得し、そのデータが空でなければデータの最後のドキュメントを `lastDocRef` として保存しておきます。
次に `ref` として同様のコレクションに対して `withConverter` メソッドの返り値を指定します。`withConverter` メソッドではやり取りするデータの方をあらかじめ決めておくことができます。`fetchQuery` ではこの `ref` を返り値として返しています。

## まとめ
最後まで読んでいただいてありがとうございました。
Firestoreでは無料プランに関してはドキュメントの書き込み回数、読み取り回数の上限が決められており、その他のプランに関しては回数によって従量課金される仕組みになっています。したがって、ユーザー数が増えた際に可能な限り書き込み回数、読み取り回数を減らすことは重要な課題になります。
今回取り上げたキャッシュの仕組みはその課題の対処法の一つになるかと思います。

まだ試験的に導入している仕組みなので、誤っている点やより効率的に書ける点があればご指摘いただけると幸いです。

### 参考
https://zenn.dev/tsuruo/articles/23894990188653

https://zenn.dev/tatsuhiko/books/b938417d5cb04d/viewer/64c196