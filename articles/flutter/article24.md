## 初めに
今回はQRコード、バーコードの読み込みができる [mobile_scanner パッケージ](https://pub.dev/packages/mobile_scanner) を使って、QRコード、バーコードを読み込む実装を行いたいと思います。

## 記事の対象者
+ Flutter 学習者
+ QRコードを読み込む実装が必要な方
+ バーコードを読み込む実装が必要な方

## 目的
今回は先述の通り、[mobile_scanner パッケージ](https://pub.dev/packages/mobile_scanner) を使ってQRコード、バーコードを読み込む実装を行います。最終的には以下の動画のようにバーコードを読み込み、その情報から書籍のデータを取得する実装を行いたいと思います。

## 導入
[mobile_scanner パッケージ](https://pub.dev/packages/mobile_scanner) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  mobile_scanner: ^4.0.0
```

または

以下をターミナルで実行
```
flutter pub add mobile_scanner
```

:::message
今回は Riverpod generator, Freezed を使用するため、周辺パッケージが追加されていない場合は以下のように追加してください。

```yaml: pubspec.yaml
dependencies:
  flutter_riverpod: ^2.4.10
  hooks_riverpod: ^2.4.10
  riverpod_annotation: ^2.3.4

dev_dependencies:
  riverpod_generator: ^2.3.11
  build_runner: ^2.4.8
  freezed: ^2.4.7
  json_serializable: ^6.7.1
```

または

以下をターミナルで実行
```
flutter pub add flutter_riverpod hooks_riverpod riverpod_annotation
flutter pub add -d riverpod_generator build_runner freezed json_serializable
```
:::

## 実装
今回は以下の手順で実装したいと思います。
1. 準備
2. QRコードの読み取り
3. バーコードから書籍情報を取得

### 1. 準備
今回は iPhone の実機でビルドするため、`Info.plist` に以下の内容を追加します。
なお、今回はカメラのみ使用しますが、画像を読み込むためには `NSPhotoLibraryUsageDescription` も追加する必要があります。
```plist
<!-- mobile scanner -->
<key>NSCameraUsageDescription</key>
<string>QR code scanner needs camera access to scan QR codes</string>
<!-- mobile scanner -->
```

Android でビルドするためには、`android/app/build.gradle` の `minSdkVersion` を `minSdkVersion 21` とする必要があります。

### 2. QRコードの読み取り
次にQRコードを読み取る実装を行います。
この章ではQRコードを読み取り、読み取った値を画面に表示させる実装を行います。
最終的には以下のようにFlutter公式サイトのQRコードを [こちらのサイト](https://qr.quel.jp/url.php) で作成し、それを読み取れるような実装を行いたいと思います。

https://youtube.com/shorts/Uswub2v4_aw?feature=share

先にコードを提示します。
コードは以下の通りです。
```dart: mobile_scanner_qrcode_sample.dart
class MobileScannerQrcodeSample extends StatefulWidget {
  const MobileScannerQrcodeSample({super.key});

  @override
  State<MobileScannerQrcodeSample> createState() =>
      _MobileScannerQrcodeSampleState();
}

class _MobileScannerQrcodeSampleState extends State<MobileScannerQrcodeSample> {
  String barcode = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile QR Scanner'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  final value = barcodes.first.rawValue;
                  if (value != null) {
                    setState(() {
                      barcode = value;
                    });
                    log('barcode value: $value');
                  } else {
                    setState(() {
                      barcode = 'コードが読み取れません';
                    });
                  }
                },
              ),
            ),
            Text(
              barcode,
            ),
          ],
        ),
      ),
    );
  }
}
```

詳しくみていきます。

この章ではQRコードの値を読み取って表示させるだけなので、簡単な StatefulWidget で実装しています。

以下ではQRコードで読み取った値の初期値を指定しています。
この `barcode` の値を更新していくことで、QRコードを読み取る部分の下部に表示させるテキストを変更していきます。
```dart
String barcode = '';
```

以下の部分では、QRコードを読み取る部分の実装を行なっています。
QRコードを読み込むのは `MobileScanner` で実装でき、`onDetect` でQRコードを読み取った時の処理を指定できます。
今回は読み取ったQRコードのうち一つを切り出し、その `rawValue` を `setState` で `barcode` 変数に代入しています。このようにすることで読み取ったQRコードの値を取得することができます。
```dart
MobileScanner(
  onDetect: (capture) {
    final List<Barcode> barcodes = capture.barcodes;
    final value = barcodes.first.rawValue;
    if (value != null) {
      setState(() {
        barcode = value;
      });
      log('barcode value: $value');
    } else {
      setState(() {
        barcode = 'コードが読み取れません';
      });
    }
  },
),
```

以下では先ほど定義した `barcode` をテキストとして表示しています。
```dart
Text(
  barcode,
),
```

以上のコードを実行することで、章の初めで提示した以下の動画のような実装ができるかと思います。

https://youtube.com/shorts/Uswub2v4_aw?feature=share

### 3. バーコードから書籍情報を取得
次は、書籍のバーコードの読み取り、そこから書籍情報を取得して表示させるまでを実装していきます。
最終的には以下のような実装を行います。

https://youtube.com/shorts/EhfvRLQflNk?feature=share

手順は以下の通りです。
1. 書籍のデータ構造定義
2. 書籍データを管理する Provider 作成
3. バーコードの読み取った値を管理する Provider 作成
4. バーコードを読み取るUI作成
5. 書籍情報を表示させるUI作成

#### 1. 書籍のデータ構造定義
今回は [Google Books API](https://developers.google.com/books/docs/v1/reference/volumes?hl=ja) を使用します。
Google Books API はAPIキーの取得や登録不要で使用することができます。

今回は ISBN番号（国際標準図書番号）を元に検索を行います。
書籍のバーコードを読み込むことでISBN番号を取得することができ、Google Books API に以下の形式で渡すことで書籍情報を取得することができます。

```
https://www.googleapis.com/books/v1/volumes?q=isbn:{ISBN番号}
```

試しにデータを取得してみると以下のようなデータが返ってきます。
```json
{
  "kind": "books#volumes",
  "totalItems": 1,
  "items": [
    {
      "kind": "books#volume",
      "id": "1FGpzQEACAAJ",
      "etag": "EbONotTK10g",
      "selfLink": "https://www.googleapis.com/books/v1/volumes/1FGpzQEACAAJ",
      "volumeInfo": {
        "title": "オブジェクト指向UIデザイン使いやすいソフトウェアの原理",
        "subtitle": "",
        "authors": [
          "ソシオメディア",
          "上野学",
          "藤井幸多"
        ],
        "publishedDate": "2020-06",
        "description": "オブジェクト指向ユーザーインターフェース(OOUI)とは、オブジェクト(もの、名詞)を起点としてUIを設計すること。タスク(やること、動詞)を起点としたUIに比べて、画面数が減って作業効率が高まり、また開発効率や拡張性も向上する、いわば「銀の弾丸」的な効果を持つ。ブログや雑誌記事などで大きな反響を得たこの設計手法について、前半部では理論やプロセスを詳説。そして後半部の「ワークアウト(実践演習)」では18の課題に読者がチャレンジ。実際に考え、手を動かし、試行錯誤をすることにより、OOUIの設計手法を体得できる。",
        "industryIdentifiers": [
          {
            "type": "ISBN_10",
            "identifier": "4297113511"
          },
          {
            "type": "ISBN_13",
            "identifier": "9784297113513"
          }
        ],
        "readingModes": {
          "text": false,
          "image": false
        },
        "pageCount": 360,
        "printType": "BOOK",
        "maturityRating": "NOT_MATURE",
        "allowAnonLogging": false,
        "contentVersion": "preview-1.0.0",
        "panelizationSummary": {
          "containsEpubBubbles": false,
          "containsImageBubbles": false
        },
        "imageLinks": {
          "smallThumbnail": "http://books.google.com/books/content?id=1FGpzQEACAAJ&printsec=frontcover&img=1&zoom=5&source=gbs_api",
          "thumbnail": "http://books.google.com/books/content?id=1FGpzQEACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api"
        },
        "language": "ja",
        "previewLink": "http://books.google.co.jp/books?id=1FGpzQEACAAJ&dq=isbn:9784297113513&hl=&cd=1&source=gbs_api",
        "infoLink": "http://books.google.co.jp/books?id=1FGpzQEACAAJ&dq=isbn:9784297113513&hl=&source=gbs_api",
        "canonicalVolumeLink": "https://books.google.com/books/about/%E3%82%AA%E3%83%96%E3%82%B8%E3%82%A7%E3%82%AF%E3%83%88%E6%8C%87%E5%90%91UI%E3%83%87%E3%82%B6%E3%82%A4%E3%83%B3.html?hl=&id=1FGpzQEACAAJ"
      },
      "saleInfo": {
        "country": "JP",
        "saleability": "NOT_FOR_SALE",
        "isEbook": false
      },
      "accessInfo": {
        "country": "JP",
        "viewability": "NO_PAGES",
        "embeddable": false,
        "publicDomain": false,
        "textToSpeechPermission": "ALLOWED",
        "epub": {
          "isAvailable": false
        },
        "pdf": {
          "isAvailable": false
        },
        "webReaderLink": "http://play.google.com/books/reader?id=1FGpzQEACAAJ&hl=&source=gbs_api",
        "accessViewStatus": "NONE",
        "quoteSharingAllowed": false
      },
      "searchInfo": {
        "textSnippet": "オブジェクト指向ユーザーインターフェース(OOUI)とは、オブジェクト(もの、名詞)を起点としてUIを設計すること。タスク(やること、動詞)を起点としたUIに比べて、画面数が減っ ..."
      }
    }
  ]
}
```

このレスポンスのデータを [こちらのサイト](https://app.quicktype.io/) に入れて Dartのコードを生成して、以下のようなデータ構造を作成します。
なお、後述の書籍のデータを扱う Provider の実装の際にレスポンスが Null になっていたプロパティがあったため、一部を Nullable にしています。

```dart: book.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

