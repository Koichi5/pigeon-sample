import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/book/screens/book_list_screen.dart';
import 'package:pigeon_sample/book/screens/record_list_screen.dart';

class TabScreen extends HookConsumerWidget {
  const TabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ライブラリ'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '本'),
              Tab(text: '記録'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BookListScreen(),
            RecordListScreen(),
          ],
        ),
      ),
    );
  }
}