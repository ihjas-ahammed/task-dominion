// lib/src/models/game_models.dart
// import 'package:arcane/src/utils/constants.dart'; // No longer needed here for constants
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:flutter/material.dart'; // For Color
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:arcane/src/theme/app_theme.dart'; // For MdiIcons

class MainTask {
  String id;
  String name;
  String description;
  String theme;
  String colorHex; // e.g., "FF64FFDA"
  int streak;
  int dailyTimeSpent;
  String? lastWorkedDate;
  List<SubTask> subTasks;

  MainTask({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    this.colorHex = "FF00F8F8", // Default to a vibrant cyan
    this.streak = 0,
    this.dailyTimeSpent = 0,
    this.lastWorkedDate,
    List<SubTask>? subTasks,
  }) : subTasks = subTasks ?? [];

  // Factory from MainTaskTemplate (which is now in this file)
  factory MainTask.fromTemplate(MainTaskTemplate template) {
    return MainTask(
      id: template.id,
      name: template.name,
      description: template.description,
      theme: template.theme,
      colorHex: template.colorHex,
    );
  }

  factory MainTask.fromJson(Map<String, dynamic> json) {
    return MainTask(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      theme: json['theme'] as String,
      colorHex: json['colorHex'] as String? ?? "FF00F8F8",
      streak: json['streak'] as int? ?? 0,
      dailyTimeSpent: json['dailyTimeSpent'] as int? ?? 0,
      lastWorkedDate: json['lastWorkedDate'] as String?,
      subTasks: (json['subTasks'] as List<dynamic>?)
              ?.map(
                  (stJson) => SubTask.fromJson(stJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'theme': theme,
      'colorHex': colorHex,
      'streak': streak,
      'dailyTimeSpent': dailyTimeSpent,
      'lastWorkedDate': lastWorkedDate,
      'subTasks': subTasks.map((st) => st.toJson()).toList(),
    };
  }

  Color get taskColor {
    try {
      return Color(int.parse("0x$colorHex"));
    } catch (e) {
      return AppTheme.fhAccentTealFixed; // Fallback color
    }
  }
}

class SubTask {
  String id;
  String name;
  bool completed;
  int currentTimeSpent; // Storing as minutes
  String? completedDate;
  bool isCountable;
  int targetCount;
  int currentCount;
  List<SubSubTask> subSubTasks;

  SubTask({
    required this.id,
    required this.name,
    this.completed = false,
    this.currentTimeSpent = 0,
    this.completedDate,
    this.isCountable = false,
    this.targetCount = 0,
    this.currentCount = 0,
    List<SubSubTask>? subSubTasks,
  }) : subSubTasks = subSubTasks ?? [];

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
      id: json['id'] as String,
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      currentTimeSpent: json['currentTimeSpent'] as int? ?? 0,
      completedDate: json['completedDate'] as String?,
      isCountable: json['isCountable'] as bool? ?? false,
      targetCount: json['targetCount'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? 0,
      subSubTasks: (json['subSubTasks'] as List<dynamic>?)
              ?.map((sssJson) =>
                  SubSubTask.fromJson(sssJson as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
      'currentTimeSpent': currentTimeSpent,
      'completedDate': completedDate,
      'isCountable': isCountable,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'subSubTasks': subSubTasks.map((sss) => sss.toJson()).toList(),
    };
  }
}

class SubSubTask {
  String id;
  String name;
  bool completed;
  bool isCountable;
  int targetCount;
  int currentCount;

  SubSubTask({
    required this.id,
    required this.name,
    this.completed = false,
    this.isCountable = false,
    this.targetCount = 0,
    this.currentCount = 0,
  });

  factory SubSubTask.fromJson(Map<String, dynamic> json) {
    return SubSubTask(
      id: json['id'] as String,
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      isCountable: json['isCountable'] as bool? ?? false,
      targetCount: json['targetCount'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? 0,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
      'isCountable': isCountable,
      'targetCount': targetCount,
      'currentCount': currentCount,
    };
  }
}

class OwnedArtifact {
  String uniqueId;
  String templateId;
  int currentLevel;
  int? uses;

  OwnedArtifact({
    required this.uniqueId,
    required this.templateId,
    required this.currentLevel,
    this.uses,
  });

  factory OwnedArtifact.fromJson(Map<String, dynamic> json) {
    return OwnedArtifact(
      uniqueId: json['uniqueId'] as String,
      templateId: json['templateId'] as String,
      currentLevel: json['currentLevel'] as int,
      uses: json['uses'] as int?,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'uniqueId': uniqueId,
      'templateId': templateId,
      'currentLevel': currentLevel,
      'uses': uses,
    };
  }
}

class CurrentGame {
  EnemyTemplate? enemy;
  double playerCurrentHp;
  List<String> log;
  String? currentPlaceKey;

  CurrentGame({
    this.enemy,
    required this.playerCurrentHp,
    List<String>? log,
    this.currentPlaceKey,
  }) : log = log ?? [];

  factory CurrentGame.fromJson(
      Map<String, dynamic> json, List<EnemyTemplate> allEnemyTemplates) {
    EnemyTemplate? currentEnemy;
    if (json['enemy'] != null) {
      final enemyData = json['enemy'] as Map<String, dynamic>;
      currentEnemy =
          allEnemyTemplates.firstWhereOrNull((t) => t.id == enemyData['id']) ??
              EnemyTemplate.fromJson(enemyData);
    }
    return CurrentGame(
      enemy: currentEnemy,
      playerCurrentHp: (json['playerCurrentHp'] as num).toDouble(),
      log: (json['log'] as List<dynamic>?)
              ?.map((entry) => entry as String)
              .toList() ??
          [],
      currentPlaceKey: json['currentPlaceKey'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enemy': enemy?.toJson(),
      'playerCurrentHp': playerCurrentHp,
      'log': log,
      'currentPlaceKey': currentPlaceKey,
    };
  }
}

class GameSettings {
  bool descriptionsVisible;
  bool autoGenerateContent;

  GameSettings(
      {this.descriptionsVisible = true, this.autoGenerateContent = true});

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      descriptionsVisible: json['descriptionsVisible'] as bool? ?? true,
      autoGenerateContent: json['autoGenerateContent'] as bool? ?? true,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'descriptionsVisible': descriptionsVisible,
      'autoGenerateContent': autoGenerateContent,
    };
  }
}

class ActiveTimerInfo {
  DateTime startTime;
  double accumulatedDisplayTime; // In seconds
  bool isRunning;
  String type;
  String mainTaskId;

  ActiveTimerInfo({
    required this.startTime,
    this.accumulatedDisplayTime = 0,
    required this.isRunning,
    required this.type,
    required this.mainTaskId,
  });

  factory ActiveTimerInfo.fromJson(Map<String, dynamic> json) {
    return ActiveTimerInfo(
      startTime: DateTime.parse(json['startTime'] as String),
      accumulatedDisplayTime:
          (json['accumulatedDisplayTime'] as num? ?? 0).toDouble(),
      isRunning: json['isRunning'] as bool? ?? false,
      type: json['type'] as String? ?? 'subtask',
      mainTaskId: json['mainTaskId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'accumulatedDisplayTime': accumulatedDisplayTime,
      'isRunning': isRunning,
      'type': type,
      'mainTaskId': mainTaskId,
    };
  }
}

class PlayerStat {
  final String name;
  final String description;
  final String icon; // Can be an emoji or an MDI icon name (e.g., "mdi-sword")
  double value;
  double base;

  PlayerStat({
    required this.name,
    required this.description,
    required this.icon,
    required this.value,
    required this.base,
  });

  factory PlayerStat.fromJson(Map<String, dynamic> json) {
    double parseNumToDouble(dynamic val, double defaultValue) {
      if (val == null) return defaultValue;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? defaultValue;
      return defaultValue;
    }

    String parseString(dynamic val, String defaultValue) {
      if (val == null) return defaultValue;
      if (val is String) return val;
      return val.toString();
    }

    return PlayerStat(
      name: parseString(json['name'], 'Unknown Stat'),
      description: parseString(json['description'], 'No description.'),
      icon: parseString(
          json['icon'],
          MdiIcons.helpCircleOutline.codePoint
              .toString()), // Use MDI icon as string default
      value: parseNumToDouble(json['value'], 0.0),
      base: parseNumToDouble(json['base'], 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'icon': icon,
      'value': value,
      'base': base,
    };
  }
}

class ArtifactTemplate {
  final String id;
  final String name;
  final String type;
  final String? theme;
  final String description;
  final int cost;
  final String icon; // Can be an emoji or an MDI icon name
  final int? baseAtt;
  final int? baseRunic;
  final int? baseDef;
  final int? baseHealth;
  final int? baseLuck;
  final int? baseCooldown;
  final double? bonusXPMod;
  final Map<String, int>? upgradeBonus;
  final int? maxLevel;
  final String? effectType;
  final int? effectValue;
  final int? uses;

  ArtifactTemplate({
    required this.id,
    required this.name,
    required this.type,
    this.theme,
    required this.description,
    required this.cost,
    required this.icon,
    this.baseAtt,
    this.baseRunic,
    this.baseDef,
    this.baseHealth,
    this.baseLuck,
    this.baseCooldown,
    this.bonusXPMod,
    this.upgradeBonus,
    this.maxLevel,
    this.effectType,
    this.effectValue,
    this.uses,
  });

  factory ArtifactTemplate.fromJson(Map<String, dynamic> json) {
    Map<String, int>? parsedUpgradeBonus;
    if (json['upgradeBonus'] != null && json['upgradeBonus'] is Map) {
      parsedUpgradeBonus = {};
      try {
        (json['upgradeBonus'] as Map<String, dynamic>).forEach((key, value) {
          if (value is num) {
            parsedUpgradeBonus![key] = value.toInt();
          } else if (value is String)
            parsedUpgradeBonus![key] = int.tryParse(value) ?? 0;
        });
      } catch (e) {/* ... */}
    }
    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is double) return val;
      if (val is int) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
    }

    return ArtifactTemplate(
      id: json['id'] as String? ??
          'unknown_id_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Artifact',
      type: json['type'] as String? ?? 'unknown',
      theme: json['theme'] as String?,
      description: json['description'] as String? ?? 'No description.',
      cost: parseInt(json['cost']) ?? 0,
      icon: json['icon'] as String? ??
          MdiIcons.treasureChest.codePoint
              .toString(), // Default to MDI icon string
      baseAtt: parseInt(json['baseAtt']),
      baseRunic: parseInt(json['baseRunic']),
      baseDef: parseInt(json['baseDef']),
      baseHealth: parseInt(json['baseHealth']),
      baseLuck: parseInt(json['baseLuck']),
      baseCooldown: parseInt(json['baseCooldown']),
      bonusXPMod: parseDouble(json['bonusXPMod']),
      upgradeBonus: parsedUpgradeBonus,
      maxLevel: parseInt(json['maxLevel']),
      effectType: json['effectType'] as String?,
      effectValue: parseInt(json['effectValue']),
      uses: parseInt(json['uses']),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'theme': theme,
      'description': description,
      'cost': cost,
      'icon': icon,
      'baseAtt': baseAtt,
      'baseRunic': baseRunic,
      'baseDef': baseDef,
      'baseHealth': baseHealth,
      'baseLuck': baseLuck,
      'baseCooldown': baseCooldown,
      'bonusXPMod': bonusXPMod,
      'upgradeBonus': upgradeBonus,
      'maxLevel': maxLevel,
      'effectType': effectType,
      'effectValue': effectValue,
      'uses': uses,
    };
  }
}

class EnemyTemplate {
  final String id;
  final String name;
  final String? theme;
  final String? locationKey;
  final int minPlayerLevel;
  final int health;
  final int attack;
  final int defense;
  int hp;
  final int coinReward;
  final int xpReward;
  final String description;

  EnemyTemplate({
    required this.id,
    required this.name,
    this.theme,
    this.locationKey,
    required this.minPlayerLevel,
    required this.health,
    required this.attack,
    required this.defense,
    int? hp,
    required this.coinReward,
    required this.xpReward,
    required this.description,
  }) : hp = hp ?? health;

  factory EnemyTemplate.fromJson(Map<String, dynamic> json) {
    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is double) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    final maxHealth = parseInt(json['health']) ?? 10;
    return EnemyTemplate(
      id: json['id'] as String? ??
          'unknown_enemy_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Nameless Foe',
      theme: json['theme'] as String?,
      locationKey: json['locationKey'] as String?,
      minPlayerLevel: parseInt(json['minPlayerLevel']) ?? 1,
      health: maxHealth,
      hp: parseInt(json['hp']) ?? maxHealth,
      attack: parseInt(json['attack']) ?? 1,
      defense: parseInt(json['defense']) ?? 0,
      coinReward: parseInt(json['coinReward']) ?? 0,
      xpReward: parseInt(json['xpReward']) ?? 0,
      description: json['description'] as String? ?? 'A mysterious enemy.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'theme': theme,
      'locationKey': locationKey,
      'minPlayerLevel': minPlayerLevel,
      'health': health,
      'hp': hp,
      'attack': attack,
      'defense': defense,
      'coinReward': coinReward,
      'xpReward': xpReward,
      'description': description,
    };
  }
}

class Rune {
  String id;
  String name;
  String description;
  String icon;
  String type;
  String effectType;
  double effectValue;
  double? effectDuration;
  String? targetStat;
  int cost;
  int? requiredLevel;

  Rune({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.effectType,
    required this.effectValue,
    this.effectDuration,
    this.targetStat,
    required this.cost,
    this.requiredLevel,
  });

  factory Rune.fromJson(Map<String, dynamic> json) {
    return Rune(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: json['type'] as String,
      effectType: json['effectType'] as String,
      effectValue: (json['effectValue'] as num).toDouble(),
      effectDuration: (json['effectDuration'] as num?)?.toDouble(),
      targetStat: json['targetStat'] as String?,
      cost: json['cost'] as int,
      requiredLevel: json['requiredLevel'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'type': type,
      'effectType': effectType,
      'effectValue': effectValue,
      'effectDuration': effectDuration,
      'targetStat': targetStat,
      'cost': cost,
      'requiredLevel': requiredLevel,
    };
  }
}

class OwnedRune {
  String uniqueId;
  String runeId;
  bool isActive;

  OwnedRune({
    required this.uniqueId,
    required this.runeId,
    this.isActive = false,
  });

  factory OwnedRune.fromJson(Map<String, dynamic> json) {
    return OwnedRune(
      uniqueId: json['uniqueId'] as String,
      runeId: json['runeId'] as String,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uniqueId': uniqueId,
      'runeId': runeId,
      'isActive': isActive,
    };
  }
}

// Moved from constants.dart
class MainTaskTemplate {
  final String id;
  final String name;
  final String description;
  final String theme;
  final String colorHex;

  MainTaskTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    this.colorHex = "FF00F8F8", // Default Cyan
  });
}

// Moved from constants.dart
class GameLocation {
  final String id; // Changed key to id for consistency
  final String name;
  final String description;
  final int minPlayerLevelToUnlock;
  final String iconEmoji; // Using specific field for emoji
  final String? associatedTheme;
  final String?
      bossEnemyIdToUnlockNextLocation; // ID of an enemy in this location
  bool isCleared; // Added field for tracking if location is cleared

