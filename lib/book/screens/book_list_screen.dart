import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/book_flutter_api_impl.dart';
import 'package:pigeon_sample/book/screens/book_add_screen.dart';
import 'package:pigeon_sample/book/screens/book_detail_screen.dart';

class BookListScreen extends HookConsumerWidget {
  const BookListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsyncValue = ref.watch(booksProvider);
    return Scaffold(
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
                      builder: (context) => BookDetailScreen(book: book),
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
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BookAddScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
