// lib/src/widgets/views/blacksmith_view.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:myapp_flutter/src/utils/constants.dart';
import 'package:myapp_flutter/src/utils/helpers.dart' as helper;
import 'package:myapp_flutter/src/widgets/ui/artifact_card.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class BlacksmithView extends StatelessWidget {
  const BlacksmithView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    final upgradableArtifacts = gameProvider.artifacts.where((art) {
      final template = gameProvider.artifactTemplatesList.firstWhere(
          (t) => t.id == art.templateId,
          orElse: () => ArtifactTemplate(
              id: '', name: '', type: '', description: '', cost: 0, icon: ''));
      return template.id
          .isNotEmpty; // All owned artifacts can be sold, powerups won't show upgrade
    }).toList();

    if (upgradableArtifacts.isEmpty) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(MdiIcons.hammerSickle, size: 48, color: AppTheme.fhAccentTeal),
            const SizedBox(height: 16),
            Text("Hephaestus' Forge",
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: AppTheme.fontMain,
                    color: AppTheme.fhAccentTeal)),
            const SizedBox(height: 8),
            Text(
              "Your satchel is empty, warrior. Acquire some artifacts to enhance or sell!",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.fhTextSecondary),
            ),
          ],
        ),
      ));
    }

    int getUpgradeCost(ArtifactTemplate template, int currentLevel) {
      if (template.type == 'powerup' ||
          template.maxLevel == null ||
          currentLevel >= template.maxLevel!) {
        return 9999999; // effectively infinity
      }
      return (template.cost *
              blacksmithUpgradeCostMultiplier *
              helper.xpLevelMultiplierPow(1.2, currentLevel - 1))
          .floor();
    }

    int getSellPrice(ArtifactTemplate template, OwnedArtifact ownedArtifact) {
      double sellMultiplier = 1.0;
      if (template.type == 'powerup' &&
          template.uses != null &&
          template.uses! > 0 &&
          ownedArtifact.uses != null) {
        sellMultiplier = (ownedArtifact.uses! / template.uses!);
      }
      return (template.cost * artifactSellPercentage * sellMultiplier).floor();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.hammerWrench,
                    color: AppTheme.fhAccentTeal, size: 32),
                const SizedBox(width: 12),
                Text(
                  "Hephaestus' Forge",
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: AppTheme.fontMain,
                      color: AppTheme.fhAccentTeal),
                ),
              ],
            ),
          ),
          LayoutBuilder(builder: (context, constraints) {
            int crossAxisCount = 2;
            if (constraints.maxWidth > 800) {
              crossAxisCount = 4;
            } else if (constraints.maxWidth > 500) {
              crossAxisCount = 3;
            }
            double itemWidth =
                (constraints.maxWidth - (crossAxisCount - 1) * 12) /
                    crossAxisCount;
            double childAspectRatio = itemWidth /
                250; // Adjust 250 based on desired card height with actions

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12.0),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: childAspectRatio.clamp(0.6, 0.9),
              ),
              itemCount: upgradableArtifacts.length,
              itemBuilder: (context, index) {
                final ownedArt = upgradableArtifacts[index];
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

                final upgradeCost =
                    getUpgradeCost(template, ownedArt.currentLevel);
                final sellPrice = getSellPrice(template, ownedArt);
                final bool canUpgrade = template.type != 'powerup' &&
                    template.maxLevel != null &&
                    ownedArt.currentLevel < template.maxLevel!;
                final bool canAffordUpgrade = gameProvider.coins >= upgradeCost;

                return ArtifactCardWidget(
                  template: template,
                  ownedArtifact: ownedArt,
                  actionSection: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (template.type != 'powerup')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Sell: $sellPrice Ø',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppTheme.fhTextSecondary),
                          ),
                        ),
                      Row(
                        // mainAxisAlignment: MainAxisAlignment.spaceBetween, // Not needed if using Spacer
                        children: [
                          if (template.type != 'powerup' &&
                              template.maxLevel != null)
                            ElevatedButton(
                              onPressed: (canUpgrade && canAffordUpgrade)
                                  ? () => gameProvider
                                      .upgradeArtifact(ownedArt.uniqueId)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.fhAccentTeal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                textStyle: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: AppTheme.fontMain,
                                    fontWeight: FontWeight.bold),
                                disabledBackgroundColor:
                                    AppTheme.fhBgDark.withOpacity(0.5),
                                disabledForegroundColor:
                                    AppTheme.fhTextSecondary.withOpacity(0.5),
                              ),
                              child: Text(canUpgrade
                                  ? (canAffordUpgrade
                                      ? 'Lvl ${ownedArt.currentLevel + 1}'
                                      : '$upgradeCost \$')
                                  : 'MAX LVL'),
                            ),
                          // If both buttons are present and you want a small gap:
                          if (template.type != 'powerup' &&
                              template.maxLevel != null)
                            const SizedBox(width: 2.0), // Gap between buttons

                          const Spacer(), // This will push the Sell button to the right
                          if (template.type != 'powerup')
                            OutlinedButton(
                              onPressed: () =>
                                  gameProvider.sellArtifact(ownedArt.uniqueId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.fhAccentOrange,
                                side: const BorderSide(
                                    color: AppTheme.fhAccentOrange, width: 0.5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                textStyle: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: AppTheme.fontMain,
                                    fontWeight: FontWeight.bold),
                              ),
                              child: const Text('SELL'),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}