@freezed
class Book with _$Book {
  const factory Book({
    required String kind,
    required int totalItems,
    required List<Item> items,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}

@freezed
class Item with _$Item {
  const factory Item({
    required String kind,
    required String id,
    required String etag,
    required String selfLink,
    required VolumeInfo volumeInfo,
    required SaleInfo saleInfo,
    required AccessInfo accessInfo,
    required SearchInfo searchInfo,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
}

@freezed
class AccessInfo with _$AccessInfo {
  const factory AccessInfo({
    required String country,
    required String viewability,
    required bool embeddable,
    required bool publicDomain,
    required String textToSpeechPermission,
    required Epub epub,
    required Pdf pdf,
    required String webReaderLink,
    required String accessViewStatus,
    required bool quoteSharingAllowed,
  }) = _AccessInfo;

  factory AccessInfo.fromJson(Map<String, dynamic> json) =>
      _$AccessInfoFromJson(json);
}

@freezed
class Epub with _$Epub {
  const factory Epub({
    required bool isAvailable,
  }) = _Epub;

  factory Epub.fromJson(Map<String, dynamic> json) => _$EpubFromJson(json);
}

@freezed
class Pdf with _$Pdf {
  const factory Pdf({
    required bool isAvailable,
    required String? acsTokenLink,
  }) = _Pdf;

  factory Pdf.fromJson(Map<String, dynamic> json) => _$PdfFromJson(json);
}

@freezed
class SaleInfo with _$SaleInfo {
  const factory SaleInfo({
    required String country,
    required String saleability,
    required bool isEbook,
  }) = _SaleInfo;

  factory SaleInfo.fromJson(Map<String, dynamic> json) =>
      _$SaleInfoFromJson(json);
}

@freezed
class SearchInfo with _$SearchInfo {
  const factory SearchInfo({
    required String textSnippet,
  }) = _SearchInfo;

  factory SearchInfo.fromJson(Map<String, dynamic> json) =>
      _$SearchInfoFromJson(json);
}

@freezed
class VolumeInfo with _$VolumeInfo {
  const factory VolumeInfo({
    required String title,
    required List<String> authors,
    required String? publisher,
    required DateTime publishedDate,
    required String description,
    required List<IndustryIdentifier> industryIdentifiers,
    required ReadingModes readingModes,
    required int pageCount,
    required String printType,
    required String maturityRating,
    required bool allowAnonLogging,
    required String contentVersion,
    required PanelizationSummary? panelizationSummary,
    required ImageLinks imageLinks,
    required String language,
    required String previewLink,
    required String infoLink,
    required String canonicalVolumeLink,
  }) = _VolumeInfo;

  factory VolumeInfo.fromJson(Map<String, dynamic> json) =>
      _$VolumeInfoFromJson(json);
}

@freezed
class ImageLinks with _$ImageLinks {
  const factory ImageLinks({
    required String smallThumbnail,
    required String thumbnail,
  }) = _ImageLinks;

  factory ImageLinks.fromJson(Map<String, dynamic> json) =>
      _$ImageLinksFromJson(json);
}

@freezed
class IndustryIdentifier with _$IndustryIdentifier {
  const factory IndustryIdentifier({
    required String type,
    required String identifier,
  }) = _IndustryIdentifier;

  factory IndustryIdentifier.fromJson(Map<String, dynamic> json) =>
      _$IndustryIdentifierFromJson(json);
}

@freezed
class PanelizationSummary with _$PanelizationSummary {
  const factory PanelizationSummary({
    required bool containsEpubBubbles,
    required bool containsImageBubbles,
  }) = _PanelizationSummary;

  factory PanelizationSummary.fromJson(Map<String, dynamic> json) =>
      _$PanelizationSummaryFromJson(json);
}

@freezed
class ReadingModes with _$ReadingModes {
  const factory ReadingModes({
    required bool text,
    required bool image,
  }) = _ReadingModes;

  factory ReadingModes.fromJson(Map<String, dynamic> json) =>
      _$ReadingModesFromJson(json);
}
```

これで書籍のデータ構造の定義は完了です。

#### 2. 書籍データを管理する Provider 作成
次に書籍のデータを管理する Provider を作成していきます。
コードは以下の通りです。
```dart: mobile_scanner_book_controller.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sample_flutter/qr/models/book.dart';

part 'mobile_scanner_book_controller.g.dart';

@riverpod
class MobileScannerBookController extends _$MobileScannerBookController {
  @override
  Book build() {
    return const Book(kind: '', totalItems: 0, items: []);
  }

  Future<Book> fetchBook({required String barcode}) async {
    final url = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$barcode';
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return Book.fromJson(json);
    } else {
      throw Exception('Failed to load weather data');
    }
  }
}
```

それぞれ詳しくみていきます。

以下では `build` メソッドで `Book` の初期値を返しています。
```dart
@override
Book build() {
  return const Book(kind: '', totalItems: 0, items: []);
}
```

以下では Google Books API から書籍情報を取得する実装を行なっています。
取得には `http.get` メソッドを使い、先ほどのURLにバーコードで読み取った値を代入します。

そして、取得できた場合は `Book.fromJson` で `Book`型に変更して返すようにします。
```dart
Future<Book> fetchBook({required String barcode}) async {
  final url = 'https://www.googleapis.com/books/v1/volumes?q=isbn:$barcode';
  final uri = Uri.parse(url);
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return Book.fromJson(json);
  } else {
    throw Exception('Failed to load weather data');
  }
}
```

#### 3. バーコードの読み取った値を管理する Provider 作成
次にバーコードを読み取った値を管理する Provider を作成します。
コードは以下の通りです。
```dart: mobile_scanner_barcode_controller.dart
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'mobile_scanner_barcode_controller.g.dart';

@riverpod
class MobileScannerBarcodeController extends _$MobileScannerBarcodeController {
  @override
  String? build() {
    return '';
  }

  String setCode({required List<Barcode> barcodes}) {
    for (final barcode in barcodes) {
      state = barcode.rawValue;
    }
    return state ?? '';
  }
}
```

それぞれ詳しくみていきます。

以下の部分では `build` メソッドを実装し、バーコードの値の初期値を設定しています。
```dart
@override
String? build() {
  return '';
}
```

以下の部分では読み取ったバーコードのリストを `barcodes` として受け取り、読み取ったバーコードの値を `state` に代入しています。
```dart
String setCode({required List<Barcode> barcodes}) {
  for (final barcode in barcodes) {
    state = barcode.rawValue;
  }
  return state ?? '';
}
```

#### 4. バーコードを読み取るUI作成
次はバーコードを読み取るUIを作成します。
コードは以下の通りです。
```dart: mobile_scanner_barcode_sample.dart
class MobileScannerBarcodeSample extends ConsumerWidget {
  const MobileScannerBarcodeSample({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mobile Barcode Scanner'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 200,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                ref
                    .watch(mobileScannerBarcodeControllerProvider.notifier)
                    .setCode(
                      barcodes: barcodes,
                    );
              },
            ),
          ),
          Text(
            ref.watch(mobileScannerBarcodeControllerProvider) ?? 'コードが読み取れません。',
          ),
          ElevatedButton(
            onPressed: () async {
              if (ref.read(mobileScannerBarcodeControllerProvider) == null) {
                showDialog(
                    context: context,
                    builder: (context) {
                      return const SimpleDialog(
                        title: Text('コードが読み取れませんでした。'),
                      );
                    });
              } else {
                await ref
                    .watch(mobileScannerBookControllerProvider.notifier)
                    .fetchBook(
                        barcode:
                            ref.read(mobileScannerBarcodeControllerProvider)!)
                    .then(
                  (value) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MobileScannerSampleDetail(
                          book: value,
                        ),
                      ),
                    );
                  },
                );
              }
            },
            child: const Text(
              '読み取り完了',
            ),
          ),
        ],
      ),
    );
  }
}
```

それぞれ詳しくみていきます。

QRコードと同様で `MobileScanner` の `onDetect` でバーコードを読み取った時の処理を記述しています。 `capture.barcodes` で読み取ったバーコードを `mobileScannerBarcodeControllerProvider` に渡しています。そして、`setCode` でバーコードの値を更新しています。
```dart
MobileScanner(
  onDetect: (capture) {
    final List<Barcode> barcodes = capture.barcodes;
    ref.watch(mobileScannerBarcodeControllerProvider.notifier).setCode(
      barcodes: barcodes,
    );
  },
),
```

以下では先ほどの `onDetect` で更新した `mobileScannerBarcodeControllerProvider` の値を読み取って、テキストとして表示させています。
```dart
Text(
  ref.watch(mobileScannerBarcodeControllerProvider) ?? 'コードが読み取れません。',
),
```

以下では、「読み取り完了」ボタンを押した際の処理を記述しています。
`mobileScannerBarcodeControllerProvider` の値が null の時は「コードが読み取れませんでした」としてダイアログを表示させ、null でない時は、バーコードの値を `mobileScannerBookControllerProvider` の `fetchBook` の引数に渡しています。
そして書籍の情報が取得できた後にその情報を `MobileScannerSampleDetail` に渡します。
```dart
onPressed: () async {
  if (ref.read(mobileScannerBarcodeControllerProvider) == null) {
    showDialog(
      context: context,
      builder: (context) {
        return const SimpleDialog(
          title: Text('コードが読み取れませんでした。'),
        );
    });
  } else {
    await ref.watch(mobileScannerBookControllerProvider.notifier)
      .fetchBook(
        barcode:
          ref.read(mobileScannerBarcodeControllerProvider)!)
            .then((value) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MobileScannerSampleDetail(
                    book: value,
                ),
              ),
            );
          },
        );
    }
},
```

#### 5. 書籍情報を表示させるUI作成
最後に先ほど実装した `MobileScannerBarcodeSample` で取得した書籍の情報を受け取り表示するUIを作成します。
コードは以下の通りです。
```dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:sample_flutter/qr/models/book.dart';

