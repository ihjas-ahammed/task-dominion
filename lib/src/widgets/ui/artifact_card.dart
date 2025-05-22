// lib/src/widgets/ui/artifact_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ArtifactCardWidget extends StatelessWidget {
  final ArtifactTemplate template;
  final OwnedArtifact? ownedArtifact;
  final Widget? actionSection;
  final int? cost;

  const ArtifactCardWidget({
    super.key,
    required this.template,
    this.ownedArtifact,
    this.actionSection,
    this.cost,
  });

  Map<String, IconData> get _statIcons => {
    'att': MdiIcons.sword,
    'def': MdiIcons.shieldOutline,
    'health': MdiIcons.heartFlash, // Changed Icon
    'runic': MdiIcons.fireAlert, // Changed Icon
    'luck': MdiIcons.cloverOutline, // Changed Icon
    'cooldown': MdiIcons.clockFast,
    'bonusXPMod': MdiIcons.schoolOutline,
    'direct_damage': MdiIcons.laserPointer, // Changed Icon
    'heal_player': MdiIcons.bottleTonicPlusOutline,
    'uses': MdiIcons.repeatVariant,
  };

  Widget _buildStatsList(BuildContext context, ArtifactTemplate effectiveTemplate, OwnedArtifact? currentOwned) {
    final theme = Theme.of(context);
    final List<Widget> statWidgets = [];

    // Helper to create stat item with new styling
    Widget statChip(IconData icon, String value, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: AppTheme.fhBgDark.withOpacity(0.5),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5), width: 0.5)
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(value, style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhTextPrimary, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }


    if (effectiveTemplate.type == 'powerup') {
      if (effectiveTemplate.effectType == 'direct_damage' && effectiveTemplate.effectValue != null && effectiveTemplate.effectValue! > 0) {
        statWidgets.add(statChip(_statIcons['direct_damage']!, '${effectiveTemplate.effectValue}', AppTheme.fhAccentRed));
      }
      if (effectiveTemplate.effectType == 'heal_player' && effectiveTemplate.effectValue != null && effectiveTemplate.effectValue! > 0) {
        statWidgets.add(statChip(_statIcons['heal_player']!, '+${effectiveTemplate.effectValue} HP', AppTheme.fhAccentGreen));
      }
      final usesValue = currentOwned?.uses ?? template.uses;
      if (usesValue != null) {
        statWidgets.add(statChip(_statIcons['uses']!, '$usesValue Uses', AppTheme.fhTextSecondary));
      }
    } else {
      if (effectiveTemplate.baseAtt != null && effectiveTemplate.baseAtt! > 0) statWidgets.add(statChip(_statIcons['att']!, '+${effectiveTemplate.baseAtt}', AppTheme.fhAccentOrange));
      if (effectiveTemplate.baseDef != null && effectiveTemplate.baseDef! > 0) statWidgets.add(statChip(_statIcons['def']!, '+${effectiveTemplate.baseDef}', AppTheme.fhAccentBrightBlue));
      if (effectiveTemplate.baseHealth != null && effectiveTemplate.baseHealth! > 0) statWidgets.add(statChip(_statIcons['health']!, '+${effectiveTemplate.baseHealth}', AppTheme.fhAccentGreen));
      if (effectiveTemplate.baseRunic != null && effectiveTemplate.baseRunic! > 0) statWidgets.add(statChip(_statIcons['runic']!, '+${effectiveTemplate.baseRunic}', AppTheme.fhAccentPurple));
      if (effectiveTemplate.baseLuck != null && effectiveTemplate.baseLuck! > 0) statWidgets.add(statChip(_statIcons['luck']!, '+${effectiveTemplate.baseLuck}%', AppTheme.fhAccentLightCyan));
      if (effectiveTemplate.baseCooldown != null && effectiveTemplate.baseCooldown! > 0) statWidgets.add(statChip(_statIcons['cooldown']!, '-${effectiveTemplate.baseCooldown}% CD', AppTheme.fhTextSecondary)); // Assuming CD reduces
      if (effectiveTemplate.bonusXPMod != null && effectiveTemplate.bonusXPMod! > 0) statWidgets.add(statChip(_statIcons['bonusXPMod']!, '+${(effectiveTemplate.bonusXPMod! * 100).toStringAsFixed(0)}% XP', AppTheme.fhAccentGreen));
    }

    if (statWidgets.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          template.type == 'powerup' ? "Single-use tactical item." : "No direct combat bonuses.", // Updated text
          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.fhTextSecondary.withOpacity(0.7), fontSize: 10),
        ),
      );
    }

    // Use Wrap for stats instead of GridView for more flexible layout
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Wrap(
        spacing: 6.0, // Horizontal spacing
        runSpacing: 4.0, // Vertical spacing
        children: statWidgets,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    final ArtifactTemplate displayTemplate = ownedArtifact != null
        ? gameProvider.getArtifactEffectiveStats(ownedArtifact!)
        : template;

    Color borderColor = AppTheme.fhBorderColor;
    if (ownedArtifact != null) {
      borderColor = AppTheme.fhAccentTeal.withOpacity(0.7); // Highlight owned items
    } else if (cost != null && gameProvider.coins >= cost!) {
      borderColor = AppTheme.fhAccentLightCyan.withOpacity(0.5); // Highlight affordable items in shop
    }


    return Card(
      elevation: 0, // Flatter card
      color: AppTheme.fhBgLight.withOpacity(0.8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
        side: BorderSide(color: borderColor, width: 1), // Themed border
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container( // Icon background
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.fhBgDark.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4)
                      ),
                      child: Text(displayTemplate.icon, style: const TextStyle(fontSize: 22)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayTemplate.name,
                            style: theme.textTheme.titleMedium?.copyWith(fontFamily:AppTheme.fontMain, color: AppTheme.fhAccentLightCyan, fontWeight: FontWeight.bold, fontSize: 14), // Adjusted style
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                           if (ownedArtifact != null && displayTemplate.type != 'powerup' && displayTemplate.maxLevel != null)
                            Text(
                              'LEVEL ${ownedArtifact!.currentLevel} / ${displayTemplate.maxLevel}', // Clearer level display
                              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhAccentPurple, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            )
                           else // Show type for templates or powerups
                             Text(
                              displayTemplate.type.toUpperCase(),
                              style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhTextSecondary, letterSpacing: 0.5, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),

                  ],
                ),
                const SizedBox(height: 8),
                 if (displayTemplate.theme != null) ...[
                    Row(
                      children: [
                        Icon(MdiIcons.paletteSwatchOutline, size: 12, color: AppTheme.fhTextSecondary.withOpacity(0.7)),
                        const SizedBox(width: 4),
                        Text("Theme: ${displayTemplate.theme!}", style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhTextSecondary.withOpacity(0.7), fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 6),
                 ],
                Text(
                  displayTemplate.description,
                  style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhTextSecondary.withOpacity(0.9), fontStyle: FontStyle.italic, fontSize: 11, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4), // Reduced space before stats
                _buildStatsList(context, displayTemplate, ownedArtifact),
              ],
            ),
            if (actionSection != null) // Action section below stats, above cost if it were shown here
              Padding(
                padding: const EdgeInsets.only(top: 0.0), // Space between stats and actions
                child: Divider(color: AppTheme.fhBorderColor.withOpacity(0.3), height: 1, thickness: 0.5),
              ),
            if (actionSection != null)
              Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: actionSection!, // Action section already contains cost if needed
              ),
          ],
        ),
      ),
    );
  }
}