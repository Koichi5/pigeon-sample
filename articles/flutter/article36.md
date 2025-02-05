## 初めに
今回は個人開発で、テキストのサイズを行数に合わせて柔軟に変更する必要があり、auto_size_textパッケージを使用することになったので、使い方等をまとめていきたいと思います。

## 記事の対象者
+ Flutter 学習者
+ テキストサイズをカスタマイズしたい方

## 目的
### 改善前
問題文の長さによって選択肢が表示される高さが異なり、ユーザーが押し間違える可能性が高い
| 問題文２行 | 問題文４行 |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/3491e5c57976-20231210.png =250x) | ![](https://storage.googleapis.com/zenn-user-upload/a4a6b9f40eb0-20231210.png =250x) |

### 改善後
問題文の長さに限らず選択肢が同じ位置に表示されるように変更する
| 問題文２行 | 問題文４行 |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/aaf9e5653732-20231210.png =250x) | ![](https://storage.googleapis.com/zenn-user-upload/17721bc12fb4-20231210.png =250x) |

## 実装
### 導入
[auto_size_text](https://pub.dev/packages/auto_size_text) パッケージの最新バージョンを `pubspec.yaml`に記述
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  auto_size_text: ^3.0.0
```

または

以下をターミナルで実行
```
flutter pub add auto_size_text
```

### 改善前のコード
```dart
  Widget quizQuestion() {
    return Container(
      alignment: Alignment.centerLeft,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  "${ref.watch(currentQuestionIndexProvider)} / ${questionList.length}",
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Text(
                    question?.text ?? "",
                    style: const TextStyle(
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

改善前では、`Padding` の `child` に `Text` として問題文を表示させています。
また、文字のサイズは固定で 18 にしています。

実行結果は以下のようになります。
| 問題文２行 | 問題文４行 |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/3491e5c57976-20231210.png =250x) | ![](https://storage.googleapis.com/zenn-user-upload/a4a6b9f40eb0-20231210.png =250x) |

### 改善後のコード
```dart
  Widget quizQuestion() {
    return Container(
      alignment: Alignment.centerLeft,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Text(
                  "${ref.watch(currentQuestionIndexProvider)} / ${questionList.length}",
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.2,
                    child: AutoSizeText(
                      question?.text ?? "",
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                      maxLines: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
```

改善後ではテキストの高さを固定するために、 `SizedBox` の `child` に指定しています。
また、`AutoSizeText` を使い、行数が３行より多くなるとテキストのフォントの大きさが小さくなるようにしています。
３行以内であればフォントサイズは 18 に固定しています。

このようにすることで、問題文を表示させるためのビューの高さを画面の高さの２割に固定することができます。

実行結果は以下のようになります。
| 問題文２行 | 問題文４行 |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/aaf9e5653732-20231210.png =250x) | ![](https://storage.googleapis.com/zenn-user-upload/17721bc12fb4-20231210.png =250x) |

### その他の設定
今回は `maxLines` のみで指定しましたが、他にもカスタマイズが可能なので、簡単に共有します。

#### minFontSize
「親要素の高さや幅によってテキストのフォントサイズは変更したいものの、ユーザーが読みにくくなるほど小さくなって欲しくない」と言った時に使用します。

例えば以下のようなコードを見てみましょう。
```dart
SizedBox(
  height: MediaQuery.of(context).size.height * 0.2,
  child: AutoSizeText(
    question?.text ?? "",
    style: const TextStyle(
      fontSize: 30,
     ),
     minFontSize: 18,
     maxLines: 3,
  ),
),
```
このコードではデフォルトのフォントサイズは 30 に指定していますが、18 より小さくならないようにしています。実行結果は以下のようになります。

| 短い問題文 | 長い問題文 |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/036a3f9098c1-20231210.png =250x) | ![](https://storage.googleapis.com/zenn-user-upload/7128961cf78f-20231210.png =250x) |

長い問題文の場合、短い問題文の時と比較して確かにフォントサイズは小さくなっています。しかし、`minFontSize: 18,` としているため、ユーザーが読める範囲の大きさが保証されていることがわかります。
この例はフォントサイズ 30 と 18 の比較で少し極端かと思いますが、ユーザーの読みやすさを担保することは非常に重要なので、使用する場面は多いかと思います。

#### overflowReplacement
もしテキストの領域が大きくなりすぎた場合に別に表示させるビューを指定することもできます。
以下のコードを見てみましょう。
```dart
SizedBox(
  height: MediaQuery.of(context).size.height * 0.2,
  child: AutoSizeText(
    question?.text ?? "",
    style: const TextStyle(
      fontSize: 18,
    ),
    minFontSize: 16,
    maxLines: 2,
    overflowReplacement: const Text('問題文が長くて表示できませんでした')
  ),
),
```
上のコードではテキストを表示させていますが、`overflowReplacement` は `Widget` 型なので様々なUIを表示させることができます。
実行すると以下のようになります。
![](https://storage.googleapis.com/zenn-user-upload/1ca44172b220-20231210.png =250x)

この場合だと問題文が表示されていないため、機能として致命的であるため、別の処置が必要かと思いますが、問題が発生していることは伝えられるかと思います。


## まとめ
最後まで読んでいただいてありがとうございました。
今回は簡単に[auto_size_text](https://pub.dev/packages/auto_size_text) パッケージの活用法を紹介しました。他にもカスタマイズする方法があるので、パッケージのページから詳しくみていただければと思います。
誤っている点等あればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/auto_size_text