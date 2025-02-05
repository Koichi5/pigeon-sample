## 初めに
今回は Cloud Storage for Firebase(以降 Cloud Storage)の使い方をまとめてみたいと思います。

## 記事の対象者
+ Flutter 学習者
+ Cloud Storage の使い方を知りたい方
+ アプリ内で画像データなどを扱う必要がある方

## 目的
今回は Cloud Storage の使い方を把握することを目的とします。
最終的には Cloud Storage, Firebase Auth, Cloud Firestore を合わせて使用して、ユーザーごとの画像データを保存できるまで実装を進めていきます。

なお、今回実装したコードは以下の GitHub で公開しているので、適宜参照いただければと思います。

https://github.com/Koichi5/functions-sample/tree/main/lib/storage_sample

## 準備
### Firebase 周りの設定
この記事では以下の設定をして、プロジェクトの紐付けが完了した段階から実装を進めていきます。
- Firebase Auth
  ログイン方法として「メール / パスワード」を指定して有効化

- Cloud Firestore
  「始める」を押して、データベースのルールで読み書きが有効であることを確認

- Cloud Storage
  「始める」を押して、データを追加できる状態であることを確認

### Flutter の設定
次に Flutter 側の設定を行います。
以下をターミナルで実行
```
flutter pub add firebase_core firebase_auth cloud_firestore firebase_storage flutter_riverpod riverpod_annotation hooks_riverpod flutter_hooks freezed_annotation gap image_picker image path palette_generator
flutter pub add -d build_runner riverpod_generator freezed json_serializable
```

または

`pubspec.yaml`を以下のように変更します。（バージョンは最新のものを使用してください）
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.6

  # firebase
  firebase_core: ^3.3.0
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  firebase_storage: ^12.3.1

  # riverpod
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.5.2

  flutter_hooks: ^0.20.5
  freezed_annotation: ^2.4.4
  gap: ^3.0.1
  image_picker: ^1.1.2
  image: ^4.2.0
  path: ^1.9.0
  palette_generator: ^0.3.3+4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
```

次に ios > Runner > Info.plist で以下の内容を追加します。
iOS では image_picker で画像を選択する際に以下の二つの記述が必要になります。
```
<plist version="1.0">
<dict>

    … 他の内容

    <key>NSCameraUsageDescription</key>
    <string>カメラを使う理由・用途を記述</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>ギャラリーを使う理由・用途を記述</string>
