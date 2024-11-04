import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pigeon_sample/battery/battery.g.dart';
import 'package:pigeon_sample/battery/battery_flutter_api_impl.dart';
import 'package:pigeon_sample/battery/battery_screen.dart';
import 'package:pigeon_sample/book/book.g.dart';
import 'package:pigeon_sample/book/book_flutter_api_impl.dart';
import 'package:pigeon_sample/book/book_list_screen.dart';
import 'package:pigeon_sample/firebase_options.dart';
import 'package:pigeon_sample/todo/todo.g.dart';
import 'package:pigeon_sample/todo/todo_flutter_api_impl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // BatteryFlutterApiの実装をセットアップ
  // BatteryFlutterApi.setUp(BatteryFlutterApiImpl());
  // SaveDataFlutterApi.setUp(SaveDataFlutterApiImpl());

  // Todo
  // TodoFlutterApi.setUp(TodoFlutterApiImpl());

  // Book, Record
  BookFlutterApi.setUp(BookFlutterApiImpl());

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Battery Level App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BookListPage()
    );
  }
}
