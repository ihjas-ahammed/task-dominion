import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/widgets/views/settings_view.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Configuration'),
        backgroundColor: AppTheme.fhBgMedium, // Match header style
      ),
      body: const SettingsView(),
    );
  }
}