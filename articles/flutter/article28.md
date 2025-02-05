## 初めに
今回は [fl_chart](https://pub.dev/packages/fl_chart)というパッケージを使って、グラフを表示させる実装を行いたいと思います。
fl_chart ではさまざまなタイプのグラフが実装できますが、今回は以下の三つに絞って実装を行います。
+ 折れ線グラフ
+ 棒グラフ
+ 円グラフ

## 記事の対象者
+ Flutter 学習者
+ モバイル、Webでグラフを表示させる実装がしたい方
+ データを扱うアプリ開発に携わっている方
+ APIで取得したデータをグラフに変換する実装がしたい方

## 目的
今回の目的は、fl_chart パッケージを使ってグラフの実装を行うことです。
最終的には以下の画像にあるような実装をすることを目的とします。
| 折れ線グラフ | 棒グラフ | 円グラフ |
| ---- | ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/c0b1d56078a9-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/d64f265c2118-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/8461b3541d0d-20240212.png) |

## 導入
[fl_chart パッケージ](https://pub.dev/packages/fl_chart) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  fl_chart: ^0.66.2
```

または

以下をターミナルで実行
```
flutter pub add fl_chart
```

## 実装
今回は以下のような手順で実装を進めていきます。
1. 折れ線グラフの実装
2. 棒グラフの実装
3. 円グラフの実装
4. 折れ線グラフで天気情報を表示させる

### 1. 折れ線グラフの実装
まずは折れ線グラフの実装を行います。
コードは以下の通りです。
```dart: fl_chart_line_chart_sample.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FlChartLineChartSample extends StatelessWidget {
  const FlChartLineChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('折れ線グラフ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: screenWidth * 0.95,
          height: screenWidth * 0.95 * 0.65,
          child: LineChart(
            LineChartData(
              lineBarsData: [
                LineChartBarData(
                  spots: const [
                    FlSpot(1, 0),
                    FlSpot(2, 400),
                    FlSpot(3, 650),
                    FlSpot(4, 800),
                    FlSpot(5, 870),
                    FlSpot(6, 920),
                    FlSpot(7, 960),
                    FlSpot(8, 980),
                    FlSpot(9, 990),
                    FlSpot(10, 995),
                  ],
                  isCurved: true,
                  color: Colors.blue,
                ),
              ],
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  axisNameWidget: Text(
                    "労働の限界生産性",
                  ),
                  axisNameSize: 35.0,
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              maxY: 1000,
              minY: 0,
            ),
          ),
        ),
      ),
    );
  }
}
```

これで実行すると以下のようになります。

| モバイル | Web |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/c0b1d56078a9-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/851471f38419-20240212.png) |

コードを詳しく見ていきます。

#### 表示領域の制限
以下のコードでは折れ線グラフを表示する `LineChart` を `SizedBox` で囲むことで特にグラフの高さに関して表示領域を制限しています。
```dart
SizedBox(
  width: screenWidth * 0.95,
  height: screenWidth * 0.95 * 0.65,
    child: LineChart(
```

Webでの表示に関してはこの指定がなくても横長のグラフは正常に表示できますが、モバイルでは以下の画像のように本来横長のグラフが縦長になってしまいます。したがってこのように `SizedBox` による高さの指定をしています。
![](https://storage.googleapis.com/zenn-user-upload/07b5ef378739-20240212.png =250x)

:::message
より細かくグラフの高さなどを指定する場合には、 `dart:io` の `Platform` でプラットフォームを判別するのが良いかもしれません。
:::

#### データの指定
以下では `lineBarsData` で表示させるデータの詳細を定義しています。
`LineChartBarData` の `spots` に `FlSpot(x, y)` のようにデータを入れることで折れ線グラフの点を描画することができます。この章ではデータをベタ打ちしていますが、第４章で実際のデータを代入して表示する実装を行います。

`isCurved` を `true` にすることで折れ線グラフの点と点を繋ぐ線をカーブさせることができます。

`color` では折れ線グラフの色を指定することができます。

```dart
lineBarsData: [
  LineChartBarData(
    spots: const [
      FlSpot(1, 0),
      FlSpot(2, 400),
      FlSpot(3, 650),
      FlSpot(4, 800),
      FlSpot(5, 870),
      FlSpot(6, 920),
      FlSpot(7, 960),
      FlSpot(8, 980),
      FlSpot(9, 990),
      FlSpot(10, 995),
    ],
  isCurved: true,
  color: Colors.blue,
  ),
],
```

#### 折れ線の下に色をつける
先ほどのコードに以下のような追加を加えると折れ線の下側に色をつけることができます。
```diff dart
lineBarsData: [
  LineChartBarData(
    spots: const [
      FlSpot(1, 0),
      FlSpot(2, 400),
      FlSpot(3, 650),
      FlSpot(4, 800),
      FlSpot(5, 870),
      FlSpot(6, 920),
      FlSpot(7, 960),
      FlSpot(8, 980),
      FlSpot(9, 990),
      FlSpot(10, 995),
    ],
  isCurved: true,
  color: Colors.blue,
+ belowBarData: BarAreaData(
+   show: true,
+   gradient: LinearGradient(
+     colors: [
+       Colors.blue.withOpacity(0.6),
+       Colors.green.withOpacity(0.6)
+     ],
+   ),
+ ),
],
```

実行すると以下のように、折れ線グラフの下側にグラデーションをつけることができます。

| モバイル | Web |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/0b5ea849ec85-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/98c57eb62a05-20240212.png) |

#### グラフのタイトルを編集する
以下のコードではグラフのタイトルを実装しています。
グラフの上部にタイトルを表示させる場合は `topTitles` に `AxisTitles` を配置することで実装できます。この時 `axisNameSize` としてタイトルを表示させる領域のサイズを大きめ指定することでタイトルとグラフの間を開けることができます。

また、タイトルを表示させない場合は表示させたくない側面のタイトルに対して `showTitles: false` とする必要があります。

```dart
titlesData: const FlTitlesData(
  topTitles: AxisTitles(
    axisNameWidget: Text(
      "労働の限界生産性",
    ),
    axisNameSize: 35.0,
  ),
  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
),
```

#### グラフの最大値と最小値を指定する
以下の部分では、グラフのY軸の最大値と最小値を指定しています。
X軸も同様に `maxX`, `minX` で指定することができます。
```dart
maxY: 1000,
minY: 0,
```

### 2. 棒グラフの実装
次は棒グラフを実装していきます。
コードは以下の通りです。
```dart: fl_chart_bar_chart_sample.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FlChartBarChartSample extends StatelessWidget {
  const FlChartBarChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('棒グラフ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: screenWidth * 0.95,
          height: screenWidth * 0.95 * 0.65,
          child: BarChart(
            BarChartData(
              borderData: FlBorderData(
                border: const Border(
                  top: BorderSide.none,
                  right: BorderSide.none,
                  left: BorderSide(width: 1),
                  bottom: BorderSide(width: 1),
                ),
              ),
              titlesData: const FlTitlesData(
                topTitles: AxisTitles(
                  axisNameWidget: Text(
                    "正規分布",
                  ),
                  axisNameSize: 35.0,
                ),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              groupsSpace: 10,
              barGroups: [
                BarChartGroupData(x: 1, barRods: [
                  BarChartRodData(toY: 1, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 2, barRods: [
                  BarChartRodData(toY: 20, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 3, barRods: [
                  BarChartRodData(toY: 30, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 4, barRods: [
                  BarChartRodData(toY: 60, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 5, barRods: [
                  BarChartRodData(toY: 90, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 6, barRods: [
                  BarChartRodData(toY: 100, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 7, barRods: [
                  BarChartRodData(toY: 90, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 8, barRods: [
                  BarChartRodData(toY: 60, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 9, barRods: [
                  BarChartRodData(toY: 30, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 10, barRods: [
                  BarChartRodData(toY: 20, width: 15, color: Colors.blue),
                ]),
                BarChartGroupData(x: 11, barRods: [
                  BarChartRodData(toY: 1, width: 15, color: Colors.blue),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

上記のコードを実行すると以下のようになります。

| モバイル | Web |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/d64f265c2118-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/5bb8ab667e2a-20240212.png) |

それではコードを詳しく見ていきます。

#### 枠線の表示
棒グラフの実装では、`BarChart` の第一引数である `BarChartData` を主に変更することで表示を変更していきます。

以下のコードでは `borderData` に `FlBorderData` を指定して、グラフの左側と下側のみに枠線を表示させるようにしています。
なお、`borderData` を指定しなかった場合はデフォルトで全ての側面に黒色の枠線が表示されます。
```dart
BarChartData(
  borderData: FlBorderData(
    border: const Border(
      top: BorderSide.none,
      right: BorderSide.none,
      left: BorderSide(width: 1),
      bottom: BorderSide(width: 1),
    ),
  ),
```

#### グラフのタイトルの編集
以下ではグラフのタイトルを編集しています。
基本的には折れ線グラフの時の実装と同じかと思うのでスキップします。
```dart
titlesData: const FlTitlesData(
  topTitles: AxisTitles(
    axisNameWidget: Text(
      "正規分布",
    ),
    axisNameSize: 35.0,
  ),
  rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
),
```

#### 棒データの指定
以下では棒データの指定を行なっています。
`x` では X軸の値、`toY` ではY軸の値を指定することができます。
`width` では棒の幅を、`color` では棒の色を編集できます。
```dart
barGroups: [
  BarChartGroupData(x: 1, barRods: [
    BarChartRodData(toY: 1, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 2, barRods: [
    BarChartRodData(toY: 20, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 3, barRods: [
    BarChartRodData(toY: 30, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 4, barRods: [
    BarChartRodData(toY: 60, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 5, barRods: [
    BarChartRodData(toY: 90, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 6, barRods: [
    BarChartRodData(toY: 100, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 7, barRods: [
    BarChartRodData(toY: 90, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 8, barRods: [
    BarChartRodData(toY: 60, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 9, barRods: [
    BarChartRodData(toY: 30, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 10, barRods: [
    BarChartRodData(toY: 20, width: 15, color: Colors.blue),
  ]),
  BarChartGroupData(x: 11, barRods: [
    BarChartRodData(toY: 1, width: 15, color: Colors.blue),
  ]),
],
```

#### 複数の棒データを表示させる
なお、以下のように複数の棒のデータを `barRods` に指定した場合、以下のように横並びで表示させることができます。
```dart
BarChartGroupData(x: 1, barRods: [
  BarChartRodData(toY: 1, width: 15, color: Colors.blue),
  BarChartRodData(toY: 10, width: 15, color: Colors.red),
]),
```

![](https://storage.googleapis.com/zenn-user-upload/104213b1ef2c-20240212.png =250x)

### 3. 円グラフの実装
次は円グラフの実装を行います。
コードは以下の通りです。
```dart: fl_chart_bar_chart_sample.dart
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FlChartBarChartSample extends StatelessWidget {
  const FlChartBarChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('円グラフ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: screenWidth * 0.95,
          height: screenWidth * 0.95 * 0.65,
          child: pieChart()
        ),
      ),
    );
  }

  Widget pieChart() {
    List<Sector> sectors = [
      Sector(color: Colors.red, value: 50, title: 'Red'),
      Sector(color: Colors.blue, value: 30, title: 'Blue'),
      Sector(color: Colors.green, value: 10, title: 'Green'),
      Sector(color: Colors.yellow, value: 5, title: 'Yellow'),
      Sector(color: Colors.purple, value: 3, title: 'Purple'),
      Sector(color: Colors.black, value: 2, title: 'Black'),
    ];

    List<PieChartSectionData> chartSections(List<Sector> sectors) {
      final List<PieChartSectionData> list = [];
      for (var sector in sectors) {
        const double radius = 50.0;
        final data = PieChartSectionData(
          color: sector.color,
          value: sector.value,
          title: sector.title,
          radius: radius,
        );
        list.add(data);
      }
      return list;
    }

    return PieChart(
      PieChartData(
        sections: chartSections(sectors),
        centerSpaceRadius: 48.0,
      ),
    );
  }
}

class Sector {
  final Color color;
  final double value;
  final String title;

  Sector({required this.color, required this.value, required this.title});
}
```

上記のコードを実行すると以下のようになります。

| モバイル | Web |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/8461b3541d0d-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/89405cf7e334-20240212.png) |

それぞれ詳しくみていきます。

#### データ構造の定義
先ほどのコードの一番下に当たりますが、円グラフで使用するデータの構造を定義しています。
`Section` としてそれぞれのデータを表示させる際の色、値、タイトルを定義しています。
```dart
class Sector {
  final Color color;
  final double value;
  final String title;

  Sector({required this.color, required this.value, required this.title});
}
```

#### データの定義
以下では先ほど定義した `Section` のリストとしてデータを定義しています。
今回のデータはベタ打ちで実装しており、`value` の合計値が 100 になるようにしています。
```dart
List<Sector> sectors = [
  Sector(color: Colors.red, value: 50, title: 'Red'),
  Sector(color: Colors.blue, value: 30, title: 'Blue'),
  Sector(color: Colors.green, value: 10, title: 'Green'),
  Sector(color: Colors.yellow, value: 5, title: 'Yellow'),
  Sector(color: Colors.purple, value: 3, title: 'Purple'),
  Sector(color: Colors.black, value: 2, title: 'Black'),
];
```

#### データのリスト作成
以下では先ほどの `sectors` から `PieChartSectionData` のリストとしてデータを作成しています。今回は `color`, `value`, `title`, `radius` のみを設定していますが、他にもタイトルのスタイルやグラデーションなども設定できます。
```dart
List<PieChartSectionData> chartSections(List<Sector> sectors) {
  final List<PieChartSectionData> list = [];
  for (var sector in sectors) {
    const double radius = 50.0;
    final data = PieChartSectionData(
      color: sector.color,
      value: sector.value,
      title: sector.title,
      radius: radius,
    );
    list.add(data);
  }
  return list;
}
```

#### PieChart の表示
以下では `PieChartData` を引数に渡すことで `PieChart` を表示させています。
`sections: chartSections(sectors)` で先ほどの `chartSections` 関数を実行しています。
`centerSpaceRadius: 48.0` では円グラフの真ん中の空間の大きさを指定しています。
```dart
return PieChart(
  PieChartData(
    sections: chartSections(sectors),
    centerSpaceRadius: 48.0,
  ),
);
```

#### 円グラフを回転させる
先ほどのコードでは円グラフが円の右側から始まっていましたが、これを上側から始まるように変更したいと思います。
コードは以下の通りです。
```dart
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class FlChartPirChartSample extends StatelessWidget {
  const FlChartPirChartSample({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('円グラフ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: screenWidth * 0.95,
          height: screenWidth * 0.95 * 0.65,
          child: rotatedPieChart()
        ),
      ),
    );
  }

  Widget rotatedPieChart() {
    List<Sector> sectors = [
      Sector(color: Colors.red, value: 50, title: 'Red'),
      Sector(color: Colors.blue, value: 30, title: 'Blue'),
      Sector(color: Colors.green, value: 10, title: 'Green'),
      Sector(color: Colors.yellow, value: 5, title: 'Yellow'),
      Sector(color: Colors.purple, value: 3, title: 'Purple'),
      Sector(color: Colors.black, value: 2, title: 'Black'),
    ];

    List<PieChartSectionData> chartSections(List<Sector> sectors) {
      final List<PieChartSectionData> list = [];
      for (var sector in sectors) {
        const double radius = 50.0;
        final data = PieChartSectionData(
          color: sector.color,
          value: sector.value,
          radius: radius,
          showTitle: false,
          badgeWidget: Transform.rotate(
            angle: 90 * pi / 180,
            child: Text(
              sector.title
            ),
          ),
        );
        list.add(data);
      }
      return list;
    }

    return Transform.rotate(
      angle: -90 * pi / 180,
      child: PieChart(
        PieChartData(
          sections: chartSections(sectors),
          centerSpaceRadius: 48.0,
        ),
      ),
    );
  }
}

class Sector {
  final Color color;
  final double value;
  final String title;

  Sector({required this.color, required this.value, required this.title});
}
```

先ほどの `pieChart` と変更した点は以下の二点です。

一点目は `PieChartSectionData` の変更です。
先ほどは `title` としてグラフの説明を追加していたところを `badgeWidget` に変更して、`Text` を90度回転させたものを指定しています。
```dart
final data = PieChartSectionData(
  color: sector.color,
  value: sector.value,
  radius: radius,
  showTitle: false,
  badgeWidget: Transform.rotate(
    angle: 90 * pi / 180,
    child: Text(
      sector.title
    ),
  ),
);
```

二点目は `PieChart` の変更です。
以下のように `PieChart` を90度回転させて表示させています。
```dart
return Transform.rotate(
  angle: -90 * pi / 180,
  child: PieChart(
    PieChartData(
      sections: chartSections(sectors),
      centerSpaceRadius: 48.0,
    ),
  ),
);
```

これで実行すると以下のように変更することができます。

| 変更前 | 変更後 |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/8461b3541d0d-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/a4b33975dd8e-20240212.png) |

### 4. 折れ線グラフで天気情報を表示させる
最後に [Open Meteo API](https://open-meteo.com/) で天気データを取得して折れ線グラフとして表示する実装を行います。

この実装は以下の手順で行います。
1. 天気のデータモデルの定義
2. API でデータを取得する Provider の作成
3. グラフの作成

#### 1. 天気のデータモデルの定義
Open Meteo API から返却されるデータを扱うために以下のようなデータモデルを Freezed で定義します。
Weather.fromJson に関して、今回はそのままの実装だとNullに関するエラーになったので、全ての値に関してNullを許容する実装にしています。

また、これらのデータ構造の定義に関して [quicktype](https://app.quicktype.io/) というサイトが非常に有用で、APIにアクセスして得られたJSON形式のデータを読み込むことで Dart のデータ構造を定義してくれます。
```dart: weather.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weather.freezed.dart';
part 'weather.g.dart';

@freezed
class Weather with _$Weather {
  factory Weather({
    required double latitude,
    required double longitude,
    required double generationtimeMs,
    required int? utcOffsetSeconds,
    required String timezone,
    required String timezoneAbbreviation,
    required double? elevation,
    required HourlyUnits hourlyUnits,
    required Hourly hourly,
  }) = _Weather;

factory Weather.fromJson(Map<String, dynamic> json) => Weather(
  latitude: (json["latitude"] as num?)?.toDouble() ?? 0.0,
  longitude: (json["longitude"] as num?)?.toDouble() ?? 0.0,
  generationtimeMs: (json["generationtime_ms"] as num?)?.toDouble() ?? 0.0,
  utcOffsetSeconds: json["utc_offset_seconds"] as int? ?? 0,
  timezone: json["timezone"] as String? ?? '',
  timezoneAbbreviation: json["timezone_abbreviation"] as String? ?? '',
  elevation: json["elevation"] as double? ?? 0.0,
  hourlyUnits: HourlyUnits.fromJson(json["hourly_units"] ?? {}),
  hourly: Hourly.fromJson(json["hourly"] ?? {}),
);
}

@freezed
class Hourly with _$Hourly {
  factory Hourly({
    required List<String> time,
    required List<double> temperature_2m,
  }) = _Hourly;

  factory Hourly.fromJson(Map<String, dynamic> json) =>
      _$HourlyFromJson(json);
}

@freezed
class HourlyUnits with _$HourlyUnits {
  factory HourlyUnits({
    required String time,
    required String temperature_2m,
  }) = _HourlyUnits;

  factory HourlyUnits.fromJson(Map<String, dynamic> json) =>
      _$HourlyUnitsFromJson(json);
}
```

#### 2. API でデータを取得する Provider の作成
次に Riverpod generator で Open Meteo のAPIにアクセスしてデータを取得する Provider を作成します。
コードは以下の通りです。
```dart: weather_provider.dart
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sample_flutter/fl_chart/model/weather.dart';
import 'package:http/http.dart' as http;

part 'weather_provider.g.dart';

@riverpod
Future<Weather> weather(WeatherRef ref) async {
  const url =
      'https://api.open-meteo.com/v1/forecast?latitude=35.6894&longitude=139.6917&hourly=temperature_2m&timezone=Asia%2FTokyo&forecast_days=1';
  final uri = Uri.parse(url);
  final response = await http.get(uri);

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return Weather.fromJson(json);
  } else {
    throw Exception('Failed to load weather data');
  }
}
```

データの取得は非同期処理で行うため、返り値に `Future<Weather>` として FutureProvider を作成しています。
また、`url` に指定しているのは、今日の東京の気温の推移を取得するためのエンドポイントです。

以下では `http` パッケージの `get` メソッドで先ほどのエンドポイントにアクセスして、その返り値を `response` としています。
そして `response` のステータスコードが 200 で正常に取得できた時だけ `Weather.fromJson` でJSON形式のデータを `Weather` オブジェクトに変換して返却しています。
```dart
final response = await http.get(uri);

if (response.statusCode == 200) {
  final json = jsonDecode(response.body);
  return Weather.fromJson(json);
} else {
  throw Exception('Failed to load weather data');
}
```

これで天気のデータを取得するための Provider が作成できました。

#### 3. グラフの作成
最後は取得した気温のデータをもとに折れ線グラフを表示させます。
コードは以下の通りです。
```dart
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sample_flutter/fl_chart/model/weather.dart';
import 'package:sample_flutter/fl_chart/providers/weather_provider.dart';

class FlChartWeatherSample extends ConsumerWidget {
  const FlChartWeatherSample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsyncValue = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('気温の折れ線グラフ'),
      ),
      body: weatherAsyncValue.when(
        data: (weather) {
          return TemperatureLineChart(weather: weather);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('エラー: $err')),
      ),
    );
  }
}

class TemperatureLineChart extends StatelessWidget {
  final Weather weather;

  const TemperatureLineChart({Key? key, required this.weather})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Weather オブジェクトから気温データの FlSpot リストを生成
    List<FlSpot> spots = weather.hourly.temperature_2m
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    int minTemperature = weather.hourly.temperature_2m.reduce(min).round();
    int maxTemperature = weather.hourly.temperature_2m.reduce(max).round();

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        width: screenWidth * 0.95,
        height: screenWidth * 0.95 * 0.65,
        child: LineChart(
          LineChartData(
            minY: minTemperature - 5,
            maxY: maxTemperature + 5,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
              ),
            ],
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    // 時刻データをX軸のラベルとして表示
                    final dateTimeHour =
                        DateTime.parse(weather.hourly.time[value.toInt()]).hour;
                    return Text(dateTimeHour.toString());
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

基本的には第１章で紹介した折れ線グラフの実装と同じですが、異なる点もあるので詳しくみていきます。

以下では、先ほど定義した `weatherProvider` の返り値を `weatherAsyncValue` という変数に代入しています。
```dart
final weatherAsyncValue = ref.watch(weatherProvider);
```

以下では AsyncValue<Weather> 型である `weatherAsyncValue` をもとに `body` を構築しています。
ローディング中には `CircularProgressIndicator` を表示し、エラー時にはエラー内容を表示し、データがあるときには後述の `TemperatureLineChart` に渡しています。
```dart
body: weatherAsyncValue.when(
  data: (weather) {
    return TemperatureLineChart(weather: weather);
  },
  loading: () => const Center(child: CircularProgressIndicator()),
  error: (err, stack) => Center(child: Text('エラー: $err')),
),
```

`TemperatureLineChart` の以下のコードでは、受け取った天気のデータから１時間ごとの気温を抽出し、それを `FlSpot` の `key` と `value` に振り分け、リストとして保存しています。
このデータをもとに折れ線グラフの点を描画することができます。
```dart
List<FlSpot> spots = weather.hourly.temperature_2m
  .asMap()
  .entries
  .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
  .toList();
```

以下では、気温のデータの最大値と最小値を求めています。
これらの値をもとに、グラフの `maxY`, `minY` を決定していきます。
```dart
int minTemperature = weather.hourly.temperature_2m.reduce(min).round();
int maxTemperature = weather.hourly.temperature_2m.reduce(max).round();
```

以下では先ほどの `spot` をデータとして指定し、グラフの最大値、最小値を `minTemperature`, `maxTemperature` をもとに決定しています。
今回は気温の最大値と最小値ともにY軸に5度の余裕を設けて表示させています。
```dart
LineChartData(
  minY: minTemperature - 5,
  maxY: maxTemperature + 5,
  lineBarsData: [
    LineChartBarData(
      spots: spots,
      isCurved: true,
      color: Colors.blue,
    ),
  ],
```

以下では、コメントにもある通り、`weather` のデータから時間のみを抽出し、それをX軸のラベルとして表示させています。
```dart
bottomTitles: AxisTitles(
  sideTitles: SideTitles(
    showTitles: true,
    getTitlesWidget: (value, meta) {
      // 時刻データをX軸のラベルとして表示
      final dateTimeHour = DateTime.parse(weather.hourly.time[value.toInt()]).hour;
      return Text(dateTimeHour.toString());
    },
  ),
),
```

これで実行すると以下のようにデータを取得でき、折れ線グラフとして表示できているかと思います。

| モバイル | Web |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/0fa233cd1847-20240212.png) | ![](https://storage.googleapis.com/zenn-user-upload/0bc692ee96af-20240212.png)|

## まとめ
最後まで読んでいただいてありがとうございました。

今回は fl_chart パッケージを使用してグラフの表示の実装を行いました。
本記事では3種類のグラフの実装のみを行いましたが、そのほかの種類のグラフを表示できたり、それぞれのグラフの見た目もかなり柔軟に変更できたりするので、非常に便利なパッケージだと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考
https://pub.dev/packages/fl_chart

https://flchart.dev/

https://blog.logrocket.com/build-beautiful-charts-flutter-fl-chart/