</dict>
</plist>
```

これで準備は完了です。

## 実装
実装は以下のステップで進めていきます。
ステップ1では単純な Cloud Storage の使い方をまとめ、ステップ2では実際のプロジェクトで使用する例としてサンプルアプリの実装を行います。必要な部分をかいつまんで読んでいただいても構いません。
1. Cloud Storage のデータの追加、読み取り
2. サンプルアプリの実装

### 1. Cloud Storage のデータの追加、読み取り
まずは Cloud Storage へのデータの追加と追加したデータの読み取りを行います。
コードは以下の通りです。

`StorageSimpleAppScreen`
```dart: storage_simple_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functions_sample/storage_sample/simple_app/image_urls_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class StorageSimpleAppScreen extends HookConsumerWidget {
  const StorageSimpleAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = FirebaseStorage.instance;  // Storage のインスタンス
    final firestore = FirebaseFirestore.instance;  // Firestore のインスタンス
    final isUploading = useState(false);  // ローディング中かどうかを保持する State

    Future<void> uploadImage() async {
      final ImagePicker imagePicker = ImagePicker();
      final XFile? pickedImage = await imagePicker.pickImage(  // 画像をピック
        source: ImageSource.gallery,
      );
      if (pickedImage == null) return;

      isUploading.value = true;
      try {
        final storageRef = storage.ref();
        final imageRef = storageRef.child(  // 画像のパスを指定
            'sample/${DateTime.now().millisecondsSinceEpoch}_${pickedImage.name}');
        final uploadTask = await imageRef.putFile(File(pickedImage.path));  // 画像のアップロード
        final url = await uploadTask.ref.getDownloadURL();  // 画像のURL取得

        await firestore.collection('images').add({'url': url});  // Firestoreに保存
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image uploaded successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload image: $e')),
          );
        }
      } finally {
        isUploading.value = false;
      }
    }

    final imageUrls = ref.watch(imageUrlsProvider);  // 画像のURLのリストを返すProvider

    return Scaffold(
      appBar: AppBar(
        title: const Text('Storage Sample'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: isUploading.value ? null : uploadImage,
            child: isUploading.value
                ? const CircularProgressIndicator()
                : const Text('Upload'),
          ),
          Expanded(
            child: imageUrls.when(
              data: (urls) => urls.isEmpty
                  ? const Center(child: Text('No images uploaded yet'))
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: urls.length,
                      itemBuilder: (context, index) => Image.network(
                        urls[index],
                        fit: BoxFit.cover,
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}
```

`imageUrls`
```dart: image_urls_provider
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'image_urls_provider.g.dart';

@riverpod
Stream<List<String>> imageUrls(ImageUrlsRef ref) =>
    FirebaseFirestore.instance.collection('images').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc['url'] as String).toList(),
        );
```

それぞれ詳しくみていきます。

以下では、 `StorageSimpleAppScreen` のビルドメソッド内で必要な変数の定義を行なっています。
Storage, Firestore のインスタンスをそれぞれ `storage`, `firestore` として定義しています。
また、画像をアップロードしている最中かどうかを保持する `isUploading` を定義しています。
```dart: storage_simple_screen.dart
class StorageSimpleAppScreen extends HookConsumerWidget {
  const StorageSimpleAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;
    final isUploading = useState(false);
```

以下では画像をピックして Cloud Storage に保存する処理を実装しています。
`ImagePicker` の `pickImage(source: ImageSource.gallery)` でギャラリーから画像を選択し、 `pickedImage` として定義しています。

また、 `storage.ref()` の `child` で画像を保存するパスを指定しています。なお、画像のパスは他の画像と被ることがないように現在時刻と画像の名前を含むように指定しています。

画像のパスに対して `putFile` を実行することで画像をアップロードすることができ、 `getDownloadURL` でアップロードした画像のURLを取得することができます。
```dart
Future<void> uploadImage() async {
  final ImagePicker imagePicker = ImagePicker();
  final XFile? pickedImage = await imagePicker.pickImage(
    source: ImageSource.gallery,
  );
  if (pickedImage == null) return;

  isUploading.value = true;
  try {
    final storageRef = storage.ref();
    final imageRef = storageRef.child(
        'sample/${DateTime.now().millisecondsSinceEpoch}_${pickedImage.name}');
    final uploadTask = await imageRef.putFile(File(pickedImage.path));
    final url = await uploadTask.ref.getDownloadURL();
```

以下では、先ほどアップロードして取得した画像URLを Firestore の `images` コレクションに追加しています。Firestore に追加することで、次回から画像にアクセスする際にはURLとして取得することができます。

画像のアップロードと Firestore への追加処理を行う途中でエラーが発生した場合にはエラー内容を出力し、正常に動作した場合は成功したことを示す `SnackBar` を表示しています。

また、 `finally` で `isUploading` を `false` にすることで、一連の処理が終了した際にアップロード中の状態を解除しています。

```dart
    await firestore.collection('images').add({'url': url});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image uploaded successfully')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: $e')),
      );
    }
  } finally {
    isUploading.value = false;
  }
}
```

以下では `imageUrls` として `imageUrlsProvider` を読み取った値を保持しています。
```dart
final imageUrls = ref.watch(imageUrlsProvider);
```

`imageUrlsProvider` は以下のような内容であり、 Firestore の `images` コレクションのスナップショットを取得して `Stream` として返却しています。
これで追加された画像のURLのリストを取得することができます。
```dart
@riverpod
Stream<List<String>> imageUrls(ImageUrlsRef ref) =>
    FirebaseFirestore.instance.collection('images').snapshots().map(
          (snapshot) =>
              snapshot.docs.map((doc) => doc['url'] as String).toList(),
        );
