// lib/src/widgets/components/skill_xp_pie_chart.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SkillXpPieChart extends StatefulWidget {
  const SkillXpPieChart({super.key});

  @override
  State<SkillXpPieChart> createState() => _SkillXpPieChartState();
}

class _SkillXpPieChartState extends State<SkillXpPieChart> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final gameProvider = context.watch<GameProvider>();
    final theme = Theme.of(context);

    final List<PieChartSectionData> pieChartSections = [];
    final double totalXp = gameProvider.skills.fold(0.0, (sum, skill) => sum + skill.xp);

    if (totalXp == 0) {
      return const SizedBox.shrink(); // Don't show chart if no XP
    }

    for (int i = 0; i < gameProvider.skills.length; i++) {
      final skill = gameProvider.skills[i];
      if (skill.xp <= 0) continue;

      final isTouched = i == _touchedPieIndex;
      final projectForColor = gameProvider.projects.firstWhere(
        (project) => project.theme == skill.id,
        orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: 'FF8A2BE2'),
      );
      final skillColor = projectForColor.color;
      final percentage = (skill.xp / totalXp) * 100;

      pieChartSections.add(PieChartSectionData(
        color: skillColor,
        value: skill.xp,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: isTouched ? 45.0 : 35.0,
        titleStyle: TextStyle(
          fontSize: isTouched ? 12.0 : 10.0,
          fontWeight: FontWeight.bold,
          color: AppTheme.fnBgDark,
          fontFamily: AppTheme.fontDisplay,
          shadows: const [Shadow(color: Colors.black38, blurRadius: 2)],
        ),
      ));
    }

    return Column(
      children: [
        Text("Total XP Distribution", style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                      _touchedPieIndex = -1;
                      return;
                    }
                    _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: pieChartSections,
            ),
          ),
        ),
      ],
    );
  }
}