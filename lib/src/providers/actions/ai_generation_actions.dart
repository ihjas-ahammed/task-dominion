// lib/src/providers/actions/ai_generation_actions.dart
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/services/ai_service.dart';
import 'package:myapp_flutter/src/models/game_models.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class AIGenerationActions {
  final GameProvider _provider;
  final AIService _aiService = AIService();

  AIGenerationActions(this._provider);

  Future<void> generateGameContent(int levelForContent, {bool isManual = false, bool isInitial = false}) async {
    if (_provider.isGeneratingContent && !isManual && !isInitial) {
      print("[AIActions] generateGameContent skipped, already in progress.");
      return;
    }
    _provider.setProviderAIGlobalLoading(true);
    print("[AIActions] Starting generateGameContent for level $levelForContent. Manual: $isManual, Initial: $isInitial");


    final themes = ['tech', 'knowledge', 'learning', 'discipline', 'order', 'nature', 'ancient', 'shadow', 'light']; // Expanded themes
    final existingEnemyIdsString = _provider.enemyTemplatesList.map((e) => e.id).join(', ');
    final existingArtifactIdsString = _provider.artifactTemplatesList.map((a) => a.id).join(', ');
    final existingLocationIdsString = _provider.gameLocationsList.map((loc) => loc.id).join(', '); // Added

    try {
      final result = await _aiService.generateGameContent(
        levelForContent: levelForContent,
        isManual: isManual,
        isInitial: isInitial,
        currentApiKeyIndex: _provider.apiKeyIndex,
        onNewApiKeyIndex: (newIndex) {
          print("[AIActions] API key index updated to $newIndex");
          _provider.setProviderApiKeyIndex(newIndex);
        },
        existingEnemyIdsString: existingEnemyIdsString.isNotEmpty ? existingEnemyIdsString : 'none',
        existingArtifactIdsString: existingArtifactIdsString.isNotEmpty ? existingArtifactIdsString : 'none',
        existingLocationIdsString: existingLocationIdsString.isNotEmpty ? existingLocationIdsString : 'none', // Added
        themes: themes,
        onLog: (logMessage) {
           _provider.setProviderState(
            currentGame: CurrentGame(
                enemy: _provider.currentGame.enemy,
                playerCurrentHp: _provider.currentGame.playerCurrentHp,
                log: [..._provider.currentGame.log, logMessage],
                currentPlaceKey: _provider.currentGame.currentPlaceKey,
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
      
      final List<GameLocation> uniqueNewLocations = (result['newGameLocations'] as List<Map<String, dynamic>>? ?? [])
          .map((locJson) => GameLocation.fromJson(locJson))
          .where((loc) => !_provider.gameLocationsList.any((gl) => gl.id == loc.id))
          .toList();
      
      print("[AIActions] AI generated: ${uniqueNewEnemies.length} enemies, ${uniqueNewArtifacts.length} artifacts, ${uniqueNewLocations.length} locations.");


      _provider.setProviderState(
        enemyTemplatesList: [..._provider.enemyTemplatesList, ...uniqueNewEnemies],
        artifactTemplatesList: [..._provider.artifactTemplatesList, ...uniqueNewArtifacts],
        gameLocationsList: [..._provider.gameLocationsList, ...uniqueNewLocations], // Add new locations
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentGreen.value.toRadixString(16).substring(2)};\">New challenges, treasures, and realms have appeared! (AI Generated)</span>"],
            currentPlaceKey: _provider.currentGame.currentPlaceKey,
        )
      );

    } catch (e) {
       print("[AIActions] Error in generateGameContent: ${e.toString()}");
       _provider.setProviderState(
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentRed.value.toRadixString(16).substring(2)};\">AI content generation failed: ${e.toString()}</span>"],
            currentPlaceKey: _provider.currentGame.currentPlaceKey,
        )
      );
    } finally {
      _provider.setProviderAIGlobalLoading(false);
      print("[AIActions] Finished generateGameContent.");
    }
  }

  Future<void> triggerAISubquestGeneration(MainTask mainTaskForSubquests, String generationMode, String userInput, int numSubquests) async {
    if (_provider.isGeneratingSubquests) {
        print("[AIActions] triggerAISubquestGeneration skipped, already in progress.");
        return;
    }
    _provider.setProviderAISubquestLoading(true);
    print("[AIActions] Starting triggerAISubquestGeneration for task '${mainTaskForSubquests.name}'. Mode: $generationMode");


    try {
      final generatedSubquestsRaw = await _aiService.generateAISubquests(
        mainTaskName: mainTaskForSubquests.name,
        mainTaskDescription: mainTaskForSubquests.description,
        mainTaskTheme: mainTaskForSubquests.theme,
        generationMode: generationMode,
        userInput: userInput,
        numSubquests: numSubquests,
        currentApiKeyIndex: _provider.apiKeyIndex,
        onNewApiKeyIndex: (newIndex) {
            print("[AIActions] API key index updated to $newIndex during subquest gen.");
            _provider.setProviderApiKeyIndex(newIndex);
        },
        onLog: (logMessage) {
           _provider.setProviderState(
            currentGame: CurrentGame(
                enemy: _provider.currentGame.enemy,
                playerCurrentHp: _provider.currentGame.playerCurrentHp,
                log: [..._provider.currentGame.log, logMessage],
                currentPlaceKey: _provider.currentGame.currentPlaceKey,
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
            id: task.id, name: task.name, description: task.description, theme: task.theme, colorHex: task.colorHex,
            streak: task.streak, dailyTimeSpent: task.dailyTimeSpent, lastWorkedDate: task.lastWorkedDate,
            subTasks: [...task.subTasks, ...newSubTasksForParent],
          );
        }
        return task;
      }).toList();
      
      print("[AIActions] Generated ${newSubTasksForParent.length} new sub-quests for task '${mainTaskForSubquests.name}'.");

      _provider.setProviderState(
        mainTasks: newMainTasks,
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentGreen.value.toRadixString(16).substring(2)};\">AI successfully generated ${generatedSubquestsRaw.length} new sub-quests for '${mainTaskForSubquests.name}'.</span>"],
            currentPlaceKey: _provider.currentGame.currentPlaceKey,
        )
      );

    } catch (e) {
      print("[AIActions] Error in triggerAISubquestGeneration: ${e.toString()}");
      _provider.setProviderState(
        currentGame: CurrentGame(
            enemy: _provider.currentGame.enemy,
            playerCurrentHp: _provider.currentGame.playerCurrentHp,
            log: [..._provider.currentGame.log, "<span style=\"color:${AppTheme.fhAccentRed.value.toRadixString(16).substring(2)};\">AI sub-quest generation failed: ${e.toString()}</span>"],
            currentPlaceKey: _provider.currentGame.currentPlaceKey,
        )
      );
    } finally {
      _provider.setProviderAISubquestLoading(false);
      print("[AIActions] Finished triggerAISubquestGeneration.");
    }
  }
}