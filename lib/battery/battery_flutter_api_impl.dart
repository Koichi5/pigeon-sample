import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:pigeon_sample/battery/battery.g.dart';

class BatteryFlutterApiImpl extends BatteryFlutterApi {
  @override
  void onBatteryInfoReceived(BatteryInfo batteryInfo) {
    saveBatteryInfoToFirestore(batteryInfo: batteryInfo);
  }

  void saveBatteryInfoToFirestore({required BatteryInfo batteryInfo}) async {
    await FirebaseFirestore.instance.collection('battery_info').add({
      'batteryLevel': batteryInfo.batteryLevel,
      'batteryStatus': batteryInfo.batteryStatus,
      'source': batteryInfo.source,
      'timestamp': DateTime.now(),
    });
    debugPrint(
        'Battery level: ${batteryInfo.batteryLevel}, status: ${batteryInfo.batteryStatus} saved to Firestore.');
  }
}
