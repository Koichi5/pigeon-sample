import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/book.g.dart';
import 'package:pigeon_sample/book/book_add_screen.dart';
import 'package:pigeon_sample/book/book_detail_screen.dart';
import 'package:pigeon_sample/book/book_flutter_api_impl.dart';

final bookApiProvider = Provider<BookFlutterApiImpl>((ref) {
  return BookFlutterApiImpl();
});

class BookListPage extends HookConsumerWidget {
  const BookListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookApi = ref.watch(bookApiProvider);

    // データを取得するための FutureProvider
    final booksFutureProvider = FutureProvider<List<Book>>((ref) async {
      return await bookApi.fetchBooks();
    });

    final booksAsyncValue = ref.watch(booksFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本の一覧'),
      ),
      body: booksAsyncValue.when(
        data: (books) {
          return ListView.builder(
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];
              return ListTile(
                title: Text(book.title),
                subtitle: Text(book.publisher),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookDetailPage(book: book),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 本の追加画面へ遷移
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookAddPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
