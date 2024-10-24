import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:pigeon_sample/battery/battery.g.dart';

class BatteryScreen extends HookWidget {
  const BatteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final batteryLevel = useState('Unknown battery level.');
    final batteryStatus = useState('Unknown battery status.');

    Future<void> getBatteryInfo() async {
      try {
        final api = BatteryHostApi();
        final result = await api.getBatteryInfo();
        batteryLevel.value = '${result.batteryLevel} %';
        batteryStatus.value = result.batteryStatus;
      } on PlatformException catch (e) {
        batteryLevel.value = "Failed to get battery level: ${e.message}.";
        batteryStatus.value = "Failed to get battery status: ${e.message}.";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Battery Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(batteryLevel.value),
            const Gap(8),
            Text(batteryStatus.value),
            const Gap(16),
            ElevatedButton(
              onPressed: getBatteryInfo,
              child: const Text('Get Battery Info'),
            ),
          ],
        ),
      ),
    );
  }
}
