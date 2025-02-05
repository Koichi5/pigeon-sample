## 初めに
今回は Pigeon を用いて、Flutter で書かれた iOS 側のアプリケーションと、Swift で書かれた watchOS 側のアプリケーションの連携を行いたいと思います。この記事では、Pigeon を使用してネイティブコードを生成し、Flutter と watchOS 間でのデータ通信を実現する方法について詳しく解説します。

## 記事の対象者
+ Flutter 学習者
+ watchOS の実装をしたい方
+ Flutter アプリに Apple Watch の実装を追加したい方

## 目的
今回は先述の通り、Pigeon を用いて Flutter アプリと watchOS のアプリとの連携を目的とします。Pigeon を使用することで、Flutter とネイティブプラットフォーム間の通信を型安全かつ効率的に行うことが可能になります。この記事を通じて、Flutter と watchOS の連携手順を学び、実際に Apple Watch から Flutter アプリを操作できるアプリケーションの開発手順を理解することが目的です。

また、Pigeon を利用した iOS 側との連携については以前の以下の記事で扱いました。
[以前の記事: Flutter と iOS の連携](https://zenn.dev/koichi_51/articles/61c45c2c30312b)

さらに、iOS 側と watchOS 側との連携については以下の記事で紹介しました。
[以前の記事: iOS と watchOS の連携](https://zenn.dev/koichi_51/articles/0b26a80841b4ed)

これらの知識を基に、今回の Flutter と watchOS の連携を進めていきます。

今回実装するコードは以下の GitHub リポジトリで公開しています。必要に応じてご参照いただければと思います。
[GitHub リポジトリ](https://github.com/Koichi5/pigeon-sample)

## 実装
今回は以下の手順で実装を進めていきます。
1. 準備
2. Pigeon で Flutter, Swift のコード生成
3. Flutter でアプリの実装
4. Flutter と Swift の繋ぎこみ実装
5. iOS と watchOS との連携実装

最終的には以下の動画のように Apple Watch からの操作を検知して、Flutter で書かれた Firestore へのデータ保存処理が実行できるようにします。

https://youtube.com/shorts/btlcRVUknf8

## 1. 準備
まずは実装に必要な準備を行います。以下の環境が整っていることを確認してください。
- Flutter SDK がインストールされていること
- Xcode がインストールされていること
- watchOS の開発に必要な Apple Developer アカウントがあること
- Flutter プロジェクトが既に作成されていること

### Flutter プロジェクトの作成
既に Flutter プロジェクトが作成されている場合はこのステップはスキップできます。新規に作成する場合は以下のコマンドを実行します。

```bash
flutter create pigeon_watch_app
```

以上で Flutter プロジェクトが作成されます。

### watchOS ターゲットの追加
作成した Flutter プロジェクトに watchOS ターゲットを追加します。Xcode を使用して以下の手順で行います。

1. Xcode で Flutter プロジェクトの iOS 部分 (`ios` フォルダ) を開きます。
2. メニューから `File` > `New` > `Target...` を選択します。
3. `watchOS` タブから `Watch App` を選択し、テンプレートを進めてターゲットを追加します。
4. プロジェクトに watchOS 用のエクステンションが追加されます。

以上で watchOS ターゲットの設定が完了します。

## 2. Pigeon で Flutter, Swift のコード生成
Pigeon を用いて Flutter とネイティブプラットフォーム間の通信コードを生成します。Pigeon を使用することで、型安全な通信が可能となり、Method Channel を手動で設定する手間を省くことができます。

### Pigeon のインストール
まずは Pigeon を Flutter プロジェクトに追加します。`pubspec.yaml` に以下の依存関係を追加します。

```yaml
dev_dependencies:
  pigeon: ^22.5.0
```

その後、以下のコマンドを実行して依存関係をインストールします。

```bash
flutter pub get
```

### Pigeon 仕様の定義
Pigeon を使用するために、通信仕様を定義する Dart ファイルを作成します。`lib/pigeons/book.dart` に以下の内容を記述します。

```dart:pigeons/book.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/pigeons/book.g.dart',
  dartOptions: DartOptions(),
  swiftOut: 'ios/Runner/Book/Book.g.swift',
  swiftOptions: SwiftOptions(),
))
class Book {
  Book({
    this.id,
    required this.title,
    required this.publisher,
    required this.imageUrl,
    required this.lastModified,
  });
  String? id;
  String title;
  String publisher;
  String imageUrl;
  int lastModified;
}

class Record {
  Record({
    this.id,
    required this.book,
    required this.seconds,
    required this.createdAt,
    required this.lastModified,
  });
  String? id;
  Book book;
  int seconds;
  int createdAt;
  int lastModified;
}

// iOS, watchOS側で行いたい処理
@FlutterApi()
abstract class BookFlutterApi {
  @async
  List<Book> fetchBooks();
  void addBook(Book book);
  void deleteBook(Book book);
  @async
  List<Record> fetchRecords();
  void addRecord(Record record);
  void deleteRecord(Record record);
  void startTimer(int? count);
  void stopTimer();
}
```

### Pigeon コードの生成
仕様が定義できたら、以下のコマンドを実行してコードを生成します。

```bash
flutter pub run pigeon \
  --input lib/pigeons/book.dart \
  --dart_out lib/pigeons/book.g.dart \
  --swift_out ios/Runner/Book/Book.g.swift
```

これにより、Flutter と Swift 側の通信コードが自動生成されます。

## 3. Flutter でアプリの実装
次に、Flutter 側の実装を行います。主にデータの管理や UI の構築を担当します。

### モデルの定義
`lib/book/models/book.dart` を作成し、以下のようにモデルを定義します。

```dart:lib/book/models/book.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
class Book with _$Book {
  const factory Book({
    String? id,
    required String title,
    required String publisher,
    required String imageUrl,
    required int lastModified,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
```

### Repository 層の実装
`lib/book/repositories/book_repository.dart` を作成し、以下のようにリポジトリを実装します。

```dart:lib/book/repositories/book_repository.dart
import 'package:pigeon/pigeon.dart';
import 'package:pigeon_sample/pigeons/book.g.dart';

abstract class BookRepository {
  Future<List<Book>> fetchBooks();
  Future<void> addBook(Book book);
  Future<void> deleteBook(Book book);
  Future<List<Record>> fetchRecords();
  Future<void> addRecord(Record record);
  Future<void> deleteRecord(Record record);
  void startTimer(int? count);
  void stopTimer();
}

class BookRepositoryImpl implements BookRepository {
  final BookFlutterApi _bookFlutterApi;

  BookRepositoryImpl(this._bookFlutterApi);

  @override
  Future<List<Book>> fetchBooks() async {
    return await _bookFlutterApi.fetchBooks();
  }

  @override
  Future<void> addBook(Book book) async {
    _bookFlutterApi.addBook(book);
  }

  @override
  Future<void> deleteBook(Book book) async {
    _bookFlutterApi.deleteBook(book);
  }

  @override
  Future<List<Record>> fetchRecords() async {
    return await _bookFlutterApi.fetchRecords();
  }

  @override
  Future<void> addRecord(Record record) async {
    _bookFlutterApi.addRecord(record);
  }

  @override
  Future<void> deleteRecord(Record record) async {
    _bookFlutterApi.deleteRecord(record);
  }

  @override
  void startTimer(int? count) {
    _bookFlutterApi.startTimer(count);
  }

  @override
  void stopTimer() {
    _bookFlutterApi.stopTimer();
  }
}
```

### 状態管理と依存関係の設定
Riverpod を用いて状態管理を行います。プロバイダーを設定します。

```dart:lib/book/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pigeon_sample/pigeons/book.g.dart';
import 'repositories/book_repository.dart';

// BookFlutterApi のインスタンスをプロバイダーとして提供
final bookFlutterApiProvider = Provider<BookFlutterApi>((ref) {
  return BookFlutterApiSetup.setup();
});

// BookRepository のインスタンスをプロバイダーとして提供
final bookRepositoryProvider = Provider<BookRepository>((ref) {
  return BookRepositoryImpl(ref.read(bookFlutterApiProvider));
});
```

## 4. Flutter と Swift の繋ぎこみ実装
Flutter と Swift の連携部分を実装します。生成された Pigeon コードを活用し、Flutter 側からネイティブコードを呼び出す実装を行います。

### Flutter 側の実装
Flutter 側でネイティブコードを呼び出すために、必要なメソッドを設定します。例えば、Apple Watch からの操作を検知し、Firestore へのデータ保存処理を実行するメソッドを実装します。

```dart:lib/book/controllers/timer_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pigeon_sample/pigeons/book.g.dart';
import 'repositories/book_repository.dart';

final timerControllerProvider = Provider<TimerController>((ref) {
  return TimerController(ref.read(bookRepositoryProvider));
});

class TimerController {
  final BookRepository _bookRepository;

  TimerController(this._bookRepository);

  void startTimer(int? count) {
    _bookRepository.startTimer(count);
  }

  void stopTimer() {
    _bookRepository.stopTimer();
  }

  Future<void> fetchRecords() async {
    final records = await _bookRepository.fetchRecords();
    // レコードを処理する
  }
}
```

### Swift 側の実装
Swift 側で Flutter からの呼び出しを受け取るために、Pigeon で生成されたコードを活用します。`BookFlutterApi` を実装し、必要な処理を行います。

```swift:ios/Runner/Book/BookFlutterApiImpl.swift
import Foundation
import Flutter

class BookFlutterApiImpl: BookFlutterApi {
    var binaryMessenger: FlutterBinaryMessenger

    init(binaryMessenger: FlutterBinaryMessenger) {
        self.binaryMessenger = binaryMessenger
    }

    func fetchBooks(completion: @escaping ([Book]?) -> Void) {
        // watchOS からデータを取得し、Flutter に返す実装
        let books: [Book] = // データ取得処理
        completion(books)
    }

    func addBook(book: Book) {
        // 新しい本を追加する処理
    }

    func deleteBook(book: Book) {
        // 本を削除する処理
    }

    func fetchRecords(completion: @escaping ([Record]?) -> Void) {
        // レコードを取得する処理
        let records: [Record] = // データ取得処理
        completion(records)
    }

    func addRecord(record: Record) {
        // 新しいレコードを追加する処理
    }

    func deleteRecord(record: Record) {
        // レコードを削除する処理
    }

    func startTimer(count: Int?) {
        // タイマーを開始する処理
    }

    func stopTimer() {
        // タイマーを停止する処理
    }
}
```

このクラスを `AppDelegate.swift` でセットアップします。

```swift:ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    lazy var bookFlutterApi: BookFlutterApiImpl = {
        return BookFlutterApiImpl(binaryMessenger: flutterEngine.binaryMessenger)
    }()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self.flutterEngine)
        BookFlutterApiSetup.setUp(binaryMessenger: flutterEngine.binaryMessenger, api: bookFlutterApi)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
```

## 5. iOS と watchOS との連携実装
最後に、iOS と watchOS 間の連携を実装します。WatchConnectivity を用いて、iPhone と Apple Watch 間でデータをやり取りします。

### WatchConnectivity の設定
Swift 側で WatchConnectivity を設定します。watchOS アプリからのメッセージを受け取り、必要な処理を実行します。

```swift:ios/Runner/WatchSessionManager.swift
import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // セッションのアクティベーション完了時の処理
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        // セッションが非アクティブになった時の処理
    }

    func sessionDidDeactivate(_ session: WCSession) {
        // セッションがデアクティベートされた時の処理
        session.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // メッセージ受信時の処理
        if let bookId = message["bookId"] as? Int,
           let title = message["title"] as? String {
            // Flutter 側にデータを送信
            // 例: Firestore にデータを保存
        }
    }
}
```

### watchOS 側の実装
Apple Watch 側でメッセージを送信します。ユーザーの操作に応じて iPhone 側にデータを送信します。

```swift:WatchWatchOS Extension/WatchSessionManager.swift
import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private var session: WCSession?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }

    func sendBookData(bookId: Int, title: String) {
        let message: [String: Any] = ["bookId": bookId, "title": title]
        session?.sendMessage(message, replyHandler: nil, errorHandler: { error in
            print("Error sending message: \(error)")
        })
    }

    // 必要な他の WCSessionDelegate メソッドの実装
}
```

### データの同期
WatchApp から送信されたデータを iOS アプリ側で受信し、Firestore に保存する処理を実装します。`BookFlutterApiImpl` クラス内でこれを行います。

```swift:ios/Runner/Book/BookFlutterApiImpl.swift
func fetchBooks(completion: @escaping ([Book]?) -> Void) {
    // Firestore からデータを取得
    let books: [Book] = // Firestore からのデータ取得処理
    completion(books)
}

func addBook(book: Book) {
    // Firestore にデータを追加
    // 例:
    let db = Firestore.firestore()
    db.collection("books").addDocument(data: [
        "title": book.title,
        "publisher": book.publisher,
        "imageUrl": book.imageUrl,
        "lastModified": book.lastModified
    ]) { error in
        if let error = error {
            print("Error adding document: \(error)")
        } else {
            print("Document added with ID: \(ref!.documentID)")
        }
    }
}

// 他のメソッドも同様に Firestore とのやりとりを実装
```

### Apple Watch の操作とデータ保存
Apple Watch 側でユーザーが操作を行った際に、データを iPhone に送信し、Firestore に保存します。Flutter アプリ側で受け取ったデータを適切に処理します。

## まとめ
最後まで読んでいただいてありがとうございました。今回は Pigeon を用いて Flutter で書かれたアプリケーションと、Swift で書かれた watchOS アプリケーションの連携を実装しました。Pigeon を使用することで、コードの自動生成により通信部分のコーディングを大幅に効率化でき、型安全な通信が実現できました。

実装のポイントは以下の通りです：
1. Pigeon による型安全なコード生成の活用
2. Flutter とネイティブコード間のシームレスな通信の実現
3. WatchConnectivity を用いた iOS と watchOS 間のデータ同期

この実装により、Flutter アプリケーションから Apple Watch の機能を活用し、ユーザー体験を向上させることが可能となりました。今後も Pigeon を活用して更なるネイティブ機能との連携を試みていきたいと思います。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考
- [Pigeon | pub.dev](https://pub.dev/packages/pigeon)
- [WatchConnectivity | Apple Developer Documentation](https://developer.apple.com/documentation/watchconnectivity)
- [Watch Connectivity | Apple Developer Documentation](https://developer.apple.com/documentation/watchkit/working_with_watch_connectivity)
- [Flutter と watchOS の連携実装](https://github.com/Koichi5/pigeon-sample)