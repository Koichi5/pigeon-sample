## 初めに
今回は [What’s new in Flutter 3.24](https://medium.com/flutter/whats-new-in-flutter-3-24-6c040f87d1e4) の記事で紹介されていた、 `SliverResizingHeader`, `PinnedHeaderSliver` を使った実装を通して、使い方を見ていきたいと思います。

## 記事の対象者
+ Flutter 学習者
+ 新しく追加された Sliver の使い方に興味がある方

## 目的
今回は上記の通り `SliverResizingHeader`, `PinnedHeaderSliver` の使い方を理解することを目的とします。今までの実装方法などと比較したり、SwiftUI の見た目との比較も行いたいと思います。

## 準備
今回は Flutter 3.24 を用いた実装を行うため、 Flutter のアップグレードをしておく必要があります。
ターミナルで以下のコマンドを実行して、 Flutter version を 3.24 以上にしておきます。
```
flutter upgrade
```

筆者の環境では `3.24.0-1.0.pre.490` を使って実装しています。

## SliverResizingHeader
### SliverResizingHeader とは
まずは `SliverResizingHeader` から見ていきたいと思います。
[Flutter公式のページ](https://api.flutter.dev/flutter/widgets/SliverResizingHeader-class.html) の記述を見ると、「CustomScrollViewの先頭に固定され、スクロールに反応して最小および最大の範囲プロトタイプの固有サイズの間でリサイズする」という旨の記述があります。
この `SliverResizingHeader` を使うことで、今まで使用していた `SliverPersistentHeaderDelegate` が不要になります。また、ヘッダーの最小値、最大値の設定が不要になります。 `SliverPersistentHeaderDelegate` を用いた実装よりも柔軟性は劣りますが、その文比較的簡単に Sliver を扱うことができるようになります。

### 実装
次は実際に `SliverResizingHeader` を用いた実装を行なっていきます。

なお、今回は以下のパッケージを使用するため、 `pubspec.yaml` に追加するか、 `flutter pub add` で追加しておきます。
+ [flutter_hooks](https://pub.dev/packages/flutter_hooks)
+ [gap](https://pub.dev/packages/gap)
+ [table_calendar](https://pub.dev/packages/table_calendar)

コードは以下の通りです。
```dart
class SliverResizingHeaderSample extends HookWidget {
  const SliverResizingHeaderSample({super.key});

  @override
  Widget build(BuildContext context) {
    final scrollController = useScrollController();

    useEffect(() {
      return scrollController.dispose;
    }, [scrollController]);

    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          controller: scrollController,
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              SliverResizingHeader(
                minExtentPrototype: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Calendar',
                  ),
                ),
                maxExtentPrototype: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Calendar',
                        ),
                      ),
                      TableCalendar(
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: DateTime.now(),
                      ),
                      const Gap(4),
                    ],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Calendar',
                          ),
                        ),
                        TableCalendar(
                          firstDay: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDay:
                              DateTime.now().add(const Duration(days: 365)),
                          focusedDay: DateTime.now(),
                        ),
                        const Gap(4),
                      ],
                    ),
                  ),
                ),
              ),
              const ItemList(),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  const ItemList({
    super.key,
    this.itemCount = 50,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return Card(
            color: colorScheme.onSecondary,
            child: ListTile(
              textColor: colorScheme.secondary,
              title: Text('Item $index'),
            ),
          );
        },
        childCount: itemCount,
      ),
    );
  }
}
```

これで実行すると以下の動画のようにカレンダーの表示/非表示をスクロールによって変化させることができます。

https://youtube.com/shorts/uRQkQzEmDUU?feature=share

それぞれ詳しく見ていきます。

以下では、ページで使用する `useScrollController` を定義しています。
`useEffect` のリターン文に `scrollController.dispose` を渡すことで、 Widget が破棄された時に `scrollController` を破棄しています。
```dart
final scrollController = useScrollController();

useEffect(() {
  return scrollController.dispose;
}, [scrollController]);
```

以下では `SafeArea` で全体を囲むことで各端末で表示が崩れないようにしています。また、他の Sliver と同様に `SliverResizingHeader` は `CustomScrollView` の配下に配置します。 `controller` には先ほど定義した `scrollController` を渡しています。
```dart
return Scaffold(
  body: SafeArea(
    child: CustomScrollView(
      controller: scrollController,
      slivers: <Widget>[
        SliverResizingHeader(
```

ここから `SliverResizingHeader` の実装を見ていきます。
コードの実装を見る前に `SliverResizingHeader` の概要をさっと確認しておきます。

以下のコードからもわかるとおり、 `SliverResizingHeader` は以下の三つのプロパティしか持っていない非常にシンプルな作りになっています。
+ minExtentPrototype
+ maxExtentPrototype
+ child

```dart
class SliverResizingHeader extends StatelessWidget {
  const SliverResizingHeader({
    super.key,
    this.minExtentPrototype,
    this.maxExtentPrototype,
    this.child,
  });

  final Widget? minExtentPrototype;
  final Widget? maxExtentPrototype;
  final Widget? child;
```

それぞれ分けてみていきます。

**minExtentPrototype**
`minExtentPrototype` は Sliver で表示される要素の最小の範囲を指定するためのプロパティです。
コードの説明文では 「`SizedBox` を用いて `minExtentPrototype` の指定を行うことができる」とありますが、 `SizedBox` 以外でも指定することができます。
そしてこの `minExtentPrototype` に指定した Widget は**実際の画面では見えない**ようになっています。
実際に描画されることはありませんが、 Sliver 部分のレイアウトを決定するために一度だけ使用されます。
`minExtentPrototype` が null の場合、デフォルトの最小範囲は0になります。

**maxExtentPrototype**
`maxExtentPrototype` は Sliver で表示される要素の最大の範囲を指定するためのプロパティです。
こちらも `minExtentPrototype` と同様に `SizedBox` 以外でも指定することができ、**実際の画面では見えない**ようになっています。 Sliver 部分のレイアウトを決定するために一度だけ使用されます。
`maxExtentPrototype` が null の場合は child に指定した Widget の大きさに合わせて最大の範囲が設定されます。

**child**
`child` は**実際の画面で見える**形で表示される Widget です。
先述の `minExtentPrototype` と `maxExtentPrototype` の大きさをもとに child が描画されます。

以上のことを踏まえてコードを見ていきます。

以下では Sliver 部分の最小のサイズを決定する `minExtentPrototype` を指定しています。
具体的には、 `Padding` に囲まれた単純な `Text` で実装しています。
この部分のサイズをもとに `child` の最小サイズを決定しています。
```dart
minExtentPrototype: const Padding(
  padding: EdgeInsets.all(8.0),
  child: Text(
    'Calendar',
  ),
),
```

以下では Sliver 部分の最大のサイズを決定する `maxExtentPrototype` を実装しています。
先ほど `minExtentPrototype` で指定したテキストに加えて、 `TableCalendar` と `Gap` を表示しています。この部分のサイズをもとに `child` の最大サイズを決定しています。
```dart
maxExtentPrototype: SingleChildScrollView(
  child: Column(
    children: [
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'Calendar',
        ),
      ),
      TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
        focusedDay: DateTime.now(),
      ),
      const Gap(4),
    ],
  ),
),
```

以下の部分では実際に画面に表示される `child` を実装しています。
基本的には `maxExtentPrototype` の方で実装した内容と同じですが、 overflow を防ぐために `SingleChildScrollView` を使用したり、背景色を設定するために `Container` を使用したりしています。
```dart
child: SingleChildScrollView(
  child: Container(
    color: Theme.of(context).colorScheme.surface,
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Calendar',
          ),
        ),
        TableCalendar(
          firstDay: DateTime.now().subtract(const Duration(days: 365)),
          lastDay: DateTime.now().add(const Duration(days: 365)),
          focusedDay: DateTime.now(),
        ),
        const Gap(4),
      ],
    ),
  ),
),
```

`ItemList` では `SliverList` を用いてリストを表示させていますが、今回の趣旨とは外れるため、解説は割愛します。

これで冒頭で提示した以下の動画のような挙動になるかと思います。

https://youtube.com/shorts/uRQkQzEmDUU?feature=share

### 少し詳しく
以下では `SliverResizingHeader` の実装を少し詳しく掘り下げてみていきたいと思います。
使い方のみ知りたい方は読み飛ばしていただいても構いません。

`SliverResizingHeader` は以下のようになっています。
返している値は `_SliverResizingHeader` であり、 `minExtentPrototype`, `maxExtentPrototype` に関しては `_excludeFocus` 関数の返り値を指定しています。
```dart
Widget build(BuildContext context) {
  return _SliverResizingHeader(
    minExtentPrototype: _excludeFocus(minExtentPrototype),
    maxExtentPrototype: _excludeFocus(maxExtentPrototype),
    child: child ?? const SizedBox.shrink(),
  );
}
```

`_excludeFocus` は以下のような内容になっていて、 `ExcludeFocus` でラップされたウィジェットとその子孫ウィジェットは、フォーカスを受け取ることができなくなります。具体的には、 `ExcludeFocus` 内のフォーカス可能な要素（テキストフィールドやボタンなど）は、キーボードやその他の入力デバイスからの入力を受け付けなくなります。これらは意図しない入力を防ぐための処理であると考えられます。
```dart
Widget? _excludeFocus(Widget? extentPrototype) {
  return extentPrototype != null ? ExcludeFocus(child: extentPrototype) : null;
}
```

次に実際に返却されている `_SliverResizingHeader` の実装を見ていきます。
`_SliverResizingHeader` では実際には以下のように `_RenderSliverResizingHeader` を返却しています。 したがって、次は `_RenderSliverResizingHeader` を見ていきます。
```dart
@override
_RenderSliverResizingHeader createRenderObject(BuildContext context) {
  return _RenderSliverResizingHeader();
}
```

`_RenderSliverResizingHeader` では以下にある通り、プロパティにあった `minExtentPrototype`, `maxExtentPrototype`, `child` を内部で使用しています。
```dart
class _RenderSliverResizingHeader extends RenderSliver with SlottedContainerRenderObjectMixin<_Slot, RenderBox>, RenderSliverHelpers {
  RenderBox? get minExtentPrototype => childForSlot(_Slot.minExtent);
  RenderBox? get maxExtentPrototype => childForSlot(_Slot.maxExtent);
  RenderBox? get child => childForSlot(_Slot.child);
```

`_RenderSliverResizingHeader` の実装で特に注目したいのが `performLayout` メソッドの部分です。多少省略している部分はありますが、実際のコードは以下のようになっています。
この `performLayout` では 「`maxExtentPrototype` と `minExtentPrototype` をもとに `child` のレイアウトを行なっている」ということがわかります。
以下で少し切り分けてみていきます。
```dart
@override
void performLayout() {
  final SliverConstraints constraints = this.constraints;
  final BoxConstraints prototypeBoxConstraints = constraints.asBoxConstraints();

  double minExtent = 0;
  if (minExtentPrototype != null) {
    minExtentPrototype!.layout(prototypeBoxConstraints, parentUsesSize: true);
    minExtent = boxExtent(minExtentPrototype!);
  }

  late final double maxExtent;
  if (maxExtentPrototype != null) {
    maxExtentPrototype!.layout(prototypeBoxConstraints, parentUsesSize: true);
    maxExtent = boxExtent(maxExtentPrototype!);
  } else {
    final Size childSize = child!.getDryLayout(prototypeBoxConstraints);
    maxExtent = switch (constraints.axis) {
      Axis.vertical => childSize.height,
      Axis.horizontal => childSize.width,
    };
  }

  final double scrollOffset = constraints.scrollOffset;
  final double shrinkOffset = math.min(scrollOffset, maxExtent);
  final BoxConstraints boxConstraints = constraints.asBoxConstraints(
    minExtent: minExtent,
    maxExtent: math.max(minExtent, maxExtent - shrinkOffset),
  );
  child?.layout(boxConstraints, parentUsesSize: true);

// 省略
```

以下の部分では、 Sliver の最小サイズを決めています。
初めに初期値0の `minExtent` という変数を用意しています。
次に、プロパティにもあった `minExtentPrototype` のレイアウトを行います。
この時のレイアウトは親のウィジェットの大きさを引き継ぐ形で行われます。
そして、 `minExtent` には `boxExtent` メソッドの引数に `minExtentPrototype` を代入した返り値を入れています。
```dart
double minExtent = 0;
if (minExtentPrototype != null) {
  minExtentPrototype!.layout(prototypeBoxConstraints, parentUsesSize: true);
  minExtent = boxExtent(minExtentPrototype!);
}
```

ちなみに `boxExtent` メソッドの内容は以下のようになっており、スクロールする方向が縦の場合は引数に入っている `RenderBox` の高さを、横の場合は幅を代入するものです。

今回実装しているカレンダーを含むヘッダーのスクロール方向は縦であるため、 `boxExtent` には `minExtentPrototype` の高さが代入されることになります。
```dart
double boxExtent(RenderBox box) {
  assert(box.hasSize);
  return switch (constraints.axis) {
    Axis.vertical => box.size.height,
    Axis.horizontal => box.size.width,
  };
}
```
これで `minExtent` には `minExtentPrototype` に指定された Widget の高さが代入されました。

次に以下の部分では Sliver の最大サイズを決めています。
基本的には `minExtent` としていることは同じで、 `maxExtentPrototype` のレイアウトを行い、その大きさをもとに `maxExtent` の大きさを変更しています。

1点異なる点して、 `maxExtentPrototype` の指定がなかった場合は `child` の大きさをもとに `maxExtent` が決定されます。
これは [Flutter公式ドキュメント](https://api.flutter.dev/flutter/widgets/SliverResizingHeader-class.html)の以下の記述と整合的であると言えます。
> If maxExtentPrototype is null then the default maximum extent is based on the child's intrisic size.
>
> 日本語訳
> もし maxExtentPrototype が null の場合、デフォルトの最大値は child の大きさによって決まります
```dart
late final double maxExtent;
if (maxExtentPrototype != null) {
  maxExtentPrototype!.layout(prototypeBoxConstraints, parentUsesSize: true);
  maxExtent = boxExtent(maxExtentPrototype!);
} else {
  final Size childSize = child!.getDryLayout(prototypeBoxConstraints);
  maxExtent = switch (constraints.axis) {
    Axis.vertical => childSize.height,
    Axis.horizontal => childSize.width,
  };
}
```

そして以下の部分で `child` のレイアウトを行なっています。
この時、 `layout` メソッドの第一引数に渡されている `boxConstraints` は先ほど調整された `minExtent`, `maxExtent` をもとに作成された `BoxConstraints` です。
この部分で `child` は `minExtentPrototype`, `maxExtentPrototype` によってレイアウトされていると言えます。
```dart
final double scrollOffset = constraints.scrollOffset;
final double shrinkOffset = math.min(scrollOffset, maxExtent);
final BoxConstraints boxConstraints = constraints.asBoxConstraints(
  minExtent: minExtent,
  maxExtent: math.max(minExtent, maxExtent - shrinkOffset),
);
child?.layout(boxConstraints, parentUsesSize: true);
```

最後に以下の部分で `child` の描画を行なっています。
先述の通り `minExtentPrototype`, `maxExtentPrototype` は画面に表示されないため、この `paint` メソッドには `child` のみが登場します。
```dart
@override
void paint(PaintingContext context, Offset offset) {
  if (child != null && geometry!.visible) {
    final SliverPhysicalParentData childParentData = child!.parentData! as SliverPhysicalParentData;
    context.paintChild(child!, offset + childParentData.paintOffset);
  }
}
```

このようにして、 `minExtentPrototype`, `maxExtentPrototype` は `child` のレイアウトを行うだけで、実際には描画されないことがわかります。

## PinnedHeaderSliver
### PinnedHeaderSliver とは
次に `PinnedHeaderSliver` を見ていきたいと思います。
[Flutter公式のページ](https://api.flutter.dev/flutter/widgets/PinnedHeaderSliver-class.html) の記述を見ると、「 PinnedHeaderSliver は**自身の child を CustomScrollView の最上部に保持する**」という旨の記述があります。

「`CustomScrollView` の最上部に AppBar を表示させたままにしておく」という挙動を実現したい時、従来では以下のどちらかの方法で実現していました。
+ [SliverAppBar](https://api.flutter.dev/flutter/material/SliverAppBar-class.html) の `pinned` プロパティを `true` にする
+ [SliverPersistentHeader](https://api.flutter.dev/flutter/widgets/SliverPersistentHeader-class.html) の `pinned` プロパティを `true` にする

一方で `PinnedHeaderSliver` を用いた実装では、 `CustomScrollView` の最上部に保持しておきたい Widget を `PinnedHeaderSliver` の `child` に指定するだけで実現できます。

### 実装
次は実際に `PinnedHeaderSliver` を用いた実装を行なっていきます。
今回は [What’s new in Flutter 3.24](https://medium.com/flutter/whats-new-in-flutter-3-24-6c040f87d1e4) の `PinnedHeaderSliver` の部分で紹介されていた、 iOS のヘッダーの再現を行いたいと思います。
コードは以下の通りです。
```dart: pinned_header_sliver_sample.dart
class PinnedHeaderSliverSample extends HookWidget {
  const PinnedHeaderSliverSample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isScrolled = useState(false);
    final scrollController = useScrollController();
    final headerColor =
        isScrolled.value ? const Color(0xFFF7F8F7) : const Color(0xFFF2F2F7);

    useEffect(() {
      void listener() {
        if (scrollController.offset > 0 && !isScrolled.value) {
          isScrolled.value = true;
        } else if (scrollController.offset <= 0 && isScrolled.value) {
          isScrolled.value = false;
        }
      }

      scrollController.addListener(listener);
      return () => scrollController.removeListener(listener);
    }, [scrollController]);

    final Widget header = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: headerColor,
      child: AnimatedCrossFade(
        duration: const Duration(milliseconds: 300),
        crossFadeState: isScrolled.value
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        firstChild: Padding(
          padding: const EdgeInsets.only(
            top: 32,
            left: 16,
          ),
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        secondChild: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(
              thickness: 0.5,
              height: 0.5,
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: headerColor,
        child: SafeArea(
          left: false,
          right: false,
          bottom: false,
          child: CustomScrollView(
            controller: scrollController,
            slivers: <Widget>[
              PinnedHeaderSliver(
                child: header,
              ),
              const ItemList(),
            ],
          ),
        ),
      ),
    );
  }
}

class ItemList extends StatelessWidget {
  const ItemList({
    Key? key,
    this.itemCount = 25,
  }) : super(key: key);

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(
        vertical: 8,
        horizontal: 16,
      ),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Padding(
                  padding: index == 0
                      ? const EdgeInsets.only(
                          left: 24,
                          top: 12,
                          right: 24,
                          bottom: 4,
                        )
                      : const EdgeInsets.symmetric(
                          vertical: 3,
                          horizontal: 24,
                        ),
                  child: Text(
                    'item $index',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                );
              },
              separatorBuilder: (context, index) {
                return const Divider(
                  indent: 16,
                  thickness: 0.5,
                );
              },
              itemCount: itemCount,
            ),
          ),
        ),
      ),
    );
  }
}
```

上記のコードで実行すると以下のような挙動になります。
https://youtube.com/shorts/T8TLl_xsWmU

SwiftUI を用いた実装をすると以下のような挙動になります。
https://youtu.be/7Q-sL2KHNRM

公式ページにある通り、ある程度高い再現度で実装できているかと思います。

ここからは `PinnedHeaderSliverSample` のコードを詳しく見ていきます。

以下ではスクロールの状態とヘッダーの色を定義しています。
`SliverResizingHeaderSample` の実装と同様に `useScrollController` を用いてスクロールの状態を管理します。
```dart
final isScrolled = useState(false);
final scrollController = useScrollController();
final headerColor =
        isScrolled.value ? const Color(0xFFF7F8F7) : const Color(0xFFF2F2F7);
```

以下では `useEffect` で `scrollController` の設定を行なっています。
`scrollController` の `offset` が正の値であり、スクロールされていない時は `isScrolled.value` を `true` にしています。
```dart
useEffect(() {
  void listener() {
    if (scrollController.offset > 0 && !isScrolled.value) {
      isScrolled.value = true;
    } else if (scrollController.offset <= 0 && isScrolled.value) {
      isScrolled.value = false;
    }
  }

  scrollController.addListener(listener);
  return () => scrollController.removeListener(listener);
}, [scrollController]);
```

以下では `AnimatedContainer` を用いて `header` を定義しています。
`duration` ではアニメーションの時間、 `color` では先ほど定義した `headerColor` を定義しています。
`firstChild` では大きな文字のタイトルを定義しており、 `secondChild` ではスクロールが発生した際に表示される小さな文字のタイトルを定義しています。

`header` に関してはスクロールされたかどうかを検知して表示する Widget を変更するだけで実装できますが、今回は iOS のヘッダーに寄せるために `AnimatedContainer` を用いて実装しています。
```dart
final Widget header = AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  color: headerColor,
  child: AnimatedCrossFade(
    duration: const Duration(milliseconds: 300),
    crossFadeState: isScrolled.value
      ? CrossFadeState.showSecond
      : CrossFadeState.showFirst,
    firstChild: Padding(
      padding: const EdgeInsets.only(
        top: 32,
        left: 16,
      ),
      child: Text(
        'Settings',
        style: Theme.of(context).textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    secondChild: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      const Divider(
        thickness: 0.5,
        height: 0.5,
      ),
    ],
  ),
  ),
);
```

以下では `PinnedHeaderSliver` を用いて `CustomScrollView` の中にヘッダーを追加しています。 `PinnedHeaderSliver` の `child` に先ほど実装した `header` を入れることで `header` に定義した Widget が `CustomScrollView` の上部に固定されるようになります。
```dart
CustomScrollView(
  controller: scrollController,
  slivers: <Widget>[
    PinnedHeaderSliver(
      child: header,
    ),
    const ItemList(),
  ],
),
```

これで先ほど提示した動画のように iOS のヘッダーに似たヘッダーが実装できるかと思います。

https://youtube.com/shorts/T8TLl_xsWmU

:::details SwiftUIでの実装
SwiftUI を用いた実装コードは以下の通りです。
```swift
import SwiftUI

struct ListSampleView: View {
    let itemCount = 25
    var body: some View {
        NavigationStack {
            List {
                ForEach(0 ..< 24) { index in
                    Text("item \(index)")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
```

<br/>
Flutter と SwiftUI の差異
先ほど実装した Flutter のコードではスクロールした際に「Settings」タイトルは動きませんが、 SwiftUI ではスクロールに合わせてタイトルが下に移動します。
このような細かい挙動を再現するためには追加で実装コストがかかりますが、一目見ただけでは判断できない程度まで再現できることがわかります。
| Flutter | SwiftUI |
| ---- | ---- |
| ![](https://storage.googleapis.com/zenn-user-upload/c9711adb1452-20240811.png =300x) | ![](https://storage.googleapis.com/zenn-user-upload/030a7356b51b-20240811.png =275x) |
:::

以上です。

## まとめ
最後まで読んでいただいてありがとうございました。

Flutter3.24 のアップデートでは、 Sliver がよりシンプルに記述できるようになりました。
ドキュメントにもあるとおり、今回紹介した二つの Widget は今までの実装よりも狭い用途で使用するものですが、その分考慮すべき項目が少なくなっていて扱いやすいと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://medium.com/flutter/whats-new-in-flutter-3-24-6c040f87d1e4

http://api.flutter.dev/flutter/widgets/SliverResizingHeader-class.html

http://api.flutter.dev/flutter/widgets/PinnedHeaderSliver-class.html
