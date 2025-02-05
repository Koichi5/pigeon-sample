# 初めに
今まで使ってきた Riverpod の `StateProvider` や `StateNotifierProvider` に関して、Riverpod Generator ではサポートされておらず、`Notifier` に置き換わっていくことが予想されます。今回はその書き換えの方法を共有したいと思います。
なお、Riverpod Generator を触り始めて日が浅い為、もっと良い書き方があったり、修正すべき点があれば指摘していただけると幸いです。

また、Riverpod Generator の書き方については以下の記事でまとめたので、よろしければ合わせてご覧ください。
https://zenn.dev/koichi_51/articles/8c73f001573d47

# 記事の対象者
+ Flutter 学習者
+ Riverpod を使っている方
+ Riverpod Generator について知りたい方

# 実装
## 導入
以下のパッケージの最新バージョンを `pubspec.yaml`に記述
+ [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
+ [hooks_riverpod](https://pub.dev/packages/hooks_riverpod)
+ [riverpod_annotation](https://pub.dev/packages/riverpod_annotation)
+ [build_runner](https://pub.dev/packages/build_runner)
+ [riverpod_generator](https://pub.dev/packages/riverpod_generator)

```yaml: pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.5
  hooks_riverpod: ^2.4.5
  riverpod_annotation: ^2.3.0

dev_dependencies:
  build_runner: ^2.4.6
  riverpod_generator: ^2.3.5
```

または

以下をターミナルで実行
```
flutter pub add flutter_riverpod hooks_riverpod riverpod_annotation
flutter pub add -d build_runner riverpod_generator
```

## StateProvider
### Riverpod の場合
#### 定義
```dart: category_controller.dart
final categoryQuestionCountProvider = StateProvider((ref) => 0);
```

`StateProvider` では `ref` を引数として受け取り、初期値を 0 としています。

#### 呼び出し
```dart: category_list_screen.dart
// 値の参照
final count = ref.watch(categoryQuestionCountProvider);

// 値の更新
ref.watch(categoryQuestionCountProvider.notifier).state++;
```

値の更新の際は `notifier` の `state` で値を参照し、一つ繰上げるなど簡単な処理は上のように行うことができます。

### Riverpod Generator の場合
#### 定義
```dart: category_contoller.dart
@riverpod
class CategoryQuestionCount extends _$CategoryQuestionCount {
  @override
  int build() {
    return 0;
  }

  void increment() => state++;
}
```

Riverpod Generator では、`build` メソッドで管理する値の型（今回だと int 型）と初期値を定義します。また、`state` を変更する場合は関数を用意して、その中に処理を記述します。

#### 呼び出し
```dart: category_list_screen.dart
// 値の参照
final count = ref.watch(categoryQuestionCountProvider);

// 値の更新
ref.watch(categoryQuestionCountProvider.notifier).increment();
```

呼び出す際は値の参照は Riverpod の場合と同様ですが、値の更新は定義した関数を呼び出すことで行います。

なお、定義の記述をした後に各々のインポート文の下に `part '{ファイル名}.g.dart'` を追加して `flutter pub run build_runner watch --delete-conflicting-outputs` を実行することで定義したProviderが自動生成されます。

## StateNotifierProvider
### Riverpod の場合
#### 定義
```dart: category_controller.dart
final categoryControllerProvider =
    StateNotifierProvider<CategoryController, AsyncValue<List<Category>>>(
        (ref) {
  final user = ref.watch(authControllerProvider);
  return CategoryController(ref, user?.uid);
});

class CategoryController extends StateNotifier<AsyncValue<List<Category>>> {
  final Ref ref;
  final String? _userId;
  late final CategoryRepository _categoryRepository;

  CategoryController(this.ref, this._userId)
      : super(const AsyncValue.loading()) {
    _categoryRepository = ref.watch(categoryRepositoryProvider);
    if (_userId != null) {
      retrieveCategoryList();
    }
  }

  Future<void> retrieveCategoryList() async {
  // retrieveCategoryList
  }

  Future<Category> retrieveCategoryById(
      {required String quizCategoryDocRef}) async {
      // retrieveCategoryById
  }

  Future<Category> addCategory(
      {String? id,
      required int categoryId,
      required String name,
      required String description,
      required DateTime createdAt,
      String? imagePath}) async {
      // addCategory
  }

  Future<void> editCategoryQuestionCount(
      {required int categoryQuestionCount,
      required String categoryDocRef}) async {
      // editCategoryQuestionCount
  }
}
```

上記のコードでは `AsyncValue<List<Category>>` を返す `StateNotifier` である `CategoryController` を定義しています。
AsyncValue として返り値を定義することで受け取った画面側で、ローディングやエラーの状態のハンドリングが可能になります。

そしてその `CategoryController` を受け取った `StateNotifierProvider` を`categoryControllerProvider` として定義しています。

#### 呼び出し
```dart: category_list_screen.dart
final categoryListState = ref.watch(categoryControllerProvider);

return SingleChildScrollView(
  child: categoryListState.when(
    data: (categories) => _buildDataState(categories, context),
    error: (error, _) => _buildErrorState(context),
    loading: () => _buildLoadingState(),
  ),
);
```

`categoryListState` として AsyncValue を受けとり、状態に応じて表示させるビューを変更しています。

### Riverpod Generator の場合
#### 定義
```dart: category_contoller.dart
@Riverpod(keepAlive: true, dependencies: [AuthRepository, CategoryRepository])
class CategoryController extends _$CategoryController {
  late final CategoryRepository _categoryRepositoryNotifier;
  @override
  Future<List<Category>> build() {
    _categoryRepositoryNotifier =
        ref.watch(categoryRepositoryProvider.notifier);
    return retrieveCategoryList();
  }

  Future<List<Category>> retrieveCategoryList() async {
  // retrieveCategoryList
  }

  Future<Category> retrieveCategoryById(
  // retrieveCategoryById
  }

  Future<Category> addCategory(
      {String? id,
      required int categoryId,
      required String name,
      required String description,
      required DateTime createdAt,
      String? imagePath}) async {
      // addCategory
  }

  Future<void> editCategoryQuestionCount(
      {required int categoryQuestionCount,
      required String categoryDocRef}) async {
      // editCategoryQuestionCount
  }
}
```

以下の部分では、
```dart
@Riverpod(keepAlive: true, dependencies: [AuthRepository, CategoryRepository])
```
`keepAlive: true` とすることで AutoDispose されないようになります。
`dependencies` では依存関係のあるその他の Provider を指定することで、`CategoryController` の中でも他の Provider を使用することができるようになります。

```dart
@Riverpod(keepAlive: true, dependencies: [{依存するProvider}])
class {Notifier名} extends _${Notifier名} {
  @override
  返り値の型 build() {
    初期に実行する処理
  }

  // その他の関数
```

以上のようにすることで Notifier を定義できます。


#### 呼び出し
```dart: category_list_screen.dart
final categoryListState = ref.watch(categoryControllerProvider);

return SingleChildScrollView(
  child: categoryListState.when(
    data: (categories) => _buildDataState(categories, context),
    error: (error, _) => _buildErrorState(context),
    loading: () => _buildLoadingState(),
  ),
);
```

呼び出しは通常の Riverpod と同様に呼び出すことができます。

## まとめ
最後まで読んでいただいてありがとうございました。
今回は StateProvider や StateNotifierProvider について書き換えを行いましたが、まだまだ Riverpod Generator について深掘れていない部分が多いので、その都度共有していきたいと思います。

### 参考
https://pub.dev/packages/riverpod_generator