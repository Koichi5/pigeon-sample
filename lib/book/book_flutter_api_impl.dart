import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pigeon_sample/book/book.g.dart';

class BookFlutterApiImpl extends BookFlutterApi {
  final books = FirebaseFirestore.instance.collection('books');
  final records = FirebaseFirestore.instance.collection('records');

  @override
  Future<List<Book>> fetchBooks() async {
    final QuerySnapshot querySnapshot = await books.get();
    final List<Book> bookList = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      return Book(
        id: data['id'] ?? doc.id,
        title: data['title'] ?? '',
        publisher: data['publisher'] ?? '',
        imageUrl: data['imageUrl'] ?? '',
        lastModified: data['lastModified'] ?? 0,
      );
    }).toList();

    return bookList;
  }

  @override
  void addBook(Book book) {
    final docRef = books.doc(book.id ?? books.doc().id);
    docRef.set({
      'id': docRef.id,
      'title': book.title,
      'publisher': book.publisher,
      'imageUrl': book.imageUrl,
      'lastModified': book.lastModified,
    });
  }

  @override
  void deleteBook(Book book) {
    if (book.id != null) {
      books.doc(book.id).delete();
    }
  }

  @override
  Future<List<Record>> fetchRecords() async {
    final QuerySnapshot querySnapshot = await records.get();
    final List<Record> recordList = querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;

      final bookData = data['book'] as Map<String, dynamic>;
      final Book book = Book(
        id: bookData['id'] ?? '',
        title: bookData['title'] ?? '',
        publisher: bookData['publisher'] ?? '',
        imageUrl: bookData['imageUrl'] ?? '',
        lastModified: bookData['lastModified'] ?? 0,
      );

      return Record(
        id: data['id'] ?? doc.id,
        book: book,
        seconds: data['seconds'] ?? 0,
        createdAt: data['createdAt'] ?? 0,
        lastModified: data['lastModified'] ?? 0,
      );
    }).toList();

    return recordList;
  }

  @override
  void addRecord(Record record) {
    final docRef = records.doc(record.id ?? records.doc().id);
    docRef.set({
      'id': docRef.id,
      'book': {
        'id': record.book.id ?? '',
        'title': record.book.title,
        'publisher': record.book.publisher,
        'imageUrl': record.book.imageUrl,
        'lastModified': record.book.lastModified,
      },
      'seconds': record.seconds,
      'createdAt': record.createdAt,
      'lastModified': record.lastModified,
    });
  }

  @override
  void deleteRecord(Record record) {
    if (record.id != null) {
      records.doc(record.id).delete();
    }
  }
}
