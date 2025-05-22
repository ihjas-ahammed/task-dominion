// lib/src/providers/actions/ai_generation_actions.dart
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/services/ai_service.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';

class AIGenerationActions {
  final GameProvider _provider;
  final AIService _aiService = AIService();

  AIGenerationActions(this._provider);

  Future<void> generateGameContent(int levelForContent, {bool isManual = false, bool isInitial = false}) async {
    if (_provider.isGeneratingContent && !isManual && !isInitial) return;
    _provider.setProviderAIGlobalLoading(true);

    final themes = ['tech', 'knowledge', 'learning', 'discipline', 'order'];
    final existingEnemyIdsString = _provider.enemyTemplatesList.map((e) => e.id).join(', ');
    final existingArtifactIdsString = _provider.artifactTemplatesList.map((a) => a.id).join(', ');

    try {
      final result = await _aiService.generateGameContent(
        levelForContent: levelForContent,
        isManual: isManual,
        isInitial: isInitial,
        currentApiKeyIndex: _provider.apiKeyIndex,
        onNewApiKeyIndex: (newIndex) => _provider.setProviderApiKeyIndex(newIndex),
        existingEnemyIdsString: existingEnemyIdsString.isNotEmpty ? existingEnemyIdsString : 'none',
        existingArtifactIdsString: existingArtifactIdsString.isNotEmpty ? existingArtifactIdsString : 'none',
        themes: themes,
        onLog: (logMessage) {
           _provider.setProviderState(
            currentGame: CurrentGame(
                enemy: _provider.currentGame.enemy,
                playerCurrentHp: _provider.currentGame.playerCurrentHp,
                log: [..._provider.currentGame.log, logMessage],
            ),
            doPersist: false,
            doNotify: true
          );
        },
      );

      final List<EnemyTemplate> uniqueNewEnemies = result['newEnemies']!
          .map((eJson) => EnemyTemplate.fromJson(eJson))
          .where((e) => !_provider.enemyTemplatesList.any((et) => et.id == e.id))
          .toList();

      final List<ArtifactTemplate> uniqueNewArtifacts = result['newArtifacts']!
          .map((aJson) => ArtifactTemplate.fromJson(aJson))
          .where((a) => !_provider.artifactTemplatesList.any((at) => at.id == a.id))
          .toList();

      _provider.setProviderState(
        enemyTemplatesList: [..._provider.enemyTemplatesList, ...uniqueNewEnemies],
        artifactTemplatesList: [..._provider.artifactTemplatesList, ...uniqueNewArtifacts],
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentGreen.value.toRadixString(16).substring(2)};\">New challenges and treasures have appeared! (AI Generated)</span>"],
        )
      );

    } catch (e) {
       _provider.setProviderState(
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentRed.value.toRadixString(16).substring(2)};\">AI content generation failed: ${e.toString()}</span>"],
        )
      );
    } finally {
      _provider.setProviderAIGlobalLoading(false);
    }
  }

  Future<void> triggerAISubquestGeneration(MainTask mainTaskForSubquests, String generationMode, String userInput, int numSubquests) async {
    if (_provider.isGeneratingSubquests) return;
    _provider.setProviderAISubquestLoading(true);

    try {
      final generatedSubquestsRaw = await _aiService.generateAISubquests(
        mainTaskName: mainTaskForSubquests.name,
        mainTaskDescription: mainTaskForSubquests.description,
        mainTaskTheme: mainTaskForSubquests.theme,
        generationMode: generationMode,
        userInput: userInput,
        numSubquests: numSubquests,
        currentApiKeyIndex: _provider.apiKeyIndex,
        onNewApiKeyIndex: (newIndex) => _provider.setProviderApiKeyIndex(newIndex),
        onLog: (logMessage) {
           _provider.setProviderState(
            currentGame: CurrentGame(
                enemy: _provider.currentGame.enemy,
                playerCurrentHp: _provider.currentGame.playerCurrentHp,
                log: [..._provider.currentGame.log, logMessage],
            ),
            doPersist: false,
            doNotify: true
          );
        },

      );

      final List<SubTask> newSubTasksForParent = [];
      for (var subquestData in generatedSubquestsRaw) {
          final List<Map<String, dynamic>> subSubTasksDataList = (subquestData['subSubTasksData'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
          final List<SubSubTask> currentSubSubTasks = [];
          for (int i = 0; i < subSubTasksDataList.length; i++) {
              final sssData = subSubTasksDataList[i];
              currentSubSubTasks.add(SubSubTask(
                  id: 'ssub_${DateTime.now().millisecondsSinceEpoch}_${newSubTasksForParent.length}_$i',
                  name: sssData['name'] as String,
                  isCountable: sssData['isCountable'] as bool? ?? false,
                  targetCount: (sssData['isCountable'] as bool? ?? false) ? (sssData['targetCount'] as int? ?? 1) : 0,
              ));
          }

          newSubTasksForParent.add(SubTask(
              id: 'sub_${DateTime.now().millisecondsSinceEpoch}_${newSubTasksForParent.length}',
              name: subquestData['name'] as String,
              isCountable: subquestData['isCountable'] as bool? ?? false,
              targetCount: (subquestData['isCountable'] as bool? ?? false) ? (subquestData['targetCount'] as int? ?? 1) : 0,
              subSubTasks: currentSubSubTasks,
          ));
      }

      final newMainTasks = _provider.mainTasks.map((task) {
        if (task.id == mainTaskForSubquests.id) {
          return MainTask(
            id: task.id, name: task.name, description: task.description, theme: task.theme,
            streak: task.streak, dailyTimeSpent: task.dailyTimeSpent, lastWorkedDate: task.lastWorkedDate,
            subTasks: [...task.subTasks, ...newSubTasksForParent],
          );
        }
        return task;
      }).toList();

      _provider.setProviderState(
        mainTasks: newMainTasks,
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentGreen.value.toRadixString(16).substring(2)};\">AI successfully generated ${generatedSubquestsRaw.length} new sub-quests for '${mainTaskForSubquests.name}'.</span>"],
        )
      );

    } catch (e) {
      _provider.setProviderState(
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentRed.value.toRadixString(16).substring(2)};\">AI sub-quest generation failed: ${e.toString()}</span>"],
        )
      );
    } finally {
      _provider.setProviderAISubquestLoading(false);
    }
  }
}