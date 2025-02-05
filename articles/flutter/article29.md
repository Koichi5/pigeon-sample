## 初めに
今回は [photo_view パッケージ](https://pub.dev/packages/photo_view) を使って、画像のリストを表示する実装を行いたいと思います。スワイプして複数の画像を見られるようなUIを実装します。

## 記事の対象者
+ Flutter 学習者
+ 複数枚の画像を表示させるUIを実装したい方

## 目的
今回は先述の通り [photo_view パッケージ](https://pub.dev/packages/photo_view) で以下の動画のような、画像を複数枚表示させるUIを実装することを目的とします。

https://youtube.com/shorts/ubdbKstD-J4?feature=share

## 導入
[photo_view パッケージ](https://pub.dev/packages/photo_view) の最新バージョンを `pubspec.yaml`に記述

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  photo_view: ^0.14.0
```

または

以下をターミナルで実行
```
flutter pub add photo_view
```

## 実装
今回は以下のような手順で実装します。
1. PhotoView のみで画像を表示
2. GridView と合わせた表示

### 1. PhotoView のみで画像を表示
まずは全画面で画像のリストを表示させる実装を行います。
コードは以下です。
```dart: photo_view_sample
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoViewSample extends StatelessWidget {
  const PhotoViewSample({super.key});

  static const imageUrls = [
    'https://cdn.pixabay.com/photo/2015/05/04/10/16/vegetables-752153_1280.jpg',
    'https://cdn.pixabay.com/photo/2015/12/09/17/11/vegetables-1085063_1280.jpg',
    'https://cdn.pixabay.com/photo/2016/08/11/08/04/vegetables-1584999_1280.jpg',
    'https://cdn.pixabay.com/photo/2015/05/30/01/18/vegetables-790022_1280.jpg',
    'https://cdn.pixabay.com/photo/2017/06/09/16/39/carrots-2387394_1280.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo View Sample'),
      ),
      body: PhotoViewGallery.builder(
        itemCount: imageUrls.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: NetworkImage(
              imageUrls[index],
            ),
          );
        },
        scrollPhysics: const BouncingScrollPhysics(),
        backgroundDecoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
        ),
        enableRotation: true,
        loadingBuilder: (context, event) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
```

それぞれ詳しく見ていきます。

以下の部分では、`PhotoViewGallery.builder` で `itemCount` と `builder` を指定することで画像を表示させるUIを実装しています。

`itemCount: imageUrls.length,` で画像のURLの数を `itemCount` に指定しています。
`PhotoViewGalleryPageOptions` では表示させる画像の設定を行うことができます。
`imageProvider` では画像として表示させる Widget を指定しています。今回はURLの画像を表示させるため、`NetworkImage` で実装しています。
```dart
PhotoViewGallery.builder(
  itemCount: imageUrls.length,
  builder: (context, index) {
    return PhotoViewGalleryPageOptions(
      imageProvider: NetworkImage(
        imageUrls[index],
      ),
    );
  },
```

以下では画像を表示させるUIの背景の設定をしています。
背景色として `canvasColor` を設定しています。
`backgroundDecoration` を指定しない場合は背景色は黒になります。
```dart
backgroundDecoration: BoxDecoration(
  color: Theme.of(context).canvasColor,
),
```

また、以下では表示させる画像を回転させるかどうかを指定できます。
```
enableRotation: true,
```

これで実行すると以下の動画のようになります。

https://youtube.com/shorts/469XibD6AQs

### 2. GridView と合わせた表示
次に GridView と PhotoView を組み合わせてアプリでよく見られるような画像表示のUIを実装します。
コードは以下のようになります。
```dart: photo_view_sample.dart
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class PhotoViewSample extends StatelessWidget {
  PhotoViewSample({Key? key}) : super(key: key);

  final List<String> imageUrls = [
    'https://cdn.pixabay.com/photo/2015/05/04/10/16/vegetables-752153_1280.jpg',
    'https://cdn.pixabay.com/photo/2015/12/09/17/11/vegetables-1085063_1280.jpg',
    'https://cdn.pixabay.com/photo/2016/08/11/08/04/vegetables-1584999_1280.jpg',
    'https://cdn.pixabay.com/photo/2015/05/30/01/18/vegetables-790022_1280.jpg',
    'https://cdn.pixabay.com/photo/2017/06/09/16/39/carrots-2387394_1280.jpg',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo View Sample'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
        ),
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () async {
              openPhotoViewGallery(context, index);
            },
            child: Image.network(imageUrls[index], fit: BoxFit.cover),
          );
        },
      ),
    );
  }

  Future<void> openPhotoViewGallery(
      BuildContext context, int initialIndex) async {
    await showDialog(
      context: context,
      builder: (context) {
        return GalleryScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
        );
      },
    );
  }
}

class GalleryScreen extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const GalleryScreen({
    Key? key,
    required this.imageUrls,
    required this.initialIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close,
            color: Colors.white,
          ),
        ),
        Expanded(
          child: PhotoViewGallery.builder(
            itemCount: imageUrls.length,
            builder: (context, index) {
              return PhotoViewGalleryPageOptions(
                imageProvider: NetworkImage(imageUrls[index]),
                initialScale: PhotoViewComputedScale.contained,
              );
            },
            pageController: PageController(initialPage: initialIndex),
            backgroundDecoration: const BoxDecoration(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
```

それぞれ詳しく見ていきます。

以下では横3列の GridView を実装しています。それぞれの要素は `Image.network` にしてあり、タップされた際に `openPhotoViewGallery` 関数が実行されるようになっています。
```dart
GridView.builder(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 3,
  ),
  itemCount: imageUrls.length,
  itemBuilder: (context, index) {
    return InkWell(
      onTap: () async {
        openPhotoViewGallery(context, index);
      },
      child: Image.network(imageUrls[index], fit: BoxFit.cover),
    );
  },
),
```

以下では、 GridView の画像をタップされた際の処理を実装しています。
画像がタップされた場合には `showDialog` でダイアログを表示し、その子要素として `GalleryScreen` を表示させています。また、タップされた画像を保持するために画像のインデックスを `initialIndex` として渡しています。
```dart
Future<void> openPhotoViewGallery(
  BuildContext context, int initialIndex
) async {
    await showDialog(
      context: context,
      builder: (context) {
        return GalleryScreen(
          imageUrls: imageUrls,
          initialIndex: initialIndex,
      );
    },
  );
}
```

以下では `PhotoViewGallery.builder` を実装しており、基本的には先ほどの実装と同様です。
```dart
PhotoViewGallery.builder(
  itemCount: imageUrls.length,
  builder: (context, index) {
    return PhotoViewGalleryPageOptions(
      imageProvider: NetworkImage(imageUrls[index]),
      initialScale: PhotoViewComputedScale.contained,
    );
  },
  pageController: PageController(initialPage: initialIndex),
  backgroundDecoration: const BoxDecoration(
    color: Colors.transparent,
  ),
),
```

なお、以下では `pageController` として `PageController(initialPage: initialIndex)` を渡すことで初めに表示される画像の番号を指定しています。
```dart
pageController: PageController(initialPage: initialIndex),
```

これで実行すると、以下のように GridView から複数枚の画像のプレビューを表示できるようになります。
https://youtube.com/shorts/ubdbKstD-J4?feature=share

## まとめ
最後まで読んでいただいてありがとうございました。

今回は photo_view パッケージを用いて複数の画像を表示させるUIを作成しました。
複数の画像を扱う場面は多くあると思うので、非常に便利だと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/photo_view

