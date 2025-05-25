// lib/src/widgets/task_navigation_drawer.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:myapp_flutter/src/models/game_models.dart'; // Added import

// import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // For color picker

class TaskNavigationDrawer extends StatefulWidget {
  const TaskNavigationDrawer({super.key});

  @override
  State<TaskNavigationDrawer> createState() => _TaskNavigationDrawerState();
}

class _TaskNavigationDrawerState extends State<TaskNavigationDrawer> {
  final _newTaskNameController = TextEditingController();
  final _newTaskDescController = TextEditingController();
  String _newTaskTheme = 'tech'; // Default theme
  String _newTaskColorHex = "FF64FFDA"; // Default color (AppTheme.fhAccentTeal)

  // For editing
  final _editTaskNameController = TextEditingController();
  final _editTaskDescController = TextEditingController();
  String _editTaskTheme = 'tech';
  String _editTaskColorHex = "FF64FFDA";


  @override
  void dispose() {
    _newTaskNameController.dispose();
    _newTaskDescController.dispose();
    _editTaskNameController.dispose();
    _editTaskDescController.dispose();
    super.dispose();
  }

  IconData _getThemeIcon(String? theme) {
    switch (theme) {
      case 'tech': return MdiIcons.memory;
      case 'knowledge': return MdiIcons.bookOpenPageVariantOutline;
      case 'learning': return MdiIcons.schoolOutline; 
      case 'discipline': return MdiIcons.karate;
      case 'order': return MdiIcons.playlistCheck;
      default: return MdiIcons.targetAccount; 
    }
  }

