import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/book.g.dart';
import 'package:pigeon_sample/book/book_flutter_api_impl.dart';

class BookDetailScreen extends HookConsumerWidget {
  final Book book;

  const BookDetailScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTiming = useState(false);
    final elapsedSeconds = useState(0);
    final stopwatch = useMemoized(() => Stopwatch());
    final bookApi = ref.watch(bookApiProvider);

    void updateTime() {
      if (stopwatch.isRunning) {
        Future.delayed(const Duration(seconds: 1), () {
          if (stopwatch.isRunning) {
            elapsedSeconds.value = stopwatch.elapsed.inSeconds;
            updateTime();
          }
        });
      }
    }

    void startStopwatch() {
      isTiming.value = true;
      stopwatch.start();
      updateTime();
    }

    void stopStopwatch() {
      isTiming.value = false;
      stopwatch.stop();
      elapsedSeconds.value = stopwatch.elapsed.inSeconds;
    }

    void resetStopwatch() {
      stopwatch.reset();
      elapsedSeconds.value = 0;
    }

    void saveRecord() async {
      final record = Record(
        id: null,
        book: book,
        seconds: elapsedSeconds.value,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        lastModified: DateTime.now().millisecondsSinceEpoch,
      );
      bookApi.addRecord(record);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('記録を保存しました')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('本の詳細'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                book.title,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '出版社: ${book.publisher}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  book.imageUrl,
                  height: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.book, size: 100);
                  },
                ),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _formatTime(elapsedSeconds.value),
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: isTiming.value ? stopStopwatch : startStopwatch,
                            icon: Icon(isTiming.value ? Icons.pause : Icons.play_arrow),
                            label: Text(isTiming.value ? 'ストップ' : 'スタート'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(120, 40),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: elapsedSeconds.value > 0 ? resetStopwatch : null,
                            icon: const Icon(Icons.refresh),
                            label: const Text('リセット'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(120, 40),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (elapsedSeconds.value > 0 && !isTiming.value)
                ElevatedButton.icon(
                  onPressed: saveRecord,
                  icon: const Icon(Icons.save),
                  label: const Text('記録を保存'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 48),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$remainingSeconds';
  }
}
