## 初めに
今回は Dart の Macros を使ってみたいと思います。
なお、2024年4月5日現在 Dart の Macros は Dart では実行できるものの、 Flutter では使用することができないためご注意ください。

Macros についての詳しい説明の前にXの投稿を2つ引用させて頂きます。
まずは以下の投稿をご覧ください。
https://x.com/SandroMaglione/status/1752682717563568419?s=20

この投稿では、Macros を使うとデータクラスを定義するコードを大幅に短縮できるとされています。

また、以下の投稿もご覧ください。
https://x.com/spydon/status/1752629743222993184

この投稿では、コード生成や freezed、json_serializable を使用せずにデータクラス定義が可能であるとされています。つまり、コード生成を行う build_runner の `flutter pub run build_runner build --delete-conflicting-outputs` コマンドも実行不要になります。

個人的には Macros を使用するメリットとして以下の二つが大きいかと思いました。
+ データクラス定義等に関して build_runner のコマンドを実行しないで済む
+ データクラスの記述が短縮できる

## Dart の Macros とは
次に Macros の説明に移りたいと思います。
Dart の Macros とは、[dart-lang / macros](https://github.com/dart-lang/language/blob/main/working/macros/feature-specification.md) の記述によると、以下のように定義されています。
> マクロとは、コンパイル時にプログラムの他の部分を変更できるコードの一部である

また、Macros は Dart における Static Metaprograming をモチベーションとして開発されています。
Static Metaprograming については[Dart の Static Metaprogramming の記述](https://github.com/dart-lang/language/issues/1482) を以下に引用します。
> Metaprogramming refers to code that operates on other code as if it were data. It can take code in as parameters, reflect over it, inspect it, create it, modify it, and return it. Static metaprogramming means doing that work at compile-time, and typically modifying or adding to the program based on that work.
>
> （日本語訳）
> メタプログラミングとは、他のコードをあたかもデータであるかのように操作するコードを指す。メタプログラミングは、コードをパラメータとして受け取り、それを反映し、検査し、作成し、修正し、返すことができる。静的メタプログラミングとは、コンパイル時にその作業を行い、通常はその作業に基づいてプログラムを修正したり追加したりすることを意味する。

上記にある通り、コンパイル時にコードを検査、作成、修正することで、問題があればコンパイル時にエラーを出してくれるようになります。したがって、より素早くコードの修正を行うことができるようになります。

説明を合わせると、 Macros はコンパイル時にプログラムの一部を変更できるものであり、その変更の内容に問題があればコンパイルエラーとして出力されるため、早い段階で気づくことができ効率も上がるということがわかります。

## 記事の対象者
+ Flutter, Dart 学習者
+ Dartの新しい機能を試してみたい方

## 目的
今回は上記の Macros を Dart で使ってみることを目的とします。なお Dart に関して理解が浅い部分も多々あるため、誤っている部分等あればご指摘いただければ幸いです。

最終的には Macros で定義されたモデルを用いて、 APIから取得した JSON 形式のデータをカスタムデータとして扱う実装を行いたいと思います。

## 準備
Macros を使うためには以下のステップが必要です。
1. Flutter, Dart のバージョンアップ
2. VSCode の拡張機能追加
3. pubspec.yaml の編集
4. analysis_options.yaml の編集

なお、自身の環境は以下の通りです。
+ Flutter version 3.22.0-5.0.pre.4 on channel master
+ Dart version 3.5.0 (build 3.5.0-18.0.dev)
+ VS Code (version 1.88.0)

### 1. Flutter, Dart のバージョンアップ
[サンプルプロジェクトの README](https://github.com/millsteed/macros) をみると、Flutter に関しては master channel に切り替える必要があります。また、Dart のバージョンもあげておく必要があります。
したがって、 Macros を実行したいプロジェクトに移動して以下を実行します。

```
flutter upgrade
```

### 2. VSCode の拡張機能の変更
次に VSCode の Dart, Flutter 拡張機能を変更します。
Dart の拡張機能の「Switch to Pre-Release Version」ボタンを選択して、リリース前の機能にもアクセスできるようにします。
![](https://storage.googleapis.com/zenn-user-upload/8c1b3f92842c-20240405.png)

Flutter の拡張機能も同様に「Switch to Pre-Release Version」ボタンを選択します。
![](https://storage.googleapis.com/zenn-user-upload/c90cbae43f1d-20240405.png)

ボタンを選択した後、プロジェクトに反映させるために一度VSCodeを再起動しておきましょう。

### 3. pubspec.yaml の編集
次にプロジェクトの `pubspec.yaml` を [サンプルプロジェクトのpubspeck.yaml](https://github.com/dart-lang/language/blob/cb2e5bd7ee4d8a6c40a4632d4bd9ae1c86f1f384/working/macros/example/pubspec.yaml)を参考に変更します。
```yaml: pubspec.yaml
dependencies:
  macros: any

dev_dependencies:
  _fe_analyzer_shared: any

dependency_overrides:
  macros:
    git:
      url: https://github.com/dart-lang/sdk.git
      path: pkg/macros
      ref: main
  _fe_analyzer_shared:
    git:
      url: https://github.com/dart-lang/sdk.git
      path: pkg/_fe_analyzer_shared
      ref: main
```

### 4. analysis_options.yaml の編集
次に `analysis_options.yaml` に関しても [サンプルプロジェクトのanalysis_options.yaml](https://github.com/dart-lang/language/blob/cb2e5bd7ee4d8a6c40a4632d4bd9ae1c86f1f384/working/macros/example/analysis_options.yaml) に従って変更します。

```yaml: analysis_options.yaml
analyzer:
  enable-experiment:
    - macros
```

これで準備は完了です。

## 実装
次に Macros で定義されたモデルを用いて、 APIから取得した JSON 形式のデータをカスタムデータとして扱う実装を行います。
実装は以下の手順で行います。
1. モデルを Macros で定義
2. 使用するデータモデルを作成
3. APIからデータを取得して表示させる処理を実装
4. 実行と結果

### 1. モデルを Macros で定義
まずは Macros でモデルを作成していきます。
コードは以下の通りです。
```dart
import 'dart:async';
import 'package:macros/macros.dart';

macro class Model implements ClassDeclarationsMacro {
  const Model();

  static const _baseTypes = ['bool', 'double', 'int', 'num', 'String'];
  static const _collectionTypes = ['List'];

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration classDeclaration,
    MemberDeclarationBuilder builder,
  ) async {
    final className = classDeclaration.identifier.name;

    final fields = await builder.fieldsOf(classDeclaration);

    final fieldNames = <String>[];
    final fieldTypes = <String, String>{};
    final fieldGenerics = <String, List<String>>{};

    for (final field in fields) {
      final fieldName = field.identifier.name;
      fieldNames.add(fieldName);

      final fieldType = (field.type.code as NamedTypeAnnotationCode).name.name;
      fieldTypes[fieldName] = fieldType;

      if (_collectionTypes.contains(fieldType)) {
        final generics = (field.type.code as NamedTypeAnnotationCode)
            .typeArguments
            .map((e) => (e as NamedTypeAnnotationCode).name.name)
            .toList();
        fieldGenerics[fieldName] = generics;
      }
    }

    final fieldTypesWithGenerics = fieldTypes.map(
      (name, type) {
        final generics = fieldGenerics[name];
        return MapEntry(
          name,
          generics == null ? type : '$type<${generics.join(', ')}>',
        );
      },
    );

    _buildFromJson(builder, className, fieldNames, fieldTypes, fieldGenerics);
    _buildToJson(builder, fieldNames, fieldTypes);
    _buildCopyWith(builder, className, fieldNames, fieldTypesWithGenerics);
    _buildToString(builder, className, fieldNames);
    _buildEquals(builder, className, fieldNames);
    _buildHashCode(builder, fieldNames);
  }

  void _buildFromJson(
    MemberDeclarationBuilder builder,
    String className,
    List<String> fieldNames,
    Map<String, String> fieldTypes,
    Map<String, List<String>> fieldGenerics,
  ) {
    final code = [
      'factory $className.fromJson(Map<String, dynamic> json) {'.indent(2),
      'return $className('.indent(4),
      for (final fieldName in fieldNames) ...[
        if (_baseTypes.contains(fieldTypes[fieldName])) ...[
          "$fieldName: json['$fieldName'] as ${fieldTypes[fieldName]},"
              .indent(6),
        ] else if (_collectionTypes.contains(fieldTypes[fieldName])) ...[
          "$fieldName: (json['$fieldName'] as List<dynamic>)".indent(6),
          '.whereType<Map<String, dynamic>>()'.indent(10),
          '.map(${fieldGenerics[fieldName]?.first}.fromJson)'.indent(10),
          '.toList(),'.indent(10),
        ] else ...[
          '$fieldName: ${fieldTypes[fieldName]}'
                  ".fromJson(json['$fieldName'] "
                  'as Map<String, dynamic>),'
              .indent(6),
        ],
      ],
      ');'.indent(4),
      '}'.indent(2),
    ].join('\n');
    builder.declareInType(DeclarationCode.fromString(code));
  }

  void _buildToJson(
    MemberDeclarationBuilder builder,
    List<String> fieldNames,
    Map<String, String> fieldTypes,
  ) {
    final code = [
      'Map<String, dynamic> toJson() {'.indent(2),
      'return {'.indent(4),
      for (final fieldName in fieldNames) ...[
        if (_baseTypes.contains(fieldTypes[fieldName])) ...[
          "'$fieldName': $fieldName,".indent(6),
        ] else if (_collectionTypes.contains(fieldTypes[fieldName])) ...[
          "'$fieldName': $fieldName.map((e) => e.toJson()).toList(),".indent(6),
        ] else ...[
          "'$fieldName': $fieldName.toJson(),".indent(6),
        ],
      ],
      '};'.indent(4),
      '}'.indent(2),
    ].join('\n');
    builder.declareInType(DeclarationCode.fromString(code));
  }

  void _buildCopyWith(
    MemberDeclarationBuilder builder,
    String className,
    List<String> fieldNames,
    Map<String, String> fieldTypes,
  ) {
    final code = [
      '$className copyWith({'.indent(2),
      for (final fieldName in fieldNames) ...[
        '${fieldTypes[fieldName]}? $fieldName,'.indent(4),
      ],
      '}) {'.indent(2),
      'return $className('.indent(4),
      for (final fieldName in fieldNames) ...[
        '$fieldName: $fieldName ?? this.$fieldName,'.indent(6),
      ],
      ');'.indent(4),
      '}'.indent(2),
    ].join('\n');
    builder.declareInType(DeclarationCode.fromString(code));
  }

  void _buildToString(
    MemberDeclarationBuilder builder,
    String className,
    List<String> fieldNames,
  ) {
    final code = [
      '@override'.indent(2),
      'String toString() {'.indent(2),
      "return '$className('".indent(4),
      for (final fieldName in fieldNames) ...[
        if (fieldName != fieldNames.last) ...[
          "'$fieldName: \$$fieldName, '".indent(8),
        ] else ...[
          "'$fieldName: \$$fieldName'".indent(8),
        ],
      ],
      "')';".indent(8),
      '}'.indent(2),
    ].join('\n');
    builder.declareInType(DeclarationCode.fromString(code));
  }

  void _buildEquals(
    MemberDeclarationBuilder builder,
    String className,
    List<String> fieldNames,
  ) {
    final code = [
      '@override'.indent(2),
      'bool operator ==(Object other) {'.indent(2),
      'return other is $className &&'.indent(4),
      'runtimeType == other.runtimeType &&'.indent(8),
      for (final fieldName in fieldNames) ...[
        if (fieldName != fieldNames.last) ...[
          '$fieldName == other.$fieldName &&'.indent(8),
        ] else ...[
          '$fieldName == other.$fieldName;'.indent(8),
        ],
      ],
      '}'.indent(2),
    ].join('\n');
    builder.declareInType(DeclarationCode.fromString(code));
  }

  void _buildHashCode(
    MemberDeclarationBuilder builder,
    List<String> fieldNames,
  ) {
    final code = [
      '@override'.indent(2),
      'int get hashCode {'.indent(2),
      'return Object.hash('.indent(4),
      'runtimeType,'.indent(6),
      for (final fieldName in fieldNames) ...[
        '$fieldName,'.indent(6),
      ],
      ');'.indent(4),
      '}'.indent(2),
    ].join('\n');
    builder.declareInType(DeclarationCode.fromString(code));
  }
}

extension on String {
  String indent(int length) {
    final space = StringBuffer();
    for (var i = 0; i < length; i++) {
      space.write(' ');
    }
    return '$space$this';
  }
}
```

こちらはサンプルプロジェクトの [model.dart](https://github.com/millsteed/macros/blob/main/lib/model.dart) をもとに作成したものです。

非常に複雑に見えますが、実装しているのは以下の項目です。
+ FromJson
+ ToJson
+ CopyWith
+ ToString
+ Equals
+ HashCode

FromJson のコードを例にとってより詳しくみていきます。
FromJson ではデータモデルを作成したいクラスの `className`, `fieldNames`, `fieldTypes`, `fieldGenerics` を引数として受け取り、それらをもとに fromJson関数を作成しています。

```dart
  void _buildFromJson(
    MemberDeclarationBuilder builder,
    String className,
    List<String> fieldNames,
    Map<String, String> fieldTypes,
    Map<String, List<String>> fieldGenerics,
  ) {
    final code = [
      'factory $className.fromJson(Map<String, dynamic> json) {'.indent(2),
      'return $className('.indent(4),
      for (final fieldName in fieldNames) ...[
        if (_baseTypes.contains(fieldTypes[fieldName])) ...[
          "$fieldName: json['$fieldName'] as ${fieldTypes[fieldName]},"
              .indent(6),
        ] else if (_collectionTypes.contains(fieldTypes[fieldName])) ...[
          "$fieldName: (json['$fieldName'] as List<dynamic>)".indent(6),
          '.whereType<Map<String, dynamic>>()'.indent(10),
          '.map(${fieldGenerics[fieldName]?.first}.fromJson)'.indent(10),
          '.toList(),'.indent(10),
        ] else ...[
          '$fieldName: ${fieldTypes[fieldName]}'
                  ".fromJson(json['$fieldName'] "
                  'as Map<String, dynamic>),'
              .indent(6),
        ],
      ],
      ');'.indent(4),
      '}'.indent(2),
    ].join('\n');
    builder.declareInType(DeclarationCode.fromString(code));
  }
```

ここで以下のようなデータクラスが引数として渡された場合を考えます。
```dart
class User {
  final String name;
  final String email;

  User(this.name, this.email);

// この場合の FromJsonの引数
// className = User
// fieldNames = [ 'name', 'email' ]
// fieldTypes = { 'name': 'String', 'email': 'String' }
```

この時、FromJson の `code` の部分は以下のように変換されます。
これは通常のデータクラスを定義したときに一緒に定義する fromJson と同じような記述になります。
```dart
factory User.fromJson(Map<String, dynamic> json) {
  return User(
    name: json[name] as String,
    email: json[email] as String,
  );
}
```

つまり、この `_buildFromJson` メソッドで何をしているかというと、`className` や `fieldNames` などのそれぞれのクラス独自の値を受け取り、その値を適切に代入することで今まで記述していた fromJson メソッドと同じようなメソッドを生成しているのです。

この辺りの実装については以下の記事が非常に参考になるかと思います。
https://www.sandromaglione.com/articles/macros-static-metaprogramming-and-primary-constructors-in-dart-and-flutter

`_buildFromJson` をもとに　Macro の Model が何を行なっているかについてみましたが、そのほかの `ToJson` や `CopyWith` についても同様で、クラス独自の値を受け取り、今までの書き方のコードを生成しています。

### 2. 使用するデータモデルを作成
次に使用するデータモデルを作成していきます。
今回データを取得するのは [JSONPlaceholder API](https://jsonplaceholder.typicode.com/) です。
かなり単純な構造のデータを JSON 形式で取得することができます。
その中でも今回は `posts` と `photos` の二種類の取得を行いたいと思います。

データモデルのコードはそれぞれ以下の通りです。
```dart: post.dart
@Model()
class Post {
  final int userId;
  final int id;
  final String title;
  final String body;

  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });
}
```

```dart: photo.dart
@Model()
class Photo {
  final int albumId;
  final int id;
  final String title;
  final String url;
  final String thumbnailUrl;

  Photo({
    required this.albumId,
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
  });
}
```

一番初めの章で紹介したXの投稿まではシンプルにできませんでしたが、それでも非常にシンプルにデータモデルの定義ができています。
`@Moddel()` アノテーションをつけることで、先程 Macros を用いて作成した Model をクラスに付与することができます。

復習にはなりますが、 `Post` の `_buildFromJson` 関数を例にとってみると、 `_buildFromJson` には以下のようなデータが引数として入ることになるかと思います。
```dart
className = Post
fieldNames = [ 'userId', 'id', 'title', 'body' ]
fieldTypes = { 'userId': 'int', 'id': 'int', 'title': 'String', 'body': 'String' }
```

これでモデルの定義は完了です。

### 3. APIからデータを取得して表示させる処理を実装
最後にAPIからデータを取得して表示させる処理を実装していきます。
コードは以下の通りです。

Post の場合
```dart: main.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'post.dartのパス';

Future main() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final jsonList = jsonDecode(response.body) as List<dynamic>;
    const int limit = 10;
    for (int i = 0; i < limit; i++) {
      final json = jsonList[i];
      final post = Post.fromJson(json as Map<String, dynamic>);
      print('${post.id} --------------------');
      print('title: ${post.title}');
      print('body: ${post.body}');
      print('posted by id: ${post.userId}\n');
    }
  } else {
    print('Get Error');
  }
}
```

Photo の場合
```dart: main.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'photo.dartのパス';

Future main() async {
  final url = Uri.parse('https://jsonplaceholder.typicode.com/photos');
  final response = await http.get(url);
  if (response.statusCode == 200) {
    final jsonList = jsonDecode(response.body) as List<dynamic>;
    const int limit = 10;
    for (int i = 0; i < limit; i++) {
      final json = jsonList[i];
      final photo = Photo.fromJson(json as Map<String, dynamic>);
      print('${photo.albumId} ---------------------');
      print('title: ${photo.title}');
      print('url: ${photo.url}');
      print('image url: ${photo.url}\n');
    }
  } else {
    print('Get Error');
  }
}
```

以下では `Post` を例にとって詳しくみていきます。

下記のコードではアクセスするAPIのエンドポイントの定義とデータの取得を行なっています。
```dart
final url = Uri.parse('https://jsonplaceholder.typicode.com/posts');
final response = await http.get(url);
```

以下では返ってきた JSONのリストに対して、取得する `Post` の件数を10件に絞って `Post`型に変換して表示しています。`Post` に関してはIDとタイトル、本文を print文で表示させるようにしています。
```dart
final jsonList = jsonDecode(response.body) as List<dynamic>;
const int limit = 10;
for (int i = 0; i < limit; i++) {
　　final json = jsonList[i];
　　final post = Post.fromJson(json as Map<String, dynamic>);
　　print('${post.id} --------------------');
　　print('title: ${post.title}');
　　print('body: ${post.body}');
　　print('posted by id: ${post.userId}\n');
}
```

これでデータクラスの定義からデータ取得、表示までの一連の実装は完了です。

### 4. 実行と結果
最後に今までのコードを実行するのですが、記事の冒頭にも記述した通り、2024年4月5日現在 Dart の Macros は Dart では実行できるものの、 Flutter では使用することができません。したがって、 `flutter run` ではなく別の方法を取る必要があります。

ターミナルを開き、以下のコマンドを実行することで Macros を含む Dart の実行を行うことができます。
```
dart --enable-experiment=macros [実行するファイルのパス]

// lib 直下の main.dart に main() がある場合
dart --enable-experiment=macros lib/main.dart
```

これで実行すると結果はそれぞれ以下のようになります。（長いので折りたたんでいます）
:::details Post
```
1 --------------------
title: sunt aut facere repellat provident occaecati excepturi optio reprehenderit
body: quia et suscipit
suscipit recusandae consequuntur expedita et cum
reprehenderit molestiae ut ut quas totam
nostrum rerum est autem sunt rem eveniet architecto
posted by id: 1

2 --------------------
title: qui est esse
body: est rerum tempore vitae
sequi sint nihil reprehenderit dolor beatae ea dolores neque
fugiat blanditiis voluptate porro vel nihil molestiae ut reiciendis
qui aperiam non debitis possimus qui neque nisi nulla
posted by id: 1

3 --------------------
title: ea molestias quasi exercitationem repellat qui ipsa sit aut
body: et iusto sed quo iure
voluptatem occaecati omnis eligendi aut ad
voluptatem doloribus vel accusantium quis pariatur
molestiae porro eius odio et labore et velit aut
posted by id: 1

4 --------------------
title: eum et est occaecati
body: ullam et saepe reiciendis voluptatem adipisci
sit amet autem assumenda provident rerum culpa
quis hic commodi nesciunt rem tenetur doloremque ipsam iure
quis sunt voluptatem rerum illo velit
posted by id: 1

5 --------------------
title: nesciunt quas odio
body: repudiandae veniam quaerat sunt sed
alias aut fugiat sit autem sed est
voluptatem omnis possimus esse voluptatibus quis
est aut tenetur dolor neque
posted by id: 1

6 --------------------
title: dolorem eum magni eos aperiam quia
body: ut aspernatur corporis harum nihil quis provident sequi
mollitia nobis aliquid molestiae
perspiciatis et ea nemo ab reprehenderit accusantium quas
voluptate dolores velit et doloremque molestiae
posted by id: 1

7 --------------------
title: magnam facilis autem
body: dolore placeat quibusdam ea quo vitae
magni quis enim qui quis quo nemo aut saepe
quidem repellat excepturi ut quia
sunt ut sequi eos ea sed quas
posted by id: 1

8 --------------------
title: dolorem dolore est ipsam
body: dignissimos aperiam dolorem qui eum
facilis quibusdam animi sint suscipit qui sint possimus cum
quaerat magni maiores excepturi
ipsam ut commodi dolor voluptatum modi aut vitae
posted by id: 1

9 --------------------
title: nesciunt iure omnis dolorem tempora et accusantium
body: consectetur animi nesciunt iure dolore
enim quia ad
veniam autem ut quam aut nobis
et est aut quod aut provident voluptas autem voluptas
posted by id: 1

10 --------------------
title: optio molestias id quia eum
body: quo et expedita modi cum officia vel magni
doloribus qui repudiandae
vero nisi sit
quos veniam quod sed accusamus veritatis error
posted by id: 1
```
:::

:::details Photo
```
1 ---------------------
title: accusamus beatae ad facilis cum similique qui sunt
url: https://via.placeholder.com/600/92c952
image url: https://via.placeholder.com/600/92c952

1 ---------------------
title: reprehenderit est deserunt velit ipsam
url: https://via.placeholder.com/600/771796
image url: https://via.placeholder.com/600/771796

1 ---------------------
title: officia porro iure quia iusto qui ipsa ut modi
url: https://via.placeholder.com/600/24f355
image url: https://via.placeholder.com/600/24f355

1 ---------------------
title: culpa odio esse rerum omnis laboriosam voluptate repudiandae
url: https://via.placeholder.com/600/d32776
image url: https://via.placeholder.com/600/d32776

1 ---------------------
title: natus nisi omnis corporis facere molestiae rerum in
url: https://via.placeholder.com/600/f66b97
image url: https://via.placeholder.com/600/f66b97

1 ---------------------
title: accusamus ea aliquid et amet sequi nemo
url: https://via.placeholder.com/600/56a8c2
image url: https://via.placeholder.com/600/56a8c2

1 ---------------------
title: officia delectus consequatur vero aut veniam explicabo molestias
url: https://via.placeholder.com/600/b0f7cc
image url: https://via.placeholder.com/600/b0f7cc

1 ---------------------
title: aut porro officiis laborum odit ea laudantium corporis
url: https://via.placeholder.com/600/54176f
image url: https://via.placeholder.com/600/54176f

1 ---------------------
title: qui eius qui autem sed
url: https://via.placeholder.com/600/51aa97
image url: https://via.placeholder.com/600/51aa97

1 ---------------------
title: beatae et provident et ut vel
url: https://via.placeholder.com/600/810b14
image url: https://via.placeholder.com/600/810b14
```
:::

結果にある通り、それぞれの独自のクラスに関して、JSON形式から正常に変換して取得、表示できていることがわかります。

## Macros ( experimental ) の内容を試してみる ( 2024/5/16追記 )
Flutter3.22 への移行とほぼ同じタイミングで以下の Dart の Macros のドキュメントが更新されたので、変更内容を試してみます。
https://dart.dev/language/macros

ドキュメントにあったのは、`JsonCodable` に関する内容です。
`JsonCodable`に関する説明は以下に引用します。
> A ready-made macro you can try out today (behind an experimental flag) that offers a seamless solution to the common issue of tedious JSON serialization and deserialization in Dart.
>
> （日本語訳）
> 今日すぐに試せる既製のマクロ（実験的なフラグの背後にあります）は、Dartにおける面倒なJSONのシリアライズとデシリアライズの一般的な問題に対するシームレスな解決策を提供します。

日本語訳にある通り、 `JsonCodable` を使うことで、 Dart の面倒なJsonシリアライズ、デシリアライズがシームレスにできるとのことです。
前の章で自作の `@Model()` マクロを用いて `fromJson`, `toJson` の実装は行いましたが、改めて公式で出されたマクロを詳しくみていきたいと思います。

### 準備
まずは Macros を使用するための準備を行います。
なお、この記事の上の章と内容が被るかと思いますが、ご容赦ください。

[公式ドキュメント](https://dart.dev/language/macros)にもありますが、現時点では Macros を使用するためには Dart のバージョンを引き上げる必要があります。
この章では `3.5.0-152` かそれ以上の Dart のバージョンが必要です。
Dart のバージョンアップデートは以下のコマンドで可能です。
```
flutter upgrade
```
なお、筆者のバージョンは以下のとおりです。
・Flutter version 3.22.0-35.0.pre.10 on channel master
・Dart version 3.5.0 (build 3.5.0-154.0.dev)

次に `analysis_options.yaml` を以下のように変更します。
```yaml: analysis_options.yaml
analyzer:
  enable-experiment:
    - macros
```

最後に、`JsonCodable`マクロを使用するためには `json` パッケージを追加する必要があります。
`pubspeck.yaml` に `json`　を追加するか以下のコマンドをターミナルで実行します。
```
flutter pub add json
```

正常に実行できない場合は以下の公式ドキュメントをご参照ください。
https://dart.dev/language/macros

### 実装
次にドキュメントにある実装を試してみます。
実装の手順は以下のとおりです。
1. データの定義
2. データの使用
3. コードの詳細

#### 1. データの定義
まずは `JsonCodable` を使ったデータの定義を行います。
`JsonCodable`アノテーションを使って `JsonCodableUser` というデータを定義しています。
ここは公式ドキュメントと同じような実装になります。
```dart: json_codable_user.dart
import 'package:json/json.dart';

@JsonCodable()
class JsonCodableUser {
 final double age;
 final String name;
 final String username;
}
```

#### 2. データの使用
次に先程定義した `JsonCodableUser` が正常に使用できるかどうかを確かめます。
コードは以下のとおりです。
公式ドキュメントと同じような実装で、各プロパティについて詳しく出力します。
```dart: json_codable_user_test.dart
void main() {
  var userJson = {'age': 5, 'name': 'Roger', 'username': 'roger1337'};
  var user = JsonCodableUser.fromJson(userJson);
  print('user age: ${user.age}');
  print('user name: ${user.name}');
  print('user username: ${user.username}');
  print(user.toJson());
}
```

次に、データを使用しているファイルを実行してみます。
`dart --enable-experiment=macros path/to/file` のように Macros を使用することを明示して実行します。
筆者の場合は `json_codable_user_test.dart` ファイルが lib > macros > json_codable_user_test.dart の位置にあったので以下のようなコマンドをターミナルで実行します。
```
dart --enable-experiment=macros lib/macros/json_codable_test.dart
```

正常にファイルを実行できると以下のような出力になるかと思います。
```
user age: 5
user name: Roger
user username: roger1337
{age: 5, name: Roger, username: roger1337}
```
`fromJson` で `JsonCodableUser` に変更されたデータは各プロパティにおいても正常に変換されていることがわかります。また、最後の行で `toJson` を実行した内容を出力していますが、これも正常にJSONに変換されていることがわかります。

余談ですが、以下のポストでも触れたとおり、今回追加された JsonCodable アノテーションで作成したデータは、テキストエディタで変更するたびにリアルタイムでデータが更新されるようになっています。
https://x.com/koichi_mobile/status/1790681001133486247

このような仕組みのおかげで問題をより早く発見することができます。


#### 3. コードの詳細
ここまででドキュメントの通り `JsonCodable` アノテーションが機能することがわかりました。
最後に `JsonCodable` の詳細を見ていきたいと思います。
コードは以下の通りです。
```dart
macro class JsonCodable
    with _Shared, _FromJson, _ToJson
    implements ClassDeclarationsMacro, ClassDefinitionMacro {
  const JsonCodable();

  /// Declares the `fromJson` constructor and `toJson` method, but does not
  /// implement them.
  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    final mapStringObject = await _setup(clazz, builder);

    await (
      _declareFromJson(clazz, builder, mapStringObject),
      _declareToJson(clazz, builder, mapStringObject),
    ).wait;
  }

  /// Provides the actual definitions of the `fromJson` constructor and `toJson`
  /// method, which were declared in the previous phase.
  @override
  Future<void> buildDefinitionForClass(
      ClassDeclaration clazz, TypeDefinitionBuilder builder) async {
    final introspectionData =
        await _SharedIntrospectionData.build(builder, clazz);

    await (
      _buildFromJson(clazz, builder, introspectionData),
      _buildToJson(clazz, builder, introspectionData),
    ).wait;
  }
}
```

用意されている関数は以下の二つです。
- buildDeclarationsForClass
- buildDefinitionForClass

`buildDeclarationsForClass` では新しいコンストラクターやメソッドの存在を宣言しています。そして `buildDefinitionForClass` では宣言されたコンストラクターやメソッドの具体的な実装を行なっています。

今回は `FromJson` に注目してそれぞれ詳しく見ていきます。
`buildDeclarationsForClass` では `_declareFromJson`、`buildDefinitionForClass` では `_buildFromJson` がそれぞれ実行されています。

`_declareFromJson` の実装は以下のようになっています。
```dart
  Future<void> _declareFromJson(
      ClassDeclaration clazz,
      MemberDeclarationBuilder builder,
      NamedTypeAnnotationCode mapStringObject) async {
    if (!(await _checkNoFromJson(builder, clazz))) return;

    builder.declareInType(DeclarationCode.fromParts([
      // TODO(language#3580): Remove/replace 'external'?
      '  external ',
      clazz.identifier.name,
      '.fromJson(',
      mapStringObject,
      ' json);',
    ]));
  }
```

上記のコードでは二つの処理を行なっています。
1. `_checkNoFromJson` で既に `fromJson` があるかどうかを判定し、ある場合は早期リターン
2. `fromJson` コンストラクタの宣言

`fromJson` のコンストラクタに関しては以下のように宣言されます
```dart
external クラス名.fromJson(Map<String, Object?> json);
```

次に `_buildFromJson` は以下のようなコードになっています。
```dart
  Future<void> _buildFromJson(
      ClassDeclaration clazz,
      TypeDefinitionBuilder typeBuilder,
      _SharedIntrospectionData introspectionData) async {
    final constructors = await typeBuilder.constructorsOf(clazz);
    final fromJson =
        constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
    if (fromJson == null) return;
    await _checkValidFromJson(fromJson, introspectionData, typeBuilder);
    final builder = await typeBuilder.buildConstructor(fromJson.identifier);

    // If extending something other than `Object`, it must have a `fromJson`
    // constructor.
    var superclassHasFromJson = false;
    final superclassDeclaration = introspectionData.superclass;
    if (superclassDeclaration != null &&
        !superclassDeclaration.isExactly('Object', _dartCore)) {
      final superclassConstructors =
          await builder.constructorsOf(superclassDeclaration);
      for (final superConstructor in superclassConstructors) {
        if (superConstructor.identifier.name == 'fromJson') {
          await _checkValidFromJson(
              superConstructor, introspectionData, builder);
          superclassHasFromJson = true;
          break;
        }
      }
      if (!superclassHasFromJson) {
        throw DiagnosticException(Diagnostic(
            DiagnosticMessage(
                'Serialization of classes that extend other classes is only '
                'supported if those classes have a valid '
                '`fromJson(Map<String, Object?> json)` constructor.',
                target: introspectionData.clazz.superclass?.asDiagnosticTarget),
            Severity.error));
      }
    }

    final fields = introspectionData.fields;
    final jsonParam = fromJson.positionalParameters.single.identifier;

    Future<Code> initializerForField(FieldDeclaration field) async {
      return RawCode.fromParts([
        field.identifier,
        ' = ',
        await _convertTypeFromJson(
            field.type,
            RawCode.fromParts([
              jsonParam,
              "['",
              field.identifier.name,
              "']",
            ]),
            builder,
            introspectionData),
      ]);
    }

    final initializers = await Future.wait(fields.map(initializerForField));

    if (superclassHasFromJson) {
      initializers.add(RawCode.fromParts([
        'super.fromJson(',
        jsonParam,
        ')',
      ]));
    }

    builder.augment(initializers: initializers);
  }
```

それぞれ詳しく見ていきます。

以下の部分では下記の三つのことを行なっています。
1. `constructorsOf` メソッドで `fromJson` コンストラクタをコードの中から見つける
2. `_checkValidFromJson` メソッドで、見つけた `fromJson` が正しい形式か確認する
3. `fromJson` コンストラクタの定義
```dart
final constructors = await typeBuilder.constructorsOf(clazz);
final fromJson =
        constructors.firstWhereOrNull((c) => c.identifier.name == 'fromJson');
if (fromJson == null) return;
await _checkValidFromJson(fromJson, introspectionData, typeBuilder);
final builder = await typeBuilder.buildConstructor(fromJson.identifier);
```

以下の部分では下記の三つのことを行なっています。
1. JsonCodableの対象となっているクラスが他のクラスを拡張していないか確認
2. 他のクラスを拡張している場合はそのクラスにも `fromJson` があるかどうか確認
3. もし `fromJson` がなければエラーを投げる
```dart
    var superclassHasFromJson = false;
    final superclassDeclaration = introspectionData.superclass;
    if (superclassDeclaration != null &&
        !superclassDeclaration.isExactly('Object', _dartCore)) {
      final superclassConstructors =
          await builder.constructorsOf(superclassDeclaration);
      for (final superConstructor in superclassConstructors) {
        if (superConstructor.identifier.name == 'fromJson') {
          await _checkValidFromJson(
              superConstructor, introspectionData, builder);
          superclassHasFromJson = true;
          break;
        }
      }
      if (!superclassHasFromJson) {
        throw DiagnosticException(Diagnostic(
            DiagnosticMessage(
                'Serialization of classes that extend other classes is only '
                'supported if those classes have a valid '
                '`fromJson(Map<String, Object?> json)` constructor.',
                target: introspectionData.clazz.superclass?.asDiagnosticTarget),
            Severity.error));
      }
    }
```

以下の部分では下記のことを行なっています。
全てのフィールドについて `fromJson` コンストラクタ内で初期化する処理を行なっています。
```dart
    final fields = introspectionData.fields;
    final jsonParam = fromJson.positionalParameters.single.identifier;

    Future<Code> initializerForField(FieldDeclaration field) async {
      return RawCode.fromParts([
        field.identifier,
        ' = ',
        await _convertTypeFromJson(
            field.type,
            RawCode.fromParts([
              jsonParam,
              "['",
              field.identifier.name,
              "']",
            ]),
            builder,
            introspectionData),
      ]);
    }

    final initializers = await Future.wait(fields.map(initializerForField));
```

以下のコードでは、対象のクラスがスーパークラスを持ち、かつそのスーパークラスが `fromJson` コンストラクタを持っている場合にスーパークラスの `fromJson` を呼び出しています。
```dart
    if (superclassHasFromJson) {
      initializers.add(RawCode.fromParts([
        'super.fromJson(',
        jsonParam,
        ')',
      ]));
    }
```

最後に以下で `builder.augment` メソッドで生成した初期化コードをfromJsonコンストラクターに追加しています。
```dart
builder.augment(initializers: initializers);
```

2024/5/16 追記分終了

## 今後の可能性
Macros は現在 Dart のみで実行が可能になっていますが、 Pub.dev を確認したところ以下のように Dart Team によって開発されている Macros パッケージが確認できました。
Flutter で使用できるようになる日も近いかもしれません。

https://pub.dev/packages/macros

## まとめ
最後まで読んでいただいてありがとうございました。

Macros を触ってみて、Flutterに導入されれば開発効率が大きく上がる技術であると感じました。
今回作成したデータクラスは二つのみでしたが、作成した Macros はアノテーションとして使いまわせるた、扱うデータクラスが増えれば増えるほど、他の書き方と比較して楽に記述できると感じました。

一方で Macros を使用して手軽にかけてしまうことで、もちろん使い方次第ではありますが、Modelなどの内部で何が起こっているのかを意識しなくなり、機能追加や変更に対処できなくなる可能性もあると感じました。
例えば今回の例だと Macros を使っているデータクラスのプロパティが nullable の時の実装はどうするのかなど、すでにあるマクロだけでなく自身で変更を加えるなどしてどのような処理が行われているかは把握しておく必要があると感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考
https://github.com/dart-lang/language/blob/main/working/macros/feature-specification.md

https://github.com/millsteed/macros

https://pub.dev/packages/macros

https://www.sandromaglione.com/articles/macros-static-metaprogramming-and-primary-constructors-in-dart-and-flutter

https://github.com/millsteed/macros/tree/main

引用させていただいた投稿
https://x.com/SandroMaglione/status/1752682717563568419?s=20

https://x.com/spydon/status/1752629743222993184