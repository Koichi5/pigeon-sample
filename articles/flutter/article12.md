## 初めに
今回は Flutter, Swagger, Go を組み合わせて簡単なメモアプリを作成してみたいと思います。
Flutter と Firebase の親和性が高いことから、バックエンドの言語や技術を触る機会が少なくなっていましたが、 Swagger や Go にも触れておきたいと考えて簡単なメモアプリの実装から進めることにしました。

## 記事の対象者
+ Flutter 学習者
+ Swagger を使ってみたい方
+ Go を使ってみたい方
+ Flutter で Firebase 以外の選択肢を試したい方

## 目的
今回は先述の通り、Flutter, Swagger, Go で簡単なアプリを作ってみることで Firebase 以外のツールを用いた Flutter 開発を行うことを目的とします。最終的には以下の機能を備えたメモアプリを作成してみたいと思います。
+ メモの作成
+ メモの一覧
+ メモの変更
+ メモの削除
+ メモの検索

最終的には以下の動画のようなサンプルアプリを実装してみます。

https://youtube.com/shorts/btlcRVUknf8

今回実装したコードは以下の GitHub で公開しているので、よろしければご参照ください。

https://github.com/Koichi5/swagger-golang-flutter-sample

## この記事でやらないこと
+ Flutter 側のUIを良くする工夫
+ Go を用いた複雑な処理
+ Riverpod, useState などの説明

## Go とは
具体的な実装に入る前に今回使用する技術について軽く触れておきます。
まずは Go についてです。

Go は2009年にGoogleによって開発されたプログラミング言語で、Google内で「プログラミングの環境を改善する」ことを目的として開発されたプログラミング言語です。Go は、静的型付け、C言語の伝統に則った特性を持ちます。Go が使用されているサービスの例として以下が挙げられます。
+ YouTube
+ Dropbox
+ メルカリ
+ クックパッド