  GameLocation({
    required this.id,
    required this.name,
    required this.description,
    this.minPlayerLevelToUnlock = 1,
    required this.iconEmoji,
    this.associatedTheme,
    this.bossEnemyIdToUnlockNextLocation,
    this.isCleared = false, // Default to not cleared
  });

  factory GameLocation.fromJson(Map<String, dynamic> json) {
    return GameLocation(
      id: json['id'] as String? ??
          'loc_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Unknown Area',
      description: json['description'] as String? ?? 'A mysterious place.',
      minPlayerLevelToUnlock: json['minPlayerLevelToUnlock'] as int? ?? 1,
      iconEmoji: json['iconEmoji'] as String? ?? '❓',
      associatedTheme: json['associatedTheme'] as String?,
      bossEnemyIdToUnlockNextLocation:
          json['bossEnemyIdToUnlockNextLocation'] as String?,
      isCleared: json['isCleared'] as bool? ?? false, // Load isCleared status
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'minPlayerLevelToUnlock': minPlayerLevelToUnlock,
      'iconEmoji': iconEmoji,
      'associatedTheme': associatedTheme,
      'bossEnemyIdToUnlockNextLocation': bossEnemyIdToUnlockNextLocation,
      'isCleared': isCleared, // Save isCleared status
    };
  }
}
