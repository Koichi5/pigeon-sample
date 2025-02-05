import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/book.g.dart';
import 'package:pigeon_sample/book/book_flutter_api_impl.dart';

class BookAddScreen extends HookConsumerWidget {
  const BookAddScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final publisherController = TextEditingController();
    final imageUrlController = TextEditingController();

    final isLoading = useState(false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('本の追加'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: <Widget>[
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'タイトル'),
                  ),
                  TextField(
                    controller: publisherController,
                    decoration: const InputDecoration(labelText: '出版社'),
                  ),
                  TextField(
                    controller: imageUrlController,
                    decoration: const InputDecoration(labelText: '画像URL'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('タイトルを入力してください')),
                        );
                        return;
                      }
                      isLoading.value = true;
                      final bookApi = ref.read(bookApiProvider);
                      final book = Book(
                        id: null,
                        title: titleController.text,
                        publisher: publisherController.text,
                        imageUrl: imageUrlController.text,
                        lastModified: DateTime.now().millisecondsSinceEpoch,
                      );
                      bookApi.addBook(book);
                      isLoading.value = false;
                      Navigator.pop(context);
                    },
                    child: const Text('保存'),
                  ),
                ],
              ),
      ),
    );
  }
}
