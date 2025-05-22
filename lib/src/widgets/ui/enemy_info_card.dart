// lib/src/widgets/ui/enemy_info_card.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/models/game_models.dart'; // For EnemyTemplate
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class EnemyInfoCardWidget extends StatelessWidget {
  final EnemyTemplate enemy;
  final int playerLevel;
  final VoidCallback onStartGame;

  const EnemyInfoCardWidget({
    super.key,
    required this.enemy,
    required this.playerLevel,
    required this.onStartGame,
  });

  Map<String, dynamic> _getEnemyDifficulty(int enemyMinLevel, int pLevel) {
    final levelDiff = enemyMinLevel - pLevel;
    if (levelDiff <= -3) return {'text': "Trivial", 'color': AppTheme.fhAccentGreen.withOpacity(0.6)};
    if (levelDiff <= -1) return {'text': "Easy", 'color': AppTheme.fhAccentGreen};
    if (levelDiff == 0) return {'text': "Moderate", 'color': AppTheme.fhAccentLightCyan};
    if (levelDiff == 1) return {'text': "Challenging", 'color': AppTheme.fhAccentOrange};
    return {'text': "Deadly", 'color': AppTheme.fhAccentRed, 'isBold': true};
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final difficulty = _getEnemyDifficulty(enemy.minPlayerLevel, playerLevel);

    return Card(
      elevation: 0,
      color: AppTheme.fhBgLight.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
        side: BorderSide(color: AppTheme.fhBorderColor.withOpacity(0.7), width: 1),
      ),
      child: InkWell(
        onTap: onStartGame,
        borderRadius: BorderRadius.circular(6.0),
        hoverColor: AppTheme.fhAccentTeal.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enemy.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.fhTextPrimary,
                        fontSize: 14),
                    textAlign: TextAlign.left,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  if (enemy.theme != null)
                    Text(
                        "${enemy.theme!.toUpperCase()} FAUNA",
                        style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhAccentPurple.withOpacity(0.8), fontSize: 9, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                        maxLines: 1, // Added for overflow safety
                        overflow: TextOverflow.ellipsis, // Added for overflow safety
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Wrapped _StatChip with Flexible
                      Flexible(child: _StatChip(icon: MdiIcons.heartOutline, value: enemy.health.toString(), color: AppTheme.fhAccentGreen)),
                      Flexible(child: _StatChip(icon: MdiIcons.sword, value: enemy.attack.toString(), color: AppTheme.fhAccentOrange)),
                      Flexible(child: _StatChip(icon: MdiIcons.shieldOutline, value: enemy.defense.toString(), color: AppTheme.fhAccentBrightBlue)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (difficulty['color'] as Color).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: (difficulty['color'] as Color).withOpacity(0.5), width: 0.5)
                        ),
                        child: Text(
                          "Threat: ${difficulty['text'] as String}",
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: difficulty['color'] as Color,
                            fontWeight: (difficulty['isBold'] as bool? ?? false) ? FontWeight.bold : FontWeight.w600,
                            fontSize: 10,
                          ),
                          maxLines: 1, // Added for overflow safety
                          overflow: TextOverflow.ellipsis, // Added for overflow safety
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onStartGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.fhAccentTeal,
                  foregroundColor: AppTheme.fhBgDark,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  textStyle: const TextStyle(
                      fontSize: 12,
                      fontFamily: AppTheme.fontMain,
                      fontWeight: FontWeight.bold),
                ),
                child: const Text(
                  'ENGAGE TARGET',
                  // textAlign: TextAlign.center, // Can be useful if text might wrap
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _StatChip({required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min, // Good for ensuring chip is not unnecessarily wide
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        // Wrapped Text with Flexible to handle long stat values
        Flexible(
          child: Text(
            value,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontSize: 12, color: AppTheme.fhTextPrimary, fontWeight: FontWeight.w500),
            maxLines: 1, // Ensure single line
            overflow: TextOverflow.ellipsis, // Add ellipsis if text is too long
          ),
        ),
      ],
    );
  }
}