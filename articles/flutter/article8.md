## 初めに
今回は Flutter で Firebase Messaging を用いた通知機能を実装してみたいと思います。
今回は Android のエミュレータで実装を進めていきます。

## 記事の対象者
+ Flutter 学習者
+ Firebase Messaging で通知機能を実装したい方

## 目的
今回は先述の通り `Firebase Messaging` を用いた実装を行います。
`Cloud Firestore`、`Cloud Functions`、`Firebase Auth`、`Firebase Messaging` を連携して通知機能を実装します。
最終的には、 `Cloud Firestore` にデータが作成された段階で通知を飛ばすような実装を行います。

## 準備
今回は以下の手順が完了されている段階から実装を進めていきます。
- Flutter のプロジェクト作成
- Firebase のプロジェクト作成
- Firebase Auth のメール・パスワードログイン設定
- Cloud Firestore の設定
- Cloud Functions の設定

これらの設定は Cloud Functions を実装した以下の記事でも行なっているため、よろしければご参照ください。
[【Flutter】Cloud Functionを試してみる](https://zenn.dev/koichi_51/articles/d5e17ed74f13ef)

これらの設定が完了したら、 Flutter プロジェクトに必要な設定を行います。
今回使用する以下のパッケージの最新バージョンを `pubspec.yaml` に追加していきます。

dependences
+ [firebase_core](https://pub.dev/packages/firebase_core)
+ [cloud_functions](https://pub.dev/packages/cloud_functions)
+ [firebase_auth](https://pub.dev/packages/firebase_auth)
+ [cloud_firestore](https://pub.dev/packages/cloud_firestore)
+ [firebase_messaging](https://pub.dev/packages/firebase_messaging)
+ [flutter_riverpod](https://pub.dev/packages/flutter_riverpod)
+ [riverpod_annotation](https://pub.dev/packages/riverpod_annotation)
+ [hooks_riverpod](https://pub.dev/packages/hooks_riverpod)
+ [flutter_hooks](https://pub.dev/packages/flutter_hooks)
+ [freezed_annotation](https://pub.dev/packages/freezed_annotation)
+ [intl](https://pub.dev/packages/intl)
+ [gap](https://pub.dev/packages/gap)
+ [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

dev_dependencies
+ [build_runner](https://pub.dev/packages/build_runner)
+ [riverpod_generator](https://pub.dev/packages/riverpod_generator)
+ [freezed](https://pub.dev/packages/freezed)
+ [json_serializable](https://pub.dev/packages/json_serializable)

`pubspec.yaml` は以下のようになっています。
```yaml: pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  # firebase
  firebase_core: ^3.3.0
  cloud_functions: ^5.0.4
  firebase_auth: ^5.1.4
  cloud_firestore: ^5.2.1
  firebase_messaging: ^15.1.0

  # riverpod
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hooks_riverpod: ^2.5.2

  flutter_hooks: ^0.20.5
  freezed_annotation: ^2.4.4
  intl: ^0.19.0
  gap: ^3.0.1
  flutter_local_notifications: ^17.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.11
  riverpod_generator: ^2.4.0
  freezed: ^2.5.2
  json_serializable: ^6.8.0
```

これで準備は完了です。
なお、iOSの場合は別途準備が必要になるため、別の機会にまとめられたらと思います。

## 実装
実装は以下の手順で進めていこうと思います。
1. 通知を呼び出すサンプルの実装
2. Cloud Firestore のコレクションに連動した通知
3. アプリ使用中（フォアグラウンド）の通知

### 1. 通知を呼び出すサンプルの実装
まずは通知を呼び出すサンプルの実装を行います。
この章では、ボタンを押すと自分の端末に通知を送る実装を行います。あまり使用する機会はないかと思いますが、仕組みの理解のために実装してみます。
実装は以下の手順で進めていきます。
1. Cloud Functions の実装
2. Flutter の実装

#### 1. Cloud Functions の実装
`ルートディレクトリ > functions > src` ディレクトリ配下に `message` ディレクトリを作成して、 `sendMessage.ts` を作成します。
コードは以下の通りです。
```ts: functions > messages > sendMessage.ts
import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';

const sendPushNotification = async function(
  token: string,
  title: string,
  body: string,
  badgeCount: string
) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
    android: {
      notification: {
        sound: "default"
      }
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: parseInt(badgeCount, 10)
        }
      }
    }
  };

  try {
    const response = await admin.messaging().send(message);
    console.log('Successfully sent message:', response);
    return response;
  } catch (error) {
    console.error('Error sending message:', error);
    throw error;
  }
};

export const sendMessage = onCall(async (request) => {
  const { fcmToken, title, body } = request.data;
  if (!fcmToken || !title || !body) {
    throw new HttpsError("invalid-argument", "fcmToken, title and body are required")
  }

  await sendPushNotification(fcmToken, title, body, "1");
});
```

それぞれ詳しくみていきます。

以下では、それぞれ必要なデータを受け取って通知を送信する `sendPushNotification` を実装しています。受け取っているデータはそれぞれ以下です。
- token: デバイスの Firebase Cloud Messaging トークン
- title: 通知のタイトル
- body: 通知の本文
- badgeCount: iOSデバイスのバッジ数

`android` は Android固有の通知の設定
`apns` は `Apple Push Notification Service` の略で、iOS固有の通知の設定を示します。
```ts
const sendPushNotification = async function(
  token: string,
  title: string,
  body: string,
  badgeCount: string
) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
    android: {
      notification: {
        sound: "default"
      }
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: parseInt(badgeCount, 10)
        }
      }
    }
  };
```

以下では、先程定義した `message` を受け取って実際に通知を行う `admin.messaging.send()` を実行しています。
通知の送信が成功した場合はレスポンスを、失敗した場合はエラーを返却しています。
```ts
try {
  const response = await admin.messaging().send(message);
  console.log('Successfully sent message:', response);
  return response;
} catch (error) {
  console.error('Error sending message:', error);
  throw error;
}
```

以下では `onCall` で外部から呼び出すための `sendMessage` 関数を定義しています。
必要なデータが揃っていない場合は `HttpsError` を返し、データが揃っている場合は先程定義した `sendPushNotification` を実行しています。
```ts
export const sendMessage = onCall(async (request) => {
  const { fcmToken, title, body } = request.data;
  if (!fcmToken || !title || !body) {
    throw new HttpsError("invalid-argument", "fcmToken, title and body are required")
  }

  await sendPushNotification(fcmToken, title, body, "1");
});
```

これで関数の定義は完了です。

次に `index.ts` の編集を行います。
`ルートディレクトリ > functions > src` 配下の `index.ts` に以下の export を追加します。
```ts: index.ts
export { sendMessage } from "./message/sendMessage"
```

最後に関数のデプロイを行います。
ターミナルで以下のコマンドを実行します。
```
firebase deploy --only functions
```

デプロイのコマンドを実行して、以下が表示されたらデプロイは完了です。
```
✔  Deploy complete!
```

#### 2. Flutter の実装
次に Flutter 側の実装を行います。

まずは `main.dart` の編集を行います。
コードは以下の通りです。

`requestPermission()` を追加することで通知機能を使用する許可を求めます。
```dart: main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Messaging
  final messagingInstance = FirebaseMessaging.instance;
  messagingInstance.requestPermission();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}
```

次に通知を送信する画面の実装を行います。
コードは以下のようになります。
```dart
import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NotificationSampleScreen extends HookConsumerWidget {
  const NotificationSampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fcmToken = useState('');
    final cloudFunctions = FirebaseFunctions.instance;
    final firebaseMessaging = FirebaseMessaging.instance;
    final titleController = useTextEditingController();
    final bodyController = useTextEditingController();
    useEffect(() {
      scheduleMicrotask(() async {
        fcmToken.value = await firebaseMessaging.getToken() ?? '';
      });
      return null;
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Messaging Sample'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'タイトル',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const Gap(16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(
                labelText: 'メッセージ',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const Gap(16),
            ElevatedButton(
              onPressed: () async {
                await cloudFunctions.httpsCallable('sendMessage').call({
                  'fcmToken': fcmToken.value,
                  'title': titleController.text,
                  'body': bodyController.text,
                });
              },
              child: const Text('送信'),
            ),
          ],
        ),
      ),
    );
  }
}
```

それぞれ詳しくみていきます。

以下では fcmToken, title, body の状態を保持する State を定義しています。
通知のタイトルやメッセージもカスタムできるようにするために TextEditingController を保持しておきます。
また、Functions と FirebaseMessaging の呼び出しを行うためにインスタンスを保持しておきます。
```dart
final fcmToken = useState('');
final cloudFunctions = FirebaseFunctions.instance;
final firebaseMessaging = FirebaseMessaging.instance;
final titleController = useTextEditingController();
final bodyController = useTextEditingController();
```

以下では `useEffect` の中で非同期処理を実行して、`firebaseMessaging.getToken()` を実行しています。FirebaseMessaging を用いた通知を行うためにはデバイスのトークンが必要になります。そのトークンを `fcmToken` の状態として保持しておきます。
```dart
useEffect(() {
  scheduleMicrotask(() async {
    fcmToken.value = await firebaseMessaging.getToken() ?? '';
  });
  return null;
});
```

以下では、`ElevatedButton` を押した際の処理として、先程 Functions 側で定義した `sendMessage` を実行しています。これで `sendMessage` が発火して通知が届くようになります。
```dart
ElevatedButton(
  onPressed: () async {
    await cloudFunctions.httpsCallable('sendMessage').call({
      'fcmToken': fcmToken.value,
      'title': titleController.text,
      'body': bodyController.text,
    });
  },
  child: const Text('送信'),
),
```

以上のコードで実行してみると以下の動画のように通知が受け取れるかと思います。
なお、まだアプリを実行中（フォアグラウンドの状態）に通知を受け取る設定をしていないため、アプリをバックグラウンドにして少し待つと通知が受け取れます。

https://youtube.com/shorts/JTQ1w1kfTMw

### 2. Cloud Firestore のコレクションに連動した通知
次に Cloud Firestore のコレクションと連動した通知の実装に移ります。
今回は、`message` というコレクションにデータが作成されたときに通知するといった実装を行います。
実装は先ほどの章と同様に以下の手順で進めていきます。
1. Cloud Functions の実装
2. Flutter の実装

#### 1. Cloud Functions の実装
まずは Cloud Functions の実装を行います。
`functions > src > message` ディレクトリに `onCreateMessage.ts` ファイルを作成して編集します。
コードは以下の通りです。
```ts: onCreateMessage.ts
import * as admin from "firebase-admin";
import * as functions from "firebase-functions";

const sendPushNotification = async function (
  token: string,
  title: string,
  body: string,
  badgeCount: string
) {
  const message = {
    notification: {
      title: title,
      body: body,
    },
    token: token,
    android: {
      notification: {
        sound: "default",
      },
    },
    apns: {
      payload: {
        aps: {
          sound: "default",
          badge: parseInt(badgeCount, 10),
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log("Successfully sent message:", response);
    return response;
  } catch (error) {
    console.error("Error sending message:", error);
    throw error;
  }
};

export const onCreateMessage = functions.firestore
  .document("/message/{messageId}")
  .onCreate(async (snapshot) => {
    try {
      const message = snapshot.data();

      if (
        !message.receiverIds ||
        !Array.isArray(message.receiverIds) ||
        message.receiverIds.length === 0
      ) {
        console.error("receiverIds is missing or invalid");
        return;
      }

      const usersRef = admin.firestore().collection("users");

      for (const receiverId of message.receiverIds) {
        const receiverDoc = await usersRef.doc(receiverId).get();

        if (receiverDoc.exists) {
          const receiver = receiverDoc.data();
          const fcmToken = receiver?.fcmToken;

          if (fcmToken) {
            const senderName = message.senderName || "Unknown";
            const content = message.content || "New message";

            const title = `${senderName}`;
            const body = `${content}`;

            const result = await sendPushNotification(
              fcmToken,
              title,
              body,
              "1"
            );
            console.log(`Notification send result for ${receiverId}:`, result);
          } else {
            console.error(`FCM token is missing for user ${receiverId}`);
          }
        } else {
          console.log(`Receiver document does not exist for ${receiverId}`);
        }
      }
      console.log("All notifications processed");
    } catch (error) {
      console.error("Error in onCreateMessage:", error);
    }
  });
```

それぞれ詳しくみていきます。

`sendPushNotification` は前の章と同じ実装であるため割愛します。

以下では、 `onCreateMessage` 関数を定義しています。この関数は、message コレクションにデータが追加された時（onCreate）に実行するように定義しています。
また、`message` コレクションに作成されたデータは `snapshot` として受け取っており、作成されたデータに応じた処理が可能になっています。
```ts
export const onCreateMessage = functions.firestore
  .document("/message/{messageId}")
  .onCreate(async (snapshot) => {
```

以下では、 `onCreate` で受け取った `snapshot` を参照して、メッセージの受信者がいるかどうかを確かめています。 `message` コレクションの `receiverIds` フィールドを確認することができ、このフィールドが空の場合はメッセージの受信者がいないことになるので、コンソールにエラーを出力するようにしています。
```ts
try {
  const message = snapshot.data();

  if (
    !message.receiverIds ||
    !Array.isArray(message.receiverIds) ||
    message.receiverIds.length === 0
  ) {
    console.error("receiverIds is missing or invalid");
    return;
  }
```

以下では、メッセージの受信者のIDのリスト（`message.receiverIds`）に当てはまるユーザーを `users` コレクションから探してきて、その `fcmToken` を `sendPushNotification` に渡すことで通知を送信しています。
```ts
const usersRef = admin.firestore().collection("users");  // ユーザーのコレクション

for (const receiverId of message.receiverIds) {
  const receiverDoc = await usersRef.doc(receiverId).get();  // 受信者IDと一致するユーザーのデータ

  if (receiverDoc.exists) {
    const receiver = receiverDoc.data();
    const fcmToken = receiver?.fcmToken;

    if (fcmToken) {
      const senderName = message.senderName || "Unknown";
      const content = message.content || "New message";

      const title = `${senderName}`;
      const body = `${content}`;

      const result = await sendPushNotification(  // 通知送信
        fcmToken,
        title,
        body,
        "1"
      );
```

これで以下の手順で複数のユーザーに通知が送信できるような関数の実装が完了しました。
1. message コレクションにデータが作成される
2. message コレクションのデータの受信者のリストを参照
3. 受信者のリストからユーザーを検索
4. ユーザーの `fcmToken` を取得
5. `fcmToken` をもとに通知を送信

次に `index.ts` に以下のコードを追加して、関数を export します。
```ts
export { onCreateMessage } from "./message/onCreateMessage";
```

最後に関数をデプロイする以下のコマンドを実行して Cloud Functions の設定は完了です。
```
firebase deploy --only functions
```

#### 2. Flutter の実装
次に Flutter 側の実装を行います。
Flutter 側の実装は以下の手順で進めていきます。
1. models の作成
2. repositories の作成
3. services の作成
4. screens の作成

**1. models の作成**
まずは `models` の作成を行います。
必要なモデルは通知のデータを扱う `Message` とユーザーのデータを扱う `FirestoreUser` です。 `User` とすると FirebaseAuth のユーザーと被ってしまうためこのような命名にしています。

`models` ディレクトリを作成して以下のようなコードを追加していきます。

まずは `FirestoreUser` のモデルを作成していきます。
```dart: firestore_user.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'firestore_user.freezed.dart';
part 'firestore_user.g.dart';

@freezed
abstract class FirestoreUser with _$FirestoreUser {
  const factory FirestoreUser({
    required String name,
    required String email,
    required String fcmToken,
  }) = _FirestoreUser;

  const FirestoreUser._();

  factory FirestoreUser.fromJson(Map<String, dynamic> json) => _$FirestoreUserFromJson(json);

  static String get collectionName => 'users';

  static FirestoreUser get mock => const FirestoreUser(
        name: 'name',
        email: 'name',
        fcmToken: 'fcmToken',
      );
}
```

`FirestoreUser` は以下のようなデータを保持するようにします。
- name : ユーザー名
- email : ユーザーのメールアドレス
- fcmToken : ユーザーの Firebase Cloud Messagin トークン

[FCM 登録トークン管理のベスト プラクティス](https://firebase.google.com/docs/cloud-messaging/manage-tokens?hl=ja) のドキュメントには、最新のトークンをサーバーに保存しておくことがベストプラクティスとして紹介されています。

次に `Message` の実装をしていきます。
コードは以下の通りです。
```dart: message.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const Message._();

  const factory Message({
    required String id,
    required String content,
    required DateTime createdAt,
    required List<String> receiverIds,
    required String senderId,
    required String senderName,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message.fromJson({
      'id': doc.id,
      'content': data['content'] ?? '',
      'createdAt': (data['createdAt'] as Timestamp).toDate().toIso8601String(),
      'receiverIds': List<String>.from(data['receiverIds'] ?? []),
      'senderId': data['senderId'] ?? '',
      'senderName': data['senderName'] ?? '',
    });
  }

  Map<String, dynamic> toFirestore() {
    return toJson()
      ..addAll({
        'createdAt': Timestamp.fromDate(createdAt),
      })
      ..remove('id');
  }

  static String get collectionName => 'message';
}
```

`Message` は以下のようなデータを保持するようにします。
- id : メッセージのID
- content : メッセージの内容
- createdAt : 作成日時
- receiverIds : 受信者のIDのリスト
- senderId : 送信者のID
- senderName : 送信者の名前


**2. repositories の作成**
次に repositories の編集を進めていきます。
まずは mixin の実装を進めていきます。
それぞれコードは以下の通りです。

FirebaseAuthAccessMixin
FirebaseAuth のインスタンスと現在のユーザーを保持するための mixin を以下のように定義します。
```dart: mixin > firebase_auth_access_mixin.dart
import 'package:firebase_auth/firebase_auth.dart';

mixin FirebaseAuthAccessMixin {
  FirebaseAuth get firebaseAuth => FirebaseAuth.instance;
  User? get currentUser => firebaseAuth.currentUser;
}
```

FireabseMessagingAccessMixin
FireabseMessaging のインスタンスを保持するための mixin を以下のように定義します。
```dart: mixin > firebase_messaging_access_mixin.dart
import 'package:firebase_messaging/firebase_messaging.dart';

mixin FireabseMessagingAccessMixin {
  FirebaseMessaging get firebaseMessaging => FirebaseMessaging.instance;
}
```

FirestoreAccessMixin
Firestore のインスタンスを保持するための mixin を以下のように定義します。
```dart
import 'package:cloud_firestore/cloud_firestore.dart';

mixin FirestoreAccessMixin {
  FirebaseFirestore get firestore => FirebaseFirestore.instance;
}
```

次にユーザーの Repository を作成していきます。
コードは以下の通りです。
`abstract` のクラスとして Repository を定義し、以下の関数を実装しています。
- ユーザーの新規登録
- サインイン
- Firestoreへの登録
- ユーザー一覧の取得

```dart: user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:functions_sample/message/models/user/firestore_user.dart';

abstract class UserRepository {
  Future<FirestoreUser?> createUser({
    required String email,
    required String password,
    required String name,
  });
  Future<FirestoreUser?> signIn({
    required String email,
    required String password,
    required String name,
  });
  Future<void> saveToFirestore({
    required String uid,
    required FirestoreUser user,
  });
  Stream<QuerySnapshot<Map<String, dynamic>>> users();
}
```

次に `FirestoreUserRepository` を実装していきます。
コードは以下の通りです。
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:functions_sample/message/models/user/firestore_user.dart';
import 'package:functions_sample/message/repositories/mixin/firebase_auth_access_mixin.dart';
import 'package:functions_sample/message/repositories/mixin/firebase_messaging_access_mixin.dart';
import 'package:functions_sample/message/repositories/mixin/firestore_access_mixin.dart';
import 'package:functions_sample/message/repositories/user_repository.dart';

class FirestoreUserRepository extends UserRepository
    with
        FirebaseAuthAccessMixin,
        FirestoreAccessMixin,
        FireabseMessagingAccessMixin {
  @override
  Future<FirestoreUser?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final authResult = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        authResult.user!.updateDisplayName(name);
        String? fcmToken = await firebaseMessaging.getToken();
        if (fcmToken != null) {
          final user = FirestoreUser(
            email: email,
            fcmToken: fcmToken,
            name: name,
          );
          await saveToFirestore(
            uid: authResult.user!.uid,
            user: user,
          );
          return user;
        }
      }
    } catch (e) {
      debugPrint('ユーザー作成エラー: $e');
    }
    return null;
  }

  @override
  Future<FirestoreUser?> signIn({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final authResult = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (authResult.user != null) {
        String? fcmToken = await firebaseMessaging.getToken();

        if (fcmToken != null) {
          final user = FirestoreUser(
            email: email,
            fcmToken: fcmToken,
            name: name,
          );

          await saveToFirestore(
            uid: authResult.user!.uid,
            user: user,
          );

          return user;
        }
      }
    } catch (e) {
      debugPrint('サインインエラー: $e');
    }
    return null;
  }

  @override
  Future<void> saveToFirestore({
    required String uid,
    required FirestoreUser user,
  }) async {
    await firestore.collection(FirestoreUser.collectionName).doc(uid).set(
          user.toJson(),
        );
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> users() {
    return firestore.collection('users').snapshots();
  }
}
```

`FirestoreUserRepository` に関して詳しくみていきます。

以下では `createUser` を実装しており、FirebaseAuth のユーザー新規登録と Firestore への登録を行なっています。
ここで Firebase Cloud Messaging Token を取得し、 Firestore へ登録しておくことで毎回トークンを取得する必要がなくなります。
```dart
Future<FirestoreUser?> createUser({
  required String email,
  required String password,
  required String name,
}) async {
  try {
    // メールアドレスとパスワードを用いた FirebaseAuth のユーザー新規登録
    final authResult = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (authResult.user != null) {
      authResult.user!.updateDisplayName(name);  // displayName の更新
      String? fcmToken = await firebaseMessaging.getToken();  // fcmToken の取得
      if (fcmToken != null) {
        final user = FirestoreUser(
          email: email,
          fcmToken: fcmToken,
          name: name,
        );
        await saveToFirestore(  // Firestore へのユーザーデータ登録
          uid: authResult.user!.uid,
          user: user,
        );
        return user;
      }
    }
  } catch (e) {
    debugPrint('ユーザー作成エラー: $e');
  }
  return null;
}
```

以下では `signIn` を実装しています。
サインインメソッドを実行して、Firestore に保存されているデータの更新も行なっています。
```dart
Future<FirestoreUser?> signIn({
  required String email,
  required String password,
  required String name,
}) async {
  try {
    // Firebase Auth でサインイン
    final authResult = await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (authResult.user != null) {
      String? fcmToken = await firebaseMessaging.getToken();

      if (fcmToken != null) {
        final user = FirestoreUser(
          email: email,
          fcmToken: fcmToken,
          name: name,
        );

        // 4. Firestore にユーザー情報を保存
        await saveToFirestore(
          uid: authResult.user!.uid,
          user: user,
        );

        return user;
      }
    }
  } catch (e) {
    debugPrint('サインインエラー: $e');
  }
  return null;
}
```

以下ではユーザー一覧の取得を実装しています。
Firestore の `users` コレクションのスナップショットを Stream で取得しています。
```dart
Stream<QuerySnapshot<Map<String, dynamic>>> users() {
  return firestore.collection('users').snapshots();
}
```

次にメッセージの Repository を作成していきます。
コードは以下の通りです。
`abstract` のクラスとして Repository を定義し、以下の関数を実装しています。
- メッセージの作成
- メッセージの一覧取得

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class MessageRepository {
  Future<void> createMessage({
    required String id,
    required String content,
    required DateTime createdAt,
    required List<String> receiverIds,
    required String senderName,
  });

  Stream<QuerySnapshot<Map<String, dynamic>>> messages();
}
```

次に `FirestoreMessageRepository` を実装していきます。
コードは以下の通りです。
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:functions_sample/message/models/message/message.dart';
import 'package:functions_sample/message/repositories/message_repository.dart';
import 'package:functions_sample/message/repositories/mixin/firebase_auth_access_mixin.dart';
import 'package:functions_sample/message/repositories/mixin/firestore_access_mixin.dart';

class FirestoreMessageRepository extends MessageRepository
    with FirestoreAccessMixin, FirebaseAuthAccessMixin {
  @override
  Future<void> createMessage({
    required String id,
    required String content,
    required DateTime createdAt,
    required List<String> receiverIds,
    required String senderName,
  }) async {
    final message = Message(
      id: id,
      content: content,
      createdAt: createdAt,
      receiverIds: receiverIds,
      senderId: currentUser?.uid ?? '',
      senderName: currentUser?.displayName ?? 'Unknown User',
    );
    await firestore
        .collection(Message.collectionName)
        .add(message.toFirestore());
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> messages() {
    return firestore
        .collection(Message.collectionName)
        .where('receiverIds', arrayContains: currentUser?.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
```

それぞれ詳しくみていきます。

以下ではメッセージを作成する `createMessage` を実装しています。
`message` コレクションにデータを作成するため、このデータの作成をトリガーとして通知が発火するようになります。
```dart
Future<void> createMessage({
  required String id,
  required String content,
  required DateTime createdAt,
  required List<String> receiverIds,
  required String senderName,
}) async {
  final message = Message(
    id: id,
    content: content,
    createdAt: createdAt,
    receiverIds: receiverIds,
    senderId: currentUser?.uid ?? '',
    senderName: currentUser?.displayName ?? 'Unknown User',
  );
  await firestore
      .collection(Message.collectionName)
      .add(message.toFirestore());
}
```

以下ではメッセージの一覧を Stream 型で取得しています。
受信者のIDが自分以外のものに関して、作成日を降順にして取得しています。
```dart
Stream<QuerySnapshot<Map<String, dynamic>>> messages() {
  return firestore
      .collection(Message.collectionName)
      .where('receiverIds', arrayContains: currentUser?.uid)
      .orderBy('createdAt', descending: true)
      .snapshots();
}
```

これで repositories の実装は完了です。

**3. services の作成**
次に services の実装を進めていきます。

まずは `FirestoreUserManager` の実装を行います。
コードは以下の通りです。
基本的には、`FirestoreUserRepository` で実装した関数を実行しています。
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:functions_sample/message/models/user/firestore_user.dart';
import 'package:functions_sample/message/repositories/firestore_user_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_user_manager.g.dart';

@riverpod
class FirestoreUserManager extends _$FirestoreUserManager {
  final repository = FirestoreUserRepository();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> build() => users();

  Stream<QuerySnapshot<Map<String, dynamic>>> users() {
    return repository.users();
  }

  Future<FirestoreUser?> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    return await repository.createUser(
      email: email,
      password: password,
      name: name,
    );
  }

  Future<FirestoreUser?> signIn({
    required String email,
    required String password,
    required String name,
  }) async {
    return await repository.signIn(
      email: email,
      password: password,
      name: name,
    );
  }
}
```

次に `FirestoreMessageManager` の実装を行います。
コードは以下の通りです。
基本的には、`FirestoreMessageRepository` で実装した関数を実行しています。
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:functions_sample/message/repositories/firestore_message_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'firestore_message_manager.g.dart';

@riverpod
class FirestoreMessageManager extends _$FirestoreMessageManager {
  final repository = FirestoreMessageRepository();

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> build() => messages();

  Stream<QuerySnapshot<Map<String, dynamic>>> messages() {
    return repository.messages();
  }

  Future<void> createMessage({
    required String id,
    required String content,
    required DateTime createdAt,
    required List<String> receiverIds,
    required String senderName,
  }) async {
    await repository.createMessage(
      id: id,
      content: content,
      createdAt: createdAt,
      receiverIds: receiverIds,
      senderName: senderName,
    );
  }
}
```

**4. screens の作成**
次に screens の作成を行います。
以下の画面の実装を行います。それぞれ長いので折りたたんでいます。
- ユーザーサインイン・新規登録画面
- メッセージ作成画面
- メッセージ一覧画面
- メッセージ詳細画面

**ユーザーサインイン・新規登録画面**
ユーザーのメールアドレス、パスワードを受け取ってサインインまたは新規登録を行います。
::: details コード全文
```dart: notification_auth_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functions_sample/message/screens/notification_list_screen.dart';
import 'package:functions_sample/message/services/user/firestore_user_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NotificationAuthScreen extends HookConsumerWidget {
  const NotificationAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firestoreUserManager =
        ref.read(firestoreUserManagerProvider.notifier);
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isLoading = useState(false);
    final isSignIn = useState(true);

    void authenticate() async {
      if (emailController.text.isEmpty || passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メールアドレスとパスワードを入力してください')),
        );
        return;
      }

      isLoading.value = true;
      final user = isSignIn.value
          ? await firestoreUserManager.signIn(
              email: emailController.text,
              password: passwordController.text,
              name: nameController.text,
            )
          : await firestoreUserManager.createUser(
              email: emailController.text,
              password: passwordController.text,
              name: nameController.text,
            );
      isLoading.value = false;

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isSignIn.value ? "サインイン" : "新規登録"}成功: ${user.email}',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NotificationListScreen(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${isSignIn.value ? "サインイン" : "新規登録"}に失敗しました',
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isSignIn.value ? 'サインイン' : '新規登録',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'ニックネーム',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: 'パスワード',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading.value ? null : authenticate,
              child: isLoading.value
                  ? const CircularProgressIndicator()
                  : Text(isSignIn.value ? 'サインイン' : '新規登録'),
            ),
            TextButton(
              onPressed: () => isSignIn.value = !isSignIn.value,
              child: Text(
                isSignIn.value ? '新規登録はこちら' : 'サインインはこちら',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```
:::
<br />

**メッセージ作成画面**
ユーザーのリストを取得し、受信者としてセットすることができ、どのユーザーに対してメッセージを送信するかを選択することができます。
::: details コード全文
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functions_sample/notes/repositories/mixin/firebase_auth_access_mixin.dart';
import 'package:functions_sample/message/services/message/firestore_message_manager.dart';
import 'package:functions_sample/message/services/user/firestore_user_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class CreateMessageScreen extends HookConsumerWidget
    with FirebaseAuthAccessMixin {
  const CreateMessageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentController = useTextEditingController();
    final selectedReceivers = useState<List<String>>([]);
    final isLoading = useState(false);

    final messageManager = ref.read(firestoreMessageManagerProvider.notifier);
    final usersStream =
        ref.watch(firestoreUserManagerProvider.notifier).users();
    final users = useStream(usersStream);

    void sendMessage() async {
      if (contentController.text.isEmpty || selectedReceivers.value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('メッセージと少なくとも1人の受信者を選択してください'),
          ),
        );
        return;
      }

      isLoading.value = true;

      try {
        messageManager.createMessage(
          id: '',
          content: contentController.text,
          createdAt: DateTime.now(),
          receiverIds: selectedReceivers.value,
          senderName: currentUser?.displayName ?? 'Unknown User',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('メッセージを送信しました')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラーが発生しました: $e')),
        );
      } finally {
        isLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('新規メッセージ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: 'メッセージ',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            const Text('受信者を選択 (複数選択可)'),
            Expanded(
              child: ListView.builder(
                itemCount: users.data?.docs.length ?? 0,
                itemBuilder: (context, index) {
                  final user = users.data!.docs[index];
                  final userData = user.data();
                  return CheckboxListTile(
                    title: Text(userData['name'] ?? 'Unknown User'),
                    value: selectedReceivers.value.contains(user.id),
                    onChanged: (bool? value) {
                      if (value == true) {
                        selectedReceivers.value = [
                          ...selectedReceivers.value,
                          user.id
                        ];
                      } else {
                        selectedReceivers.value = selectedReceivers.value
                            .where((id) => id != user.id)
                            .toList();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading.value ? null : sendMessage,
              child: isLoading.value
                  ? const CircularProgressIndicator()
                  : const Text('送信'),
            ),
          ],
        ),
      ),
    );
  }
}
```
:::
<br />

**メッセージ一覧画面**
`message` コレクションの Stream を一覧として表示します。
::: details コード全文
```dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:functions_sample/message/screens/create_message_screen.dart';
import 'package:functions_sample/message/models/message/message.dart';
import 'package:functions_sample/message/screens/notification_detail_screen.dart';
import 'package:functions_sample/message/services/message/firestore_message_manager.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

class NotificationListScreen extends HookConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String formatDateTime(DateTime dateTime) {
      return DateFormat('yyyy年MM月dd日HH時mm分').format(dateTime);
    }

    final messagesStream = useMemoized(
      () => ref.read(firestoreMessageManagerProvider.notifier).messages(),
      [],
    );
    final messages = useStream(messagesStream);

    return Scaffold(
      appBar: AppBar(
        title: const Text('通知一覧'),
      ),
      body: messages.connectionState == ConnectionState.waiting
          ? const Center(child: CircularProgressIndicator())
          : messages.hasError
              ? Center(child: Text('エラーが発生しました: ${messages.error}'))
              : ListView.builder(
                  itemCount: messages.data?.docs.length ?? 0,
                  itemBuilder: (context, index) {
                    final doc = messages.data!.docs[index];
                    final message = Message.fromFirestore(doc);
                    return ListTile(
                      title: Text(message.senderName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message.content),
                          Text(formatDateTime(message.createdAt)),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NotificationDetailScreen(
                              message: message,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateMessageScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
```
:::
<br />

**メッセージ詳細画面**
メッセージ一覧画面から受け取ったメッセージを詳細に表示します。
::: details コード全文
```dart: notification_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:functions_sample/message/models/message/message.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class NotificationDetailScreen extends StatelessWidget {
  const NotificationDetailScreen({
    super.key,
    required this.message,
  });

  final Message message;
  String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy年MM月dd日HH時mm分').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('通知詳細'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '送信者 : ${message.senderName}',
              style: const TextStyle(
                fontSize: 18,
              ),
            ),
            const Gap(8),
            Text('送信日 : ${formatDateTime(message.createdAt)}'),
            const Gap(8),
            Text(message.content),
          ],
        ),
      ),
    );
  }
}
```
:::
<br />

上記のコードで実行すると、以下の動画のように選択したユーザーに対して通知を送信することができるかと思います。（動画ではアプリ起動中でも通知を受け取れていますが、今の実装では受け取れないかと思います🙇‍♂️）

https://youtu.be/bOfrudiT1WI

### 3. アプリ使用中（フォアグラウンド）の通知
今の実装ではアプリ使用中に通知が来た場合にそれを受け取ることができません。この章ではアプリ使用中でも通知を受け取ることができるように変更していきます。

アプリ使用中に通知を受け取る方法は以下の記事をもとに実装させていただきました。
[FlutterとFirebase Cloud Messagingでプッシュ通知を実装する その１ 〜Android編〜](https://note.shiftinc.jp/n/n97fc26eafc93)

アプリ使用中にも通知を受け取るためには、 `main.dart` の設定を変更する必要があります。
変更後のコードは以下の通りです。
```dart: main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase Messaging
  final messagingInstance = FirebaseMessaging.instance;
  messagingInstance.requestPermission();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  if (Platform.isAndroid) {
    final androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description:
            'This channel is used for important notifications.', // description
        importance: Importance.max,
      ),
    );
    await androidImplementation?.requestNotificationsPermission();
  }

  _initNotification();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<void> _initNotification() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin().show(
        0,
        notification!.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            icon: android?.smallIcon,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  });

  flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
    onDidReceiveNotificationResponse: (details) {
      if (details.payload != null) {
        final payloadMap =
            json.decode(details.payload!) as Map<String, dynamic>;
        debugPrint(payloadMap.toString());
      }
    },
  );
}
```

それぞれ詳しくみていきます。

以下の部分では、[flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) を用いて通知を行うためのチャネルを作成しています。チャネルには `id` を指定することができ、どのチャネルからの通知かを判別するために使用することができます。

```dart
final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
if (Platform.isAndroid) {
  final androidImplementation =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  await androidImplementation?.createNotificationChannel(
    const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    ),
  );
  await androidImplementation?.requestNotificationsPermission();
}
```

以下では、`runApp` の前に呼び出される `_initNotification` の処理を実装しています。
[`FirebaseMessaging.onMessage.listen`](https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=ja#foreground_messages) でアプリ起動中の通知を監視することができます。

通知を監視して、通知があった場合は `show` メソッドで通知を表示しています。
表示内容は引数として受け取った `message` のデータをもとにしています。
```dart
Future<void> _initNotification() async {
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (Platform.isAndroid) {
      await FlutterLocalNotificationsPlugin().show(
        0,
        notification!.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.max,
            icon: android?.smallIcon,
          ),
        ),
        payload: json.encode(message.data),
      );
    }
  });
```

以下では Android の通知に使うアイコンを指定するために initialize の処理を行なっています。
`@mipmap/ic_launcher` を指定することで、通知のアイコンとして Flutter のアイコンが表示されるようになります。
```dart
flutterLocalNotificationsPlugin.initialize(
  const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ),
  onDidReceiveNotificationResponse: (details) {
    if (details.payload != null) {
      final payloadMap =
          json.decode(details.payload!) as Map<String, dynamic>;
      debugPrint(payloadMap.toString());
    }
  },
);
```

この編集を加えて実行すると以下の動画のようにアプリ起動中でも通知を受け取ることができるようになります。

https://youtube.com/shorts/SReg9reefRM

なお、今回実装した内容は以下の GitHub に公開しているので、よろしければ適宜ご参照ください。

https://github.com/Koichi5/functions-sample

以上です。


## まとめ
最後まで読んでいただいてありがとうございました。

通知機能はかなり多くのアプリで使用されている機能なので、この辺りがサクッと実装できるようになるとかなり効率的に開発できるようになるのではないかと思いました。

誤っている点やもっと良い書き方があればご指摘いただければ幸いです。

### 参考

https://note.shiftinc.jp/n/n97fc26eafc93

https://firebase.google.com/docs/cloud-messaging/flutter/receive?hl=ja

https://firebase.google.com/docs/cloud-messaging/manage-tokens?hl=ja

https://firebase.flutter.dev/docs/messaging/notifications/#foreground-notifications



