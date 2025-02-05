## 初めに
今回は [table_calendarパッケージ](https://pub.dev/packages/table_calendar) を使ってカレンダーを表示する実装を行います。

## 記事の対象者
+ Flutter 学習者
+ カレンダーを実装したい方

## 目的
今回は上記の通り、[table_calendarパッケージ](https://pub.dev/packages/table_calendar) を使ってカレンダーを実装することを目的とします。最終的には以下のようなカレンダーの表示を実装します。
![](https://storage.googleapis.com/zenn-user-upload/68a8f6450aaf-20240214.png =300x)

## 導入
[table_calendarパッケージ](https://pub.dev/packages/table_calendar) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  table_calendar: ^3.1.0
```

または

以下をターミナルで実行
```
flutter pub add table_calendar
```

## 実装
今回は以下の手順で実装を進めていきます。
1. カレンダーの表示
2. 日本語対応
3. 日付をタップした時の処理実装
4. イベントの追加

### 1. カレンダーの表示
この章では、以下の動画のようにシンプルなカレンダーを表示させる実装を行います。
![](https://storage.googleapis.com/zenn-user-upload/f9fc3115e534-20240214.png =300x)

コードは以下の通りです。
基本的なカレンダーのみであれば４行で実装できます。
`firstDay` ではカレンダーで表示できる初めの日、`lastDay` ではカレンダーで表示できる最後の日、`focusedDay` ではフォーカスが当たっている日を指定できます。

```dart: table_calendar_sample.dart
class TableCalendarSample extends StatelessWidget {
  const TableCalendarSample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2010, 1, 1),
        lastDay: DateTime.utc(2030, 1, 1),
        focusedDay: DateTime.now(),
     ),
    );
  }
}
```

### 2. 日本語対応
次にカレンダーを日本語に対応させていきます。
手順は以下の通りです。
1. intl パッケージの導入
2. main.dart の変更
3. カレンダーの変更

それぞれ実装していきましょう。

#### 1. intl パッケージの導入
カレンダーを日本語対応させるためには [intl パッケージ](https://pub.dev/packages/intl) の導入が必要です。

`pubspec.yaml` の内容を以下のように変更します。
```diff yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  table_calendar: ^3.1.0
+ intl: ^0.19.0
```

または

以下をターミナルで実行
```
flutter pub add intl
```

#### 2. main.dart の変更
次に `main.dart` を以下のように変更します。
`initializeDateFormatting` で日付のフォーマットを初期化することができます。
日本語に対応させるために引数として `ja_JP` を指定しています。
```diff dart: main.dart
Future<void> main() async {
+ await initializeDateFormatting('ja_JP').then(
+   (_) {
      runApp(
        const ProviderScope(
          child: MyApp(),
        ),
      );
+   },
+ );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TableCalendarSample(),
    );
  }
}
```

:::message
`initializeDateFormatting` を実装する際の import 文に関して、`package:intl/date_symbol_data_local.dart` から正しくインポートされているかどうかを確認するようにしましょう。
:::

#### 3. カレンダーの変更
最後にカレンダーを以下のように変更します。
`locale` で日本を指定することで以下の画像のように日本語の日付を表示させることができます。
```diff dart: table_calendar_sample.dart
TableCalendar(
  firstDay: DateTime.utc(2010, 1, 1),
  lastDay: DateTime.utc(2030, 1, 1),
  focusedDay: DateTime.now(),
+ locale: 'ja_JP',
)
```

![](https://storage.googleapis.com/zenn-user-upload/3cf7ad82f64b-20240214.png =300x)

### 3. 日付をタップした時の処理実装
次に日付をタップした際の処理を実装します。
カレンダーの実装を以下のように変更します。
```diff dart: table_calendar_sample.dart
class TableCalendarSample extends HookWidget {  // HookWidget に変更
  const TableCalendarSample({super.key});

  @override
  Widget build(BuildContext context) {
+   final focusedDayState = useState(DateTime.now());
+   final selectedDayState = useState(DateTime.now());
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2010, 1, 1),
        lastDay: DateTime.utc(2030, 1, 1),
        focusedDay: DateTime.now(),
        locale: 'ja_JP',
+       selectedDayPredicate: (day) {
+         return isSameDay(selectedDayState.value, day);
+       },
+       onDaySelected: (selectedDay, focusedDay) {
+         selectedDayState.value = selectedDay;
+         focusedDayState.value = focusedDay;
+       },
      ),
    );
  }
