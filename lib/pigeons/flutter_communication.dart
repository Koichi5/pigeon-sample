import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/flutter_communication/flutter_communication.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Battery/Battery.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/FlutterCommunication/FlutterCommunication.g.swift',
  swiftOptions: SwiftOptions(),
))

@FlutterApi()
abstract class FlutterCommunicationApi {
  void triggerSave();
}