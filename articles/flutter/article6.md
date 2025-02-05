## 初めに
Flutter 開発を進めている中で、以下のような画面で「Widget を Wrap したいのに、Wrap するのに適切な Widget がない...」といった場面に遭遇したことはないでしょうか？
![](https://storage.googleapis.com/zenn-user-upload/047ac68d7684-20240907.png)

以下のポストで、[Flutter Plus](https://marketplace.visualstudio.com/items?itemName=plugfox.flutter-plus) が紹介されており、冒頭の課題を解決できそうだったので、 VSCode に導入して使ってみました。今回はその使い方などを簡単に共有できればと思います。
https://x.com/michael_lazebny/status/1830536261796266431

## 記事の対象者
+ VSCode で Flutter の開発を行なっている方
+ Flutter での開発効率をちょっと上げたい方

:::message
今回は VSCode の Flutter 向け拡張機能を使用します。現状では当該拡張機能の別エディタのバージョンが見つからなかったため、 VSCode 以外のエディタで開発を行なっている方はご注意ください。
:::

## 目的
先述の通り、VSCode では Widget にカーソルを当てて `command + .` を押すと「Wrap with ...」が表示されます。
この表示をカスタマイズすることでより効率的に開発ができるようになることを目的とします。

## 準備
まずは VSCode の拡張機能を開いて、「Flutter Plus」を検索して追加します。
以下のような画面で追加できます。
![](https://storage.googleapis.com/zenn-user-upload/2793f5797808-20240908.png)

必要であれば VSCode を再起動して準備は完了です。

## settings.json の編集
すでに `settings.json` がある場合はそれを編集していきます。

ない場合は以下の手順で `settings.json` の追加をしておきます。
1. VSCode で Flutter のプロジェクトを開く
2. ルートディレクトリに `.vscode` ディレクトリを作成
3. `.vscode` ディレクトリに `settings.json` ファイルを追加

ファイルが追加できたら以下のように変更していきます。

```json settings.json
{
  "flutter-plus.wraps": [
    {
        "name": "Scaffold",
        "body": [
            "Scaffold(",
            "  body: ${widget},",
            ")"
        ]
    }
  ]
}
```

`flutter-plus.wraps` で追加したい Wrap の種類をリストで追加していきます。
`name` では 「Wrap with」の後に来る名前を指定することができます。
`body` では実際に記述されるコードを定義します。 `${widget}` を使用することで、 `command + .` を押した Widget を指定した位置に配置することができます。


## 実際の運用
以下のコードを追加して試してみます。
```dart
class SampleScreen extends StatelessWidget {
  const SampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Text('Sample');
  }
}
```

`Text` の部分で `command + .` を押してみると以下のような画面になります。
「Wrap with Scaffold」のサジェストが追加されていることが確認できます。
![](https://storage.googleapis.com/zenn-user-upload/3f9e285fe9ba-20240909.png)

「Wrap with Scaffold」 を適用すると以下のように Scaffold が追加されているかと思います。
コマンド一つで簡単に適用できるのでかなり時間短縮になるかと思います。
```diff dart
import 'package:flutter/material.dart';

class SampleScreen extends StatelessWidget {
  const SampleScreen({super.key});

  @override
  Widget build(BuildContext context) {
+   return Scaffold(
+     body: const Text('Sample'),
+   );
  }
}
```

## コードの追加
今回は Scaffold の他に以下を追加していきます。
- ListView
- ListView.builder
- SingleChildScrollView

`settings.json` のコードは以下の通りです。
```json settings.json
{
  "flutter-plus.wraps": [
    {
      "name": "Scaffold",
      "body": [
        "Scaffold(",
        "  body: ${widget},",
        ")"
      ]
    },
    {
      "name": "ListView",
      "body": [
        "ListView(",
        "  children: [",
        "    ${widget},",
        "  ],",
        ")"
      ]
    },
    {
      "name": "ListView.builder",
      "body": [
        "ListView.builder(",
        "  itemCount: ${1:length},",
        "  itemBuilder: (context, index) {",
        "    return ${widget};",
        "  },",
        ")"
      ]
    },
    {
      "name": "SingleChildScrollView",
      "body": [
        "SingleChildScrollView(",
        "  child: ${widget},",
        ")"
      ]
    }
  ]
}
```

これで実行すると「Wrap with」に項目が追加されていることがわかります。
![](https://storage.googleapis.com/zenn-user-upload/0214c451d209-20240909.png)

「Wrap with」の項目が増えてくると、選択したい項目が探しにくくなるかと思います。
そのような場合は選択したい項目の `name` を打ち込むとすぐに選択できるようになります。
例えば、「Wrap with Scaffold」を選択したい場合は、 `command + .` を押した後に「scaffold」と入力していくと、「Wrap with Scaffold」が選択されます。
これで項目を追加してもすぐに選択できるかと思います。

以上です。

## まとめ
最後まで読んでいただいてありがとうございました。

今回は VSCode の「Wrap with」をカスタマイズする方法を共有しました。
一回で短縮できる時間は非常に短いかと思いますが、何度も使用する機能だと思うので使うことで効率的に開発ができるようになるかと思います。

### 参考

https://marketplace.visualstudio.com/items?itemName=plugfox.flutter-plus