```

以下では画像をアップロードするボタンの実装を行なっています。
画像をアップロード中でない場合は `uploadImage` を実行するようにしています。
また、アップロード中は `CircularProgressIndicator` を表示しています。
```dart
ElevatedButton(
  onPressed: isUploading.value ? null : uploadImage,
  child: isUploading.value
      ? const CircularProgressIndicator()
      : const Text('Upload'),
),
```

以下では `imageUrls` の取得した結果を `GridView` で表示しています。
`Image.network` にURLを渡すことで、保存されている画像のURLから画像を表示することができます。
```dart
Expanded(
  child: imageUrls.when(
    data: (urls) => urls.isEmpty
        ? const Center(child: Text('No images uploaded yet'))
        : GridView.builder(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: urls.length,
            itemBuilder: (context, index) => Image.network(
              urls[index],
              fit: BoxFit.cover,
            ),
          ),
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (error, stack) => Center(child: Text('Error: $error')),
  ),
),
```

これで実行すると以下のような挙動になります。

https://youtube.com/shorts/CcAQLsUpaHs

画像を保存すると、 Storage には `sample` というフォルダの配下に画像が追加されて、Firestore には `images` コレクションの `url` フィールドに画像のURLが追加されているかと思います。

Cloud Storage を用いた画像のアップロードと読み取りは上記のサンプルを参考にすれば実装できるかと思います。

### 2. サンプルアプリの実装
この章では Cloud Storage を用いた画像のアップロード、読み取り機能をアプリに取り入れる場合を考えて、サンプルアプリを実装していきます。

最終的には以下の動画のように本のデータを管理するようなアプリを完成させます。

https://youtube.com/shorts/yGtqnRnenxI

実装は以下の手順で進めていきます。
1. models の実装
2. repositories の実装
3. managers の実装
4. services の実装
5. screens の実装

#### 1. models の実装
まずは今回使用するモデルを定義していきます。
ユーザーごとの本のデータを管理するために `FirestoreUser`, `Book` の二つのモデルを用意します。
コードは以下の通りです。

```dart: models/user/firestore_user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'firestore_user.freezed.dart';
part 'firestore_user.g.dart';

@freezed
abstract class FirestoreUser with _$FirestoreUser {
  const factory FirestoreUser({
    required String name,    // ユーザー名
    required String email,   // メールアドレス
  }) = _FirestoreUser;

  const FirestoreUser._();

  factory FirestoreUser.fromJson(Map<String, dynamic> json) => _$FirestoreUserFromJson(json);

  static String get collectionName => 'book_users';
}
```

```dart: models/book/book.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
abstract class Book with _$Book {
  const factory Book({
    required String id,
    required String imageUrl,     // 画像のURL
    required String imagePath,    // 画像のパス
    required String title,        // タイトル
    required String author,       // 著者名
    required String description,  // 説明文
    String? publishedAt,          // 出版日
    String? dominantColor,        // テーマカラー
  }) = _Book;

  const Book._();

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  static String get collectionName => 'books';
}
```

これでモデルの実装は完了です。
なお、`FirestoreUser` に関しては FirebaseAuth の `User` と区別するためにこのような名前にしています。

#### 2. repositories の実装
次に Repository の実装を行います。
まずは FirebaseAuth, Firestore, Cloud Storage の三つにアクセスしやすいように `mixin` や `Provider` を作っていきます。

`FirebaseAuthAccessMixin`
以下の mixin を付与することで、 FirebaseAuth のインスタンスと現在のユーザーに簡単にアクセスできるようになります。
```dart: repositories/mixin/firebase_auth_access_mixin.dart
import 'package:firebase_auth/firebase_auth.dart';

mixin FirebaseAuthAccessMixin {
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
  User? get currentUser => firebaseAuth.currentUser;
}
```

`FirestoreAccessMixin`
以下の mixin を付与することで、 Firestore のインスタンスとユーザーを保存しているコレクション、本を保存しているコレクションにアクセスしやすくなります。それぞれのパスはコメントアウトしてあるようなパスになっています。
```dart: repositories/mixin/firestore_access_mixin.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:functions_sample/storage_sample/book_app/models/book/book.dart';
import 'package:functions_sample/storage_sample/book_app/models/user/firestore_user.dart';

