import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/watch_communication/watch_communication.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Battery/Battery.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/WatchCommunication/WatchCommunication.g.swift',
  swiftOptions: SwiftOptions(),
))

@HostApi()
abstract class WatchCommunicationApi {
  void triggerSave();
}