```

上記のコードを実行すると以下の動画のようになります。
https://youtube.com/shorts/zr8at31baZQ

コードを詳しくみていきます。

以下のコードでは、`selectedDayPredicate` で特定の日付が選択されているかどうかを判断しています。
引数として DateTime 型の `day` を受け取り、`isSameDay` 関数で特定の日付が選択されているかどうかを判断します。
```dart
selectedDayPredicate: (day) {
  return isSameDay(selectedDayState.value, day);
},
```

以下のコードでは `onDaySelected` で日付が選択された際の処理を記述しています。
`useState` で管理している `selectedDayState`, `focusedDayState` をそれぞれ割り当てることで、日付が選択されたときにそこにフォーカスが当たるようにしています。
```dart
onDaySelected: (selectedDay, focusedDay) {
  selectedDayState.value = selectedDay;
  focusedDayState.value = focusedDay;
},
```

### 4. イベントの追加
次にイベントが追加できるような実装を行います。
実装は以下の手順で行います。
1. イベントのデータ構造を定義
2. イベントを管理するProviderを作成
3. カレンダーの表示を変更

最終的には以下の動画のようにイベントの追加、削除が行えるような実装を行います。

https://youtube.com/shorts/unDr-go1hf8?feature=share

#### 1. イベントのデータ構造を定義
まずはイベントのデータ構造を定義します。
コードは以下の通りで、今回は Freezed などは用いずに実装を行います。
`title` ではイベントのタイトルを、`description` ではイベントの詳細情報を、`dateTime` ではイベントの日付を保持するようにします。
```dart: event.dart
class Event {
  final String title;
  final String? description;
  final DateTime dateTime;

  Event(
      {required this.title, this.description, required this.dateTime});
}
```

#### 2. イベントを管理するProviderを作成
次にイベントを管理するための Provider を作成します。
コードは以下の通りで、Riverpod generator を用いて実装を行います。
```dart: table_calendar_even_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'table_calendar_event_provider.g.dart';

@riverpod
class TableCalendarEventController extends _$TableCalendarEventController {
  final List<Event> sampleEvents = [
    Event(
        title: 'firstEvent', dateTime: DateTime.utc(2024, 2, 15)),
    Event(
      title: 'secondEvent',
      description: 'description',
      dateTime: DateTime.utc(2024, 2, 15),
    ),
  ];

  @override
  List<Event> build() {
    state = sampleEvents;
    return state;
  }

  void addEvent(
      {required DateTime dateTime,
      required String title,
      String? description}) {
    var newData = Event(title: title, description: description, dateTime: dateTime);
    state.add(newData);
  }

  void deleteEvent({required Event event}) {
    state.remove(event);
  }
}
```

コードを詳しくみていきます。

以下の部分ではサンプルのイベントを用意しています。
本来であれば予定はFirestoreなどのデータベースやローカルデータベースに格納されているかと思いますが、今回は簡単な実装のため単純な変数として定義しています。
```dart
final List<Event> sampleEvents = [
  Event(
    title: 'firstEvent',
    dateTime: DateTime.utc(2024, 2, 15)
  ),
  Event(
    title: 'secondEvent',
    description: 'description',
    dateTime: DateTime.utc(2024, 2, 15),
  ),
];
```

以下では `build` メソッドで、Provider で管理するデータの `state` の初期値として `sampleEvents` を代入しています。
```dart
@override
List<Event> build() {
  state = sampleEvents;
  return state;
}
```

以下ではイベントの作成と削除を行うためのメソッドを作成しています。
先述の通りデータベースの実装は行わず、単純に `state` に指定されている `List<Event>` を変更するのみにとどめています。
```dart
void addEvent(
  {required DateTime dateTime,
  required String title,
  String? description}) {
    var newData = Event(title: title, description: description, dateTime: dateTime);
    state.add(newData);
}

void deleteEvent({required Event event}) {
  state.remove(event);
}
```

これで Event を管理する Provider の作成は完了です。

#### 3. カレンダーの表示を変更
最後に先ほどの Event データや Provider を用いてイベントを追加、削除できるようにカレンダーを変更していきます。

変更後のコードは以下の通りです。
```dart: table_calendar_sample.dart
class TableCalendarSample extends HookConsumerWidget {
  const TableCalendarSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusedDayState = useState(DateTime.now());
    final selectedDayState = useState(DateTime.now());
    final selectedEventsState = useState([]);
    final eventProvider = ref.watch(tableCalendarEventControllerProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: TableCalendar(
        firstDay: DateTime.utc(2010, 1, 1),
        lastDay: DateTime.utc(2030, 1, 1),
        focusedDay: DateTime.now(),
        locale: 'ja_JP',
        selectedDayPredicate: (day) {
          return isSameDay(selectedDayState.value, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          List<Event> selectedEventList = [];
          for (var event in eventProvider) {
            if (event.dateTime == selectedDay) {
              selectedEventList.add(event);
            }
          }
          selectedDayState.value = selectedDay;
          focusedDayState.value = focusedDay;
          selectedEventsState.value = selectedEventList;
        },
        onDayLongPressed: (selectedDay, focusedDay) async {
          await showAddEventDialog(context, selectedDay, ref);
        },
        eventLoader: (date) {
          List<Event> selectedEventList = [];
          for (var event in eventProvider) {
            if (event.dateTime == date) {
              selectedEventList.add(event);
            }
          }
          return selectedEventList;
        },
      ),
    );
  }

