import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/widgets/views/daily_summary_view.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mission Logbook'),
        backgroundColor: AppTheme.fhBgMedium, // Match header style
      ),
      body: const DailySummaryView(),
    );
  }
}