// lib/src/widgets/views/game_view.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:myapp_flutter/src/utils/constants.dart'; // For energyPerAttack
import 'package:myapp_flutter/src/widgets/ui/enemy_info_card.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class GameView extends StatelessWidget {
  const GameView({super.key});

  Widget _renderCharacterStats(BuildContext context, dynamic character, bool isPlayer, GameProvider gameProvider) {
    final theme = Theme.of(context);
    final double maxHp = isPlayer ? gameProvider.playerGameStats['vitality']!.value : (character as EnemyTemplate).health.toDouble();
    // final double currentHp = isPlayer ? gameProvider.currentGame.playerCurrentHp : (character as EnemyTemplate).hp.toDouble(); // Assuming currentHealth is on the enemy object if in combat
    double currentHp;

    String characterName = "Your Stats";
    String? description;
    int attackStat = 0;
    int defenseStat = 0;

    if (isPlayer) {
        currentHp = gameProvider.currentGame.playerCurrentHp;
        attackStat = gameProvider.playerGameStats['strength']!.value.toInt();
        defenseStat = gameProvider.playerGameStats['defense']!.value.toInt();
    } else if (character is EnemyTemplate) {
        characterName = character.name;
        description = character.description;
        attackStat = character.attack;
        defenseStat = character.defense;
        // If this is the enemy currently in combat, get its dynamic health
        if (gameProvider.currentGame.enemy != null && gameProvider.currentGame.enemy!.id == character.id) {
             currentHp = gameProvider.currentGame.enemy!.hp.toDouble();
        } else {
            currentHp = character.hp.toDouble(); // Fallback to template's hp if not current enemy
        }
    } else {
        currentHp = 0; // Should not happen
    }


    final double hpPercent = maxHp > 0 ? (currentHp / maxHp) : 0.0;
     Color hpBarColor;
    if (hpPercent * 100 > 60) { hpBarColor = AppTheme.fhAccentGreen; }
    else if (hpPercent * 100 > 30) { hpBarColor = AppTheme.fhAccentOrange; }
    else { hpBarColor = AppTheme.fhAccentRed; }

    return Card(
      elevation: 1,
      color: AppTheme.fhBgLight,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for Column in Expanded
          children: [
            Text(
              characterName,
              style: theme.textTheme.titleMedium?.copyWith(fontFamily: AppTheme.fontMain, color: AppTheme.fhAccentTeal, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
             SizedBox(
                height: 10,
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                    value: hpPercent,
                    backgroundColor: AppTheme.fhBgDark,
                    valueColor: AlwaysStoppedAnimation<Color>(hpBarColor),
                    ),
                )
            ),
            const SizedBox(height: 4),
            Text('HP: ${currentHp.toStringAsFixed(0)} / ${maxHp.toStringAsFixed(0)}', style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text('ATK: $attackStat | DEF: $defenseStat', style: theme.textTheme.bodySmall),
             if (!isPlayer && description != null && description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Tooltip(
                    message: description,
                    preferBelow: false,
                    child: Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.fhTextSecondary.withOpacity(0.7)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                    ),
                )
            ]
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final currentTask = gameProvider.getSelectedTask();
    final String? currentTaskTheme = currentTask?.theme;

    final availableEnemies = gameProvider.enemyTemplatesList.where((enemyTmpl) =>
        gameProvider.playerLevel >= enemyTmpl.minPlayerLevel &&
        !gameProvider.defeatedEnemyIds.contains(enemyTmpl.id) &&
        (currentTaskTheme == null || enemyTmpl.theme == currentTaskTheme || enemyTmpl.theme == null)
    ).toList()..sort((a,b) {
        int lvlCompare = a.minPlayerLevel.compareTo(b.minPlayerLevel);
        if (lvlCompare != 0) return lvlCompare;
        return a.name.compareTo(b.name);
    });

    final ownedPowerUps = gameProvider.artifacts.map((ownedArt) {
        final template = gameProvider.artifactTemplatesList.firstWhere((t) => t.id == ownedArt.templateId, orElse: () => ArtifactTemplate(id:'', name:'', type:'', description: '', cost:0, icon:''));
        return (template.id.isNotEmpty && template.type == 'powerup' && (ownedArt.uses ?? 0) > 0) ? {'owned': ownedArt, 'template': template} : null;
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();


    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.swordCross, color: AppTheme.fhAccentTeal, size: 32),
                const SizedBox(width: 12),
                Text(
                  "The Dark Forest Arena",
                  style: theme.textTheme.headlineSmall?.copyWith(fontFamily: AppTheme.fontMain, color: AppTheme.fhAccentTeal),
                ),
              ],
            ),
          ),

          if (gameProvider.currentGame.enemy == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Choose Your Opponent:', style: theme.textTheme.titleLarge?.copyWith(color: AppTheme.fhTextPrimary)),
            ),
            if (availableEnemies.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  "No suitable opponents found for your current level (${gameProvider.playerLevel})${currentTaskTheme != null ? ' and theme ($currentTaskTheme)' : ''}. Try a different quest, level up, or use Settings to generate more!",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fhTextSecondary),
                ),
              )
            else
             LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = 2;
                  if (constraints.maxWidth > 700) { // Adjusted breakpoints
                    crossAxisCount = 3;
                  }
                   double itemWidth = (constraints.maxWidth - (crossAxisCount -1) * 12) / crossAxisCount;
                   double childAspectRatio = itemWidth / 220; // Adjusted based on EnemyInfoCard estimated height

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: childAspectRatio.clamp(1.0, 1.5), // Ensure cards are not too tall or too flat
                    ),
                    itemCount: availableEnemies.length,
                    itemBuilder: (context, index) {
                      final enemyTmpl = availableEnemies[index];
                      return EnemyInfoCardWidget(
                        enemy: enemyTmpl,
                        playerLevel: gameProvider.playerLevel,
                        onStartGame: () => gameProvider.startGame(enemyTmpl.id),
                      );
                    },
                  );
                }
              )
          ] else ...[ // In Combat
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _renderCharacterStats(context, gameProvider.playerGameStats, true, gameProvider)),
                  const SizedBox(width: 12),
                  Expanded(child: _renderCharacterStats(context, gameProvider.currentGame.enemy!, false, gameProvider)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ElevatedButton.icon(
                icon: Icon(MdiIcons.sword, size: 20),
                label: Text('ATTACK! (${energyPerAttack.toInt()}⚡)'),
                onPressed: gameProvider.playerEnergy < energyPerAttack ? null : gameProvider.handleFight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.fhAccentRed,
                  disabledBackgroundColor: AppTheme.fhBgLight,
                  disabledForegroundColor: AppTheme.fhTextSecondary.withOpacity(0.7),
                  minimumSize: const Size(double.infinity, 48),
                  textStyle: const TextStyle(fontSize: 16, fontFamily: AppTheme.fontMain, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (gameProvider.playerEnergy < energyPerAttack)
                Text('Not enough energy! Complete sub-quests.', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhAccentRed)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: OutlinedButton(
                onPressed: gameProvider.forfeitMatch,
                 style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.fhAccentOrange,
                    side: const BorderSide(color: AppTheme.fhAccentOrange),
                    minimumSize: const Size(double.infinity, 40),
                    textStyle: const TextStyle(fontSize: 14, fontFamily: AppTheme.fontMain),
                  ),
                child: const Text('Forfeit Match (-10% Ø, 0⚡)'),
              ),
            ),
             if (ownedPowerUps.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              Padding(
                padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
                child: Text('Power-ups:', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.fhTextSecondary)),
              ),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: ownedPowerUps.map((powerUpData) {
                  final OwnedArtifact owned = powerUpData['owned'] as OwnedArtifact;
                  final ArtifactTemplate template = powerUpData['template'] as ArtifactTemplate;
                  return Tooltip(
                    message: '${template.name}: ${template.description} (Uses: ${owned.uses})',
                    child: OutlinedButton(
                      onPressed: () => gameProvider.usePowerUp(owned.uniqueId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.fhAccentPurple,
                        side: const BorderSide(color: AppTheme.fhAccentPurple, width: 0.5),
                        padding: const EdgeInsets.all(8),
                        minimumSize: const Size(40,40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(template.icon, style: const TextStyle(fontSize: 20)),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Combat Log:', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.fhTextSecondary, fontFamily: AppTheme.fontMain)),
          ),
          const SizedBox(height: 8),
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppTheme.fhBgDark.withOpacity(0.7),
              border: Border.all(color: AppTheme.fhBorderColor),
              borderRadius: BorderRadius.circular(4),
            ),
            child: gameProvider.currentGame.log.isEmpty
              ? Text('No actions yet...', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.fhTextSecondary.withOpacity(0.7)))
              : ListView.builder(
                  reverse: true, // Show latest logs first
                  itemCount: gameProvider.currentGame.log.length,
                  itemBuilder: (context, index) {
                    final entry = gameProvider.currentGame.log.reversed.toList()[index];
                    // Simple color parsing from HTML-like spans
                    Color entryColor = AppTheme.fhTextSecondary;
                    String cleanEntry = entry.replaceAll(RegExp(r'<span[^>]*>|<\/span>'), "");

                    // More robust color parsing
                    final colorMatch = RegExp(r'color:#([0-9a-fA-F]{6})').firstMatch(entry);
                    if (colorMatch != null) {
                        try {
                           entryColor = Color(int.parse('FF${colorMatch.group(1)}', radix: 16));
                        } catch (e) { /* fallback to default */ }
                    } else if (entry.contains('color:var(--fh-accent-green)')) { entryColor = AppTheme.fhAccentGreen; }
                    else if (entry.contains('color:var(--fh-accent-red)')) { entryColor = AppTheme.fhAccentRed; }
                    else if (entry.contains('color:var(--fh-accent-orange)')) { entryColor = AppTheme.fhAccentOrange; }
                    else if (entry.contains('color:var(--fh-accent-purple)')) { entryColor = AppTheme.fhAccentPurple; }
                     else if (entry.contains('font-weight:bold')) { entryColor = AppTheme.fhTextPrimary; }


                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        cleanEntry,
                        style: theme.textTheme.bodySmall?.copyWith(color: entryColor, height: 1.3),
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