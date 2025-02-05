## 初めに
今回は題名にある通り、`Sliver` と `SingleChildScrollView` の使い分けについてみていきたいと思います。また、タイトルには書きませんでしたが、ほかにも `ListView`, `ListView.builder` についても比較対象としてどのように使い分けるべきかを考えていきたいと思います。

## 記事の対象者
+ Flutter 学習者
+ Sliver などを適切に使いたい方

## 目的
最近の開発で、 `Sliver` を使用する場面があり、あまりよく理解せず使っていたので、今回は先述の通り `Sliver` について少し掘り下げ、 `SingleChildScrollView` などと比較することで、それぞれどのように使い分けるかについて考えていきたいと思います。

## Sliver とは
早速、 Sliver についてです。
[Flutter の公式ドキュメント](https://api.flutter.dev/flutter/widgets/CustomScrollView/slivers.html)に「What is a sliver?」というそのままの記述があったので引用します。
> sliver (noun): a small, thin piece of something.
>
>A sliver is a widget backed by a RenderSliver subclass, i.e. one that implements the constraint/geometry protocol that uses SliverConstraints and SliverGeometry.
>
>This is as distinct from those widgets that are backed by RenderBox subclasses, which use BoxConstraints and Size respectively, and are known as box widgets. (Widgets like Container, Row, and SizedBox are box widgets.)
>
>While boxes are much more straightforward (implementing a simple two-dimensional Cartesian layout system), slivers are much more powerful, and are optimized for one-axis scrolling environments.
>
>Slivers are hosted in viewports, also known as scroll views, most notably CustomScrollView.
>
> 日本語訳
> sliver (名詞): 何かの小さくて薄い部分。
>
> Sliver は RenderSliver サブクラスによってサポートされるウィジェットであり、 SliverConstraints と SliverGeometry を使用する制約/ジオメトリプロトコルを実装するものです。
>
> これは、 BoxConstraints と Size をそれぞれ使用し、ボックスウィジェットとして知られる RenderBox サブクラスによってサポートされるウィジェットとは異なります。（Container、Row、SizedBoxなどのウィジェットはボックスウィジェットです。）
>
> ボックスは二次元のデカルトレイアウトシステムを実装するのに対して、 Sliver はより強力で、一軸スクロール環境に最適化されています。
>
> Sliver はビューポート、またはスクロールビュー（特に CustomScrollView ）にホストされます。

まとめると以下のようなことが言えるかと思います。
+ `Sliver` は `RenderSliver` によってサポートされており、これは `Container`、`Row`、`SizedBox` などをサポートしている `RenderBox` とは異なる
+ `RenderBox` は二次元のレイアウトを実装するのに対して、 `RenderSliver` は一つの方向のスクロールを実装するのに適している
+ `Sliver` の実装には `SliverConstraints` や `SliverGeometry` などを用いる

## RenderBox側の実装
まずは `Column`, `Row`, `SizedBox` などに使用されている `RenderBox` をみていきます。
`Column` の実装を見ると以下のように `Flex` を継承していることがわかります。
ちなみに、`Column` 以外にも `Row` も `Flex` を継承しています。
```dart
class Column extends Flex {
  const Column({
    super.key,
    super.mainAxisAlignment,
    super.mainAxisSize,
    super.crossAxisAlignment,
    super.textDirection,
    super.verticalDirection,
    super.textBaseline,
    super.children,
  }) : super(
    direction: Axis.vertical,
  );
}
```

`Column` が継承している `Flex` をみてみます。
```dart
  const Flex({
    super.key,
    required this.direction,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
    this.textBaseline,
    this.clipBehavior = Clip.none,
    super.children,
  }) : assert(!identical(crossAxisAlignment, CrossAxisAlignment.baseline) || textBaseline != null, 'textBaseline is required if you specify the crossAxisAlignment with CrossAxisAlignment.baseline');
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final TextBaseline? textBaseline;
  final Clip clipBehavior;

  // 省略

  @override
  RenderFlex createRenderObject(BuildContext context) {
    return RenderFlex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      textDirection: getEffectiveTextDirection(context),
      verticalDirection: verticalDirection,
      textBaseline: textBaseline,
      clipBehavior: clipBehavior,
    );
  }
```

`Flex` が生成される際に返り値として指定されている `RenderFlex` をみてみます。
```dart
class RenderFlex extends RenderBox with ContainerRenderObjectMixin<RenderBox, FlexParentData>,
                                        RenderBoxContainerDefaultsMixin<RenderBox, FlexParentData>,
                                        DebugOverflowIndicatorMixin {
  RenderFlex({
    List<RenderBox>? children,
    Axis direction = Axis.horizontal,
    MainAxisSize mainAxisSize = MainAxisSize.max,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    TextDirection? textDirection,
    VerticalDirection verticalDirection = VerticalDirection.down,
    TextBaseline? textBaseline,
    Clip clipBehavior = Clip.none,
  })
```

上記のように `RenderFlex` は `RenderBox` を継承していることがわかります。
ちなみに、`SizedBox` は `Column` や `Row` とは異なり、 `SingleChildRenderObjectWidget` を継承しているのですが、生成を行う `createRenderObject` の中で `RenderConstrainedBox` を返しており、これが `RenderBox` を受け取っているため、`RenderBox` にサポートされていると言えそうです。

:::details Container の場合
余談ですが、 `Container` についても同様に調べてみたところ、`Container` は `StatelessWidget` を継承しており、今まで見てきた `Column`, `Row`, `SizedBox` とは異なる性質を持っていることがわかりました。

具体的にコードを見てみると以下のようになっています。
```dart
class Container extends StatelessWidget {
  Container({
    super.key,
    this.alignment,
    this.padding,
    this.color,
    this.decoration,
    this.foregroundDecoration,
    double? width,
    double? height,
    BoxConstraints? constraints,
    this.margin,
    this.transform,
    this.transformAlignment,
    this.child,
    this.clipBehavior = Clip.none,
  // 省略
  @override
  Widget build(BuildContext context) {
    Widget? current = child;

    if (child == null && (constraints == null || !constraints!.isTight)) {
      current = LimitedBox(
        maxWidth: 0.0,
        maxHeight: 0.0,
        child: ConstrainedBox(constraints: const BoxConstraints.expand()),
      );
    } else if (alignment != null) {
      current = Align(alignment: alignment!, child: current);
    }

    final EdgeInsetsGeometry? effectivePadding = _paddingIncludingDecoration;
    if (effectivePadding != null) {
      current = Padding(padding: effectivePadding, child: current);
    }

    if (color != null) {
      current = ColoredBox(color: color!, child: current);
    }

    if (clipBehavior != Clip.none) {
      assert(decoration != null);
      current = ClipPath(
        clipper: _DecorationClipper(
          textDirection: Directionality.maybeOf(context),
          decoration: decoration!,
        ),
        clipBehavior: clipBehavior,
        child: current,
      );
    }

    if (decoration != null) {
      current = DecoratedBox(decoration: decoration!, child: current);
    }

    if (foregroundDecoration != null) {
      current = DecoratedBox(
        decoration: foregroundDecoration!,
        position: DecorationPosition.foreground,
        child: current,
      );
    }

    if (constraints != null) {
      current = ConstrainedBox(constraints: constraints!, child: current);
    }

    if (margin != null) {
      current = Padding(padding: margin!, child: current);
    }

    if (transform != null) {
      current = Transform(transform: transform!, alignment: transformAlignment, child: current);
    }

    return current!;
  }
```

`Container` の実装は、各プロパティの有無によって Widget 型の `current` がどんどん変化する形で実装されているようでした。
しかし、それぞれの条件分岐で `current` に指定されている以下の Widget は全て `SingleChildRenderObjectWidget` を継承していることがわかりました。
`SingleChildRenderObjectWidget` では `SizedBox` と同様に、`createRenderObject` の中で `RenderConstrainedBox` を返しており、これが `RenderBox` を受け取っているため、RenderBox にサポートされていると言えそうです。

+ ConstrainedBox
+ Align
+ Padding
+ ColoredBox
+ ClipPath
+ DecoratedBox
:::

`SingleChildRenderObjectWidget` を例にとって考えると、`createRenderObject`メソッドで `RenderObject` を生成し、 `updateRenderObject` メソッドで `RenderObject` を更新しています。

## RenderSliver側の実装
次に `SliverList` や `SliverToBoxAdapter` が含まれる `RenderSliver` 側の実装を見てみたいと思います。
具体的に、 `SliverList` をみていきます。
`createRenderObject` では `RenderSliverList` が返されています。
```dart
class SliverList extends SliverMultiBoxAdaptorWidget {
  const SliverList({
    super.key,
    required super.delegate,
  });
  // 省略
  @override
  RenderSliverList createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element = context as SliverMultiBoxAdaptorElement;
    return RenderSliverList(childManager: element);
  }
```

`RenderSliverList` についてみてみます。
    `RenderSliverMultiBoxAdaptor` を継承しているようです。
```dart
class RenderSliverList extends RenderSliverMultiBoxAdaptor {
  RenderSliverList({
    required super.childManager,
  });

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
 // 省略
```

`RenderSliverMultiBoxAdaptor` についてみてみます。
`RenderSliverMultiBoxAdaptor` は以下のように `RenderSliver` を継承していることがわかりました。
```dart
abstract class RenderSliverMultiBoxAdaptor extends RenderSliver
  with ContainerRenderObjectMixin<RenderBox, SliverMultiBoxAdaptorParentData>,
       RenderSliverHelpers, RenderSliverWithKeepAliveMixin {
```

先ほど見てきた `Column` や `Row`、 `SizedBox` とは異なり、`RenderSliver` に基づいて構成されていることがわかりました。

## RenderSliver の詳細
次に `RenderSliver` の詳細を見ていきます。
`RenderSliver` 自体は `SliverConstraints` や `SliverGeometry` を保持しており、それぞれレイアウトに関する情報などを持っています。一部を抜き出すと、以下のような内容を保持しています。

**SliverConstraints**
+ axis:  スクロール方向
+ crossAxisExtent:  クロスアクシスの長さ
+ scrollOffset:  スクロールオフセット
+ remainingPaintExtent:  残りのペイント可能な長さ
+ remainingCacheExtent:  残りのキャッシュ可能な長さ

**SliverGeometry**
+ scrollExtent:  スクロール可能な全長
+ paintExtent:  実際に描画される長さ
+ maxPaintExtent:  描画可能な最大長さ
+ hitTestExtent:  ヒットテストに使用される長さ
+ scrollOffsetCorrection:  スクロールオフセットの補正

これらのレイアウトに関する情報を保持しているため、Sliverでは「表示されている部分だけ描画し、それ以外は破棄する」といったことが可能になります。

具体的に描画を行うのは、 `RenderSliver` ではなく、 `RenderSliver` を継承した `RenderSliverSingleBoxAdapter` や `RenderSliverToBoxAdapter` になります。

レイアウトから描画までの流れを簡単にまとめると以下のようになります。

1. レイアウト計算
`performLayout`メソッド内で `SliverConstraints` を使用して、レイアウトを計算し、 `SliverGeometry` に結果を設定する
<br/>
2. ジオメトリ計算
`geometry`プロパティを通じて、`performLayout` または`performResize`メソッド内で、`SliverGeometry` オブジェクトに計算結果をセット。
<br/>
3. 描画領域の計算
`paintBounds`プロパティを使用して、描画領域を計算。
<br/>
4. ヒットテスト
`hitTest`メソッドでタッチイベントの処理を実行
`mainAxisPosition` と `crossAxisPosition` を使って、対象領域内かを判定
<br/>
5. 描画
`paint`メソッドSliverの描画を行う。
<br/>

簡単にまとめましたが、詳しくは以下のドキュメントをご覧ください

https://api.flutter.dev/flutter/rendering/RenderSliver-class.html

## SingleChildScrollView などとの比較
ここからは本題である `SingleChildScrollView` との比較を行いたいと思います。
なお、 `SingleChildScrollView` は `RenderBox` プロトコルに準拠している Widget であり、 `SliverList` や `SliverToBoxAdapter` とは異なります。

今回は特に以下の２点に関してみていきたいと思います。
1. Widgetの破棄
2. パフォーマンス

なお、今回は `SliverList`, `SliverToBoxAdapter`, `SingleChildScrollView`, `ListViewBuilder` の四つを比較してみます。

### 1. Widgetの破棄
まずは Widget の破棄についてです。
Sliver は基本的に画面内の要素のみを描画し、それ以外の要素は破棄するため、そのような破棄がどのような影響を与えるかをみていきます。
今回は `TextField` を例にとってみていきます。

#### SliverList
コードは以下の通りです。
```dart
class SliverListTextFiledHome extends HookWidget {
  const SliverListTextFiledHome({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    const textFieldLength = 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SliverListTextFiledHome'),
      ),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= textFieldLength) return null;
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    initialValue: 'Field $index',
                    decoration: InputDecoration(
                      labelText: 'Field $index',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                );
              },
              childCount: textFieldLength,
            ),
          ),
        ],
      ),
    );
  }
}
```

上記のコードを実行すると動画のような挙動になります。

https://youtube.com/shorts/bmBCD6mpqq0?feature=share

上記の動画では `SliverList` の一番上にあるテキストフィールドに「edited」というテキストを入力し、一番下までスクロールした後、再度一番上のテキストフィールドを確認すると、入力した「edited」のテキストがリセットされていることがわかります。
これは `SliverList` の「画面外のWidgetは破棄する」という特性によるものです。

`SliverList` を使用する場合は、そのリスト内にある Widget や Widget の状態が破棄されても問題ないものであるかを確認する必要があると言えます。

#### SliverToBoxAdapter
次は `SliverToBoxAdapter` です。
コードは以下の通りです。
```dart
class SliverToBoxAdapterTextFiledHome extends HookWidget {
  const SliverToBoxAdapterTextFiledHome({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    const textFieldLength = 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SliverToBoxAdapterTextFiledHome'),
      ),
      body: CustomScrollView(
        controller: scrollController,
        slivers: [
          for (int i = 0; i < textFieldLength; i++) ...{
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  initialValue: 'Field $i',
                  decoration: InputDecoration(
                    labelText: 'Field $i',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          },
        ],
      ),
    );
  }
}
```

上記のコードを実行すると動画のような挙動になります。

https://youtube.com/shorts/f-iF_7QP2dI

上記の動画では、一番上のテキストフィールドは値が入力された後に一度画面外までスクロールされます。その後一番上まで戻ってくると値が保持されたまま残っています。

`SliverList` と `SliverToBoxAdapter` でどのような仕組みの違いがあるでしょうか？
そもそも `SliverToBoxAdapter` は通常の `RenderBox` に基づいた Widget を Sliver としてスクロール可能な領域に配置するための Widget です。
実際に `SliverToBoxAdapter` のコードを見ていくと以下のような記述があります。
`Creates a [RenderSliver] that wraps a [RenderBox].`

`SliverToBoxAdapter` のコードを詳しくみていきます。
```dart
class SliverToBoxAdapter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.
  const SliverToBoxAdapter({
    super.key,
    super.child,
  });

  @override
  RenderSliverToBoxAdapter createRenderObject(BuildContext context) =>
      RenderSliverToBoxAdapter();
}
```

`SliverToBoxAdapter` では上記のように一つだけ `child` として Widget を受け取り、 `createRenderObject` メソッドのみを持つ非常にシンプルな実装になっています。

この `createRenderObject` メソッドで返り値に指定されている `RenderSliverToBoxAdapter` をみてみます。
コードは以下の通りです。
 ```dart
class RenderSliverToBoxAdapter extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a [RenderBox].
  RenderSliverToBoxAdapter({
    super.child,
  });

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }
    final SliverConstraints constraints = this.constraints;
    child!.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    // 省略
}
```
`RenderSliverToBoxAdapter` は `performLayout`メソッドのみを持ちます。
この `performLayout`メソッドは、 `SliverList` のもとになっている `RenderSliverList` にも実装されています。
`RenderSliverList` のコードは以下の通りです。
```dart
class RenderSliverList extends RenderSliverMultiBoxAdaptor {
  /// Creates a sliver that places multiple box children in a linear array along
  RenderSliverList({
    required super.childManager,
  });

  @override
  void performLayout() {
    final SliverConstraints constraints = this.constraints;
    childManager.didStartLayout();
    childManager.setDidUnderflow(false);
    // 省略
```

つまり、 `RenderSliverToBoxAdapter（SliverToBoxAdapter）` はその一つ一つがレイアウトの計算を行なっていることになり、自身が画面外にいてもいなくてもレイアウトまで行われるようになります。

ちなみに、 `SliverList` の子要素として `SliverToBoxAdapter` を並べると以下のようなエラーになります。子要素として `RenderSliver` は並べられないようです。
```
A RenderRepaintBoundary expected a child of type RenderBox but received a child of type RenderSliverToBoxAdapter.
```

同じ Sliver でも、 `SliverList` と `SliverToBoxAdapter` には使用目的や状態の破棄について異なる点が見られることがわかります。

#### SingleChildScrollView
次に `SingleChildScrollView` の場合を見てみます。
コードは以下の通りです。
```dart
class SingleChildScrollViewTextFiledHome extends HookWidget {
  const SingleChildScrollViewTextFiledHome({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();
    const textFieldLength = 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SingleChildScrollViewHome'),
      ),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: List.generate(
              textFieldLength,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TextFormField(
                  initialValue: 'Field $index',
                  decoration: InputDecoration(
                    labelText: 'Field $index',
                    border: const OutlineInputBorder(),
                  ),
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

上記のコードを実行して、上の二つの Sliver のケースと同様の手順を踏むと、一度画面外に出たテキストフィールドの**値は破棄されず**保持されていることがわかります。

先述の通り、 `SingleChildScrollView` は `RenderBox` に基づいており、Widgetが画面外に出た時点で破棄されるようなことはないため、テキストフィールドの値も保持されたままになります。

#### ListViewBuilder
次に `ListView.builder` についてみていきます。
コードは以下の通りです。
```dart
class ListViewBuilderTextFiledHome extends HookWidget {
  const ListViewBuilderTextFiledHome({super.key});

  @override
  Widget build(BuildContext context) {
    const textFieldLength = 30;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ListViewBuilderHome'),
      ),
      body: ListView.builder(
        itemCount: textFieldLength,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextFormField(
              initialValue: 'Field $index',
              decoration: InputDecoration(
                labelText: 'Field $index',
                border: const OutlineInputBorder(),
              ),
            ),
          );
        },
      ),
    );
  }
}
```

上記のコードで、一度入力したテキストフィールドを画面外までスクロールして、もう一度表示させると、テキストフィールドの**値は破棄され**、初期値に戻っています。

この理由をコードから調べていきます。
コードは以下です。
```dart
class ListView extends BoxScrollView {
  // 省略
  @override
  Widget buildChildLayout(BuildContext context) {
    if (itemExtent != null) {
      return SliverFixedExtentList(
        delegate: childrenDelegate,
        itemExtent: itemExtent!,
      );
    } else if (itemExtentBuilder != null) {
      return SliverVariedExtentList(
        delegate: childrenDelegate,
        itemExtentBuilder: itemExtentBuilder!,
      );
    } else if (prototypeItem != null) {
      return SliverPrototypeExtentList(
        delegate: childrenDelegate,
        prototypeItem: prototypeItem!,
      );
    }
    return SliverList(delegate: childrenDelegate);
  }
```

`ListView.builder` に渡された子要素のレイアウトを行う `buildChildLayout` メソッドを見てみると、返り値が `SliverList` になっています。
先述の通り、`SliverList` に渡された子要素は画面外に出た時点で破棄されます。

`ListView` では名前に Sliver こそついていないものの、内部的には `SliverList` を使用してレイアウトを行なっています。これが `ListView.builder` の子要素のうち画面外の Widget が破棄される理由になります。

今までの結果を表にまとめると以下のようになります。
| Widget名 | 画面外のWidgetの破棄 |
| ---- | ---- |
| SliverList | ○ |
| SliverToBoxAdapter | × |
| SingleChildScrollView | × |
| ListView.builder | ○ |

### 2. パフォーマンス
次にパフォーマンスの面から比較していきます。
Flutter DevTools の Performance で比較します。
なお、それぞれのコードは前述のコードとほとんど同じですが、より負荷をわかりやすくするために、表示させるテキストフィールドの数を1万に設定しています。
実際のケースでは読み込みに時間がかかる画像や Lottie ファイルなどが負荷のかかる処理になるかと思います。

前提条件として、[Flutter performance profiling](https://docs.flutter.dev/perf/ui-performance)のドキュメントでは、Flutterでは 60fps 以上のパフォーマンスを維持することが目標であると記されています。
Flutter DevTools においても、パフォーマンスが 60fps を下回ると棒グラフが赤く表示されるようになっています。

60fps 以上のパフォーマンスを発揮するためには、1フレームの読み込み時間が約16ms以下である必要があります。今回は1フレームの読み込み時間の方をもとにパフォーマンスを測っていきます。

#### SliverList
まずは `SliverList` です。
画面が描画されるタイミングで、以下の画像のように1フレームの読み込み時間が 9.7ms になっています。
1フレーム 9.7ms なので、単純計算で 103.09fps となります。基準となる 60fps は上回っているので、問題ないと言えるかと思います。
![](https://storage.googleapis.com/zenn-user-upload/f027e44f9ca7-20240621.png)

その後画面をスクロールしてみると、以下の画像のように安定して短い読み込み時間で描画されていることがわかります。
![](https://storage.googleapis.com/zenn-user-upload/d421e1d29b39-20240621.png)

以上のことから、`SliverList` では、画面描画のタイミング、画面スクロールのタイミングの両方においてパフォーマンスに大きな問題はないと言えそうです。

#### SliverToBoxAdapter
次は `SliverToBoxAdapter` です。
画面が描画されるタイミングを見てみると、画像のように1フレームの読み込み時間が 697.8ms になっており、非常に大きな値であることがわかります。
1フレーム 697.8ms　なので、パフォーマンスとしては 1.43fps となります。基準となる 60fps を大きく下回っており、実行した段階でかなり長い時間画面がフリーズするような挙動になりました。
パフォーマンス上大きな問題があることがわかります。
![](https://storage.googleapis.com/zenn-user-upload/088b171ff81a-20240621.png)

また、テキストフィールドのリストをスクロールしていくと以下の画像のように何度も 60fps を下回ることが確認できます。実際の挙動を見ても画面が何度も固まることが確認できます。
![](https://storage.googleapis.com/zenn-user-upload/d5935f9137fa-20240621.png)

以上のことから、`SliverToBoxAdapter` を複数個並べると非常にパフォーマンスが悪くなることがわかります。

#### SingleChildScrollView
次に `SingleChildScrollView` のパフォーマンスを見ていきます。
画面が描画されるタイミングを見てみると、以下の画像のように1フレームの読み込み時間が 734.3ms になっており、非常に大きな値であることがわかります。
パフォーマンスとしては、 1.36fps となっており、 60fps を大きく下回っていることがわかります。
![](https://storage.googleapis.com/zenn-user-upload/71f76f940e4b-20240621.png)

また、画面をスクロールしていくと以下の画像のように何度も 60fps を下回ることが確認できます。実際の画面でもスクロールしようとすると何度も画面が固まってしまうことが確認できました。
![](https://storage.googleapis.com/zenn-user-upload/8186560cc8ed-20240621.png)

以上のことから、 `SligleChildScrollView` でコストのかかる複数の要素を並べるとパフォーマンスが非常に悪くなることがわかります。

#### ListViewBuilder
最後に `ListView.builder` のパフォーマンスを見ていきます。
画面が描画されるタイミングを見てみると、以下の画像のように1フレームの読み込み時間が 9.5ms になっています。
パフォーマンスとしては、105.26fps となっており、60fps を上回っていることがわかります。
![](https://storage.googleapis.com/zenn-user-upload/9d3ff06de009-20240621.png)

また、画面をスクロールしていくと、以下の画像のように、読み込み時間が短く、60fps を上回っていることが確認できます。
![](https://storage.googleapis.com/zenn-user-upload/a1cf9838da83-20240621.png)

以上のことから、`ListView.builder` ではパフォーマンスを維持したまま複数の要素を描画できることがわかります。

今までの結果を表にまとめると以下のようになります。
| Widget名 | パフォーマンス |
| ---- | ---- |
| SliverList | ○ |
| SliverToBoxAdapter | × |
| SingleChildScrollView | × |
| ListView.builder | ○ |

前の章では画面外にでた Widget が破棄されるかどうかを調べましたが、その結果と照らし合わせると、**画面外のWidgetが破棄される場合はパフォーマンスが良くなる**と言えるかと思います。
Widget を破棄しているから当然と言えば当然ですが、目に見えてパフォーマンスの違いを認識することができました。

## まとめ
最後まで読んでいただいてありがとうございました。

Widgetの破棄とパフォーマンスの観点から見て、これからの実装に活かすとすると以下のようなことが言えるかと思います。
+ 細かなスクロールの実装をする必要がない かつ 表示件数が少ない場合
SingleChildScrollView
<br/>
+ 細かなスクロールの実装をする必要がない かつ 表示件数が多い場合
ListView.builder
<br/>
+ 細かなスクロールの実装をする必要がある場合 かつ 表示件数が少ない場合
SliverToBoxAdapter
<br/>
+ 細かなスクロールの実装をする必要がある場合 かつ 表示件数が多い場合
SliverList
<br/>
+ ListView.builder と SliverList では画面外の Widget が破棄されるため注意

なお、Widget の状態の破棄に対しては、flutter_hooks の useTextEditingController などを合わせて使用することで問題に対処できるかと思います。

以上です。

誤っている点などがあればご指摘いただければ幸いです。

### 参考

https://zenn.dev/3ta/articles/5a439a8f0c4b62

https://zenn.dev/shinkano/articles/d010892e4b8b00

https://docs.flutter.dev/ui/layout/scrolling/slivers

https://docs.flutter.dev/perf/ui-performance

https://www.youtube.com/live/YY-_yrZdjGc?si=ZLAQwbhnVgjni0zv

