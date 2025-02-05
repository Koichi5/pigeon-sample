## 初めに
今回は以下で公開されていた郵便番号から住所を取得するAPIを用いて、郵便番号から住所を自動的に補完入力するような実装を行いたいと思います。
ちょうど Flutter Web のプロジェクトの方で郵便番号や住所を登録するような実装をする必要があったため、使わせていただきました。

https://zenn.dev/ttskch/articles/309423d26a1aaa

## 記事の対象者
+ Flutter 学習者
+ Flutter で住所入力を実装したい方

## 目的
今回の目的は、先述の通り郵便番号から住所を自動的に入力するような実装を行うことです。このような実装ができればユーザーは住所の入力をある程度スキップでき、スムーズに登録が行えるようになります。
最終的には以下の動画のような実装を行いたいと思います。

https://youtu.be/tpPHr941cA0

## 準備
以下のパッケージの最新バージョンを `pubspec.yaml`に記述

dependencies
+ [gap](https://pub.dev/packages/gap)
+ [http](https://pub.dev/packages/http)
+ [hooks_riverpod](https://pub.dev/packages/hooks_riverpod)
+ [flutter_hooks](https://pub.dev/packages/flutter_hooks)
+ [riverpod_annotation](https://pub.dev/packages/riverpod_annotation)
+ [freezed_annotation](https://pub.dev/packages/freezed_annotation)

dev_dependencies
+ [freezed](https://pub.dev/packages/freezed)
+ [build_runner](https://pub.dev/packages/build_runner)
+ [json_serializable](https://pub.dev/packages/json_serializable)
+ [riverpod_generator](https://pub.dev/packages/riverpod_generator)

または

以下をターミナルで実行
```
flutter pub add gap http hooks_riverpod flutter_hooks riverpod_annotation freezed_annotation
flutter pub add -d freezed build_runner json_serializable riverpod_generator
```

## 実装
実装は以下の手順で進めたいと思います。
1. データクラスの作成
2. APIのやり取りを行う Repository の作成
3. UI作成
4. 改善できる部分

### 1. データクラスの作成
まずはAPIの仕様を確認して、どのようなデータクラスが必要かを確認していきます。
今回使用させていただく郵便番号から住所を取得するためのAPIのドキュメントは以下のReadmeで確認できます。

https://github.com/ttskch/jp-postal-code-api

ドキュメントにもある通り、郵便番号を渡して、結果として返ってくるのは以下のようなJSONです。
```json
{
    "postalCode": "1000014",
    "addresses": [
        {
            "prefectureCode": "13",
            "ja": {
                "prefecture": "東京都",
                "address1": "千代田区",
                "address2": "永田町",
                "address3": "",
                "address4": ""
            },
            "kana": {
                "prefecture": "トウキョウト",
                "address1": "チヨダク",
                "address2": "ナガタチョウ",
                "address3": "",
                "address4": ""
            },
            "en": {
                "prefecture": "Tokyo",
                "address1": "Chiyoda-ku",
                "address2": "Nagatacho ",
                "address3": "",
                "address4": ""
            }
        }
    ]
}
```

上記のJSONをもとにデータクラスを作っていきます。
または、JSONを以下のサイトに入力して、Dartで使用できるデータクラスを作成することも可能です。

https://app.quicktype.io/

作成したデータクラスのコードは以下の通りです。

```dart: postal_code_api_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample_flutter/postal_code_api/model/address.dart';

part 'postal_code_api_response.freezed.dart';
part 'postal_code_api_response.g.dart';

@freezed
abstract class PostalCodeApiResponse with _$PostalCodeApiResponse {
    const factory PostalCodeApiResponse({
      required String postalCode,
      required List<Address>? addresses,
    }) = _PostalCodeApiResponse;

    const PostalCodeApiResponse._();

    factory PostalCodeApiResponse.fromJson(Map<String, dynamic> json) => _$PostalCodeApiResponseFromJson(json);
}
```

```dart: address.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:sample_flutter/postal_code_api/model/en.dart';

part 'address.freezed.dart';
part 'address.g.dart';

@freezed
abstract class Address with _$Address {
  const factory Address({
    required String? prefectureCode,
    required En? ja,
    required En? kana,
    required En? en,
  }) = _Address;

  const Address._();

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
}
```

```dart: en.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'en.freezed.dart';
part 'en.g.dart';

@freezed
abstract class En with _$En {
  const factory En({
    required String prefecture,
    required String address1,
    required String address2,
    required String address3,
    required String address4,
  }) = _En;

  const En._();

  factory En.fromJson(Map<String, dynamic> json) => _$EnFromJson(json);
}
```

`PostalCodeApiResponse` が `Address` をもち、さらに `Address` が `En` を持つといった入れ子構造になっており、それぞれのデータクラスが `fromJson` メソッドで JSON 形式から変換できるようにしています。

これでデータクラスの作成は完了です。

この辺りのデータクラスの作成は先ほど紹介した以下のサイトと、以前の記事で紹介した freezed の VSCode スニペットを活用することでかなり楽に作成できるようになります。

https://app.quicktype.io/

https://zenn.dev/koichi_51/articles/bc1d9461d34493


### 2. APIのやり取りを行う Repository の作成
次にAPIのやり取りを行うRepositoryの実装を行います。
入力はInt型の郵便番号であり、出力は先ほど定義した `PostalCodeApiResponse` となります。
コードは以下の通りです。
```dart
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sample_flutter/postal_code_api/model/postal_code_api_response.dart';
import 'package:http/http.dart' as http;

part 'postal_code_repository.g.dart';

@riverpod
Future<PostalCodeApiResponse> fetchPostalCodeApiResponse(
    FetchPostalCodeApiResponseRef ref, int postalCode) async {
  final url = 'https://jp-postal-code-api.ttskch.com/api/v1/$postalCode.json';
  final response = await http.get(Uri.parse(url));
  final postalCodeApiResponseMap = json.decode(response.body);
  final postalCodeApiResponse =
      PostalCodeApiResponse.fromJson(postalCodeApiResponseMap);
  return postalCodeApiResponse;
}
```

今回は特に内部でデータを変更する必要がないため、 NotifierProvider ではなく、通常の Provider 型で定義しています。内部でやっていることは通常のAPIの実装であり、引数として受け取った Int型の郵便番号をURLに乗せて `get` メソッドを実行しています。
そして、返ってきたデータの `body` をデコードして、 `PostalCodeApiResponse` に変換しています。

これで任意の郵便番号を受け取り、その住所を取得するための実装が完了しました。

### 3. UI作成
最後にUI部分の作成です。
コードは以下の通りです。`PostalCodeApiDetail`に関しては前の画面から値を受け取って表示しているだけであるため、解説は省きます。
```dart: postal_code_api_home.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:sample_flutter/postal_code_api/view/postal_code_api_detail.dart';
import 'package:sample_flutter/postal_code_api/view_model/postal_code_repository.dart';

class PostalCodeApiHome extends HookConsumerWidget {
  const PostalCodeApiHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postalCodeController = useTextEditingController();
    final prefectureController = useTextEditingController();
    final address1Controller = useTextEditingController();
    final address2Controller = useTextEditingController();
    final address3Controller = useTextEditingController();
    final address4Controller = useTextEditingController();
    const postalCodeLength = 7;

    void fetchAddress() async {
      final postalCode = int.parse(postalCodeController.text);
      final postalCodeApiResponse =
          await ref.read(fetchPostalCodeApiResponseProvider(postalCode).future);
      prefectureController.text =
          postalCodeApiResponse.addresses?.first.ja?.prefecture ?? '';
      address1Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address1 ?? '';
      address2Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address2 ?? '';
      address3Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address3 ?? '';
      address4Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address4 ?? '';
    }

    bool isValid() {
      return postalCodeController.text != '' &&
          prefectureController.text != '' &&
          address1Controller.text != '' &&
          address2Controller.text != '' &&
          address3Controller.text != '' &&
          address4Controller.text != '';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('PostalCodeApiHome'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('郵便番号'),
          const Gap(8),
          TextField(
            controller: postalCodeController,
            onChanged: (value) {
              if (value.length == postalCodeLength) {
                fetchAddress();
              }
            },
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '郵便番号を入力してください',
              border: OutlineInputBorder(),
            ),
          ),
          const Gap(16),
          const Text('都道府県'),
          const Gap(8),
          TextField(
            controller: prefectureController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例）東京都',
            ),
          ),
          const Gap(16),
          const Text('市区町村'),
          const Gap(8),
          TextField(
            controller: address1Controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例）千代田区',
            ),
          ),
          const Gap(16),
          const Text('町域'),
          const Gap(8),
          TextField(
            controller: address2Controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例）霞が関',
            ),
          ),
          const Gap(16),
          const Text('番地'),
          const Gap(8),
          TextField(
            controller: address3Controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例）１丁目１番',
            ),
          ),
          const Gap(16),
          const Text('アパート・建物名'),
          const Gap(8),
          TextField(
            controller: address4Controller,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '例）アパートHoge １０１号',
            ),
          ),
          const Gap(24),
          ElevatedButton(
            onPressed: () {
              if (!isValid()) {
                showDialog(
                  context: context,
                  builder: (context) => const SimpleDialog(
                    title: Text('入力内容に誤りがあります'),
                    children: [
                      Center(
                        child: Text(
                          '入力内容に抜け漏れがないか\n再度ご確認ください',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostalCodeApiDetail(
                      postalCode: postalCodeController.text,
                      prefecture: prefectureController.text,
                      address1: address1Controller.text,
                      address2: address2Controller.text,
                      address3: address3Controller.text,
                      address4: address4Controller.text,
                    ),
                  ),
                );
              }
            },
            child: const Text(
              '登 録',
            ),
          ),
        ],
      ),
    );
  }
}
```

```dart: postal_code_api_detail.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PostalCodeApiDetail extends StatelessWidget {
  const PostalCodeApiDetail({
    super.key,
    required this.postalCode,
    required this.prefecture,
    required this.address1,
    required this.address2,
    required this.address3,
    required this.address4,
  });

  final String postalCode;
  final String prefecture;
  final String address1;
  final String address2;
  final String address3;
  final String address4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PostalCodeApiDetail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('登録された住所'),
            const Gap(24),
            Text('郵便番号：$postalCode'),
            const Gap(8),
            Text('都道府県：$prefecture'),
            const Gap(8),
            Text('市区町村：$address1'),
            const Gap(8),
            Text('町域：$address2'),
            const Gap(8),
            Text('番地：$address3'),
            const Gap(8),
            Text('アパート・建物名：$address4'),
          ],
        ),
      ),
    );
  }
}
```

`PostalCodeApiHome` に関してそれぞれ詳しくみていきます。

まずは以下の部分です。以下では各入力項目の `TextEditingController` を定義しています。
今回は `HookConsumerWidget` を使用しており、Widget内部で hooks が使えるため、`useTextEditingController` でテキストフィールドのコントローラを定義しています。加えて、テキストフィールドのコントローラといった状態は一つの画面、Widgetで完結し、他の画面やWidgetでは参照する必要のない「Ephemeral State」に含まれるため、今回は hooks を用いた実装にしています。
また、郵便番号の長さも定義しています。これについては後述します。
```dart
final postalCodeController = useTextEditingController();
final prefectureController = useTextEditingController();
final address1Controller = useTextEditingController();
final address2Controller = useTextEditingController();
final address3Controller = useTextEditingController();
final address4Controller = useTextEditingController();
const postalCodeLength = 7;
```

次に以下の部分です。
`fetchAddress` メソッドを定義しており、ここで郵便番号による住所の取得を行なっています。
先ほど定義した `fetchPostalCodeApiResponseProvider` に対して郵便番号を渡し、非同期で返ってきた結果を `postalCodeApiResponse` に格納しています。
そして、 `postalCodeApiResponse` の値を都道府県や市区町村のテキストフィールドのコントローラに渡しています。これで、取得した住所をテキストフィールドに表示させることができるようになります。
```dart
void fetchAddress() async {
  final postalCode = int.parse(postalCodeController.text);
  final postalCodeApiResponse =
          await ref.read(fetchPostalCodeApiResponseProvider(postalCode).future);
  prefectureController.text =
          postalCodeApiResponse.addresses?.first.ja?.prefecture ?? '';
  address1Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address1 ?? '';
  address2Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address2 ?? '';
  address3Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address3 ?? '';
  address4Controller.text =
          postalCodeApiResponse.addresses?.first.ja?.address4 ?? '';
}
```

以下では全てのテキストフィールドに値が入っているかどうかを判定する `isValid` 関数を定義しています。
本来であれば住所の形式などでさらに詳しくバリデーションをかけることで表記揺れを減らすなどの工夫ができるかと思いますが、今回は単純に値が入っているかどうかのみを判断しています。
```dart
bool isValid() {
  return postalCodeController.text != '' &&
    prefectureController.text != '' &&
    address1Controller.text != '' &&
    address2Controller.text != '' &&
    address3Controller.text != '' &&
    address4Controller.text != '';
}
```

次に以下の部分です。
以下では郵便番号を入力するテキストフィールドを実装しています。 `onChange` で文字の入力を監視しており、文字数が郵便番号の長さ（通常は７文字）と一致した段階で、入力されている郵便番号から住所を取得する `fetchAddress` メソッドを実行しています。
```dart
TextField(
  controller: postalCodeController,
  onChanged: (value) {
    if (value.length == postalCodeLength) {
      fetchAddress();
    }
  },
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(
  hintText: '郵便番号を入力してください',
  border: OutlineInputBorder(),
  ),
),
```

他のサイトなどを見ると郵便番号を入力するテキストフィールドの隣に「住所を検索する」といったボタンを設けて、ボタンが押された時のみ住所を検索するような仕組みがよくみられます。 `fetchAddress` の発火条件を `ElevatedButton` の `onPressed` にすることで同じような実装は簡単に可能かと思います。

次に以下の部分です。
以下では都道府県のテキストフィールドを実装しています。
ここではこのページで初めに定義した `TextEditingController` を渡したり、ヒントテキストを表示させる実装をしたりしています。基本的には都道府県以下の住所のテキストフィールドも同様の実装であるため、解説はスキップします。
```dart
TextField(
  controller: prefectureController,
  decoration: const InputDecoration(
  border: OutlineInputBorder(),
  hintText: '例）東京都',
  ),
),
```

最後に以下の部分です。
以下では「登録」の `ElevatedButton` を押した時点で、先ほど定義した `isValid` の判定を行い、適切であれば次の画面へデータを渡しつつ遷移を行い、不適切であればダイアログを表示させるようにしています。
```dart
ElevatedButton(
  onPressed: () {
    if (!isValid()) {
      showDialog(
        context: context,
        builder: (context) => const SimpleDialog(
          title: Text('入力内容に誤りがあります'),
          children: [
            Center(
              child: Text(
                '入力内容に抜け漏れがないか\n再度ご確認ください',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostalCodeApiDetail(
            postalCode: postalCodeController.text,
            prefecture: prefectureController.text,
            address1: address1Controller.text,
            address2: address2Controller.text,
            address3: address3Controller.text,
            address4: address4Controller.text,
          ),
        ),
      );
    }
  },
  child: const Text(
    '登 録',
  ),
),
```

以上のコードで実行すると、この記事の初めでも紹介した以下の動画のような挙動になるかと思います。

https://youtu.be/tpPHr941cA0

### 4. 改善できる部分
今回の実装では、ユーザーがテキストを入力している最中にAPIを叩き、表示結果を変更するため、テキストフィールドの表示がユーザーの通信状況に左右されてしまいます。
実際に、「Network Link Conditioner」というサービスで「Very Bad Network（Down: １mbps, Up: １mbps）」の設定を行い、通信状況が非常に悪い状態を再現して実行したところ、７桁の郵便番号を入力してから各テキストフィールドに住所が反映されるまで２, ３秒かかりました。
したがって、データが返ってくるまではテキストフィールドに `CircularProgressIndicator` を表示させておくなどの対応が必要かと思いました。

## まとめ
最後まで読んでいただいてありがとうございました。

今回は郵便番号から住所を取得して表示させる実装を行いました。
冒頭でも述べましたが、住所を入力する画面の実装をちょうど行なっていたところだったので、このAPIに非常に助けられました。

https://zenn.dev/ttskch/articles/309423d26a1aaa

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://app.quicktype.io/

https://github.com/ttskch/jp-postal-code-api

https://zenn.dev/ttskch/articles/309423d26a1aaa

