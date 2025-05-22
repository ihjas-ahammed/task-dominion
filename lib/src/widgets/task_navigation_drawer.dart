// lib/src/widgets/task_navigation_drawer.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class TaskNavigationDrawer extends StatelessWidget {
  const TaskNavigationDrawer({super.key});

  IconData _getThemeIcon(String? theme) {
    switch (theme) {
      case 'tech': return MdiIcons.memory;
      case 'knowledge': return MdiIcons.bookOpenPageVariantOutline;
      case 'learning': return MdiIcons.schoolOutline; // Changed icon
      case 'discipline': return MdiIcons.karate;
      case 'order': return MdiIcons.playlistCheck;
      default: return MdiIcons.targetAccount; // Changed icon
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: AppTheme.fhBgMedium,
      child: Column(
        children: [
          AppBar(
            title: Text('Select Quest', style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.fhAccentTeal)),
            automaticallyImplyLeading: false, // No back button in drawer header
            backgroundColor: AppTheme.fhBgDark,
            elevation: 1,
          ),
          Expanded(
            child: gameProvider.mainTasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No quests available.\nAdd some from the initial set or generate new ones via Settings.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fhTextSecondary, fontStyle: FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: gameProvider.mainTasks.length,
                    itemBuilder: (context, index) {
                      final task = gameProvider.mainTasks[index];
                      final isSelected = gameProvider.selectedTaskId == task.id;
                      return Material(
                        color: isSelected ? AppTheme.fhAccentTeal.withOpacity(0.15) : Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            _getThemeIcon(task.theme),
                            color: isSelected ? AppTheme.fhAccentTeal : AppTheme.fhTextSecondary,
                            size: 22,
                          ),
                          title: Text(
                            task.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isSelected ? AppTheme.fhAccentTeal : AppTheme.fhTextPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: task.streak > 0
                            ? Chip(
                                avatar: Icon(MdiIcons.fire, color: AppTheme.fhAccentOrange, size: 14),
                                label: Text('${task.streak}', style: const TextStyle(color: AppTheme.fhAccentOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                                backgroundColor: AppTheme.fhBgLight,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                          selected: isSelected,
                          onTap: () {
                            gameProvider.setSelectedTaskId(task.id);
                            // If the current view is not details, switch to it.
                            if (gameProvider.currentView != 'task-details') {
                                gameProvider.setCurrentView('task-details');
                            }
                            double width = MediaQuery.of(context).size.width; 
                            if(width < 700) Navigator.pop(context);
                          },
                          selectedTileColor: AppTheme.fhAccentTeal.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}