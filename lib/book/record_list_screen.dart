import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/book.g.dart';
import 'package:pigeon_sample/book/book_list_screen.dart';

class RecordListPage extends HookConsumerWidget {
  const RecordListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookApi = ref.watch(bookApiProvider);

    // 記録の取得
    final recordsFutureProvider = FutureProvider<List<Record>>((ref) async {
      return await bookApi.fetchRecords();
    });

    final recordsAsyncValue = ref.watch(recordsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('記録一覧'),
      ),
      body: recordsAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('記録がありません'));
          }
          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final date = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
              final formattedDate = '${date.year}/${date.month}/${date.day}';
              return ListTile(
                title: Text('本: ${record.book.title}'),
                subtitle: Text(
                    '勉強時間: ${_formatTime(record.seconds)} 日付: $formattedDate'),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラーが発生しました: $error')),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}
