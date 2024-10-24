import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/greeting/greeting.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/app/src/main/kotlin/dev/flutter/pigeon_example_app/Greeting/Greeting.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/Greeting/Greeting.g.swift',
  swiftOptions: SwiftOptions(),
))

@HostApi()
abstract class GreetingHostApi {
  bool sendMessage(String message);
  void showMessage(String message);
}

@FlutterApi()
abstract class GreetingFlutterApi {
  String getGreeting();
}
