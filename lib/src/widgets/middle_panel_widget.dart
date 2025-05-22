// lib/src/widgets/middle_panel_widget.dart
import 'package:flutter/material.dart';
// Import views
import 'package:myapp_flutter/src/widgets/views/task_details_view.dart';
import 'package:myapp_flutter/src/widgets/views/artifact_shop_view.dart';
import 'package:myapp_flutter/src/widgets/views/blacksmith_view.dart';
import 'package:myapp_flutter/src/widgets/views/game_view.dart';
import 'package:myapp_flutter/src/widgets/views/daily_summary_view.dart';
import 'package:myapp_flutter/src/widgets/views/settings_view.dart';

class MiddlePanelWidget extends StatelessWidget {
  final TabController tabController;
  const MiddlePanelWidget({super.key, required this.tabController});

  @override
  Widget build(BuildContext context) {
    print("[MiddlePanelWidget] Building MiddlePanelWidget."); // DEBUG

    final List<Widget> views = [
      const TaskDetailsView(),
      const ArtifactShopView(),
      const BlacksmithView(),
      const GameView(),
      const DailySummaryView(),
      const SettingsView(),
    ];

    // Define a maximum width for the content
    const double maxWidth = 500.0; // You can adjust this value as needed

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      child: Center( // Center the content horizontally
        child: ConstrainedBox( // Apply maxWidth
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: TabBarView(
            controller: tabController,
            children: views.map((view) {
              return KeepAliveWrapper(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: view,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// Helper widget to keep state in TabBarView
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context); // Important to call super.build
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}