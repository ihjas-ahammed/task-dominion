// lib/src/widgets/header_widget.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart'; // For MDI Icons

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
     final List<Map<String, dynamic>> viewTabs = [
    {'label': 'Details', 'value': 'task-details', 'icon': MdiIcons.textBoxSearchOutline},
    {'label': 'Wares', 'value': 'artifact-shop', 'icon': MdiIcons.storefrontOutline},
    {'label': 'Forge', 'value': 'blacksmith', 'icon': MdiIcons.hammerWrench},
    {'label': 'Arena', 'value': 'game', 'icon': MdiIcons.swordCross},
    {'label': 'Logbook', 'value': 'daily-summary', 'icon': MdiIcons.bookOpenPageVariantOutline},
    {'label': 'Settings', 'value': 'settings', 'icon': MdiIcons.cogOutline},
  ];

    return AppBar(
      // backgroundColor, elevation, etc., are now primarily controlled by AppTheme.appBarTheme
      title:  Text(
          viewTabs[viewTabs.indexWhere((tab) => tab['value'] == gameProvider.currentView)]['label'] // Already styled by appBarTheme.titleTextStyle]
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(MdiIcons.accountCircleOutline, size: 25), // User/Stats icon
        onPressed: () => Scaffold.of(context).openDrawer(), // Keep leading as the user stats button
        tooltip: 'Player Stats & Inventory', // Keep tooltip
      ),
      actions: <Widget>[
        // Combined XP and Level display
        const SizedBox(width: 20),
        // Coins Display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            children: [
              Icon(MdiIcons.circleMultipleOutline, color: AppTheme.fhAccentOrange, size: 14), // Coin icon
              const SizedBox(width: 3),
              Text(
                gameProvider.coins.toStringAsFixed(0),
                style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhTextPrimary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Energy Display
         Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            children: [
              Icon(MdiIcons.flashOutline, color: AppTheme.fhAccentGreen, size: 15), // Energy icon
              const SizedBox(width: 3),
              Text(
                '${gameProvider.playerEnergy.toStringAsFixed(0)}/${gameProvider.calculatedMaxEnergy.toStringAsFixed(0)}',
                style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhTextPrimary, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        
        // Open Task Drawer (Right Drawer)
        IconButton(
          icon: Icon(MdiIcons.formatListChecks, size: 24), // Icon for task list
          onPressed: () => Scaffold.of(context).openEndDrawer(), // This will remain in the actions list
          tooltip: 'Select Quest',
        ),
      ],
    );
  }
}