## 初めに
今回は `PopScope` を使って戻るボタンをカスタムしてみたいと思います。
`PopScope` は戻るボタンを押して、編集した内容を破棄しても良いかどうかを確認する時などに使用できます。

## 記事の対象者
+ Flutter 学習者
+ `PopScope` の使い方が知りたい方

## 目的
今回は先述の通り、`PopScope` の使い方を確認していきます。
簡単な例を用いてどのような場面で使用できるかを見ていきたいと思います。

## 実装
以下では、編集画面などで内容を保存せずに破棄する際に `PopScope` を使用する場合を考えます。
コードは以下の通りです。


初めのページ
```dart: first_screen.dart
import 'package:flutter/material.dart';
import 'package:sample_flutter/pop_scope/pop_scope_second_screen.dart';

class PopScopeFirstScreen extends StatelessWidget {
  const PopScopeFirstScreen({super.key});

  static const name = 'Flutter';
  static const email = 'flutter@gmail.com';
  static const password = 'flutter1234';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Screen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ユーザー情報',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            _buildInfoSection(context, '名前', name),
            _buildInfoSection(context, 'メールアドレス', email),
            _buildInfoSection(context, 'パスワード', password),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.center,
              child: ElevatedButton(
                onPressed: () => _navigateToEditScreen(context),
                child: const Text('編集画面へ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PopScopeSecondScreen(
          name: name,
          email: email,
          password: password,
        ),
      ),
    );
  }
}
```
長いコードですが、基本的にはユーザーの名前、メールアドレス、パスワードを表示させているだけのページになります。
「編集画面へ」のボタンを押すと次のページに値を渡すような実装になっています。

編集画面
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PopScopeSecondScreen extends HookWidget {
  const PopScopeSecondScreen({
    super.key,
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController(text: name);
    final emailController = useTextEditingController(text: email);
    final passwordController = useTextEditingController(text: password);

    bool isEdited() {
      return nameController.text != name ||
          emailController.text != email ||
          passwordController.text != password;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!isEdited()) {
          Navigator.pop(context);
        } else {
          final bool? shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('変更を破棄しますか？'),
              content: const Text('未保存の変更があります。本当に戻りますか？'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('キャンセル'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('破棄して戻る'),
                ),
              ],
            ),
          );
          if (shouldPop ?? false) {
            if (!context.mounted) return;
            Navigator.pop(context);
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Second Screen'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ユーザー情報',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              _buildInfoSection(
                context: context,
                label: '名前',
                value: name,
                controller: nameController,
              ),
              _buildInfoSection(
                context: context,
                label: 'メールアドレス',
                value: email,
                controller: emailController,
              ),
              _buildInfoSection(
                context: context,
                label: 'パスワード',
                value: password,
                controller: passwordController,
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                  onPressed: () {
                    debugPrint('Saved');
                    // ここで保存処理を行う
                  },
                  child: const Text('保存'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required BuildContext context,
    required String label,
    required String value,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
```

編集画面に関して詳しく見ていきます。

以下では前の画面から受け取った名前、メールアドレス、パスワードを初期値とする `TextEditingController` を定義しています。
また、データが変更されているかどうかを `isEdited` で保持しています。
```dart
final nameController = useTextEditingController(text: name);
final emailController = useTextEditingController(text: email);
final passwordController = useTextEditingController(text: password);

bool isEdited() {
  return nameController.text != name ||
      emailController.text != email ||
      passwordController.text != password;
}
```

以下では `PopScope` の実装を行なっています。
`canPop` が `false` になっている場合は、現在表示されている画面を pop できないようになります。デフォルトは `true` に設定されています。

`onPopInvokedWithResult` は pop が処理された後に呼び出されるメソッドです。
以下で詳しく見ていきます。

```dart
return PopScope(
  canPop: false,
  onPopInvokedWithResult: (didPop, result) async {
    if (didPop) return;
    if (!isEdited()) {
      Navigator.pop(context);
    } else {
        // 編集内容を破棄して良いかどうかダイアログを表示
    }
  },
```

`onPopInvokedWithResult` に関して詳しく見ていきます。
ソースコードには以下のように書かれています。
> Called after a route pop was handled.
>
> It's not possible to prevent the pop from happening at the time that this method is called; the pop has already happened. Use [canPop] to disable pops in advance.
>
> This will still be called even when the pop is canceled. A pop is canceled when the relevant [Route.popDisposition] returns false, such as when [canPop] is set to false on a [PopScope]. The didPop parameter indicates whether or not the back navigation actually happened successfully.
>
> (日本語訳)
> ルートのポップ（画面遷移の戻り）が処理された後に呼び出されます。
このメソッドが呼び出された時点でポップを防ぐことはできません。ポップはすでに発生しています。事前にポップを無効にするには[canPop]を使用してください。
ポップがキャンセルされた場合でも、このメソッドは依然として呼び出されます。ポップは、関連する[Route.popDisposition]がfalseを返す場合（例えば、[PopScope]の[canPop]がfalseに設定されている場合など）にキャンセルされます。didPopパラメータは、戻る操作が実際に成功したかどうかを示します。
resultはポップの結果を含んでいます。

ここから以下のようなことが言えます。
- pop が処理された後に呼び出される
- pop がキャンセルされた場合でも呼び出される
- `didPop` は戻る操作が実際に成功したかどうかを示す
- `result` は pop の結果を含む

それを踏まえて以下のコードを見ていきます。
今回のコードでは `canPop` が false であるため、本来は呼ばれることはありませんが、`didPop` が true の場合は return するようにしています。

`isEdited` が false の場合（変更内容がない場合）は pop を行います。
true の場合は編集内容を破棄するかどうかをダイアログで表示しています。
```dart
onPopInvokedWithResult: (didPop, result) async {
  if (didPop) return;
  if (!isEdited()) {
    Navigator.pop(context);
  } else {
    final bool? shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('変更を破棄しますか？'),
        content: const Text('未保存の変更があります。本当に戻りますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('破棄して戻る'),
          ),
        ],
      ),
    );
    if (shouldPop ?? false) {
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
},
```

これで実行すると以下のような挙動になるかと思います。
編集した内容があれば前のページに戻る前にダイアログを表示させることができています。

https://youtube.com/shorts/aw9i1gybh6Q

## Flutter 3.24 の破壊的変更
[Generic types in PopScope](https://docs.flutter.dev/release/breaking-changes/popscope-with-result) のページで `PopScope` の破壊的変更が表記されていました。
具体的には、`onPopInvoked` メソッドが deprecated になり、今回使用した `onPopInvokedWithResult` が代わりに使用されるようになります。

背景としては、「以前までの PopScope は `onPopInvoked` が呼ばれた際にその pop の結果にアクセスする方法がなかった。 `onPopInvokedWithResult` ではその結果にアクセスできるようになった」という記述がありました。

使用頻度はそこまで低くない Widget だと思うので、すでに使用している場合は複数箇所でリプレイスする必要があるかと思います。

https://docs.flutter.dev/release/breaking-changes/popscope-with-result#migration-guide

以上です。

## まとめ
最後まで読んでいただいてありがとうございました。

今回は `PopScope` の活用方法を簡単にまとめました。
誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://api.flutter.dev/flutter/widgets/PopScope-class.html

https://docs.flutter.dev/release/breaking-changes/popscope-with-result

https://api.flutter.dev/flutter/widgets/ModalRoute/onPopInvokedWithResult.html