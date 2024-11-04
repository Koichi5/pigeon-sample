import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/book.g.dart';
import 'package:pigeon_sample/book/book_list_screen.dart';

// 記録の取得
final recordsFutureProvider = FutureProvider<List<Record>>((ref) async {
  final bookApi = ref.watch(bookApiProvider);

  final allRecords = await bookApi.fetchRecords();
  // 該当する本の記録のみフィルタリング
  return allRecords;
});

class BookDetailPage extends HookConsumerWidget {
  final Book book;

  const BookDetailPage({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTiming = useState(false);
    final elapsedSeconds = useState(0);
    final stopwatch = useMemoized(() => Stopwatch());
    final bookApi = ref.watch(bookApiProvider);

    void _updateTime() {
      if (stopwatch.isRunning) {
        Future.delayed(const Duration(seconds: 1), () {
          if (stopwatch.isRunning) {
            elapsedSeconds.value = stopwatch.elapsed.inSeconds;
            _updateTime();
          }
        });
      }
    }

    void _startStopwatch() {
      isTiming.value = true;
      stopwatch.start();
      _updateTime();
    }

    void _stopStopwatch() async {
      isTiming.value = false;
      stopwatch.stop();
      elapsedSeconds.value = stopwatch.elapsed.inSeconds;

      // 記録を保存
      final record = Record(
        id: null,
        book: book,
        seconds: elapsedSeconds.value,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      bookApi.addRecord(record);

      // ストップウォッチをリセット
      stopwatch.reset();
      elapsedSeconds.value = 0;
    }

    final recordsAsyncValue = ref.watch(recordsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(book.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Text('出版社: ${book.publisher}'),
            const SizedBox(height: 20),
            Image.network(
              book.imageUrl,
              height: 200,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.book, size: 100);
              },
            ),
            const SizedBox(height: 20),
            Text(
              '勉強時間: ${_formatTime(elapsedSeconds.value)}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: isTiming.value ? _stopStopwatch : _startStopwatch,
              child: Text(isTiming.value ? 'ストップ' : 'スタート'),
            ),
            const SizedBox(height: 20),
            const Text('記録一覧', style: TextStyle(fontSize: 18)),
            Expanded(
              child: recordsAsyncValue.when(
                data: (records) {
                  if (records.isEmpty) {
                    return const Center(child: Text('記録がありません'));
                  }
                  return ListView.builder(
                    itemCount: records.length,
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(record.createdAt);
                      final formattedDate =
                          '${date.year}/${date.month}/${date.day}';
                      return ListTile(
                        title: Text('勉強時間: ${_formatTime(record.seconds)}'),
                        subtitle: Text('日付: $formattedDate'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    Center(child: Text('エラーが発生しました: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remainingSeconds';
  }
}
