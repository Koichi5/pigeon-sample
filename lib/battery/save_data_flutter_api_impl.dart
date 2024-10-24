// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:pigeon_sample/battery/battery.g.dart';

// class SaveDataFlutterApiImpl extends SaveDataFlutterApi {
//   @override
//   void triggerSave(double batteryLevel, String source) {
//     saveBatteryLevelToFirestoreWithLabel(batteryLevel, source);
//   }

//   void saveBatteryLevelToFirestoreWithLabel(
//       double batteryLevel, String source) async {
//     await FirebaseFirestore.instance.collection('battery_levels').add({
//       'level': batteryLevel,
//       'source': source,
//       'timestamp': DateTime.now(),
//     });
//     print('Battery level $batteryLevel saved to Firestore.');
//   }
// }