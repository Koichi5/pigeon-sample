## 初めに
今回は画像から色を抽出する方法についてまとめたいと思います。
画像から色を抽出できれば、ユーザーの色をカスタマイズしたり、詳細画面を画像に合わせて変更したりできるようになります。

## 記事の対象者
+ Flutter 学習者
+ アプリのUIに少し工夫を加えたい方

## 目的
今回は上記の通り画像から色を抽出して使うことを目的とします。
画像から色を抽出することができる [palette_generator](https://pub.dev/packages/palette_generator) パッケージを使用します。

今回の実装では、以下のように画像から色をとってきて表示できるようにします。
![](https://storage.googleapis.com/zenn-user-upload/684476f042f2-20240925.png =300x)

なお、今回実装するコードは以下の GitHub でも公開しているので、よろしければご参照ください。
https://github.com/Koichi5/functions-sample/tree/main/lib/storage_sample/palette_generator

## 導入
以下のパッケージの最新バージョンを `pubspec.yaml`に記述
+ [flutter_hooks](https://pub.dev/packages/flutter_hooks)
+ [image_picker](https://pub.dev/packages/flutter_hooks)
+ [palette_generator](https://pub.dev/packages/palette_generator)

```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  go_router: ^12.1.3

dev_dependencies:
  flutter_test:
    sdk: flutter

  flutter_hooks: ^0.20.5
  image_picker: ^1.1.2
  palette_generator: ^0.3.3+4
```

または

以下をターミナルで実行
```
flutter pub add flutter_hooks image_picker palette_generator
```

## 実装
次に画像から色を抽出する実装を行います。
実装は以下の２ステップで行います。
使用方法だけであれば１ステップ目のみであとは読み飛ばしていただいて問題ないかと思います。
1. 画像から色を抽出する簡単なサンプル
2. アイコン画像から色を抽出する

### 1. 画像から色を抽出する簡単なサンプル
まずはユーザー選択した画像から色を抽出するサンプルを実装していきます。
この章では以下の画像のように抽出した色の一覧を表示できるまで実装を進めます。
![](https://storage.googleapis.com/zenn-user-upload/684476f042f2-20240925.png =300x)

まずは以下のコードのようなで `HookWidget` を作ります。
```dart
class PaletteGeneratorSample extends HookWidget {
  const PaletteGeneratorSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
```

次に画像とパレットの状態を `image`, `paletteGenerator` として定義しておきます。
```diff dart
class PaletteGeneratorSample extends HookWidget {
  const PaletteGeneratorSample({super.key});

  @override
  Widget build(BuildContext context) {
+   final image = useState<File?>(null);
+   final paletteGenerator = useState<PaletteGenerator?>(null);

    return const Placeholder();
  }
}
```

次に以下のようにカラーパレットを生成するためのコードを追加します。
`fromImageProvider` の引数に画像ファイルを渡すことで、その画像から色を抽出してパレットを生成することができます。
生成する色の数なども調整することができます。
```diff dart
class PaletteGeneratorSample extends HookWidget {
  const PaletteGeneratorSample({super.key});

  @override
  Widget build(BuildContext context) {
    final image = useState<File?>(null);
    final paletteGenerator = useState<PaletteGenerator?>(null);

+   Future<void> generatePalette() async {
+     if (image.value != null) {
+       final imageProvider = FileImage(image.value!);
+       final generator = await PaletteGenerator.fromImageProvider(
+         imageProvider,
+         size: const Size(100, 100),
+         maximumColorCount: 10,
+       );
+       paletteGenerator.value = generator;
+     }
+   }
    return const Placeholder();
  }
}
```

次に画像を取得するための `pickImage` を追加します。
`image_picker` でギャラリーから画像を取得し、先ほどの `generatePalette` メソッドを実行することで、取得した画像から色を抽出することができるようになります。
```diff dart
class PaletteGeneratorSample extends HookWidget {
  const PaletteGeneratorSample({super.key});

  @override
  Widget build(BuildContext context) {
    final image = useState<File?>(null);
    final paletteGenerator = useState<PaletteGenerator?>(null);

    Future<void> generatePalette() async {
      if (image.value != null) {
        final imageProvider = FileImage(image.value!);
        final generator = await PaletteGenerator.fromImageProvider(
          imageProvider,
          size: const Size(100, 100),
          maximumColorCount: 10,
        );
        paletteGenerator.value = generator;
      }
    }

+   Future<void> pickImage() async {
+     final picker = ImagePicker();
+     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
+
+     if (pickedFile != null) {
+       image.value = File(pickedFile.path);
+       generatePalette();
+     }
+   }

    return const Placeholder();
  }
}
```

:::message
image_picker で画像を選択する際には iOS で権限の設定が必要になります。
設定をしていない場合は以下の対応が必要になります。

`ios > Runner > Info.plist` に、カメラとライブラリへアクセスする理由を追加
```markdown
<plist version="1.0">
<dict>
    ... 他の設定
    <key>NSCameraUsageDescription</key>
    <string>カメラを使用する理由</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>フォトライブラリを使用する理由</string>
</dict>
</plist>
```
:::

最後にUI部分を追加していきます。
全体コードは以下の通りです。
```dart
class PaletteGeneratorSample extends HookWidget {
  const PaletteGeneratorSample({super.key});

  @override
  Widget build(BuildContext context) {
    final image = useState<File?>(null);
    final paletteGenerator = useState<PaletteGenerator?>(null);

    Future<void> generatePalette() async {
      if (image.value != null) {
        final imageProvider = FileImage(image.value!);
        final generator = await PaletteGenerator.fromImageProvider(
          imageProvider,
          size: const Size(100, 100),
          maximumColorCount: 10,
        );
        paletteGenerator.value = generator;
      }
    }

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        image.value = File(pickedFile.path);
        generatePalette();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Palette Generator Sample'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: pickImage,
                child: const Text('Select Image'),
              ),
              if (image.value != null) ...[
                Image.file(
                  image.value!,
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: 20),
                if (paletteGenerator.value != null) ...[
                  const Text('Extracted Colors:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      buildColorInfo('Dominant',
                          paletteGenerator.value!.dominantColor?.color),
                      buildColorInfo('Vibrant',
                          paletteGenerator.value!.vibrantColor?.color),
                      buildColorInfo('Light Vibrant',
                          paletteGenerator.value!.lightVibrantColor?.color),
                      buildColorInfo('Dark Vibrant',
                          paletteGenerator.value!.darkVibrantColor?.color),
                      buildColorInfo(
                          'Muted', paletteGenerator.value!.mutedColor?.color),
                      buildColorInfo('Light Muted',
                          paletteGenerator.value!.lightMutedColor?.color),
                      buildColorInfo('Dark Muted',
                          paletteGenerator.value!.darkMutedColor?.color),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'All Colors:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: paletteGenerator.value!.colors.map((color) {
                      return buildColorInfo('', color);
                    }).toList(),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget buildColorInfo(String label, Color? color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          color: color ?? Colors.transparent,
        ),
        const SizedBox(height: 5),
        if (label.isNotEmpty)
          Text(
            label,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        Text(
          color?.value.toRadixString(16).toUpperCase() ?? 'N/A',
          style: const TextStyle(fontSize: 10),
        ),
      ],
    );
  }
}
```

UI部分について少し見ていきます。

以下ではパレットに用意されているカラーの名前と対応する色を独自Widgetに入れて表示させています。それぞれの色については後述します。
```dart
children: [
  buildColorInfo('Dominant',
      paletteGenerator.value!.dominantColor?.color),
  buildColorInfo('Vibrant',
      paletteGenerator.value!.vibrantColor?.color),
  buildColorInfo('Light Vibrant',
      paletteGenerator.value!.lightVibrantColor?.color),
  buildColorInfo('Dark Vibrant',
      paletteGenerator.value!.darkVibrantColor?.color),
  buildColorInfo(
      'Muted', paletteGenerator.value!.mutedColor?.color),
  buildColorInfo('Light Muted',
      paletteGenerator.value!.lightMutedColor?.color),
  buildColorInfo('Dark Muted',
      paletteGenerator.value!.darkMutedColor?.color),
],
```

以下では画像から取得できた色を全て並べて表示しています。
今回はパレットを生成する際の `maximumColorCount` を 10 に設定していたので、最大で10色が表示されるようになっています。
```dart
Wrap(
  spacing: 10,
  runSpacing: 10,
  children: paletteGenerator.value!.colors.map((color) {
    return buildColorInfo('', color);
  }).toList(),
),
```

これで以下の画像のように選択した色のパレットが表示されるようになったかと思います。

![](https://storage.googleapis.com/zenn-user-upload/684476f042f2-20240925.png =300x)

それぞれの色に関して詳しく見ていきます。

**dominant color**
dominant(支配的な)という名前の通り、画像内で最も頻繁に出現する色です。
コードでも以下のような記述があります。
> The dominant color (the color with the largest population).
> [日本語訳] 支配的な色（最も多く出現する色）

実際のコードを見てみても、`population` が色の出現頻度を表し、その頻度で並べた時の一つ目の要素として `_dominantColor` が指定されていることがわかります。
```dart
void _sortSwatches() {
  if (paletteColors.isEmpty) {
    _dominantColor = null;
    return;
  }
  // Sort from most common to least common.
  paletteColors.sort((PaletteColor a, PaletteColor b) {
    return b.population.compareTo(a.population);
  });
  _dominantColor = paletteColors[0];
}
```

**lightVibrant**
明るい鮮やかな色。輝度が明るい、鮮やかな色の特徴を持つ。

**vibrant**
鮮やかな色。明るくも暗くもない、鮮やかな色の特徴を持つ。

**darkVibrant**
暗い鮮やかな色。輝度が暗い、鮮やかな色の特徴を持つ。

**lightMuted**
明るい落ち着いた色。輝度が明るい、落ち着いた色の特徴を持つ。

**muted**
落ち着いた色。明るくも暗くもない、落ち着いた色の特徴を持つ。

**darkMuted**
暗い落ち着いた色。輝度が暗い、落ち着いた色の特徴を持つ。

`dominantColor` 以外の色は図にまとめると以下のようになるかと思います。
|  | 明るい | 普通 | 暗い |
| ---- | ---- | ---- | ---- |
| **鮮やか** | lightVibrant | vibrant | darkVibrant |
| **落ち着いた** | lightMuted | muted | darkMuted |

### 2. アイコン画像から色を抽出する
次に実際の使用ケースを想定して、アイコン画像から色を抽出する実装を行います。
この実装を進めるにあたって、Cloud Firestore, Cloud Storage の設定を済ませておく必要があります。

また、今回扱うメインが `palette_generator` であることから、 Cloud Firestore, Cloud Storage の実装をかなり簡素化しています。以下の記事ではカラーパレットを使いつつ、Cloud Firestore, Cloud Storage も意識した実装をしているので、詳しくはそちらをご覧ください。

https://zenn.dev/koichi_51/articles/336b2f678053eb

この章では以下のようにユーザーアイコンから色を抽出して表示するような実装を行います。
![](https://storage.googleapis.com/zenn-user-upload/178fc93e3cc4-20240926.png =300x)

一画面に収まる内容ではありますが、実装は以下の手順で進めます。
1. 画像の選択 & 色の抽出処理
2. 画像のアップロード処理
3. Firestore への追加、取得処理
4. UI実装

#### 1. 画像の選択 & 色の抽出処理
まずは画像の選択と色の抽出処理を追加していきます。
`PaletteGeneratorUserIconSample` という名前で `HookWidget` を作っておきます。
```dart
class PaletteGeneratorUserIconSample extends HookWidget {
  const PaletteGeneratorUserIconSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
```

次に必要な変数を揃えていきます。
`nameController` はユーザーの名前を保持する `TextEditingController` です。
`imageFile` は選択された画像を保持するための State です。
`dominantColor` は選択された画像から抽出された `dominantColor` を保持するための State です。
`isLoading` は画像アップロード中などにローディングかどうかを保持するための State です。
```diff dart
class PaletteGeneratorUserIconSample extends HookWidget {
  const PaletteGeneratorUserIconSample({super.key});

  @override
  Widget build(BuildContext context) {
+   final nameController = useTextEditingController();
+   final imageFile = useState<File?>(null);
+   final dominantColor = useState<Color?>(null);
+   final isLoading = useState(false);

    return const Placeholder();
  }
}
```

次に画像の選択と色の抽出処理を追加します。
前の章の実装と同様に ImagePicker でギャラリーから画像を選択して、 `imageFile` にセットします。
そして、選択した画像から色を抽出するために `PaletteGenerator.fromImageProvider` に画像を渡しています。これでカラーパレットが生成されます。この章では生成された色のうち `dominantColor` のみを使用します。
```diff dart
class PaletteGeneratorUserIconSample extends HookWidget {
  const PaletteGeneratorUserIconSample({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final imageFile = useState<File?>(null);
    final dominantColor = useState<Color?>(null);
    final isLoading = useState(false);

+   Future<void> pickImage() async {
+     final picker = ImagePicker();
+     final pickedFile = await picker.pickImage(source: ImageSource.gallery);
+     if (pickedFile != null) {
+       imageFile.value = File(pickedFile.path);
+       final paletteGenerator = await PaletteGenerator.fromImageProvider(
+         FileImage(imageFile.value!),
+         size: const Size(200, 300),
+       );
+       dominantColor.value =
+           paletteGenerator.dominantColor?.color ?? Colors.grey;
+     }
+   }

    return const Placeholder();
  }
}
```

#### 2. 画像のアップロード処理
次に画像を Cloud Storage にアップロードする処理を追加していきます。

以下のコードを追加します。
`addUser` 関数でアイコン画像の Cloud Storage へのアップロードと Firestore へのユーザーデータの登録を一度に行います。
以下ではユーザーが選択した画像をアイコン画像として、Cloud Storage の `palette_users` というフォルダの中に保存しています。
また、アップロードした画像に関して `getDownloadURL` でURLを取得し、`imageUrl` として保持しています。
```diff dart
class PaletteGeneratorUserIconSample extends HookWidget {
  const PaletteGeneratorUserIconSample({super.key});

  @override
  Widget build(BuildContext context) {
    // useState などの定義（省略）

    // pickImage の実装（省略）

+   Future<void> addUser() async {
+     // 入力が適切でない場合の処理
+     if (nameController.text.isEmpty || imageFile.value == null) {
+       ScaffoldMessenger.of(context).showSnackBar(
+         const SnackBar(
+           content: Text('Please fill name field and select an image'),
+         ),
+       );
+       return;
+     }
+
+     isLoading.value = true;
+
+     // アイコン画像のアップロード
+     final String fileName =
+         '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.value!.path)}';
+     final String imagePath = 'palette_users/$fileName';
+     final TaskSnapshot uploadTask = await FirebaseStorage.instance
+         .ref(imagePath)
+         .putFile(imageFile.value!);
+     final String imageUrl = await uploadTask.ref.getDownloadURL();
+   }

    return const Placeholder();
  }
}
```

これで Cloud Storage へのアップロード処理が完成しました。

#### 3. Firestore への追加、取得処理
次に Firestore への追加処理を記述していきます。

先ほど実装した `addUser` 関数の中に以下のようなコードを追加します。
Firestore の処理では、`palette_users` というコレクションにユーザーのデータを追加しています。ユーザーのデータは以下の三つのデータのみを持つシンプルなものになっています。
- `name`（ユーザー名）
- `iconImageUrl`（アイコン画像URL）
- `dominantColor`（画像から抽出した色）

```diff dart
class PaletteGeneratorUserIconSample extends HookWidget {
  const PaletteGeneratorUserIconSample({super.key});

  @override
  Widget build(BuildContext context) {
    // useState などの定義（省略）

    // pickImage の実装（省略）

    Future<void> addUser() async {
      // 入力が適切でない場合の処理（省略）

      // アイコン画像のアップロード
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.value!.path)}';
      final String imagePath = 'palette_users/$fileName';
      final TaskSnapshot uploadTask = await FirebaseStorage.instance
          .ref(imagePath)
          .putFile(imageFile.value!);
      final String imageUrl = await uploadTask.ref.getDownloadURL();

+     // Firestore への保存
+     try {
+       await FirebaseFirestore.instance.collection('palette_users').add({
+         'name': nameController.text,
+         'iconImageUrl': imageUrl,
+         'dominantColor': dominantColor.value?.value.toRadixString(16) ?? ''
+       });
+     } catch (e) {
+       debugPrint('Error in add user');
+     } finally {
+       isLoading.value = false;
+     }
    }

    return const Placeholder();
  }
}
```

これで Firestore へのユーザーデータの追加処理は実装完了です。

次はユーザーデータの取得処理を追加していきます。
以下のコードを追加します。
先ほどの Firestore への追加処理でデータを追加した `palette_users` コレクションに対してスナップショットを取得し、Stream としてユーザーデータを取得しています。
取得した内容は `users` として保持されています。
```diff dart
class PaletteGeneratorUserIconSample extends HookWidget {
  const PaletteGeneratorUserIconSample({super.key});

  @override
  Widget build(BuildContext context) {
    // useState などの定義（省略）

    // pickImage の実装（省略）

    // addUser の実装（省略）

+   final users =
+       FirebaseFirestore.instance.collection('palette_users').snapshots().map(
+     (event) {
+       return event.docs.map((doc) {
+         return {
+           'name': doc['name'],
+           'iconImageUrl': doc['iconImageUrl'],
+           'dominantColor': doc['dominantColor']
+         };
+       }).toList();
+     },
+   );

    return const Placeholder();
  }
}
```

これで Firestore へのユーザーデータの追加と取得処理の実装が完了しました。

#### 4. UI実装
最後にUIの実装を行います。
UI実装を含む最終的なコードは以下のようになります。
```dart
class PaletteGeneratorUserIconSample extends HookWidget {
  const PaletteGeneratorUserIconSample({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final imageFile = useState<File?>(null);
    final dominantColor = useState<Color?>(null);
    final isLoading = useState(false);

    Future<void> pickImage() async {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        imageFile.value = File(pickedFile.path);
        final paletteGenerator = await PaletteGenerator.fromImageProvider(
          FileImage(imageFile.value!),
          size: const Size(200, 300),
        );
        dominantColor.value =
            paletteGenerator.dominantColor?.color ?? Colors.grey;
      }
    }

    Future<void> addUser() async {
      // 入力が適切でない場合の処理
      if (nameController.text.isEmpty || imageFile.value == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill name field and select an image'),
          ),
        );
        return;
      }

      isLoading.value = true;

      // アイコン画像のアップロード
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${path.basename(imageFile.value!.path)}';
      final String imagePath = 'palette_users/$fileName';
      final TaskSnapshot uploadTask = await FirebaseStorage.instance
          .ref(imagePath)
          .putFile(imageFile.value!);
      final String imageUrl = await uploadTask.ref.getDownloadURL();

      // Firestore への保存
      try {
        await FirebaseFirestore.instance.collection('palette_users').add({
          'name': nameController.text,
          'iconImageUrl': imageUrl,
          'dominantColor': dominantColor.value?.value.toRadixString(16) ?? ''
        });
      } catch (e) {
        debugPrint('Error in add user');
      } finally {
        isLoading.value = false;
      }
    }

    final users =
        FirebaseFirestore.instance.collection('palette_users').snapshots().map(
      (event) {
        return event.docs.map((doc) {
          return {
            'name': doc['name'],
            'iconImageUrl': doc['iconImageUrl'],
            'dominantColor': doc['dominantColor']
          };
        }).toList();
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ユーザー追加'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                if (imageFile.value == null) ...[
                  const CircleAvatar(
                    backgroundColor: Colors.grey,
                    radius: 20,
                  )
                ] else ...[
                  CircleAvatar(
                    backgroundImage: FileImage(imageFile.value!),
                    radius: 20,
                  ),
                ],
                const Gap(16),
                TextButton(
                  onPressed: () {
                    pickImage();
                  },
                  child: const Text(
                    'アイコン画像を選択',
                  ),
                ),
              ],
            ),
            const Gap(32),
            TextField(
              controller: nameController,
            ),
            const Gap(32),
            ElevatedButton(
              onPressed: () async {
                await addUser();
              },
              child: const Text(
                'ユーザー追加',
              ),
            ),
            const Gap(32),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: users,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No users found'));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final user = snapshot.data![index];
                      final dominantColor = user['dominantColor'] != null &&
                              user['dominantColor'].isNotEmpty
                          ? Color(int.parse(user['dominantColor'], radix: 16))
                          : Colors.grey;

                      return ListTile(
                        contentPadding: const EdgeInsets.all(8),
                        leading: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircleAvatar(
                              backgroundColor: dominantColor,
                              radius: 28,
                            ),
                            const CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 24,
                            ),
                            CircleAvatar(
                              backgroundImage:
                                  NetworkImage(user['iconImageUrl']),
                              radius: 20,
                            ),
                          ],
                        ),
                        title: Text(user['name']),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

UI実装に関して少し詳しくみていきます。

以下ではユーザーアイコンと選択ボタンを表示しています。
`imageFile` が存在する場合はその画像を、存在しない場合は灰色を背景とする `CircleAvatar` を表示しています。
また、「アイコン画像を選択」ボタンで先ほど実装した `pickImage` が実行されるようになっています。
```dart
Row(
  children: [
    if (imageFile.value == null) ...[
      const CircleAvatar(
        backgroundColor: Colors.grey,
        radius: 20,
      )
    ] else ...[
      CircleAvatar(
        backgroundImage: FileImage(imageFile.value!),
        radius: 20,
      ),
    ],
    const Gap(16),
    TextButton(
      onPressed: () {
        pickImage();
      },
      child: const Text(
        'アイコン画像を選択',
      ),
    ),
  ],
),
```

以下では先ほど実装した `addUser` を実行するボタンを表示しています。
このボタンを押すことで、ユーザーの名前、アイコン画像URL、dominantColor が Firestore に保存されるようになっています。
```dart
ElevatedButton(
  onPressed: () async {
    await addUser();
  },
  child: const Text(
    'ユーザー追加',
  ),
),
```

以下では、 `users` として Firestore から Stream で取得したユーザーデータを `ListTile` として表示しています。
この章の初めに画像で提示したように、各ユーザーのアイコン画像と、アイコン画像から抽出された色とユーザー名が表示されます。
```dart
return ListTile(
  contentPadding: const EdgeInsets.all(8),
  leading: Stack(
    alignment: Alignment.center,
    children: [
      CircleAvatar(
        backgroundColor: dominantColor,
        radius: 28,
      ),
      const CircleAvatar(
        backgroundColor: Colors.white,
        radius: 24,
      ),
      CircleAvatar(
        backgroundImage:
            NetworkImage(user['iconImageUrl']),
        radius: 20,
      ),
    ],
  ),
  title: Text(user['name']),
);
```

上記のコードで実行して、ユーザーを追加すると以下の画像のような見た目になっているかと思います。
これでユーザーのアイコン画像から色を抽出するサンプルができました。

![](https://storage.googleapis.com/zenn-user-upload/178fc93e3cc4-20240926.png =300x)

以上です。

## まとめ
最後まで読んでいただいてありがとうございました。

今回は [palette_generator](https://pub.dev/packages/palette_generator) パッケージを使って画像から色を抽出する実装を行いました。
今回の実装を使えば、ユーザーカラーを設定したり、コンテンツごとに表示を変えたりできるため、表現の幅が広がって良いと思いました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://pub.dev/packages/palette_generator

