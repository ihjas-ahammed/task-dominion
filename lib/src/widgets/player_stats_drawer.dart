// lib/src/widgets/player_stats_drawer.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class PlayerStatsDrawer extends StatelessWidget {
  const PlayerStatsDrawer({super.key});

  Widget _buildStatDisplay(
      BuildContext context, String iconEmoji, String name, String value,
      {String? buffValue,
      Color? buffColor,
      String? description,
      double? progressPercent}) {
    final theme = Theme.of(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(iconEmoji,
                  style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.fhAccentLightCyan.withOpacity(0.8))),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                      fontFamily: AppTheme.fontMain,
                      color: AppTheme.fhTextSecondary,
                      letterSpacing: 0.8),
                ),
              ),
              if (buffValue != null)
                Text(
                  buffValue,
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: buffColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11),
                ),
              const SizedBox(width: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.fhTextPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          if (progressPercent != null &&
              name.toUpperCase() != 'VITALITY' &&
              name.toUpperCase() != 'XP BONUS')
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 32),
              child: SizedBox(
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2.5),
                    child: LinearProgressIndicator(
                      value: progressPercent.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.fhBorderColor.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.fhAccentLightCyan.withOpacity(0.7)),
                    ),
                  )),
            ),
          if (gameProvider.settings.descriptionsVisible &&
              description != null &&
              description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 3.0, left: 32),
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: AppTheme.fhTextSecondary.withOpacity(0.7),
                    fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(
          bottom: 5.0, top: 16.0, left: 16.0, right: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.fhAccentTeal, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
                fontFamily: AppTheme.fontMain,
                color: AppTheme.fhAccentTeal,
                fontSize: 13,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedItemRow(BuildContext context, ThemeData theme,
      String label, Map<String, dynamic>? itemDetails, VoidCallback onUnequip) {
    // ignore: unused_local_variable
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final String name = itemDetails?['name'] ?? 'None';
    final String icon = itemDetails?['icon'] ?? '➖';
    // ignore: unused_local_variable
    final int? level = itemDetails?['level'];
    final String? uniqueId = itemDetails?['uniqueId'];
    final bool isEquipped = uniqueId != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text('$label:',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.fhTextSecondary, fontSize: 12)),
          ),
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
               name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: isEquipped
                    ? AppTheme.fhAccentLightCyan
                    : AppTheme.fhTextSecondary.withOpacity(0.7),
                fontStyle: isEquipped ? FontStyle.normal : FontStyle.italic,
                fontWeight: isEquipped ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isEquipped)
            OutlinedButton(
              // Changed to OutlinedButton for consistency
              onPressed: onUnequip,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                textStyle: const TextStyle(
                    fontSize: 9,
                    fontFamily: AppTheme.fontMain,
                    fontWeight: FontWeight.bold),
                foregroundColor: AppTheme.fhAccentOrange,
                side: BorderSide(
                    color: AppTheme.fhAccentOrange.withOpacity(0.7), width: 1),
                minimumSize: const Size(0, 22),
              ),
              child: const Text('UNEQUIP'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    final playerMaxHp = gameProvider.playerGameStats['vitality']!.value;
    final playerCurrentHp = gameProvider.currentGame.playerCurrentHp;
    final hpPercent =
        playerMaxHp > 0 ? (playerCurrentHp / playerMaxHp).clamp(0.0, 1.0) : 0.0;
    Color hpBarColor;
    if (hpPercent * 100 > 60) {
      hpBarColor = AppTheme.fhAccentGreen;
    } else if (hpPercent * 100 > 30) {
      hpBarColor = AppTheme
          .fhAccentOrange; // Changed yellow to orange for better contrast potentially
    } else {
      hpBarColor = AppTheme.fhAccentRed;
    }

    final Map<String, dynamic> equippedItemsDetails = {};
    gameProvider.equippedItems.forEach((slot, uniqueId) {
      if (uniqueId != null) {
        final owned = gameProvider.artifacts.firstWhere(
            (art) => art.uniqueId == uniqueId,
            orElse: () =>
                OwnedArtifact(uniqueId: '', templateId: '', currentLevel: 0));
        if (owned.uniqueId.isNotEmpty) {
          final template = gameProvider.artifactTemplatesList.firstWhere(
              (tmpl) => tmpl.id == owned.templateId,
              orElse: () => ArtifactTemplate(
                  id: '',
                  name: '',
                  type: '',
                  description: '',
                  cost: 0,
                  icon: ''));
          if (template.id.isNotEmpty) {
            equippedItemsDetails[slot] = {
              'name': template.name,
              'icon': template.icon,
              'level': owned.currentLevel,
              'uniqueId': owned.uniqueId,
            };
          } else {
            equippedItemsDetails[slot] = {
              'name': 'Unknown Item',
              'icon': '❓',
              'level': 0,
              'uniqueId': uniqueId
            };
          }
        } else {
          equippedItemsDetails[slot] = {
            'name': 'Error Loading',
            'icon': '⚠️',
            'level': 0,
            'uniqueId': uniqueId
          };
        }
      } else {
        equippedItemsDetails[slot] = {
          'name': 'None',
          'icon': '➖',
          'level': null,
          'uniqueId': null
        };
      }
    });

    final unequippedArtifacts = gameProvider.artifacts
        .where((ownedArt) =>
            !gameProvider.equippedItems.values.contains(ownedArt.uniqueId) &&
            (gameProvider.artifactTemplatesList
                    .firstWhere((t) => t.id == ownedArt.templateId,
                        orElse: () => ArtifactTemplate(
                            id: '',
                            name: '',
                            type: '',
                            description: '',
                            cost: 0,
                            icon: ''))
                    .type !=
                'powerup'))
        .toList();

    return Drawer(
      backgroundColor: AppTheme.fhBgMedium,
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 10,
                16,
                12), // Adjust top padding for status bar
            decoration: const BoxDecoration(
                color: AppTheme.fhBgDark,
                border: Border(
                    bottom:
                        BorderSide(color: AppTheme.fhBorderColor, width: 1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Level ${gameProvider.romanize(gameProvider.playerLevel)} Adventurer',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(color: AppTheme.fhAccentTeal)),
                    Expanded(
                      child: Text(
                        gameProvider.currentUser?.email?.split('@')[0] ??
                            "Player",
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppTheme.fhTextSecondary),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(MdiIcons.starShootingOutline,
                              color: AppTheme.fhAccentLightCyan, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            gameProvider.xp.toStringAsFixed(0),
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.fhTextPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                          Text(
                            ' / ${gameProvider.xpNeededForNextLevel.toStringAsFixed(0)} XP',
                            style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.fhTextSecondary, fontSize: 9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 60,
                        height: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (gameProvider.xpProgressPercent / 100)
                                .clamp(0.0, 1.0),
                            backgroundColor:
                                AppTheme.fhBorderColor.withOpacity(0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.fhAccentLightCyan),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Icon(MdiIcons.heartPulse, size: 16, color: hpBarColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 8,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: hpPercent,
                            backgroundColor:
                                AppTheme.fhBorderColor.withOpacity(0.3),
                            valueColor:
                                AlwaysStoppedAnimation<Color>(hpBarColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${playerCurrentHp.toStringAsFixed(0)} / ${playerMaxHp.toStringAsFixed(0)} HP',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.fhTextPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildSectionTitle(
              theme, MdiIcons.swordCross, 'Equipped Gear'), // Changed icon
          _buildEquippedItemRow(
              context,
              theme,
              'Weapon',
              equippedItemsDetails['weapon'],
              () => gameProvider.unequipArtifact('weapon')),
          _buildEquippedItemRow(
              context,
              theme,
              'Armor',
              equippedItemsDetails['armor'],
              () => gameProvider.unequipArtifact('armor')),
          _buildEquippedItemRow(
              context,
              theme,
              'Talisman',
              equippedItemsDetails['talisman'],
              () => gameProvider.unequipArtifact('talisman')),

          _buildSectionTitle(theme, MdiIcons.treasureChestOutline,
              'Backpack (Gear)'), // Changed icon
          if (unequippedArtifacts.isEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
              child: Center(
                  child: Text('Backpack is empty of gear.',
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppTheme.fhTextSecondary,
                          fontSize: 11))),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: unequippedArtifacts.length,
              itemBuilder: (context, index) {
                final ownedArt = unequippedArtifacts[index];
                final template = gameProvider.artifactTemplatesList.firstWhere(
                    (t) => t.id == ownedArt.templateId,
                    orElse: () => ArtifactTemplate(
                        id: '',
                        name: '',
                        type: '',
                        description: '',
                        cost: 0,
                        icon: ''));
                if (template.id == '') return const SizedBox.shrink();

                return Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 2.0, horizontal: 16.0),
                  child: Material(
                    color: AppTheme.fhBgLight.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                    child: InkWell(
                      onTap: () =>
                          gameProvider.equipArtifact(ownedArt.uniqueId),
                      borderRadius: BorderRadius.circular(4),
                      hoverColor: AppTheme.fhAccentTeal.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 6.0),
                        child: Row(
                          children: [
                            Text(template.icon,
                                style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${template.name} (Lvl ${ownedArt.currentLevel})',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.fhTextPrimary,
                                    fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            ElevatedButton(
                              // Changed to ElevatedButton
                              onPressed: () =>
                                  gameProvider.equipArtifact(ownedArt.uniqueId),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                textStyle: const TextStyle(
                                    fontSize: 9,
                                    fontFamily: AppTheme.fontMain,
                                    fontWeight: FontWeight.bold),
                                minimumSize: const Size(0, 22),
                                elevation: 1,
                              ),
                              child: const Text('EQUIP'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          _buildSectionTitle(
              theme, MdiIcons.chartLineVariant, 'Player Stats'), // Changed icon
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: gameProvider.playerGameStats.entries.map((entry) {
              final stat = entry.value;
              final buffValue = stat.value - stat.base;
              String statValDisplay =
                  stat.value.toStringAsFixed(stat.name == 'XP Bonus' ? 2 : 0);
              if (stat.name == 'LUCK' ||
                  stat.name == 'COOLDOWN' ||
                  stat.name == 'XP Bonus') {
                statValDisplay =
                    '${(stat.value * (stat.name == 'XP Bonus' ? 100 : 1)).toStringAsFixed(0)}%';
              }

              String? buffDisplay;
              Color? buffColorVal;
              if (buffValue != 0 && stat.name != 'XP Bonus') {
                // Don't show buff for XP Bonus as it's always from items
                buffDisplay =
                    '${buffValue > 0 ? '+' : ''}${(stat.name == 'LUCK' || stat.name == 'COOLDOWN') ? '${buffValue.toStringAsFixed(0)}%' : buffValue.toStringAsFixed(0)}';
                buffColorVal = buffValue > 0
                    ? AppTheme.fhAccentGreen
                    : AppTheme.fhAccentRed;
              }

              double progress = 0.0;
              if (stat.name != 'VITALITY' && stat.name != 'XP Bonus') {
                double typicalMax =
                    50; // Arbitrary max for visual progress bar scaling
                if (stat.name == 'LUCK' || stat.name == 'COOLDOWN') {
                  typicalMax = 50; // Percentage based
                }
                progress = (stat.value / typicalMax);
              }

              return _buildStatDisplay(
                context,
                stat.icon,
                stat.name,
                statValDisplay,
                buffValue: buffDisplay,
                buffColor: buffColorVal,
                description: stat.description,
                progressPercent:
                    (stat.name != 'VITALITY' && stat.name != 'XP Bonus')
                        ? progress
                        : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}