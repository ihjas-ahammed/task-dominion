// lib/src/widgets/views/game_view.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:myapp_flutter/src/utils/constants.dart';
import 'package:myapp_flutter/src/widgets/ui/enemy_info_card.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:collection/collection.dart';


class GameView extends StatefulWidget {
  const GameView({super.key});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  String? _selectedLocationId; 

  @override
  void initState() {
    super.initState();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    print("[GameView] initState called.");

    final availableLocations = gameProvider.gameLocationsList.where((loc) => gameProvider.isLocationUnlocked(loc.id)).toList();
    print("[GameView] Available unlocked locations: ${availableLocations.map((l) => l.name).join(', ')}");


    _selectedLocationId = gameProvider.currentGame.currentPlaceKey;

    if (_selectedLocationId == null || !gameProvider.isLocationUnlocked(_selectedLocationId!)) {
        if (availableLocations.isNotEmpty) {
            _selectedLocationId = availableLocations.first.id;
            print("[GameView] Defaulting selectedLocationId to first available: ${_selectedLocationId}");
        } else if (gameProvider.gameLocationsList.isNotEmpty) {
            _selectedLocationId = gameProvider.gameLocationsList.first.id;
             print("[GameView] No unlocked locations, defaulting selectedLocationId to absolute first: ${_selectedLocationId}");
        } else {
            _selectedLocationId = null; 
            print("[GameView] No locations available at all.");
        }
    }


    if(_selectedLocationId != null && gameProvider.currentGame.currentPlaceKey != _selectedLocationId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print("[GameView] Updating provider with selectedLocationId: $_selectedLocationId");
          gameProvider.setProviderState(
            currentGame: CurrentGame(
              enemy: gameProvider.currentGame.enemy, 
              playerCurrentHp: gameProvider.currentGame.playerCurrentHp,
              log: gameProvider.currentGame.log,
              currentPlaceKey: _selectedLocationId,
            ),
            doPersist: false 
          );
        }
      });
    }
     print("[GameView] Final _selectedLocationId in initState: $_selectedLocationId");
  }


  Widget _renderCharacterStats(BuildContext context, dynamic character, bool isPlayer, GameProvider gameProvider) {
    final theme = Theme.of(context);
    final Color dynamicAccent = gameProvider.getSelectedTask()?.taskColor ?? theme.colorScheme.secondary;
    final double maxHp = isPlayer ? gameProvider.playerGameStats['vitality']!.value : (character as EnemyTemplate).health.toDouble();
    double currentHp;

    String characterName = "Your Stats";
    String? description;
    int attackStat = 0;
    int defenseStat = 0;
    List<Widget> runeEffectsDisplay = []; 

    if (isPlayer) {
        currentHp = gameProvider.currentGame.playerCurrentHp;
        characterName = gameProvider.currentUser?.displayName ?? "Adventurer";
        attackStat = gameProvider.playerGameStats['strength']!.value.toInt();
        defenseStat = gameProvider.playerGameStats['defense']!.value.toInt();
    } else if (character is EnemyTemplate) {
        characterName = character.name;
        description = character.description;
        attackStat = character.attack;
        defenseStat = character.defense;
        if (gameProvider.currentGame.enemy != null && gameProvider.currentGame.enemy!.id == character.id) {
             currentHp = gameProvider.currentGame.enemy!.hp.toDouble();
        } else {
            currentHp = character.hp.toDouble();
        }
    } else {
        currentHp = 0;
    }


    final double hpPercent = maxHp > 0 ? (currentHp / maxHp) : 0.0;
     Color hpBarColor;
    if (hpPercent * 100 > 60) { hpBarColor = AppTheme.fhAccentGreen; }
    else if (hpPercent * 100 > 30) { hpBarColor = AppTheme.fhAccentOrange; }
    else { hpBarColor = AppTheme.fhAccentRed; }

    return Card(
      elevation: 1,
      color: AppTheme.fhBgMedium.withOpacity(0.7), 
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              characterName,
              style: theme.textTheme.titleLarge?.copyWith(color: isPlayer ? dynamicAccent : AppTheme.fhAccentRed, fontWeight: FontWeight.bold, fontSize: 17),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
             SizedBox(
                height: 12, 
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(3), 
                    child: LinearProgressIndicator(
                    value: hpPercent,
                    backgroundColor: AppTheme.fhBgDark,
                    valueColor: AlwaysStoppedAnimation<Color>(hpBarColor),
                    ),
                )
            ),
            const SizedBox(height: 6),
            Text('HP: ${currentHp.toStringAsFixed(0)} / ${maxHp.toStringAsFixed(0)}', style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fhTextSecondary, fontSize: 13)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(MdiIcons.sword, size: 14, color: AppTheme.fhAccentOrange.withOpacity(0.8)),
                Text(' ATK: $attackStat  ', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
                Icon(MdiIcons.shield, size: 14, color: AppTheme.fhAccentTealFixed.withOpacity(0.8)), // Use fixed teal for clarity
                Text(' DEF: $defenseStat', style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13)),
              ],
            ),
             if (isPlayer && runeEffectsDisplay.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(spacing: 4, runSpacing: 4, children: runeEffectsDisplay),
             ],
             if (!isPlayer && description != null && description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Tooltip(
                    message: description,
                    preferBelow: false,
                    child: Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.fhTextSecondary.withOpacity(0.7), fontSize: 11),
                        maxLines: 2, 
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
    final Color dynamicAccent = gameProvider.getSelectedTask()?.taskColor ?? theme.colorScheme.secondary;
    final Color buttonTextColor = ThemeData.estimateBrightnessForColor(dynamicAccent) == Brightness.dark ? AppTheme.fhTextPrimary : AppTheme.fhBgDark;

    print("[GameView] build called. SelectedLocationId: $_selectedLocationId, currentPlaceKey from provider: ${gameProvider.currentGame.currentPlaceKey}");
    
    final List<GameLocation> unlockedLocations = gameProvider.gameLocationsList.where((loc) => gameProvider.isLocationUnlocked(loc.id)).toList();
    print("[GameView] Unlocked locations for dropdown: ${unlockedLocations.map((l) => l.name).join(', ')}");

    if (_selectedLocationId != null && !unlockedLocations.any((loc) => loc.id == _selectedLocationId)) {
        print("[GameView] _selectedLocationId '$_selectedLocationId' is no longer valid/unlocked.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
                setState(() {
                    _selectedLocationId = unlockedLocations.isNotEmpty ? unlockedLocations.first.id : (gameProvider.gameLocationsList.isNotEmpty ? gameProvider.gameLocationsList.first.id : null);
                    print("[GameView] Reset _selectedLocationId to '$_selectedLocationId'");
                    if (_selectedLocationId != null) {
                        gameProvider.setProviderState(
                            currentGame: CurrentGame(
                                playerCurrentHp: gameProvider.currentGame.playerCurrentHp,
                                log: gameProvider.currentGame.log,
                                currentPlaceKey: _selectedLocationId,
                            ),
                            doPersist: false
                        );
                    }
                });
            }
        });
    }


    final availableEnemies = gameProvider.enemyTemplatesList.where((enemyTmpl) =>
        enemyTmpl.locationKey == _selectedLocationId && 
        gameProvider.playerLevel >= enemyTmpl.minPlayerLevel &&
        !gameProvider.defeatedEnemyIds.contains(enemyTmpl.id)
    ).toList()..sort((a,b) {
        int lvlCompare = a.minPlayerLevel.compareTo(b.minPlayerLevel);
        if (lvlCompare != 0) return lvlCompare;
        return a.name.compareTo(b.name);
    });

    final ownedPowerUps = gameProvider.artifacts.map((ownedArt) {
        final template = gameProvider.getArtifactTemplateById(ownedArt.templateId);
        return (template != null && template.type == 'powerup' && (ownedArt.uses ?? 0) > 0) ? {'owned': ownedArt, 'template': template} : null;
    }).where((item) => item != null).cast<Map<String, dynamic>>().toList();

    GameLocation? displayedLocation = _selectedLocationId != null
      ? gameProvider.gameLocationsList.firstWhereOrNull((loc) => loc.id == _selectedLocationId)
      : null;
    if (displayedLocation == null && gameProvider.gameLocationsList.isNotEmpty) {
        displayedLocation = gameProvider.gameLocationsList.first;
        _selectedLocationId = displayedLocation.id; 
         print("[GameView] Fallback: displayedLocation set to ${displayedLocation.name}");
    }


    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, right: 4, left: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(displayedLocation?.iconEmoji ?? '🗺️', style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Text(
                  displayedLocation?.name ?? "No Zone Selected",
                  style: theme.textTheme.displaySmall?.copyWith(color: AppTheme.fhTextPrimary, fontSize: 24), // Slightly smaller title
                ),
              ],
            ),
          ),

           if (gameProvider.currentGame.enemy == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical:8.0),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Select Combat Zone'),
                dropdownColor: AppTheme.fhBgMedium,
                value: _selectedLocationId,
                items: gameProvider.gameLocationsList.map((location) {
                  final bool isUnlocked = gameProvider.isLocationUnlocked(location.id);
                  return DropdownMenuItem<String>(
                    value: location.id,
                    enabled: isUnlocked,
                    child: Row(
                      children: [
                        Text(location.iconEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          location.name,
                          style: TextStyle(color: isUnlocked ? AppTheme.fhTextPrimary : AppTheme.fhTextDisabled),
                        ),
                        if (!isUnlocked) ...[
                          const SizedBox(width: 8),
                          Icon(MdiIcons.lockOutline, size: 14, color: AppTheme.fhTextDisabled.withOpacity(0.7)),
                          Text(" (Lvl ${location.minPlayerLevelToUnlock})", style: TextStyle(fontSize: 10, color: AppTheme.fhTextDisabled.withOpacity(0.7)))
                        ]
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null && gameProvider.isLocationUnlocked(newValue)) {
                    print("[GameView] Location changed to: $newValue");
                    setState(() {
                      _selectedLocationId = newValue;
                    });
                     gameProvider.setProviderState(
                        currentGame: CurrentGame(
                          playerCurrentHp: gameProvider.currentGame.playerCurrentHp,
                          log: gameProvider.currentGame.log,
                          currentPlaceKey: newValue,
                        ),
                        doPersist: false
                     );
                  } else if (newValue != null) {
                    print("[GameView] Attempted to select locked location: $newValue");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Location ${gameProvider.gameLocationsList.firstWhereOrNull((l)=>l.id == newValue)?.name ?? ''} is locked!"), backgroundColor: AppTheme.fhAccentOrange),
                    );
                  }
                },
              ),
            ),


          if (gameProvider.currentGame.enemy == null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Choose Your Opponent:', style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.fhTextPrimary, fontSize: 20)),
            ),
            if (availableEnemies.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _selectedLocationId == null ? "Please select a combat zone." :
                  "No suitable opponents found in ${displayedLocation?.name ?? 'this zone'} for your current level (${gameProvider.playerLevel}). Try another zone or await new threats.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.fhTextSecondary),
                ),
              )
            else
             LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 600 ? 2 : 1); // Adjusted counts
                   double itemWidth = (constraints.maxWidth - (crossAxisCount +1) * 10) / crossAxisCount;
                   double childAspectRatio = itemWidth / 260; // Adjusted for new card height

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(10),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 10.0,
                      mainAxisSpacing: 10.0,
                      childAspectRatio: childAspectRatio.clamp(0.8, 1.1), // Adjusted clamp
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
          ] else ...[
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
                  backgroundColor: dynamicAccent,
                  foregroundColor: buttonTextColor,
                  minimumSize: const Size(double.infinity, 52), 
                  textStyle: theme.textTheme.labelLarge?.copyWith(color: buttonTextColor),
                ),
              ),
            ),
            if (gameProvider.playerEnergy < energyPerAttack)
                Text('Not enough energy! Complete sub-quests.', style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhAccentOrange)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: OutlinedButton(
                onPressed: gameProvider.forfeitMatch,
                 style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.fhAccentOrange,
                    side: const BorderSide(color: AppTheme.fhAccentOrange, width: 1),
                    minimumSize: const Size(double.infinity, 44),
                    textStyle: theme.textTheme.labelMedium?.copyWith(color: AppTheme.fhAccentOrange),
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
                  
                  Widget powerUpIcon;
                  if (template.icon.length == 1 || template.icon.length == 2) { 
                      powerUpIcon = Text(template.icon, style: const TextStyle(fontSize: 22));
                  } else { 
                      powerUpIcon = Icon(MdiIcons.fromString(template.icon.replaceAll('mdi-','')) ?? MdiIcons.flashAlert, size: 22);
                  }

                  return Tooltip(
                    message: '${template.name}: ${template.description} (Uses: ${owned.uses})',
                    child: OutlinedButton(
                      onPressed: () => gameProvider.usePowerUp(owned.uniqueId),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.fhAccentPurple,
                        side: const BorderSide(color: AppTheme.fhAccentPurple, width: 1),
                        padding: const EdgeInsets.all(10),
                        minimumSize: const Size(48,48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      child: powerUpIcon,
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('Combat Log:', style: theme.textTheme.titleSmall?.copyWith(color: AppTheme.fhTextSecondary)),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180, 
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              color: AppTheme.fhBgMedium.withOpacity(0.6), 
              border: Border.all(color: AppTheme.fhBorderColor.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: gameProvider.currentGame.log.isEmpty
              ? Text('No actions yet...', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.fhTextSecondary.withOpacity(0.7)))
              : ListView.builder(
                  reverse: true,
                  itemCount: gameProvider.currentGame.log.length,
                  itemBuilder: (context, index) {
                    final entry = gameProvider.currentGame.log.reversed.toList()[index];
                    Color entryColor = AppTheme.fhTextSecondary;
                    String cleanEntry = entry.replaceAll(RegExp(r'<span[^>]*>|<\/span>'), "");

                    final colorMatch = RegExp(r'color:#([0-9a-fA-F]{6})').firstMatch(entry);
                    if (colorMatch != null) {
                        try {
                           entryColor = Color(int.parse('FF${colorMatch.group(1)}', radix: 16));
                        } catch (e) { /* fallback */ }
                    } else if (entry.contains('var(--fh-accent-green)')) { entryColor = AppTheme.fhAccentGreen; }
                    else if (entry.contains('var(--fh-accent-red)')) { entryColor = AppTheme.fhAccentRed; }
                    else if (entry.contains('var(--fh-accent-orange)')) { entryColor = AppTheme.fhAccentOrange; }
                    else if (entry.contains('var(--fh-accent-purple)')) { entryColor = AppTheme.fhAccentPurple; }
                    else if (entry.contains('font-weight:bold')) { entryColor = AppTheme.fhTextPrimary; }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        cleanEntry,
                        style: theme.textTheme.bodySmall?.copyWith(color: entryColor, height: 1.4),
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