import 'package:flutter/material.dart';
import 'package:pigeon_sample/shared_preferences/services/shared_preferences_service.dart';

class SharedPreferencesScreen extends StatelessWidget {
  const SharedPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Preferences'),
      ),
      body: Center(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                SharedPreferencesService.sharedPreferences.setString(
                  'name',
                  'John Doe',
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
