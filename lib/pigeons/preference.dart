import 'package:pigeon/pigeon.dart';

//run in the root folder: flutter pub run pigeon --input lib/pigeons/preference.dart

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/preference/preference.g.dart',
  dartOptions: DartOptions(),
  kotlinOut:
      'android/app/src/main/kotlin/dev/flutter/pigeon_sample/Preference/Preference.g.kt',
  kotlinOptions: KotlinOptions(),
  swiftOut: 'ios/Runner/Preference/Preference.g.swift',
  swiftOptions: SwiftOptions(),
))

class Preference {
  Preference({
    required this.key,
    this.value,
  });
  String key;
  Object? value;
}

@HostApi()
abstract class PreferenceApi {
  bool setValue(Preference preference);
  bool remove(String key);
  bool clear();
  List<Preference> getAll();
}
