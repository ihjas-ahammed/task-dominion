// lib/src/widgets/dialogs/project_edit_dialog.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class ProjectEditDialog extends StatefulWidget {
  final Project? project;

  const ProjectEditDialog({super.key, this.project});

  bool get isEditMode => project != null;

  @override
  State<ProjectEditDialog> createState() => _ProjectEditDialogState();
}

class _ProjectEditDialogState extends State<ProjectEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late String _selectedTheme;
  late String _selectedColorHex;

  final List<Map<String, dynamic>> _availableThemes =
      themeToIconName.entries.map((entry) {
    Color color;
    switch (entry.key) {
      case 'tech': color = AppTheme.fortniteBlue; break;
      case 'knowledge': color = AppTheme.fortnitePurple; break;
      case 'learning': color = AppTheme.fnAccentOrange; break;
      case 'discipline': color = AppTheme.fnAccentRed; break;
      case 'order': color = AppTheme.fnAccentGreen; break;
      case 'health': color = const Color(0xFF58D68D); break;
      case 'finance': color = const Color(0xFFF1C40F); break;
      case 'creative': color = const Color(0xFFEC7063); break;
      case 'exploration': color = const Color(0xFF5DADE2); break;
      case 'social': color = const Color(0xFFE59866); break;
      case 'nature': color = const Color(0xFF2ECC71); break;
      default: color = AppTheme.fnTextSecondary;
    }
    return {'name': entry.key, 'icon': MdiIcons.fromString(entry.value), 'color': color};
  }).toList();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _selectedTheme = widget.project?.theme ?? 'tech';
    _selectedColorHex = widget.project?.colorHex ?? _colorToHex(_getColorForTheme(_selectedTheme));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _colorToHex(Color color) {
    return color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
  }

  Color _getColorForTheme(String themeName) {
    return _availableThemes.firstWhere((t) => t['name'] == themeName,
        orElse: () => {'color': AppTheme.fortniteBlue})['color'] as Color;
  }

  void _handleSaveChanges() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    if (_nameController.text.isNotEmpty) {
      if (widget.isEditMode) {
        gameProvider.editProject(
          widget.project!.id,
          name: _nameController.text,
          description: _descController.text,
          theme: _selectedTheme,
          colorHex: _selectedColorHex,
        );
      } else {
        gameProvider.addProject(
          name: _nameController.text,
          description: _descController.text,
          theme: _selectedTheme,
          colorHex: _selectedColorHex,
        );
      }
      Navigator.of(context).pop();
    }
  }
  
  void _handleDelete() {
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Project?', style: TextStyle(color: AppTheme.fnAccentRed)),
        content: Text('Are you sure you want to delete "${widget.project!.name}"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              gameProvider.deleteProject(widget.project!.id);
              Navigator.of(ctx).pop(); // Close confirmation dialog
              Navigator.of(context).pop(); // Close edit dialog
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentRed),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.fnBgMedium,
      title: Text(widget.isEditMode ? 'Edit Project' : 'Add New Project'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Project Name')),
            const SizedBox(height: 8),
            TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Theme'),
              dropdownColor: AppTheme.fnBgLight,
              value: _selectedTheme,
              items: _availableThemes.map((themeMap) {
                return DropdownMenuItem<String>(
                  value: themeMap['name'] as String,
                  child: Row(
                    children: [
                      Icon(themeMap['icon'] as IconData, size: 18, color: themeMap['color'] as Color),
                      const SizedBox(width: 8),
                      Text(themeMap['name'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTheme = newValue;
                    _selectedColorHex = _colorToHex(_getColorForTheme(newValue));
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Text("Select Theme Color:", style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0, runSpacing: 8.0,
              children: _availableThemes.map((themeMap) {
                Color color = themeMap['color'] as Color;
                String colorHex = _colorToHex(color);
                bool isSelectedColor = _selectedColorHex == colorHex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = colorHex),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: isSelectedColor
                          ? Border.all(color: Colors.white, width: 2)
                          : Border.all(color: Colors.white.withAlpha(77), width: 1),
                    ),
                    child: isSelectedColor
                        ? Icon(MdiIcons.check, color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark ? Colors.white : Colors.black, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        if (widget.isEditMode)
          IconButton(
            icon: Icon(MdiIcons.deleteForeverOutline, color: AppTheme.fnAccentRed),
            onPressed: _handleDelete,
            tooltip: 'Delete Project',
          ),
        const Spacer(),
        TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
        ElevatedButton(
          child: Text(widget.isEditMode ? 'Save Changes' : 'Add Project'),
          onPressed: _handleSaveChanges,
        ),
      ],
    );
  }
}