mixin FirestoreAccessMixin {
  FirebaseFirestore get firestore => FirebaseFirestore.instance;

  // users: FirebaseFirestore.instance.collection('book_users')
  CollectionReference<Map<String, dynamic>> get usersCollection => firestore.collection(FirestoreUser.collectionName);

  // users: FirebaseFirestore.instance.collection('book_users').doc({userId})
  DocumentReference userOf({String? userId}) =>
      usersCollection.doc(userId);

  // books: FirebaseFirestore.instance.collection('book_users').doc({userId}).collection('books')
  CollectionReference<Map<String, dynamic>> booksCollection({String? userId}) =>
      userOf(userId: userId).collection(Book.collectionName);

  // books: FirebaseFirestore.instance.collection('book_users').doc({userId}).collection('books').doc({bookId})
  DocumentReference bookOf({String? userId, required String bookId}) =>
      userOf(userId: userId).collection(Book.collectionName).doc(bookId);
}
```

`firebaseStorage`
以下では Cloud Storage のインスタンスを保持する Provider を定義しています。
Cloud Storage に関しては Repository 層以外でも使用するため Provider にしています。
```dart: : repositories/mixin/firebase_storage.dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firebase_storage.g.dart';

@Riverpod(keepAlive: true)
FirebaseStorage firebaseStorage(FirebaseStorageRef ref) {
  return FirebaseStorage.instance;
}
```

次に今まで定義した mixin などを使って Repository の実装に入っていきます。
まずは FirestoreUser の管理を行う `FirestoreUserRepository` を実装します。
`FirestoreUserRepository` では以下のメソッドを実装しています。
- createUser
- signIn
- signOut
- saveToFirestore

コードは以下の通りです。
```dart: repositories/user/firestore_user_repository.dart
import 'package:flutter/material.dart';
import 'package:functions_sample/storage_sample/book_app/models/user/firestore_user.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/mixin/firebase_auth_access_mixin.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/mixin/firestore_access_mixin.dart';

class FirestoreUserRepository
    with FirebaseAuthAccessMixin, FirestoreAccessMixin {
  Future<FirestoreUser?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // メールアドレスとパスワードでユーザー新規作成
      final authResult = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ユーザーの名前とメールアドレスを FirestoreUser として Firestore に保存
      if (authResult.user != null) {
        final user = FirestoreUser(name: name, email: email);
        authResult.user!.updateDisplayName(name);
        await saveToFirestore(uid: authResult.user!.uid, user: user);
        return user;
      }
    } catch (e) {
      debugPrint('Failed to create user: $e');
    }
    return null;
  }

  Future<FirestoreUser?> signIn({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      // メールアドレスとパスワードでサインイン
      final authResult = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        final user = FirestoreUser(
          email: email,
          name: name,
        );

        // サインインした際のデータを保存
        await saveToFirestore(
          uid: authResult.user!.uid,
          user: user,
        );

        return user;
      }
    } catch (e) {
      debugPrint('Failed to sign in: $e');
    }
    return null;
  }

  void signOut() {
    firebaseAuth.signOut();
  }

  Future<void> saveToFirestore({
    required String uid,
    required FirestoreUser user,
  }) async {
    // Firestore の book_users コレクションにデータを保存
    await firestore.collection(FirestoreUser.collectionName).doc(uid).set(
          user.toJson(),
        );
  }
}
```

次にユーザーの本の管理を行う `FirestoreBookRepository` を実装します。
`FirestoreBookRepository` では以下のメソッドを実装しています。
- createBook
- deleteBook
- stream

コードは以下の通りです。
```dart: repositories/user/firestore_book_repository.dart
import 'package:flutter/foundation.dart';
import 'package:functions_sample/storage_sample/book_app/models/book/book.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/book/book_repository.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/mixin/firebase_auth_access_mixin.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/mixin/firestore_access_mixin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_book_repository.g.dart';