  void _showAddTaskDialog(BuildContext context, GameProvider gameProvider) {
    _newTaskNameController.clear();
    _newTaskDescController.clear();
    _newTaskTheme = 'tech'; // Reset to default
    _newTaskColorHex = "FF64FFDA"; // Reset to default

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        // Use a StatefulWidget for the dialog content to manage local state for color picker
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.fhBgMedium,
              title: Text('Add New Mission', style: TextStyle(color: AppTheme.fhAccentRed)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(controller: _newTaskNameController, decoration: InputDecoration(labelText: 'Mission Name')),
                    const SizedBox(height: 8),
                    TextField(controller: _newTaskDescController, decoration: InputDecoration(labelText: 'Description'), maxLines: 2),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: 'Theme'),
                      dropdownColor: AppTheme.fhBgLight,
                      value: _newTaskTheme,
                      items: ['tech', 'knowledge', 'learning', 'discipline', 'order', 'general']
                          .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                          .toList(),
                      onChanged: (String? newValue) {
                         if (newValue != null) {
                            setStateDialog(() => _newTaskTheme = newValue);
                         }
                      },
                    ),
                    const SizedBox(height: 16),
                    Text("Select Theme Color:", style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 8),
                    // Simplified Color Picker (Grid of predefined colors)
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        AppTheme.fhAccentRed, AppTheme.fhAccentTeal, AppTheme.fhAccentGold,
                        AppTheme.fhAccentPurple, AppTheme.fhAccentGreen, AppTheme.fhAccentOrange,
                        Color(0xFF0077B6), Color(0xFFFCA311) // Blue, Another Orange
                      ].map((color) {
                        String colorHex = color.value.toRadixString(16).toUpperCase();
                        return GestureDetector(
                          onTap: () => setStateDialog(() => _newTaskColorHex = colorHex),
                          child: Container(
                            width: 30, height: 30,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                              border: _newTaskColorHex == colorHex
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    // For a full color picker, you would use:
                    // ColorPicker(
                    //   pickerColor: Color(int.parse("0x$_newTaskColorHex")),
                    //   onColorChanged: (color) => setStateDialog(() => _newTaskColorHex = color.value.toRadixString(16).toUpperCase()),
                    // ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
                ElevatedButton(
                  child: Text('Add Mission'),
                  onPressed: () {
                    if (_newTaskNameController.text.isNotEmpty) {
                      gameProvider.addMainTask(
                        name: _newTaskNameController.text,
                        description: _newTaskDescController.text,
                        theme: _newTaskTheme,
                        colorHex: _newTaskColorHex,
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }
  
  void _showEditTaskDialog(BuildContext context, GameProvider gameProvider, MainTask taskToEdit) {
    _editTaskNameController.text = taskToEdit.name;
    _editTaskDescController.text = taskToEdit.description;
    _editTaskTheme = taskToEdit.theme;
    _editTaskColorHex = taskToEdit.colorHex;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder( // For managing dialog's local state (color picker)
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              backgroundColor: AppTheme.fhBgMedium,
              title: Text('Edit Mission', style: TextStyle(color: AppTheme.fhAccentRed)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(controller: _editTaskNameController, decoration: InputDecoration(labelText: 'Mission Name')),
                    const SizedBox(height: 8),
                    TextField(controller: _editTaskDescController, decoration: InputDecoration(labelText: 'Description'), maxLines: 2),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                       decoration: InputDecoration(labelText: 'Theme'),
                       dropdownColor: AppTheme.fhBgLight,
                       value: _editTaskTheme,
                       items: ['tech', 'knowledge', 'learning', 'discipline', 'order', 'general']
                          .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value)))
                          .toList(),
                       onChanged: (String? newValue) {
                          if (newValue != null) {
                            setStateDialog(() => _editTaskTheme = newValue);
                          }
                       }
                    ),
                     const SizedBox(height: 16),
                     Text("Select Theme Color:", style: Theme.of(context).textTheme.labelMedium),
                     const SizedBox(height: 8),
                     Wrap( // Simplified Color Picker
                       spacing: 8.0, runSpacing: 8.0,
                       children: [AppTheme.fhAccentRed, AppTheme.fhAccentTeal, AppTheme.fhAccentGold, AppTheme.fhAccentPurple, AppTheme.fhAccentGreen, AppTheme.fhAccentOrange, Color(0xFF0077B6), Color(0xFFFCA311)]
                           .map((color) {
                         String colorHex = color.value.toRadixString(16).toUpperCase();
                         return GestureDetector(
                           onTap: () => setStateDialog(() => _editTaskColorHex = colorHex),
                           child: Container(
                             width: 30, height: 30,
                             decoration: BoxDecoration(
                               color: color,
                               borderRadius: BorderRadius.circular(4),
                               border: _editTaskColorHex == colorHex ? Border.all(color: Colors.white, width: 2) : null,
                             ),
                           ),
                         );
                       }).toList(),
                     ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(child: Text('Cancel'), onPressed: () => Navigator.of(dialogContext).pop()),
                ElevatedButton(
                  child: Text('Save Changes'),
                  onPressed: () {
                    if (_editTaskNameController.text.isNotEmpty) {
                      gameProvider.editMainTask(
                        taskToEdit.id,
                        name: _editTaskNameController.text,
                        description: _editTaskDescController.text,
                        theme: _editTaskTheme,
                        colorHex: _editTaskColorHex,
                      );
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    return Drawer( // Or Container if used as a fixed panel
      backgroundColor: AppTheme.fhBgDark, // Match Valorant panel style
      child: Column(
        children: [
          AppBar( // Styled header for the panel
            title: Text('MISSIONS', style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.fhTextPrimary, letterSpacing: 1)),
            automaticallyImplyLeading: false, 
            backgroundColor: AppTheme.fhBgMedium,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(MdiIcons.plusCircleOutline, color: AppTheme.fhAccentTeal),
                onPressed: () => _showAddTaskDialog(context, gameProvider),
                tooltip: 'Add New Mission',
              ),
            ],
          ),
          Expanded(
            child: gameProvider.mainTasks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No missions available. Add a new one to begin.',
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
                      final taskColor = Color(int.parse("0x${task.colorHex}"));

                      return Material( // For InkWell splash
                        color: isSelected ? taskColor.withOpacity(0.25) : Colors.transparent,
                        child: ListTile(
                          leading: Icon(
                            _getThemeIcon(task.theme),
                            color: isSelected ? taskColor : AppTheme.fhTextSecondary,
                            size: 22,
                          ),
                          title: Text(
                            task.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: isSelected ? taskColor : AppTheme.fhTextPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, // Bolder selection
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Wrap(
                            spacing: 0, // No space between edit and streak
                            children: [
                              if (task.streak > 0)
                                Chip(
                                  avatar: Icon(MdiIcons.fire, color: AppTheme.fhAccentOrange, size: 14),
                                  label: Text('${task.streak}', style: TextStyle(color: AppTheme.fhAccentOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppTheme.fhBgMedium, // Darker chip
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                  visualDensity: VisualDensity.compact,
                                ),
                              IconButton(
                                icon: Icon(MdiIcons.pencilOutline, size: 18, color: AppTheme.fhTextSecondary.withOpacity(0.7)),
                                onPressed: () => _showEditTaskDialog(context, gameProvider, task),
                                tooltip: 'Edit Mission',
                                padding: EdgeInsets.zero,
                                constraints: BoxConstraints(),
                              ),
                            ]
                          ),
                          selected: isSelected,
                          onTap: () {
                            gameProvider.setSelectedTaskId(task.id);
                            if (gameProvider.currentView != 'task-details') {
                                gameProvider.setCurrentView('task-details');
                            }
                            // Close drawer on small screens
                            if (MediaQuery.of(context).size.width < 900) { // Match HomeScreen breakpoint
                              Navigator.pop(context);
                            }
                          },
                          selectedTileColor: taskColor.withOpacity(0.15), // Use task color for selection
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Increased vertical padding
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