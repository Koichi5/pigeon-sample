import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/battery/battery.g.dart',
  dartOptions: DartOptions(),
  kotlinOut: 'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Battery/Battery.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/Battery/Battery.g.swift',
  swiftOptions: SwiftOptions(),
))

class BatteryInfo {
  BatteryInfo({
    required this.batteryLevel,
    required this.batteryStatus,
    required this.source,
  });
  int batteryLevel;
  String batteryStatus;
  String source;
}

@HostApi()
abstract class BatteryHostApi {
  BatteryInfo getBatteryInfo();
}

@FlutterApi()
abstract class BatteryFlutterApi {
  void onBatteryInfoReceived(BatteryInfo batteryInfo);
}

// Flutter側からHost側を呼び出すときは、@HostApi()をつける
// @HostApi()
// abstract class BatteryHostApi {
//   int getBatteryLevel();
//   String getBatteryStatus();
// }

// ネイティブコードからFlutter側を呼び出すときは、@FlutterApi()をつける
// @FlutterApi()
// abstract class BatteryFlutterApi {
//   void onBatteryLevelReceived(int batteryLevel, String source);
//   void onBatteryStatusReceived(String batteryStatus, String source);
// }

// @FlutterApi()
// abstract class SaveDataFlutterApi {
//   void triggerSave(double batteryLevel, String source);
// }