@Riverpod(keepAlive: true)
FirestoreBookRepository firestoreBookRepository(
    FirestoreBookRepositoryRef ref) {
  return FirestoreBookRepository();
}

class FirestoreBookRepository
    with FirebaseAuthAccessMixin, FirestoreAccessMixin {
  Future<Book> createBook({required Book book}) async {
    try {
      // documentId を指定してから set メソッドで本のデータを保存
      final docRef = booksCollection(userId: currentUser?.uid).doc();
      final bookWithId = book.copyWith(id: docRef.id);
      await docRef.set(bookWithId.toJson());

      return bookWithId;
    } catch (e) {
      debugPrint('Error creating book: $e');
      rethrow;
    }
  }

  Future<void> deleteBook({required String bookId}) async {
    try {
      // 現在のユーザーのIDと本のIDから本のデータを削除
      await bookOf(userId: currentUser!.uid, bookId: bookId).delete();
    } catch (e) {
      debugPrint('Error deleting book: $e');
      rethrow;
    }
  }

  Stream<List<Book>> stream() {
    // 現在のユーザーの本のスナップショットを Book に直して、Stream で取得
    return booksCollection(userId: currentUser?.uid).snapshots().map((event) {
      return event.docs.map((doc) {
        final bookDocument = Book.fromJson(doc.data());
        return Book(
          id: doc.id,
          imageUrl: bookDocument.imageUrl,
          imagePath: bookDocument.imagePath,
          title: bookDocument.title,
          author: bookDocument.author,
          dominantColor: bookDocument.dominantColor,
          description: bookDocument.description,
        );
      }).toList();
    });
  }
}
```

これで Repository 層の実装は完了です。
Firebase Auth, Cloud Firestore の連携が完了したので、データの管理ができるようになりました。

#### 3. managers の実装
次に Manager 層の実装を行います。
まずはユーザーの管理を行う `FirestoreUserManager` の実装を行います。
基本的には Repository に定義した関数を呼び出すのみになっています。

コードは以下の通りです。
```dart: managers/user/firestore_user_manager.dart
import 'package:functions_sample/storage_sample/book_app/models/user/firestore_user.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/user/firestore_user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_user_manager.g.dart';

@riverpod
class FirestoreUserManager extends _$FirestoreUserManager {
  final repository = FirestoreUserRepository();

  @override
  void build() {}

  Future<FirestoreUser?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    return await repository.createUser(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<FirestoreUser?> signIn({
    required String email,
    required String password,
    required String name,
  }) async {
    return await repository.signIn(
      email: email,
      password: password,
      name: name,
    );
  }

  void signOut() {
    repository.signOut();
  }
}
```

次に本の管理を行う `FirestoreBookManager` の実装を行います。
基本的には Repository に定義した関数を呼び出すのみになっていますが、 `createBook` と `deleteBook` メソッドでは、本のデータを作成、削除する際に Cloud Storage の画像の追加と削除も同時に行なっています。

コードは以下の通りです。
```dart: managers/book/firestore_book_manager.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/book/firestore_book_repository.dart';
import 'package:functions_sample/storage_sample/book_app/repositories/mixin/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:functions_sample/storage_sample/book_app/models/book/book.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_book_manager.g.dart';

@riverpod
FirestoreBookManager bookManager(BookManagerRef ref) {
  final storage = ref.watch(firebaseStorageProvider);
  final repository = ref.watch(firestoreBookRepositoryProvider);
  return FirestoreBookManager(repository, storage);
}

class FirestoreBookManager {
  final FirestoreBookRepository _bookRepository;
  final FirebaseStorage _storage;
  StreamController<List<Book>>? _bookStreamController;
  StreamSubscription? _bookStreamSubscription;

  FirestoreBookManager(this._bookRepository, this._storage);

