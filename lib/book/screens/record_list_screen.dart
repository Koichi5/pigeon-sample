import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/book_flutter_api_impl.dart';

class RecordListScreen extends HookConsumerWidget {
  const RecordListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsyncValue = ref.watch(recordsProvider);

    return Scaffold(
      body: recordsAsyncValue.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(child: Text('記録がありません'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recordsProvider);
            },
            child: ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                final date = DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                final formattedDate = '${date.year}/${date.month}/${date.day}';
                return ListTile(
                  title: Text(record.book.title),
                  subtitle: Text(
                      '勉強時間: ${_formatTime(record.seconds)} 日付: $formattedDate'),
                );
              },
            ),
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