[Go のホームページ](https://go.dev/)には以下のような記述があります。
より詳しく知りたい方はホームページをご覧ください。
> Build simple, secure, scalable systems with Go
・　An open-source programming language supported by Google
・　Easy to learn and great for teams
・　Built-in concurrency and a robust standard library
・　Large ecosystem of partners, communities, and tools
>
> （日本語訳）
> シンプルで安全かつスケーラブルなシステムをGoで構築する
・　Googleがサポートするオープンソースのプログラミング言語
・　学びやすく、チームでの使用に最適
・　組み込みの並行処理と堅牢な標準ライブラリ
・　多数のパートナー、コミュニティ、ツールのエコシステム

## Swagger とは
次に Swagger についてです。
[Swagger のホームページ](https://swagger.io/)の内容を引用します。
> Simplify your API development with our open-source and professional tools, built to help you and your team efficiently design and document APIs at scale.
> Swagger is a set of open-source tools built around the OpenAPI Specification that can help you design, build, document and consume REST APIs.
>
> （日本語訳）
> オープンソースとプロフェッショナルなツールを使って、API開発をシンプルにしましょう。これらのツールは、あなたとあなたのチームが効率的にAPIを設計し、スケールに合わせてドキュメントを作成するために作られています。
> Swaggerは、OpenAPI仕様に基づいて設計されたオープンソースツールのセットで、REST APIの設計、構築、ドキュメント作成、および利用を支援します。



## 実装
では早速実装を進めていきたいと思います。
実装は以下の手順で進めていきます。
1. Flutter のプロジェクト作成
2. Go の環境構築
3. Swagger の環境構築
4. Flutter のプロジェクト設定
5. Swagger の実装
6. Go 側の実装
7. Flutter 側の実装

### 1. Flutter のプロジェクト作成
まずは Flutter のプロジェクトを作成します。
VSCode の場合は上部のテキストフィールドに「> Flutter: New Project」を入れて、アプリケーション名を設定して作成完了です。今回筆者の手元では「swagger_golang_flutter_sample」というプロジェクト名にしています。
Android Studio の場合はホーム画面の「New Flutter Project」を押して、プロジェクト名を設定して完了です。

以下ではこのプロジェクト内で作業していきます。

### 2. Go の環境構築
次に Go の環境構築を行います。
Go の環境構築は非常にシンプルで、Homebrewをインストールしている場合は以下のコマンドをターミナルで実行するだけで完了です。特にパスを通したりする必要がないのが楽で良いですね。
```
brew install go
```

以下のコマンドを実行して Go のバージョンが表示されればインストール完了です。
筆者の手元では `go version go1.22.5 darwin/arm64` を使用しています。
```
go version
```

次にプロジェクトにおける Go の設定に移ります。
プロジェクトのルートディレクトリで以下のコマンドを実行するか、「backend」ディレクトリを作成します。
```
mkdir backend
```

現状のディレクトリ構造は以下のようになっているかと思います。
```
memo_app/
├── android/
├── ios/
├── backend/
├── lib/
├── test/
├── pubspec.yaml
└── ...（その他のFlutterプロジェクトファイル）
```

Go の実装は基本的にこの backend ディレクトリの中で行なっていくことになります。

次に backend ディレクトリに移動して、以下のコマンドを実行します。
`go mod init` は Go の新しいプロジェクトを作成するためのコマンドです。
コマンドを実行すると `go.mod`, `go.sum` というファイルが生成されるかと思います。
```
go mod init github.com/GitHubユーザー名/プロジェクトのパス
```

次に必要なパッケージをインストールしておきます。
backend ディレクトリで以下のコマンドを実行します。
```
go get -u github.com/gin-gonic/gin
go get -u gorm.io/gorm
go get -u gorm.io/driver/sqlite
```

使用するパッケージについて少し触れておきます。
+ gin-gonic
  Ginは、Goで書かれた高性能なWebフレームワーク。JSONを扱う場合などに使用します。

+ gorm
  Goのためのフル機能のORMライブラリ。データベース抽象化、自動マイグレーション、CRUD操作などを行うことができます。Webで言うと Prisma などにあたるのでしょうか。

+ sqlite
  GORMのSQLiteドライバー。SQLiteデータベースとの接続が可能になります。

最後に backend ディレクトリで以下のコマンドを実行しておきます。
```
mkdir models handlers repositories services database
```

現状のディレクトリ構造は以下のようになっているかと思います。
```
backend/
├── database/
├── handlers/
├── models/
├── repositories/
├── services/
├── go.mod
├── go.sum
```

### 3. Swagger の環境構築
次に Swagger 側での環境構築を行います。
npmが既にインストールされている場合は、ターミナルで以下のコマンドを実行してください。
```
npm install @openapitools/openapi-generator-cli
```

これで openapi generator を使うことができるようになります。

次にプロジェクトのルートディレクトリに `memo-api.yaml` を作成します。
Swagger ではAPIの仕様をこの `memo-api.yaml` に定義していきます。

### 4. Flutter のプロジェクト設定
プロジェクトの設定では必要なパッケージの導入を進めていきます。 `pubspec.yaml` の内容を以下のように変更するか、ターミナルで以下のコマンドを実行します。
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.2.1
  intl: ^0.19.0
  collection: ^1.18.0
  gap: ^3.0.1
  flutter_riverpod: ^2.5.1
  hooks_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  json_serializable: ^6.8.0
  flutter_hooks: ^0.20.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
```

```
flutter pub add http intl collection gap flutter_riverpod hooks_riverpod riverpod_annotation json_serializable flutter_hooks
flutter pub add -d build_runner riverpod_generator
```

Flutter 側の設定は完了です。

### 5. Swagger の実装
次に Swagger の実装を行います。
先ほど作成した `memo-api.yaml` を仕様に合わせて変更していきます。
コードは以下の通りです。
```yaml: memo-api.yaml
openapi: 3.0.0
info:
  title: メモアプリAPI
  version: 1.0.0
  description: シンプルなメモアプリのためのRESTful API

paths:
  /memos:
    get:
      summary: メモ一覧の取得
      responses:
        "200":
          description: 成功
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Memo"
    post:
      summary: 新規メモの作成
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/NewMemo"
      responses:
        "201":
          description: 作成成功
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Memo"

  /memos/{memoId}:
    get:
      summary: 特定のメモの取得
      parameters:
        - name: memoId
          in: path
          required: true
          schema:
            type: string
      responses:
        "200":
          description: 成功
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Memo"
        "404":
          description: メモが見つかりません

    put:
      summary: メモの更新
      parameters:
        - name: memoId
          in: path
          required: true
          schema:
            type: int
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: "#/components/schemas/NewMemo"
      responses:
        "200":
          description: 更新成功
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Memo"
        "404":
          description: メモが見つかりません

    delete:
      summary: メモの削除
      parameters:
        - name: memoId
          in: path
          required: true
          schema:
            type: string
      responses:
        "204":
          description: 削除成功
        "404":
          description: メモが見つかりません

  /memos/{memoId}/tags:
    post:
      summary: タグの追加
      parameters:
        - name: memoId
          in: path
          required: true
          schema:
            type: string
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                tag:
                  type: string
      responses:
        "200":
          description: タグ追加成功
          content:
            application/json:
              schema:
                $ref: "#/components/schemas/Memo"

  /memos/search:
    get:
      summary: メモの検索
      parameters:
        - name: keyword
          in: query
          required: true
          schema:
            type: string
      responses:
        "200":
          description: 検索成功
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Memo"

components:
  schemas:
    Memo:
      type: object
      properties:
        id:
          type: int
        title:
          type: string
        content:
          type: string
        tags:
          type: array
          items:
            type: string
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    NewMemo:
      type: object
      required:
        - title
        - content
      properties:
        title:
          type: string
        content:
          type: string
        tags:
          type: array
          items:
            type: string
```

APIの仕様としては以下の機能を実装しています。
+ メモの一覧取得
+ メモの作成
+ 特定のメモの取得
+ メモの更新
+ メモの削除
+ タグの追加
+ メモの検索

一つ例にとって詳しくみていきます。
以下はメモの一覧を取得するためのAPIです。
`/memos` はAPIのエンドポイントを定義しており、その下に `get` とあることから、 `/memos` に対してGETリクエストを送っていることがわかります。
`summary` ではこのリクエストの説明文を指定しています。
`response` ではリクエストのAPIのレスポンスを定義しており、以下では成功した場合の `content` としてJSON形式で返ってくること、さらにそのJSONは Memo の配列であることを示しています。
```yaml
  /memos:
    get:
      summary: メモ一覧の取得
      responses:
        "200":
          description: 成功
          content:
            application/json:
              schema:
                type: array
                items:
                  $ref: "#/components/schemas/Memo"
```

機能が必要になった場合には逐一この Swagger の仕様を追加していく必要があります。今回は必要な機能を上記のコードにまとめています。

次に先ほど作成した `memo-api.yaml` をもとにAPIのクライアントを生成します。

実際にAPIクライアントを生成する前に以下のコードを実行してバリデーションを行い、Errorがないか検証しておきましょう。
```markdown:  Swagger の仕様が memo-api.yaml に記述されている場合
openapi-generator validate -i memo-api.yaml
```

次に以下のコードを実行することで、APIのクライアントを自動生成することができます。
`openapi-generator generate` の部分では OpenAPI Generator の generate メソッドを実行しています。これはコード生成することを示しています。
`-i memo-api.yaml` の部分では、ファイルの入力を定義しており、今回は `memo-api.yaml` ファイルを入力として指定しています。このファイルを元にAPIクライアントが生成されます。
`-g dart` の部分では、生成したいクライアントコードの言語やフレームワークを指定しています。
`-o lib/api` では、生成するコードの出力先を指定しており、今回は `lib` フォルダの配下の `api` フォルダに生成されます。
```
openapi-generator generate -i memo-api.yaml -g dart -o lib/api
```

抽象化すると以下のようなコマンドになります。
```
openapi-generator generate -i {APIの仕様を定義しているyamlファイルのパス} -g {生成したい言語やフレームワーク} -o {生成ファイルの出力先}
```

生成のコマンドを実行すると以下の画像のようなファイル構造の api フォルダが生成されます。
![](https://storage.googleapis.com/zenn-user-upload/bf4035d4a9d5-20240715.png =350x)

:::message
APIクライアントの自動生成は既存の Swagger の仕様のyamlに応じて生成されます。
したがって、apiフォルダ内の内容を変更していても、APIクライアントの自動生成を行うと内容が上書きされてしまいます。誤って上書きされても問題ないように Git などで管理しておいた方が良いかもしれません。
`openapi-generator generate` コマンドは注意して使用し、APIの仕様を定義している yaml は常に最新に保つようにしておきましょう。
:::

生成されたコードを少し覗いてみましょう。

`lib/api/lib/api/default_api.dart`
基本的にはこの `default_api.dart` にある `DefaultApi` を用いてバックエンド側の関数を呼び出します。

`lib/api/lib/auth`
こちらのフォルダでは auth に関する実装がされています。今回は Auth には触れないためスキップします。

`lib/api/lib/model`
こちらのフォルダでは、 yaml に定義した components を元に生成されたモデルが格納されます。
今回は `Memo`, `NewMemo` などを生成しているため、それらのモデルが定義されます。

`lib/api/api_client.dart`
こちらのファイルでは `ApiClient` を定義しており、APIクライアントのパスや、APIを呼び出すためのメソッドなどを実装しています。
このAPIクライアントのパスは生成されたままでは `http://localhost` のようになっているかと思います。しかし、これは実行するデバイスなどに応じて変更する必要があります。筆者の手元では Android Emulator で実行するために `http://10.0.2.2:8080` に変更しています。

これで Swagger の定義は完了です。

:::details 実際のコード
```dart: default_api.dart
//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class DefaultApi {
  DefaultApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// メモ一覧の取得
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> memosGetWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/memos';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// メモ一覧の取得
  Future<List<Memo>?> memosGet() async {
    final response = await memosGetWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Memo>') as List)
        .cast<Memo>()
        .toList(growable: false);

    }
    return null;
  }

  /// メモの削除
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] memoId (required):
  Future<Response> memosMemoIdDeleteWithHttpInfo(String memoId,) async {
    // ignore: prefer_const_declarations
    final path = r'/memos/{memoId}'
      .replaceAll('{memoId}', memoId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// メモの削除
  ///
  /// Parameters:
  ///
  /// * [String] memoId (required):
  Future<void> memosMemoIdDelete(String memoId,) async {
    final response = await memosMemoIdDeleteWithHttpInfo(memoId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// 特定のメモの取得
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] memoId (required):
  Future<Response> memosMemoIdGetWithHttpInfo(String memoId,) async {
    // ignore: prefer_const_declarations
    final path = r'/memos/{memoId}'
      .replaceAll('{memoId}', memoId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 特定のメモの取得
  ///
  /// Parameters:
  ///
  /// * [String] memoId (required):
  Future<Memo?> memosMemoIdGet(String memoId,) async {
    final response = await memosMemoIdGetWithHttpInfo(memoId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Memo',) as Memo;

    }
    return null;
  }

  /// メモの更新
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] memoId (required):
  ///
  /// * [NewMemo] newMemo (required):
  Future<Response> memosMemoIdPutWithHttpInfo(int memoId, NewMemo newMemo,) async {
    // ignore: prefer_const_declarations
    final path = r'/memos/{memoId}'
      .replaceAll('{memoId}', memoId.toString());

    // ignore: prefer_final_locals
    Object? postBody = newMemo;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'PUT',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// メモの更新
  ///
  /// Parameters:
  ///
  /// * [int] memoId (required):
  ///
  /// * [NewMemo] newMemo (required):
  Future<Memo?> memosMemoIdPut(int memoId, NewMemo newMemo,) async {
    final response = await memosMemoIdPutWithHttpInfo(memoId, newMemo,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Memo',) as Memo;

    }
    return null;
  }

  /// タグの追加
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] memoId (required):
  ///
  /// * [MemosMemoIdTagsPostRequest] memosMemoIdTagsPostRequest (required):
  Future<Response> memosMemoIdTagsPostWithHttpInfo(String memoId, MemosMemoIdTagsPostRequest memosMemoIdTagsPostRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/memos/{memoId}/tags'
      .replaceAll('{memoId}', memoId);

    // ignore: prefer_final_locals
    Object? postBody = memosMemoIdTagsPostRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// タグの追加
  ///
  /// Parameters:
  ///
  /// * [String] memoId (required):
  ///
  /// * [MemosMemoIdTagsPostRequest] memosMemoIdTagsPostRequest (required):
  Future<Memo?> memosMemoIdTagsPost(String memoId, MemosMemoIdTagsPostRequest memosMemoIdTagsPostRequest,) async {
    final response = await memosMemoIdTagsPostWithHttpInfo(memoId, memosMemoIdTagsPostRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Memo',) as Memo;

    }
    return null;
  }

  /// 新規メモの作成
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [NewMemo] newMemo (required):
  Future<Response> memosPostWithHttpInfo(NewMemo newMemo,) async {
    // ignore: prefer_const_declarations
    final path = r'/memos';

    // ignore: prefer_final_locals
    Object? postBody = newMemo;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// 新規メモの作成
  ///
  /// Parameters:
  ///
  /// * [NewMemo] newMemo (required):
  Future<Memo?> memosPost(NewMemo newMemo,) async {
    final response = await memosPostWithHttpInfo(newMemo,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Memo',) as Memo;

    }
    return null;
  }

  /// メモの検索
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] keyword (required):
  Future<Response> memosSearchGetWithHttpInfo(String keyword,) async {
    // ignore: prefer_const_declarations
    final path = r'/memos/search';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'keyword', keyword));

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// メモの検索
  ///
  /// Parameters:
  ///
  /// * [String] keyword (required):
  Future<List<Memo>?> memosSearchGet(String keyword,) async {
    final response = await memosSearchGetWithHttpInfo(keyword,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Memo>') as List)
        .cast<Memo>()
        .toList(growable: false);

    }
    return null;
  }
}
```
:::

### 6. Go 側の実装
次は Go 側の実装をしていきます。
先ほど作成した通り、 `backend` のディレクトリ構造は以下のようになっています。
```
backend/
├── database/
├── handlers/
├── models/
├── repositories/
├── services/
├── go.mod
├── go.sum
```

この構造では以下のような依存関係になっています。
```
handlers → services → repositories → models
    ↓                     ↓
    └─────────────────────┴─→ database
```

それぞれについて少し触れておきます。
+ models/
  アプリケーションのデータ構造を定義します。他の層に依存しません。

+ database/
  データベース接続の設定と管理を行います。
  通常、他の層には依存しませんが、`models` を使用することがあります。

+ repositories/
  データの永続化と取得のロジックを含みます。
  `models` に依存します。
  `database` を使用してデータベースとやり取りします。

+ services/
  ビジネスロジックを実装します。
  `repositories` と `models` に依存します。

+ handlers/
  HTTPリクエストの受け取りとレスポンスの生成を担当します。
  `services` と `models` に依存します。

Go の実装は以下の手順で進めていきます。
1. models の実装
2. database の実装
3. repositories の実装
4. services の実装
5. handlers の実装
6. main.go の実装

#### 1. models の実装
`models` ディレクトリに `memo.go` を作成します。
コードは以下の通りです。
```go: models/memo.go
package models

import (
	"database/sql/driver"
	"encoding/json"
	"time"
	"gorm.io/gorm"
)

type Memo struct {
    ID        uint      `json:"id" gorm:"primarykey"`
    CreatedAt time.Time `json:"createdAt"`
    UpdatedAt time.Time `json:"updatedAt"`
    DeletedAt gorm.DeletedAt `json:"deletedAt,omitempty" gorm:"index"`
    Title     string    `json:"title"`
    Content   string    `json:"content"`
    Tags      Tags      `json:"tags" gorm:"type:text"`
}

type Tags []string
```

一つずつ解説していきます。

以下では models を package として定義しています。
package とすることで外部からも使用することができるようになります。
```go
package models
```

以下では必要な外部パッケージを import しています。
models 層では他の層に依存していないため、外部のパッケージのみに依存しています。
```go
import (
	"database/sql/driver"
	"encoding/json"
	"time"
	"gorm.io/gorm"
)
```

以下では Memo, Tags の構造体（struct）を定義しています。
Go では明示的に class を定義することはせず、 struct を用いた実装を行います。したがって、Flutter の class と異なり以下のような特徴を持ちます。
+ コンストラクタを持たない
+ 内部でメソッドを定義しない
+ カプセル化をしない

各フィールドは名前、型、JSONシリアライゼーションのためのデータを保持しています。
`gorm:"primarykey"` では `ID` が主キーであることを示しており、 外部の `gorm` の機能を援用しています。

```go
type Memo struct {
    ID        uint      `json:"id" gorm:"primarykey"`
    CreatedAt time.Time `json:"createdAt"`
    UpdatedAt time.Time `json:"updatedAt"`
    DeletedAt gorm.DeletedAt `json:"deletedAt,omitempty" gorm:"index"`
    Title     string    `json:"title"`
    Content   string    `json:"content"`
    Tags      Tags      `json:"tags" gorm:"type:text"`
}

type Tags []string
```

これで Memo のモデルの定義は完了です。

#### 2. database の実装
次は database の実装を行います。
コードは以下の通りです。

こちらも package として database を定義しており、データベースの接続とマイグレーションの設定を行なっています。 これらの関数はアプリを実行した段階でデータベースに接続するために使用されます。
```go: database/database.go
package database

import (
	"github.com/Koichi5/swagger_golang_flutter_sample/models"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func ConnectDatabase() {
	database, err := gorm.Open(sqlite.Open("memos.db"), &gorm.Config{})
	if err != nil {
		panic("Failed to connect to database!")
	}

	database.AutoMigrate(&models.Memo{})

	DB = database
}

func MigrateDB(db *gorm.DB) error {
    return db.AutoMigrate(&models.Memo{})
}
```

これで database の設定は完了です。

#### 3. repositories の実装
次に repositories の実装を行います。
コードは以下の通りです。

```go: repositories/memo_repository.go
package repositories

import (
	"fmt"
	"github.com/Koichi5/swagger_golang_flutter_sample/models"
	"gorm.io/gorm"
)

type MemoRepository struct {
    DB *gorm.DB
}

func NewMemoRepository(db *gorm.DB) *MemoRepository {
    return &MemoRepository{DB: db}
}

func (r *MemoRepository) Create(memo *models.Memo) error {
    return r.DB.Create(memo).Error
}

func (r *MemoRepository) GetAll() ([]models.Memo, error) {
    var memos []models.Memo
    err := r.DB.Find(&memos).Error
    for _, memo := range memos {
        fmt.Printf("Repository: Memo ID=%v, Title=%s\n", memo.ID, memo.Title)
    }
    return memos, err
}

func (r *MemoRepository) GetByID(id uint) (*models.Memo, error) {
    var memo models.Memo
    err := r.DB.First(&memo, id).Error
    if err != nil {
        return nil, err
    }
    return &memo, nil
}

func (r *MemoRepository) Update(memo *models.Memo) error {
    return r.DB.Model(memo).Updates(models.Memo{Title: memo.Title, Content: memo.Content, Tags: memo.Tags}).Error
}

func (r *MemoRepository) Delete(id uint) error {
    return r.DB.Delete(&models.Memo{}, id).Error
}

func (r *MemoRepository) SearchMemos(keyword string) ([]models.Memo, error) {
	var memos []models.Memo
	result:= r.DB.Where("title LIKE ? OR content LIKE ?", "%"+keyword+"%", "%"+keyword+"%").Find(&memos)
	return memos, result.Error
}

func (r *MemoRepository) GetByTag(tag string) ([]models.Memo, error) {
    var memos []models.Memo
    err := r.DB.Where("tags LIKE ?", "%"+tag+"%").Find(&memos).Error
    return memos, err
}
```

それぞれ詳しくみていきます。

以下では Memo を作成するためのメソッドを実装しています。
`(r *MemoRepository)` はレシーバで、この関数が `MemoRepository` 型のポインタに対するメソッドであることを示しています。Flutterでは内部にメソッドを記述しますが、Go ではこのように記述します。
`memo *models.Memo` は引数で、作成するメモのポインタを受け取ります。
`Create(memo)` は gorm のメソッドで、渡された Memo をデータベースに挿入します。
データの挿入が成功した場合は Error は nil となり、失敗した場合は Error が返ってきます。
```go
func (r *MemoRepository) Create(memo *models.Memo) error {
    return r.DB.Create(memo).Error
}
```

以下では現在保存されている Memo の一覧を取得するためのメソッドを実装しています。
Create メソッドと同様で、GetAll メソッドも `MemoRepository` のメソッドです。
返り値として、Memo の配列またはエラーを返すようにしています。
`Find(&memos)` は gorm のメソッドで、データベースから全てのメモを取得し、 `memos` に格納します。
Memo のデータが取得できているかどうかを調べるために fmt.Printf を実行していますが、本来は不要です。
```go
func (r *MemoRepository) GetAll() ([]models.Memo, error) {
    var memos []models.Memo
    err := r.DB.Find(&memos).Error
    for _, memo := range memos {
        fmt.Printf("Repository: Memo ID=%v, Title=%s\n", memo.ID, memo.Title)
    }
    return memos, err
}
```

その他のメソッドを簡単に紹介します。

+ GetByID
  Memo の ID をもとに Memo を取得するメソッド。
  引数として ID を受け取り、First メソッドを用いることで、IDが一致する一番目の Memo を返す。
  ```go
  func (r *MemoRepository) GetByID(id uint) (*models.Memo, error) {
    var memo models.Memo
    err := r.DB.First(&memo, id).Error
    if err != nil {
        return nil, err
    }
    return &memo, nil
  }
  ```

+ Update
  Memo の更新を行うメソッド。
  `Model(memo)` で更新対象のモデルを指定し、今回は Memo の ID から更新すべき Memo のデータを特定する。
  `Updates(models.Memo{})` で更新対象となった Memo の内容を更新する。
  ```go
  func (r *MemoRepository) Update(memo *models.Memo) error {
    return r.DB.Model(memo).Updates(models.Memo{Title: memo.Title, Content: memo.Content, Tags: memo.Tags}).Error
  }
  ```

+ Delete
  Memo の削除を行うメソッド。
  Delete メソッドでは第一引数で Memo を削除することを示し、第二引数で削除したい Memo の id を指定することで特定の Memo を削除することができる。
  ```go
  func (r *MemoRepository) Delete(id uint) error {
    return r.DB.Delete(&models.Memo{}, id).Error
  }
  ```

+ SearchMemos
  Memo の検索を行うメソッド。
  keyword を引数として受け取り、 Where の中で LIKE を用いて実装
  title LIKE, content LIKE で title, content の内容を検索することを示す。
  第二、第三引数で `"%"+keyword+"%"` とすることで受け取った keyword を含むことを指定できる。
  ```go
  func (r *MemoRepository) SearchMemos(keyword string) ([]models.Memo, error) {
	var memos []models.Memo
	result:= r.DB.Where("title LIKE ? OR content LIKE ?", "%"+keyword+"%", "%"+keyword+"%").Find(&memos)
	return memos, result.Error
  }
  ```

+ GetByTag
  Memo に付随する Tag のデータを元に Memo を絞り込むメソッド。
  引数として tag を受け取り、先ほどの SearchMemo メソッドと同様に LIKE で絞り込みを行い、該当の Tag を含む Memo の配列を返す。
  ```go
  func (r *MemoRepository) GetByTag(tag string) ([]models.Memo, error) {
    var memos []models.Memo
    err := r.DB.Where("tags LIKE ?", "%"+tag+"%").Find(&memos).Error
    return memos, err
  }
  ```

これで repositories の実装は完了です。
今回はサンプルということで gorm の DB を使用しましたが、そのほかにも AWS, GCP などの選択肢もあります。

#### 4. services の実装
次に services の実装に移ります。
コードは以下の通りです。
Go の実装の初めに説明したとおり、 services は models, repositories に依存しており、それが impport の部分からもわかるかと思います。
```go: services/memo_service.go
package services

import (
	"fmt"
	"github.com/Koichi5/swagger_golang_flutter_sample/models"
	"github.com/Koichi5/swagger_golang_flutter_sample/repositories"
)

type MemoService struct {
    repo *repositories.MemoRepository
}

func NewMemoService(repo *repositories.MemoRepository) *MemoService {
    return &MemoService{repo: repo}
}

func (s *MemoService) CreateMemo(memo *models.Memo) error {
    return s.repo.Create(memo)
}

func (s *MemoService) GetAllMemos() ([]models.Memo, error) {
    memos, err := s.repo.GetAll()
    // デバッグ出力を追加
    for _, memo := range memos {
        fmt.Printf("Service: Memo ID=%v, Title=%s\n", memo.ID, memo.Title)
    }
    return memos, err}

func (s *MemoService) GetMemoByID(id uint) (*models.Memo, error) {
    return s.repo.GetByID(id)
}

func (s *MemoService) UpdateMemo(id uint, title, content string, tags []string) (*models.Memo, error) {
    memo, err := s.repo.GetByID(id)
    if err != nil {
        return nil, err
    }

    memo.Title = title
    memo.Content = content
    memo.Tags = tags

    err = s.repo.Update(memo)
    if err != nil {
        return nil, err
    }

    return memo, nil
}

func (s *MemoService) DeleteMemo(id uint) error {
    return s.repo.Delete(id)
}

func (s *MemoService) SearchMemos(keyword string) ([]models.Memo, error) {
	return s.repo.SearchMemos(keyword)
}

func (s *MemoService) GetMemosByTag(tag string) ([]models.Memo, error) {
    return s.repo.GetByTag(tag)
}
```

基本的には `MemoRepository` で定義した関数を呼び出しているだけであり、引数も `MemoRepository` の実装とほぼ同じですが、 `UpdateMemo` では id で修正すべき Memo を取得して、変更しています。

今回は実装が少なかったですが、 services では以下のような実装を行うことが多いです。
+ 複数の Repository を組み合わせた処理
+ トランザクションの実行
+ 権限のチェック
+ 複雑なクエリの実行

#### 5. handlers の実装
最後に handlers の実装を行います。
コードは以下の通りです。
```go: handlers/memo_handlers.go
package handlers

import (
	"fmt"
	"net/http"
	"strconv"

	"github.com/Koichi5/swagger_golang_flutter_sample/models"
	"github.com/Koichi5/swagger_golang_flutter_sample/services"
	"github.com/gin-gonic/gin"
)

type MemoHandler struct {
    service *services.MemoService
}

func NewMemoHandler(service *services.MemoService) *MemoHandler {
    return &MemoHandler{service: service}
}

func (h *MemoHandler) CreateMemo(c *gin.Context) {
    var input struct {
        Title   string   `json:"title" binding:"required"`
        Content string   `json:"content" binding:"required"`
        Tags    []string `json:"tags"`
    }
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    memo := &models.Memo{
        Title:   input.Title,
        Content: input.Content,
        Tags:    input.Tags,
    }

    if err := h.service.CreateMemo(memo); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, memo)
}

func (h *MemoHandler) GetAllMemos(c *gin.Context) {
    memos, err := h.service.GetAllMemos()
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }
    // デバッグ出力を追加
    for _, memo := range memos {
        fmt.Printf("Handler: Memo ID=%v, Title=%s\n", memo.ID, memo.Title)
    }

    c.JSON(http.StatusOK, memos)
}

func (h *MemoHandler) GetMemoByID(c *gin.Context) {
    id, _ := strconv.ParseUint(c.Param("id"), 10, 32)
    memo, err := h.service.GetMemoByID(uint(id))
    if err != nil {
        c.JSON(http.StatusNotFound, gin.H{"error": "Memo not found"})
        return
    }

    c.JSON(http.StatusOK, memo)
}

func (h *MemoHandler) UpdateMemo(c *gin.Context) {
    id, err := strconv.ParseUint(c.Param("id"), 10, 32)
    if err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid ID"})
        return
    }

    var input struct {
        Title   string `json:"title"`
        Content string `json:"content"`
        Tags []string `json:"tags"`
    }
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    updatedMemo, err := h.service.UpdateMemo(uint(id), input.Title, input.Content, input.Tags)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, updatedMemo)
}

func (h *MemoHandler) DeleteMemo(c *gin.Context) {
    id, _ := strconv.ParseUint(c.Param("id"), 10, 32)
    if err := h.service.DeleteMemo(uint(id)); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, gin.H{"message": "Memo deleted successfully"})
}

func (h *MemoHandler) SearchMemos(c *gin.Context) {
	keyword := c.Query("keyword")
	if keyword == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Keyword is required"})
		return
	}

	memos, err := h.service.SearchMemos(keyword)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, memos)
}

func (h *MemoHandler) GetMemosByTag(c *gin.Context) {
    tag := c.Query("tag")
    if tag == "" {
        c.JSON(http.StatusBadRequest, gin.H{"error": "Tag is required"})
        return
    }

    memos, err := h.service.GetMemosByTag(tag)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusOK, memos)
}
```

メソッドを詳しくみていきます。
以下では Memo を作成するための handler を定義しています。

引数として受け取っている `c *gin.Context` は　gin のコンテキストで、リクエスト/レスポンス情報を含みます。
`input` はリクエストを JSON 形式にパースするために使用され、 `ShouldBindJSON` でエラーがあった場合（必須フィールドが欠落している場合など）は 400 Bad Request エラーを返すようにしています。

リクエストに問題がなかった場合は新しい `memo` を作成して、 service で定義していた `CreateMemo` メソッドに `memo` を渡すことで新たにメモを作成します。ここで問題が発生した場合は 500 Internal Server Error を返します。

メモの作成が完了した段階で 201 Createdステータスコードと作成されたメモのJSONを返します。
```go
func (h *MemoHandler) CreateMemo(c *gin.Context) {
    var input struct {
        Title   string   `json:"title" binding:"required"`
        Content string   `json:"content" binding:"required"`
        Tags    []string `json:"tags"`
    }
    if err := c.ShouldBindJSON(&input); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
        return
    }

    memo := &models.Memo{
        Title:   input.Title,
        Content: input.Content,
        Tags:    input.Tags,
    }

    if err := h.service.CreateMemo(memo); err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
        return
    }

    c.JSON(http.StatusCreated, memo)
}
```

他のメソッドも処理内容は異なりますが、基本的には JSON 形式でレスポンスを返し、問題がある場合は `StatusInternalServerError` や `StatusBadRequest` などの的したエラーを返却しています。

これで handler の実装は完了です。

#### 6. main.go の実装
最後に `main.go` の実装を行います。
backend ディレクトリに `main.go` ファイルを作成して、内容を以下のようにします。
```go: main.go
package main

import (
	"log"
	"github.com/Koichi5/swagger_golang_flutter_sample/database"
	"github.com/Koichi5/swagger_golang_flutter_sample/handlers"
	"github.com/Koichi5/swagger_golang_flutter_sample/repositories"
	"github.com/Koichi5/swagger_golang_flutter_sample/services"
	"github.com/gin-gonic/gin"
	"gorm.io/gorm"
)

func main() {
	database.ConnectDatabase()
	if err := database.MigrateDB(database.DB); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}

	r := setupRouter(database.DB)
	r.Run(":8080")
}

func setupRouter(db *gorm.DB) *gin.Engine {
    router := gin.Default()

    memoRepo := repositories.NewMemoRepository(db)
    memoService := services.NewMemoService(memoRepo)
    memoHandler := handlers.NewMemoHandler(memoService)

    router.POST("/memos", memoHandler.CreateMemo)
    router.GET("/memos", memoHandler.GetAllMemos)
    router.GET("/memos/:id", memoHandler.GetMemoByID)
    router.PUT("/memos/:id", memoHandler.UpdateMemo)
    router.DELETE("/memos/:id", memoHandler.DeleteMemo)
    router.GET("/memos/search", memoHandler.SearchMemos)
	router.GET("/memos/bytag", memoHandler.GetMemosByTag)

    return router
}
```

それぞれ詳しくみていきます。

以下では database で実装した `ConnectDatabase()` メソッドを実行しています。具体的にはデータベースの接続やマイグレーションを行なっています。
エラーがあれば `Fatalf` が実行され、 `os.Exit` が実行されるためアプリが終了するようになっています。
```go
	database.ConnectDatabase()
	if err := database.MigrateDB(database.DB); err != nil {
		log.Fatalf("Failed to migrate database: %v", err)
	}
```

以下では DB を受け取り、ルーターの初期化を行なっています。
`gin.Default()` は gin フレームワークを使い始めるための基本的なセットアップを自動で行ってくれるメソッドです。
```go
func setupRouter(db *gorm.DB) *gin.Engine {
    router := gin.Default()
    // 詳細実装
}
```

以下では、`setupRouter` のメソッド内で依存関係の注入を行なっています。
`memoRepo` は `db` に依存しており、 `memoService` は `memoRepo` に依存しており、 `memoHandler` は `memoService` に依存しているため以下のようになります。
このように階層構造を保っておくことで依存関係が明確になり、テストやモックの作成が簡単になります。
```go
memoRepo := repositories.NewMemoRepository(db)
memoService := services.NewMemoService(memoRepo)
memoHandler := handlers.NewMemoHandler(memoService)
```

以下ではアプリ内で使用するHTTPメソッドと対応するハンドラーの関数を定義しています。
例えば、 `/memos` に対する POST メソッドは `CreateMemo` 関数で対応するといった実装です。
```go
router.POST("/memos", memoHandler.CreateMemo)
router.GET("/memos", memoHandler.GetAllMemos)
router.GET("/memos/:id", memoHandler.GetMemoByID)
router.PUT("/memos/:id", memoHandler.UpdateMemo)
router.DELETE("/memos/:id", memoHandler.DeleteMemo)
router.GET("/memos/search", memoHandler.SearchMemos)
router.GET("/memos/bytag", memoHandler.GetMemosByTag)
```

`setupRouter` 関数ではこれらの設定が組み込まれた `router` が返却されます。
そして、 `r.Run(":8080")` で `router` の設定を反映させた状態でポート番号 `8080` で処理が実行されます。

なお、アプリケーションのデバッグする場合には `main.go` が含まれるディレクトリにおいて以下のコマンドを実行しておく必要があります。
このコマンドでサーバーが起動します。
```
go run main.go
```

正常にサーバーが起動すると以下のような出力が得られるかと思います。これでバックエンド側でリクエストを受け付けるようになります。
```
[GIN-debug] Listening and serving HTTP on :8080
```

これで Go 側の実装は完了です。

### 7. Flutter 側の実装
最後は Flutter 側の実装に入っていきます。
Flutter 側の実装は以下の2ステップで行います。

1. Memo の Controller の作成
2. UIの作成

#### 1. Memo の Controller の作成
API の実装は Swagger でできているので、 Memo に関するAPIのやり取りを行う `MemoController` を riverpod_generator を用いて実装していきます。

コードは以下の通りです。

`final DefaultApi _api = DefaultApi(ApiClient());` の部分で使用するAPIの定義を行います。
そして、APIで定義していた各メソッドを元に以下のメソッドを実装しています。
+ fetchMemos : メモの一覧取得
+ createMemo : メモの作成
+ updateMemo : メモの更新
+ deleteMemo : メモの削除
+ searchMemo : メモの検索

`build` メソッドの返り値は Future型の Memo のリストにしているので、呼び出す側では when メソッドを用いて表示を変更することになります。

```dart: memo_controller.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:swagger_golang_flutter_sample/api/lib/api.dart';

part 'memo_controller.g.dart';

@riverpod
class MemoController extends _$MemoController {
  final DefaultApi _api = DefaultApi(ApiClient());

  @override
  Future<List<Memo>> build() async {
    return [];
  }

  Future<void> fetchMemos() async {
    state = const AsyncValue.loading();
    try {
      final memos = await _api.memosGet() ?? [];
      state = AsyncValue.data(memos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createMemo(NewMemo newMemo) async {
    final createdMemo = await _api.memosPost(newMemo);
    if (createdMemo != null) {
      state = AsyncValue.data([...state.value ?? [], createdMemo]);
    }
  }

  Future<void> updateMemo(int id, NewMemo updatedMemo) async {
    state = const AsyncValue.loading();
    try {
      final updated = await _api.memosMemoIdPut(id, updatedMemo);
      if (updated != null) {
        state = AsyncValue.data(state.value!.map((memo) {
          return memo.id == id ? updated : memo;
        }).toList());
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteMemo(int id) async {
    try {
      await _api.memosMemoIdDelete(id.toString());
      state = AsyncValue.data(
        state.value?.where((memo) => memo.id != id).toList() ?? []
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> searchMemos(String keyword) async {
    state = const AsyncValue.loading();
    try {
      final searchedMemos = await _api.memosSearchGet(keyword) ?? [];
      state = AsyncValue.data(searchedMemos);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
```

#### 2. UIの作成
最後にUIの作成を行います。
こちらは簡単な解説にとどめておきます。

**メモ一覧画面**
`useEffect` でメモ一覧を取得して表示
useTextEditingController, useState でテキストフィールドの値や状態管理
メモの検索ではテキストフィールドの値が変更されてから Duration をかけて検索
```dart: memo_list_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:swagger_golang_flutter_sample/screens/create_memo_screen.dart';
import 'package:swagger_golang_flutter_sample/screens/detail_memo_screen.dart';
import 'package:swagger_golang_flutter_sample/screens/edit_memo_screen.dart';
import 'package:swagger_golang_flutter_sample/screens/state/memo_controller.dart';

class MemoListScreen extends HookConsumerWidget {
  const MemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoController = ref.watch(memoControllerProvider.notifier);
    final memos = ref.watch(memoControllerProvider);
    final searchController = useTextEditingController();
    final searchDebounce = useState<Timer?>(null);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        memoController.fetchMemos();
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memos'),
      ),
      body: memos.when(
        data: (memoList) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: 'Search Memos',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      searchController.clear();
                      memoController.fetchMemos();
                    },
                  ),
                ),
                onChanged: (value) {
                  searchDebounce.value?.cancel();
                  searchDebounce.value = Timer(
                    const Duration(milliseconds: 500),
                    () {
                      memoController.searchMemos(value);
                    },
                  );
                },
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: memoList.length,
                itemBuilder: (context, index) {
                  final memo = memoList[index];
                  return Dismissible(
                    key: Key(memo.id.toString()),
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    direction: DismissDirection.endToStart,
                    onDismissed: (direction) {
                      ref
                          .read(memoControllerProvider.notifier)
                          .deleteMemo(memo.id!);
                    },
                    child: ListTile(
                      title: Text(memo.title ?? ''),
                      subtitle: Text(memo.content ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMemoScreen(memo: memo),
                            ),
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailMemoScreen(memo: memo),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateMemoScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**メモ詳細画面**
メモ一覧画面からメモを受け取って遷移。
基本的にデータの表示のみ。
```dart: detail_memo_screen.dart
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:swagger_golang_flutter_sample/api/lib/api.dart';

class DetailMemoScreen extends StatelessWidget {
  const DetailMemoScreen({
    required this.memo,
    super.key,
  });

  final Memo memo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Title',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(memo.title ?? 'No title'),
            const Gap(24),
            const Text(
              'Content',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Text(memo.content ?? 'No content'),
            const Gap(24),
            const Text(
              'Tags',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Gap(8),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: (memo.tags)
                  .map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.blue.shade100,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
```

**メモ作成画面**
`createMemo` メソッドで `memoControllerProvider` の `createMemo` を実行
テキストや追加されているタグの状態は Hooks で管理
```dart: create_memo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:swagger_golang_flutter_sample/api/lib/api.dart';
import 'package:swagger_golang_flutter_sample/screens/state/memo_controller.dart';

class CreateMemoScreen extends HookConsumerWidget {
  const CreateMemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final tagController = useTextEditingController();
    final tags = useState<List<String>>([]);

    void addTag() {
      if (tagController.text.isNotEmpty) {
        tags.value = [...tags.value, tagController.text];
        tagController.clear();
      }
    }

    Future<void> createMemo() async {
      if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
        final newMemo = NewMemo(
          title: titleController.text,
          content: contentController.text,
          tags: tags.value,
        );

        await ref.read(memoControllerProvider.notifier).createMemo(newMemo);
        Navigator.pop(context, true);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('新規メモ作成'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(labelText: '内容'),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: tagController,
                    decoration: const InputDecoration(labelText: 'タグ'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addTag,
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: tags.value.map((tag) => Chip(
                label: Text(tag),
                onDeleted: () {
                  tags.value = tags.value.where((t) => t != tag).toList();
                },
              )).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: createMemo,
              child: const Text('メモを作成'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**メモ編集画面**
メモ一覧画面から編集したいメモのデータが渡される。
`updateMemo` メソッドで `memoControllerProvider` の `updateMemo` を呼び出してデータ更新。
タグの情報は `tags` として useState で管理。
```dart: edite_memo_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:swagger_golang_flutter_sample/api/lib/api.dart';
import 'package:swagger_golang_flutter_sample/screens/state/memo_controller.dart';

class EditMemoScreen extends HookConsumerWidget {
  final Memo memo;

  const EditMemoScreen({
    super.key,
    required this.memo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final titleController = useTextEditingController(text: memo.title);
    final contentController = useTextEditingController(text: memo.content);
    final tagController = useTextEditingController();
    final tags = useState<List<String>>(memo.tags.toList());

    void addTag() {
      if (tagController.text.isNotEmpty) {
        tags.value = [...tags.value, tagController.text];
        tagController.clear();
      }
    }

    Future<void> updateMemo() async {
      if (formKey.currentState!.validate()) {
        try {
          final updatedMemo = NewMemo(
            title: titleController.text,
            content: contentController.text,
            tags: tags.value,
          );
          await ref
              .read(memoControllerProvider.notifier)
              .updateMemo(memo.id!, updatedMemo);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('メモが更新されました')),
            );
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('エラーが発生しました: $e')),
            );
          }
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('メモを編集'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルを入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: contentController,
                decoration: const InputDecoration(labelText: '内容'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '内容を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: tagController,
                      decoration: const InputDecoration(labelText: 'Add Tag'),
                      onSubmitted: (_) => addTag(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: addTag,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: tags.value
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        onDeleted: () {
                          tags.value =
                              tags.value.where((t) => t != tag).toList();
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: updateMemo,
                child: const Text('メモを更新'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

これで Flutter 側の実装は完了です。
最終的には以下の動画のようにメモの基本的な機能が実装されていることがわかるかと思います。

https://youtube.com/shorts/btlcRVUknf8

冒頭でも述べましたが、今回の実装したコードは以下で公開しているので、よろしければご覧ください。

https://github.com/Koichi5/swagger-golang-flutter-sample

## まとめ
最後まで読んでいただいてありがとうございました。

今回 Swagger と Go を使ってみて、Claude などに頼りながらではありましたがシンプルなアプリを実装できました。Go に関して深く触れてこなかったので身構えていたのですが、ORMもあって比較的短時間で実装することができました。
今までオブジェクト指向言語をメインで扱ってきていたので、クラスに当たる表現がないことに今更衝撃を受けましたが、外部でメソッドを定義するのも新鮮で面白いと感じました。

Flutter と Firebase の相性が良すぎるが故に Firebase 以外の選択肢を積極的に試していませんでしたが、今回試してみて新たな選択肢として持っておいた方が良いなと感じました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://go.dev/

https://qiita.com/hasesiu/items/cbdb7e9c9a4d13886485

https://swagger.io/

https://qiita.com/oukayuka/items/0021f8bfb45d072fd107



