## 初めに
今回は [flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker) パッケージを使って色を選択するための実装を行いたいと思います。

## 記事の対象者
+ Flutter 学習者
+ 色の選択を実装する必要がある方

## 目的
今回は上記の通り、[flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker)　パッケージで色を選択するUIの作成を行うことを目的とします、最終的には以下のように色を選択してその保存もできるような実装を行いたいと思います。
なお、今回はカラーピッカーを使って値を保存することが目的であるため、リスト表示の実装は行いません。

https://youtu.be/A71SjQUAWrI

## 導入
### パッケージの導入
[flutter_colorpicker](https://pub.dev/packages/flutter_colorpicker) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_colorpicker: ^1.0.3
```

または

以下をターミナルで実行
```
flutter pub add flutter_colorpicker
```

## 実装
実装は以下の手順で行います。
1. タグのモデル作成
2. タグを管理するためのレポジトリ作成
3. TagScreen の State 作成
4. TagScreen の ViewModel 作成
5. TagScreen の View 作成

### 1. タグのモデル作成
まずはタグのモデルの作成を行います。
タグは色と名前のみを持つシンプルな構成にします。
コードは以下の通りです。
```dart: tag.dart
part 'tag.freezed.dart';
part 'tag.g.dart';

// IDと名前と色の値を持つタグを作成
@freezed
abstract class Tag with _$Tag {
  const factory Tag({
    required String tagId,
    required String name,
    required int colorValue,
  }) = _Tag;

  const Tag._();

  factory Tag.fromJson(Map<String, dynamic> json) =>
      _$TagFromJson(json);

// Firestore のコレクション名を定義
  static String get collectionName => 'tags';
}
```

### 2. タグを管理するためのレポジトリ作成
次にタグを管理するためのレポジトリを作成します。
Firestore への保存もここで行います。
今回は　Repository を画面の ViewModel で読み取る形で実装しているため、この保存先を SharedPreferences や flutter_secure_storage などに切り替えることも可能です。

今回は保存するための処理のみを記述しています。
コードは以下の通りです。
```dart: tag_repo.dart
part 'tag_repo.g.dart';

@riverpod
class TagRepo extends _$TagRepo {
// FirestoreFirestore の instance を取得
  FirebaseFirestore get db => ref.read(firestoreProvider);

// コレクションのパスを取得
  CollectionReference<Tag> get collection => db
      .collection(Tag.collectionName);

  @override
  void build() {}

// タグを追加する処理（tagId　の有無によって追加と更新が可能）
  Future<String> save({
    required String? tagId,
    required String name,
    required int colorValue,
  }) async {
    final doc = collection.doc(tagId);
    final tag = Tag(
      tagId: doc.id,
      name: name,
      colorValue: colorValue,
    );

    return doc
        .set(tag, SetOptions(merge: true))
        .then((value) => doc.id);
  }
}
```

:::message
上記の実装ではタグの色を表す `colorValue` を int 型で指定しています。
2024年3月現在、Firestoreでは Color を一つの型として保存するような記載はなかったかと思うので、 `Colors.black.value` のようにして色の値を int 型で取得して保存しています。
`value`　と指定するだけで簡単に色を保存できるので、非常に便利かと思います。
:::

### 3. TagScreen の State 作成
次にタグを追加する画面の State を作成していきます。
画面内ではタグの名前と選択する色の状態の二つを保持します。
コードは以下の通りです。
```dart: tag_screen_state.dart
part 'tag_screen_state.freezed.dart';

// タグの名前を保持する tagNameController, タグの色を保持する tagColor
@freezed
abstract class TagScreenState with _$TagScreenState {
  const factory TagScreenState({
    required TextEditingController tagNameController,
    required Color tagColor,
  }) = _TagScreenState;
}
```

### 4. TagScreen の ViewModel 作成
次にタグを追加する画面の ViewModel を作成していきます。
コードは以下の通りです。
```dart: tag_screen_view_model.dart
part 'tag_screen_view_model.g.dart';

@riverpod
class TagScreenViewModel extends _$TagScreenViewModel {
  TagRepo get tagRepo =>
      ref.read(tagRepoProvider.notifier);

  @override
  TagScreenState build() {
      return TagScreenState(
      tagNameController: TextEditingController(text: ''),
      tagColor: Color(4278190080), // 初期値は黒色の colorValue
    );
  }

  void updateTagColor(Color color) {
    state = state.copyWith(tagColor: color),
  }

  Future<void> save() async {
    final data = state;
    validate(data);

    await tagRepo.save(
      tagId: 'tagId',
      name: data.tagNameController.text,
      colorValue: tagColor.value,
    );
  }

  void validate(TagScreenState data) {
    if (data.tagNameController.text.isEmpty) {
      throw Exception('タグの名前を入力してください');
    }
  }
}
```

詳しくみていきます。

以下の部分では、buildメソッドに、名前が空の文字列で、色が黒色の `TagScreenState` を指定しています。
```dart
@override
  TagScreenState build() {
    return TagScreenState(
      tagNameController: TextEditingController(text: ''),
      tagColor: Color(4278190080), // 初期値は黒色の colorValue
    );
  }
```

以下ではタグの名前が入力されていない時のバリデーションを実装しています。
```dart
void validate(TagScreenState data) {
  if (data.tagNameController.text.isEmpty) {
    throw Exception('タグの名前を入力してください');
  }
}
```

### 5. TagScreen の View 作成
最後にタグを追加するページの View を実装していきます。
コードは以下の通りです。
```dart: tag_screen_view.dart
class TagScreen extends ConsumerWidget {
  const TagScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state =
        ref.watch(tagScreenViewModelProvider);
    final controller = ref.read(tagScreenViewModelProvider.notifier);
    return Scaffolf(
      body: state.when(
        error: (err, stack) => // エラー時に表示させる Widget
        loading: () => // ローディング時に表示させる Widget
        data: (data) => Padding(
          padding: EdgeInsets.all(context.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('タグのカラー'),
              const Gap(20),
              InkWell(
                onTap: () async {
                  showDialig(
                    context: context,
                    builder: (context) {
                      SimpleDialig(
                        title: const Text('タグカラー選択'),
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ColorPicker(
                                pickerColor: data.tagColor,
                                onColorChanged:
                                    controller.updateTagColor,
                                pickerAreaHeightPercent: 0.8,
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text('閉じる'),
                                ),
                              ),
                            ],
                          ),
                        ],
                       }
                    );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: data.tagColor,
                    ),
                    const Gap(20),
                    const Text('カラーを選択する'),
                  ],
                ),
              ),
              const Gap(40),
              const Text('タグの名前'),
              const Gap(20),
              SizedBox(
                width: context.bodyWidth * 0.4,
                child: TextField(
                  controller: data.tagNameController,
                ),
              ),
              const Gap(40),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      context.pop(context);
                    },
                    child: const Text('キャンセル'),
                  ),
                  const Gap(20),
                  ElevatedButton(
                    onPressed: () async {
                      await controller.save().then((value) {
                        context.pop(context)
                      }).catchError((e) {
                        context
                          ..pop()
                          ..errorDialog(e);
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: context.colorScheme.onPrimary,
                      backgroundColor: context.colorScheme.primary,
                    ),
                    child: Text('作成'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

以下では `ColorPicker` の実装を行なっています。
`pickerColor` には取得したデータの `tagColor` を指定しています。初期値では黒色となります。
`onColorChanged` には名前の通り色を変更した時の処理を指定しています。

`controller.updateTagColor` を指定することで State の tagColor を更新しています。

`pickerAreaHeightPercent` では色を選択するエリアの高さの割合を指定しています。
この場合では横の幅に対して高さが 0.8 になるように設定しています。

```dart
ColorPicker(
  pickerColor: data.tagColor,
  onColorChanged: controller.updateTagColor,
  pickerAreaHeightPercent: 0.8,
),
```

以下では「作成」ボタンが押された時の処理を実装しています。
`controller.save()` を実行することで、現在の State に保存されているタグの名前と色を Firestore に保存することができます。
また、エラーがあった場合はダイアログで表示させています。
```dart
onPressed: () async {
  await controller.save().then((value) {
    context.pop(context)
  }).catchError((e) {
    context
      ..pop()
      ..errorDialog(e);
    });
},
```

## まとめ
最後まで読んでいただいてありがとうございました。

今回は flutter_colorpicker パッケージを用いて、色を選択する実装を行いました。
ColorPicker自体のコードは数行で実装することができ、非常に手軽に実装することができました。

今回はプロジェクトで行った実装を一部抜粋した形で記事にしているので、動かない部分もあるかと思いますが、少しでも実装の参考になればと思います。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/flutter_colorpicker
