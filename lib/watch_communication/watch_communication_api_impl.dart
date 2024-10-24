import 'package:pigeon_sample/pigeons/watch_communication.dart';

class WatchCommunicationApiImpl extends WatchCommunicationApi {
  @override
  void triggerSave() {
    // ここでFirestoreへの保存処理を実装
    saveDataToFirestore();
  }

  void saveDataToFirestore() {
    // Firestoreへの保存ロジック
  }
}
