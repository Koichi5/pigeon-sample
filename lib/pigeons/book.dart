import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/book/book.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Book/Book.g.kt',
  kotlinOptions: KotlinOptions(),
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
