// lib/src/widgets/views/settings_sections/skill_management_settings.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/constants.dart';
import 'package:arcane/src/widgets/views/settings_sections/settings_section_card.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class SkillManagementSettings extends StatefulWidget {
  const SkillManagementSettings({super.key});

  @override
  State<SkillManagementSettings> createState() => _SkillManagementSettingsState();
}

class _SkillManagementSettingsState extends State<SkillManagementSettings> {
  void _showEditSkillDialog(BuildContext context, GameProvider gameProvider, Skill skill) {
    final nameController = TextEditingController(text: skill.name);
    String selectedIconName = skill.iconName;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: Text('Edit Skill: ${skill.name}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Skill Name'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Select Icon'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: themeToIconName.entries.map((entry) {
                        bool isSelected = selectedIconName == entry.key;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIconName = entry.key),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected ? Theme.of(context).primaryColor : AppTheme.fnBgLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? Theme.of(context).primaryColor : AppTheme.fnBorderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(MdiIcons.fromString(entry.value), color: isSelected ? Colors.white : AppTheme.fnTextSecondary),
                          ),
                        );
                      }).toList(),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    gameProvider.editSkill(skill.id, newName: nameController.text, newIconName: selectedIconName);
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmAndDeleteSubskill(BuildContext context, GameProvider gameProvider, Subskill subskill) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Subskill?', style: TextStyle(color: AppTheme.fnAccentRed)),
        content: Text('Are you sure you want to delete the "${subskill.name}" subskill? This will remove its XP from all tasks and cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              gameProvider.deleteSubskill(subskill.id);
              Navigator.of(ctx).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentRed),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        return SettingsSectionCard(
          icon: MdiIcons.schoolOutline,
          title: 'Skill System',
          children: [
            Text(
              'Manually edit skill names and icons, or remove unwanted subskills. You can also recalculate all skill XP from your entire completion history to fix any inconsistencies.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 16),
            ...gameProvider.skills.map(
              (skill) => ExpansionTile(
                leading: Icon(MdiIcons.fromString(skill.iconName)),
                title: Text(skill.name),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditSkillDialog(context, gameProvider, skill),
                ),
                children: skill.subskills
                    .map((subskill) => ListTile(
                          title: Text(subskill.name, style: Theme.of(context).textTheme.bodySmall),
                          trailing: IconButton(
                            icon:  Icon(MdiIcons.deleteOutline, size: 20),
                            color: AppTheme.fnAccentRed.withOpacity(0.8),
                            onPressed: () => _confirmAndDeleteSubskill(context, gameProvider, subskill),
                          ),
                          dense: true,
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon:  Icon(MdiIcons.restart, size: 18),
              label: const Text('RECALCULATE ALL SKILL XP'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title:  Row(children: [
                      Icon(MdiIcons.alertOutline, color: AppTheme.fnAccentOrange),
                      const SizedBox(width: 10),
                      const Text('Confirm')
                    ]),
                    content: const Text('Are you sure you want to reset and recalculate all skills from your logs? This cannot be undone.'),
                    actionsAlignment: MainAxisAlignment.spaceBetween,
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL')),
                      ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentOrange), child: const Text('CONFIRM')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await gameProvider.resetAndRecalculateSkillsFromLog();
                   if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skills recalculated successfully.'), backgroundColor: AppTheme.fnAccentGreen));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fnAccentOrange, foregroundColor: AppTheme.fnTextPrimary, minimumSize: const Size(double.infinity, 44)),
            ),
          ],
        );
      },
    );
  }
}