  Future<void> showAddEventDialog(
      BuildContext context, DateTime selectedDay, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('イベントの追加', style: TextStyle(fontSize: 20),),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'タイトル'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    maxLines: 3,
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                        border: OutlineInputBorder(), hintText: '詳細'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'キャンセル',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .watch(tableCalendarEventControllerProvider.notifier)
                              .addEvent(
                                  dateTime: selectedDay,
                                  title: titleController.text,
                                  description: descriptionController.text);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '追加',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

上記のコードで実行するとこの章の上で提示した動画のようにイベントの作成や削除が行えるようになります。

コードを詳しくみていきます。

イベントの操作は Riverpod で行い、その結果をカレンダーで受け取るため、`TableCalendarSample` を `HookConsumerWidget` に変更しておきます。
```dart
class TableCalendarSample extends HookConsumerWidget {
    ... 省略
}
```

以下の部分では、選択されているイベントとイベントを管理する Provider の返り値を `useState` で監視しています。
`tableCalendarEventControllerProvider` では `build` メソッドで `sampleEvents` を `state` に設定したため、初期値では `sampleEvents` が代入されています。
```dart
final selectedEventsState = useState([]);
final eventProvider = ref.watch(tableCalendarEventControllerProvider);
```

以下のコードでは、日付が選択された際の処理を変更しています。
`selectedEventList` という即時関数を使って、選択された日付に登録されているイベントを探し、もしイベントがある場合は `selectedEventList` に追加し、その結果を `selectedEventsState` に格納しています。
```dart
onDaySelected: (selectedDay, focusedDay) {
  List<Event> selectedEventList = [];
    for (var event in eventProvider) {
      if (event.dateTime == selectedDay) {
        selectedEventList.add(event);
      }
    }
  selectedEventsState.value = selectedEventList;
```

以下のコードでは `onDayLongPressed` を用いて、日付が長押しされた際の処理を記述しています。
ユーザーが日付を長押しした際には、後述の `showAddEventDialog` 関数を実行するようにしています。
```dart
onDayLongPressed: (selectedDay, focusedDay) async {
  await showAddEventDialog(context, selectedDay, ref);
},
```

以下では `eventLoader` を用いてそれぞれの日付のイベントを読み込む処理を行なっています。
`onDaySelected` の場合と同様に即時関数を用いて実装しています。
公式ドキュメントの実装ではイベントを単純な Map として扱っていたため、キーである日付を指定するだけで良かったものが、Event という自作のクラスにしたため、この辺りの処理が多少複雑になっています。
```dart
eventLoader: (date) {
List<Event> selectedEventList = [];
  for (var event in eventProvider) {
    if (event.dateTime == date) {
      selectedEventList.add(event);
    }
  }
  return selectedEventList;
},
```

以下ではそれぞれの日付の予定を表示させるための `ListView.builder` を実装しています。
選択されている日付のイベントを表す `selectedEventsState` をもとにUIを構築しており、イベントがある場合は動画のようにカレンダーの下にリスト形式で表示されるようになっています。

また、イベントの削除を行うための `IconButton` も実装しており、押された際の処理として Provider で実装した `deleteEvent` 関数を実装しています。
```dart
Expanded(
  child: ListView.builder(
    itemCount: selectedEventsState.value.length,
    itemBuilder: (context, index) {
      final event = selectedEventsState.value[index];
      return Card(
        child: ListTile(
          title: Text(event.title),
          subtitle: event.description == null
            ? null
            : Text(event.description!),
          trailing: IconButton(
            onPressed: () {
              ref.read(tableCalendarEventControllerProvider.notifier)
                .deleteEvent(event: event);
            },
            icon: const Icon(Icons.delete),
          ),
        ),
      );
    },
  ),
),
```

以下では、先ほどの `onDayLongPressed` で発火する `showAddEventDialog` 関数を実装しています。名前の通りカレンダーの日付を長押しするとイベントを追加するためのダイアログが表示されるようにしています。

イベントのタイトルや説明文は `TextEditingController` で管理して、「追加」ボタンが押されるときにイベントを管理する Provider の `addEvent` 関数に渡すことでイベントを追加しています。
```dart
  Future<void> showAddEventDialog(
      BuildContext context, DateTime selectedDay, WidgetRef ref) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('イベントの追加', style: TextStyle(fontSize: 20),),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(), hintText: 'タイトル'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    maxLines: 3,
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 40, horizontal: 10),
                        border: OutlineInputBorder(), hintText: '詳細'),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'キャンセル',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ref
                              .watch(tableCalendarEventControllerProvider.notifier)
                              .addEvent(
                                  dateTime: selectedDay,
                                  title: titleController.text,
                                  description: descriptionController.text);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          '追加',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
```

上記のコードで実行すると、この章の初めに提示した動画のような挙動になるかと思います。

## まとめ
最後まで読んでいただいてありがとうございました。

今回は table_calendar パッケージを使ってカレンダーを表示したりイベントを追加する実装を行いました。表示させるだけなら４行でできるという非常に導入の簡単なパッケージだと感じました。
また、細かくカスタマイズもできるので、汎用性も高いと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考
https://pub.dev/packages/table_calendar

https://zenn.dev/rafekun/articles/0d91235356ac2a

