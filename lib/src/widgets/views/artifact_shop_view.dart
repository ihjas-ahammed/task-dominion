// lib/src/widgets/views/artifact_shop_view.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:myapp_flutter/src/widgets/ui/artifact_card.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ArtifactShopView extends StatelessWidget {
  const ArtifactShopView({super.key});

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);
    final currentTask = gameProvider.getSelectedTask();
    final String? currentTaskTheme = currentTask?.theme;

    final itemsToShow = gameProvider.artifactTemplatesList.where((template) {
      // Basic filter: exclude items with type containing "powerup_dev"
      // Theme filter: show if current task has no theme, or item theme matches, or item theme is null/general
      final bool themeMatch = currentTaskTheme == null ||
          template.theme == null ||
          template.theme == currentTaskTheme;
      return !template.type.contains("powerup_dev") && themeMatch;
    }).toList()
      ..sort((a, b) {
        // Sorting logic
        if (currentTaskTheme != null) {
          final bool aIsThemed = a.theme == currentTaskTheme;
          final bool bIsThemed = b.theme == currentTaskTheme;
          if (aIsThemed && !bIsThemed) return -1;
          if (!aIsThemed && bIsThemed) return 1;
        }
        if (a.cost != b.cost) return a.cost.compareTo(b.cost);
        return a.name.compareTo(b.name);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16, right: 4),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.storefrontOutline,
                    color: AppTheme.fhAccentTeal, size: 32),
                const SizedBox(width: 12),
                Text(
                  "Brok & Sindri's Wares",
                  style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: AppTheme.fontMain,
                      color: AppTheme.fhAccentTeal),
                ),
              ],
            ),
          ),
          if (itemsToShow.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                "No wares currently matching your quest's focus. Perhaps try a different quest or generate more content via Settings?",
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.fhTextSecondary),
              ),
            )
          else
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
              double childAspectRatio =
                  itemWidth / 230; // Adjust 230 based on desired card height

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(
                    12.0), // GridView itself has no padding here
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio:
                      childAspectRatio.clamp(0.6, 1.0), // Clamp aspect ratio
                ),
                itemCount: itemsToShow.length,
                itemBuilder: (context, index) {
                  final template = itemsToShow[index];
                  final bool canAfford = gameProvider.coins >= template.cost;
                  final bool isOwned = template.type != 'powerup' &&
                      gameProvider.artifacts
                          .any((art) => art.templateId == template.id);
                  // final bool isOwned = false; // Original dead code line

                  return ArtifactCardWidget(
                    template: template,
                    cost: template.cost,
                    actionSection: SizedBox(
                      // <--- WRAP HERE
                      width: double.infinity, // <--- MAKE IT TAKE FULL WIDTH
                      child: ElevatedButton(
                        onPressed: (!canAfford || isOwned)
                            ? null
                            : () => gameProvider.buyArtifact(template.id),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 6),
                          textStyle: const TextStyle(
                              fontSize: 11,
                              fontFamily: AppTheme.fontMain,
                              fontWeight: FontWeight.bold),
                          disabledBackgroundColor:
                              AppTheme.fhBgDark.withOpacity(0.5),
                          disabledForegroundColor:
                              AppTheme.fhTextSecondary.withOpacity(0.5),
                          // You can also set a minimum height if you want, e.g.,
                          // minimumSize: Size(double.infinity, 48), // 48 is an example height
                        ),
                        child: Text(isOwned
                            ? 'OWNED'
                            : (canAfford
                                ? '${template.cost} \$'
                                : '${template.cost} \$')),
                      ),
                    ), // // ElevatedButton
                  );
                },
              );
            }),
        ],
      ),
    );
  }
}