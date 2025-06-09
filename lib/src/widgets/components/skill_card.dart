// lib/src/widgets/components/skill_card.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/helpers.dart' as helper;
import 'package:arcane/src/widgets/components/subskill_list_item.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SkillCard extends StatelessWidget {
  final Skill skill;
  final Color skillColor;
  final bool isSelected;
  final VoidCallback onSelect;
  final Function(String) onSubskillSelect;

  const SkillCard({
    super.key,
    required this.skill,
    required this.skillColor,
    required this.isSelected,
    required this.onSelect,
    required this.onSubskillSelect,
  });

  IconData _getIconData(String? iconName) {
    return MdiIcons.fromString(iconName ?? 'star-shooting-outline') ?? MdiIcons.starShootingOutline;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double currentLevelXpStart = helper.skillXpForLevel(skill.level);
    final double xpNeededForNext = helper.skillXpToNext(skill.level);
    final double currentLevelProgress = skill.xp - currentLevelXpStart;
    final double progressPercent = xpNeededForNext > 0 ? (currentLevelProgress / xpNeededForNext).clamp(0.0, 1.0) : 0.0;

    return Card(
      color: isSelected ? skillColor.withAlpha((255 * 0.25).round()) : AppTheme.fnBgMedium,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected ? BorderSide(color: skillColor, width: 1.5) : BorderSide(color: AppTheme.fnBorderColor.withAlpha((255 * 0.5).round()), width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: ValueKey(skill.id), // Ensure state is preserved on rebuilds
        onExpansionChanged: (expanded) {
          if (expanded) {
            onSelect();
          }
        },
        initiallyExpanded: isSelected,
        collapsedIconColor: skillColor,
        iconColor: skillColor,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(_getIconData(skill.iconName), color: skillColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(skill.name, style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.fnTextPrimary, fontWeight: FontWeight.bold, fontSize: 16))),
                  Text('LVL ${skill.level}', style: theme.textTheme.titleMedium?.copyWith(fontFamily: AppTheme.fontDisplay, color: skillColor, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppTheme.fnBorderColor.withAlpha((255 * 0.2).round()),
                    valueColor: AlwaysStoppedAnimation<Color>(skillColor.withAlpha((255 * 0.8).round())),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('XP: ${currentLevelProgress.toStringAsFixed(1)} / ${xpNeededForNext.toStringAsFixed(1)}', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary, fontSize: 11)),
                  Text('Total: ${skill.xp.toStringAsFixed(1)} XP', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fnTextSecondary.withAlpha((255 * 0.7).round()), fontSize: 10)),
                ],
              )
            ],
          ),
        ),
        children: [
          Container(
            color: AppTheme.fnBgDark.withAlpha(100),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                 if (skill.subskills.isEmpty)
                   Padding(
                     padding: const EdgeInsets.symmetric(vertical: 16.0),
                     child: Text('No subskills yet. Enhance tasks to unlock them!', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.fnTextSecondary)),
                   )
                 else
                  ...skill.subskills
                      .map((subskill) => SubskillListItem(
                            subskill: subskill,
                            skillColor: skillColor,
                            onSelect: () => onSubskillSelect(subskill.id),
                          ))
                      .toList()
              ],
            ),
          )
        ],
      ),
    );
  }
}