class MobileScannerSampleDetail extends StatelessWidget {
  const MobileScannerSampleDetail({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本の詳細'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              book.items.first.volumeInfo.imageLinks.thumbnail,
              width: 200,
              height: 300,
            ),
            const Gap(20),
            const Text('タイトル'),
            Text(book.items.first.volumeInfo.title),
            const Gap(20),
            const Text('著者'),
            Column(
              children: book.items.first.volumeInfo.authors.map((auther) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(auther),
                );
              }).toList(),
            ),
            const Gap(20),
            Text('出版社：${book.items.first.volumeInfo.publisher ?? '情報がありません'}'),
            const Gap(20),
            Text('詳細：${book.items.first.volumeInfo.description}'),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}
```

Google Books API では書籍の情報は `book.items.first.volumeInfo` に多く含まれているため、そこからタイトルや著者、詳細情報などを表示しています。

動画にもありますが、以下のような見た目になります。

![](https://storage.googleapis.com/zenn-user-upload/dc81793e5fbc-20240222.png =300x)

## まとめ
最後まで読んでいただいてありがとうございました。

今回は mobile_scanner を用いてQRコード、バーコードを読み取り、それを元に書籍データを取得する実装を行いました。
MobileScanner の onDetected で簡単に実装できたので、非常に便利なパッケージだと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/mobile_scanner

quicktype (JSONからDartのデータモデルに変換)
https://app.quicktype.io/

Google Books API
https://developers.google.com/books/docs/v1/reference/volumes?hl=ja

https://qiita.com/DEmodoriGatsuO/items/29f7b3e145b1215e5bb8

