// lib/src/widgets/views/skills_view.dart
import 'package:arcane/src/widgets/components/skill_card.dart';
import 'package:arcane/src/widgets/components/skill_xp_pie_chart.dart';
import 'package:arcane/src/widgets/components/xp_history_graph.dart';
import 'package:flutter/material.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:arcane/src/models/game_models.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

class SkillsView extends StatefulWidget {
  const SkillsView({super.key});

  @override
  State<SkillsView> createState() => _SkillsViewState();
}

class _SkillsViewState extends State<SkillsView> {
  String? _selectedSkillIdForCards;
  String? _selectedSubskillIdForGraph;

  @override
  void initState() {
    super.initState();
    final gameProvider = Provider.of<GameProvider>(context, listen: false);
    _initializeSelection(gameProvider);
  }
  
  void _initializeSelection(GameProvider gameProvider) {
    if (gameProvider.skills.isNotEmpty) {
      _selectedSkillIdForCards = gameProvider.skills.first.id;
      if (gameProvider.skills.first.subskills.isNotEmpty) {
        _selectedSubskillIdForGraph = gameProvider.skills.first.subskills.first.id;
      }
    }
  }

  void _updateSelection(GameProvider gameProvider) {
    if (_selectedSkillIdForCards == null && gameProvider.skills.isNotEmpty) {
       _selectedSkillIdForCards = gameProvider.skills.first.id;
    } else if (_selectedSkillIdForCards != null && !gameProvider.skills.any((s) => s.id == _selectedSkillIdForCards)) {
       _selectedSkillIdForCards = gameProvider.skills.isNotEmpty ? gameProvider.skills.first.id : null;
    }

    final selectedSkill = gameProvider.skills.firstWhereOrNull((s) => s.id == _selectedSkillIdForCards);
    if (_selectedSubskillIdForGraph == null && selectedSkill?.subskills.isNotEmpty == true) {
      _selectedSubskillIdForGraph = selectedSkill!.subskills.first.id;
    } else if (_selectedSubskillIdForGraph != null && selectedSkill?.subskills != null && selectedSkill?.subskills.any((ss) => ss.id == _selectedSubskillIdForGraph) != true) {
       _selectedSubskillIdForGraph = selectedSkill?.subskills.isNotEmpty == true ? selectedSkill?.subskills.first.id : null;
    }
  }


  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, child) {
        final theme = Theme.of(context);
        final skills = gameProvider.skills;

        if (skills.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No skills acquired yet. Complete tasks to develop new skills.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.fnTextSecondary,
                    fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Ensure selections are valid after a rebuild (e.g., a skill was deleted)
        WidgetsBinding.instance.addPostFrameCallback((_) {
            _updateSelection(gameProvider);
        });

        final selectedSkill = _selectedSkillIdForCards != null
            ? skills.firstWhereOrNull((s) => s.id == _selectedSkillIdForCards)
            : null;

        final skillColorForGraph = selectedSkill != null
            ? gameProvider.projects.firstWhere(
                (project) => project.theme == selectedSkill.id,
                orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: 'FF8A2BE2'),
              ).color
            : AppTheme.fortnitePurple;
            
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SkillXpPieChart(),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: skills.length + 1, // +1 for the graph
                itemBuilder: (context, index) {
                   if (index == skills.length) {
                    // This is the last item, show the graph
                    return Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                      child: _selectedSubskillIdForGraph != null
                          ? XpHistoryGraph(
                              selectedSubskillId: _selectedSubskillIdForGraph!,
                              skillColor: skillColorForGraph,
                            )
                          : const SizedBox(height: 150),
                    );
                  }
                  final skill = skills[index];
                  final projectForColor = gameProvider.projects.firstWhere(
                    (project) => project.theme == skill.id,
                    orElse: () => Project(id: '', name: '', description: '', theme: '', colorHex: 'FF8A2BE2'),
                  );
                  final skillColor = projectForColor.color;
                  return SkillCard(
                    skill: skill,
                    skillColor: skillColor,
                    isSelected: _selectedSkillIdForCards == skill.id,
                    onSelect: () {
                      setState(() {
                        _selectedSkillIdForCards = skill.id;
                        _selectedSubskillIdForGraph = skill.subskills.isNotEmpty ? skill.subskills.first.id : null;
                      });
                    },
                    onSubskillSelect: (subskillId) {
                       setState(() => _selectedSubskillIdForGraph = subskillId);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}