  Future<Book> createBook({
    required String userId,
    required String title,
    required String author,
    required File imageFile,
    required String dominantColor,
    required String description,
    String? publishedAt,
  }) async {
    try {
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
      final String imagePath = 'images/books/$userId/$fileName';
      final TaskSnapshot uploadTask =
          await _storage.ref(imagePath).putFile(imageFile);
      final String imageUrl = await uploadTask.ref.getDownloadURL();

      final Book newBook = Book(
        id: '',
        imageUrl: imageUrl,
        imagePath: imagePath,
        title: title,
        author: author,
        publishedAt: publishedAt,
        dominantColor: dominantColor,
        description: description,
      );

      final Book createdBook = await _bookRepository.createBook(book: newBook);

      return createdBook;
    } catch (e) {
      debugPrint('Error in createBook: $e');
      rethrow;
    }
  }

  Future<void> deleteBook({required Book book}) async {
    try {
      await _storage.ref(book.imagePath).delete();
      await _bookRepository.deleteBook(bookId: book.id);
    } catch (e) {
      debugPrint('Error in deleteBook: $e');
      rethrow;
    }
  }

  Stream<List<Book>> streamBookList() {
    _bookStreamController = StreamController<List<Book>>(onListen: () {
      _bookStreamSubscription = _bookRepository.stream().map((books) {
        return [...books];
      }).listen((books) {
        _bookStreamController?.add(books);
      });
    }, onCancel: () {
      _bookStreamSubscription?.cancel();
    });
    return _bookStreamController!.stream;
  }
}
```

`createBook` について少し詳しくみておきます。
`fileName` に関しては前の実装と同様に現在時刻と画像のパスを組み合わせた名前にしています。
`putFile` メソッドで Storage への保存を行なった後 `getDownloadURL` で画像のURLの取得を行なっています。このURLを Book の `imageUrl` に格納しています。

また、Cloud Storage に保存された画像の削除を行う際に画像のパスが必要になるため `imagePath` も一緒に保存しています、
```dart
Future<Book> createBook({
  required String userId,
  // 省略 ...
}) async {
  try {
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.path)}';
    final String imagePath = 'images/books/$userId/$fileName';
    final TaskSnapshot uploadTask =
        await _storage.ref(imagePath).putFile(imageFile);
    final String imageUrl = await uploadTask.ref.getDownloadURL();

    final Book newBook = Book(
      id: '',
      imageUrl: imageUrl,
      imagePath: imagePath,
      title: title,
      author: author,
      publishedAt: publishedAt,
      dominantColor: dominantColor,
      description: description,
    );

    final Book createdBook = await _bookRepository.createBook(book: newBook);

    return createdBook;
  } catch (e) {
    debugPrint('Error in createBook: $e');
    rethrow;
  }
}
```

`deleteBook` についても詳しくみておきます。
`_storage.ref(book.imagePath)` で `Book` に格納されている `imagePath` を渡し、 `delete` メソッドを実行することで指定されたパスにある Cloud Storage 上の画像を削除することができます。

Cloud Storage の画像の削除と合わせて、`deleteBook` メソッドを実行することで Firestore 上の本のデータも削除しています、
```dart
Future<void> deleteBook({required Book book}) async {
  try {
    await _storage.ref(book.imagePath).delete();
    await _bookRepository.deleteBook(bookId: book.id);
  } catch (e) {
    debugPrint('Error in deleteBook: $e');
    rethrow;
  }
}
```

これで Manager 層の実装は完了です。

#### 4. services の実装
次に Service 層の実装を行います。
Service 層では本の一覧を取得するための関数を実装するのみで、あとは Manager から呼び出すようにします。

コードは以下の通りです。
```dart: services/book/book_service.dart
import 'package:functions_sample/storage_sample/book_app/managers/book/firestore_book_manager.dart';
import 'package:functions_sample/storage_sample/book_app/models/book/book.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_service.g.dart';

