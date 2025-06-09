// lib/src/widgets/components/subskill_list_item.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/utils/helpers.dart' as helper;
import 'package:flutter/material.dart';

class SubskillListItem extends StatelessWidget {
  final Subskill subskill;
  final Color skillColor;
  final VoidCallback onSelect;

  const SubskillListItem({
    super.key,
    required this.subskill,
    required this.skillColor,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double currentLevelXpStart = helper.skillXpForLevel(subskill.level);
    final double xpNeededForNext = helper.skillXpToNext(subskill.level);
    final double currentLevelProgress = subskill.xp - currentLevelXpStart;
    final double progressPercent = xpNeededForNext > 0 ? (currentLevelProgress / xpNeededForNext).clamp(0.0, 1.0) : 0.0;

    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    subskill.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.fnTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  'Lvl ${subskill.level}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: skillColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 4,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: AppTheme.fnBorderColor.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(skillColor.withAlpha(150)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${currentLevelProgress.toStringAsFixed(1)} / ${xpNeededForNext.toStringAsFixed(1)} XP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.fnTextSecondary.withAlpha(150),
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}