@riverpod
Stream<List<Book>> books(BooksRef ref) {
  final manager = ref.watch(bookManagerProvider);

  return manager.streamBookList();
}
```

これで Stream として本の一覧を取得できるようになります。

#### 5. screens の実装
最後に画面の実装に入っていきます。
画面は以下の4つを作成していきます。
- BookAuthScreen
- BookListScreen
- AddBookScreen
- DetailBookScreen

<br>
まずはユーザーの新規作成・サインインを行う `BookAuthScreen` を作成していきます。

`isSignIn` でサインインか新規作成かの状態を保持し、それによって `firestoreUserManager` の `signIn`, `createUser` を切り替えて実行しています。これによって FirebaseAuth のユーザーのサインインまたは新規作成が完了し、ユーザーのデータが Firestore に保存されます。
コードは以下の通りです。
```dart: screens/user/book_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functions_sample/storage_sample/book_app/managers/user/firestore_user_manager.dart';
import 'package:functions_sample/storage_sample/book_app/screens/book/add_book_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BookAuthScreen extends HookConsumerWidget {
  const BookAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreUserManager =
        ref.read(firestoreUserManagerProvider.notifier);
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final isSignIn = useState(true);

    void authenticate() async {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メールアドレスとパスワードを入力してください')),
        );
        return;
      }

      isLoading.value = true;
      final user = isSignIn.value
          ? await firestoreUserManager.signIn(
              email: emailController.text,
              password: passwordController.text,
              name: nameController.text,
            )
          : await firestoreUserManager.createUser(
              email: emailController.text,
              password: passwordController.text,
              name: nameController.text,
            );
      isLoading.value = false;

      if (user != null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isSignIn.value ? "サインイン" : "新規登録"}成功: ${user.email}',
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const AddBookScreen(),
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${isSignIn.value ? "サインイン" : "新規登録"}に失敗しました',
              ),
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSignIn.value ? 'サインイン' : '新規登録',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ニックネーム',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'パスワード',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading.value ? null : authenticate,
              child: isLoading.value
                  ? const CircularProgressIndicator()
                  : Text(isSignIn.value ? 'サインイン' : '新規登録'),
            ),
            TextButton(
              onPressed: () => isSignIn.value = !isSignIn.value,
              child: Text(
                isSignIn.value ? '新規登録はこちら' : 'サインインはこちら',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

次に本の一覧を表示する `BookListScreen` を実装していきます。

`books` として `booksProvider` を読み取った値を代入し、それを `ListTile` で表示しています。ここで表示している本の画像は Cloud Storage に保存してある画像で、Firestore に保存されているURLを参照しています。また `ListTile` がタップされた時にはこれから実装する `DetailBookScreen` に遷移するようにしています。

コードは以下の通りです。
```dart: screens/book/book_list_screen.dart
import 'package:flutter/material.dart';
import 'package:functions_sample/storage_sample/book_app/managers/user/firestore_user_manager.dart';
import 'package:functions_sample/storage_sample/book_app/screens/book/add_book_screen.dart';
import 'package:functions_sample/storage_sample/book_app/screens/book/detail_book_screen.dart';
import 'package:functions_sample/storage_sample/book_app/services/book/book_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BookListScreen extends HookConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreUserManager =
        ref.read(firestoreUserManagerProvider.notifier);
    final books = ref.watch(booksProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Books'),
        actions: [
          IconButton(
            onPressed: () {
              firestoreUserManager.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Image.network(
              books[index].imageUrl,
              width: 40,
              height: 60,
              fit: BoxFit.cover,
            ),
            title: Text(
              books[index].title,
            ),
            subtitle: Text(books[index].author),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailBookScreen(
                    book: books[index],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (context) => const AddBookScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

次に本を追加する `AddBookScreen` を実装していきます。

`pickImage` メソッドでは、先ほどの実装と同様にギャラリーから画像を選択するようにしています。
`addBook` メソッドの中で `manager.createBook` を実行しています。
```dart: screens/book/add_book_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:functions_sample/storage_sample/book_app/managers/book/firestore_book_manager.dart';
import 'package:palette_generator/palette_generator.dart';

class AddBookScreen extends HookConsumerWidget {
  const AddBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final authorController = useTextEditingController();
    final descriptionController = useTextEditingController();
    final imageFile = useState<File?>(null);
    final dominantColor = useState<Color?>(null);
    final isLoading = useState(false);

    final manager = ref.watch(bookManagerProvider);

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          FileImage(imageFile.value!),
          size: const Size(200, 300),
        );
        dominantColor.value =
            paletteGenerator.dominantColor?.color ?? Colors.grey;
      }
    }

    Future<void> addBook() async {
      if (titleController.text.isEmpty ||
          authorController.text.isEmpty ||
          imageFile.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields and select an image'),
          ),
        );
        return;
      }

      isLoading.value = true;
      try {
        await manager.createBook(
          userId: 'userId',
          title: titleController.text,
          author: authorController.text,
          description: descriptionController.text,
          imageFile: imageFile.value!,
          dominantColor: dominantColor.value?.value.toRadixString(16) ?? '',
        );
        if (context.mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add book: $e')),
        );
        }
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Book')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const Gap(16),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
              ),
              const Gap(16),
              SizedBox(
                height: 200,
                child: TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 5,
                ),
              ),
              if (imageFile.value != null) ...[
                const Gap(16),
                Image.file(
                  imageFile.value!,
                  width: 200,
                  height: 300,
                ),
              ],
              const Gap(16),
              ElevatedButton(
                onPressed: pickImage,
                child: const Text('Select Image'),
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: isLoading.value ? null : addBook,
                child: isLoading.value
                    ? const CircularProgressIndicator()
                    : const Text('Add Book'),
              ),
              const Gap(32),
            ],
          ),
        ),
      ),
    );
  }
}
```

次に本の詳細を表示する `DetailBookScreen` を実装していきます。
基本的には、本の一覧画面から受け取ったデータを表示しています。

コードは以下の通りです。
```dart: screens/book/detail_book_screen.dart
import 'package:flutter/material.dart';
import 'package:functions_sample/storage_sample/book_app/managers/book/firestore_book_manager.dart';
import 'package:functions_sample/storage_sample/book_app/models/book/book.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class DetailBookScreen extends HookConsumerWidget {
  const DetailBookScreen({
    required this.book,
    super.key,
  });

  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dominantColor = Color(
      int.parse(book.dominantColor ?? 'FF808080', radix: 16),
    );
    final textColor =
        dominantColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;

    final manager = ref.watch(bookManagerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Detail'),
        backgroundColor: dominantColor,
        foregroundColor: textColor,
        actions: [
          IconButton(
            onPressed: () {
              manager.deleteBook(book: book);
              Navigator.pop(context);
            },
            icon: const Icon(
              Icons.delete,
            ),
          ),
        ],
      ),
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Container(
          color: dominantColor.withOpacity(0.1),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(20),
                Center(
                  child: Image.network(
                    book.imageUrl,
                    width: 200,
                    height: 300,
                  ),
                ),
                const Gap(20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    book.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Gap(20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    '${book.author} 氏',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Gap(20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    book.description,
                  ),
                ),
                const Gap(40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

最後に `main.dart` の内容を以下のように変更して、現在のユーザーがある場合は本の一覧画面を表示し、ない場合はユーザーの新規登録・サインイン画面を表示するようにします。
```dart: main.dart
class MyApp extends ConsumerWidget with FirebaseAuthAccessMixin {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home:
          currentUser == null ? const BookAuthScreen() : const BookListScreen(),
    );
  }
}
```

これで実装は完了です。
以上のコードで実行すると以下のような挙動になるかと思います。

https://youtube.com/shorts/yGtqnRnenxI


## まとめ
最後まで読んでいただいてありがとうございました。

今回は Cloud Storage for Firebase の使い方をまとめました。
かなり多くのアプリで画像などのデータを扱う必要があると思うので、 Cloud Storage の実装に慣れておけば役立つ場面も多いかと思います。
今回は単純に画像を保存するだけでしたが、他にも画像を圧縮したり、メタデータを編集したりもできるので、別の機会にまとめられたらと思います。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考
https://firebase.google.com/docs/storage/flutter/start?hl=ja

https://firebase.flutter.dev/docs/storage/overview

https://zenn.dev/joo_hashi/books/ddceed5b07c26a/viewer/c587c3

