// lib/src/models/game_models.dart
import 'package:arcane/src/utils/helpers.dart' as helper;
import 'package:flutter/material.dart';
import 'package:arcane/src/theme/app_theme.dart';

class Project {
  String id;
  String name;
  String description;
  String theme;
  String colorHex;
  int streak;
  int dailyTimeSpent;
  String? lastWorkedDate;
  List<Task> tasks;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    this.colorHex = "FF00BFFF", // Default to fortnite blue
    this.streak = 0,
    this.dailyTimeSpent = 0,
    this.lastWorkedDate,
    List<Task>? tasks,
  }) : tasks = tasks ?? [];

  factory Project.fromTemplate(ProjectTemplate template) {
    return Project(
      id: template.id,
      name: template.name,
      description: template.description,
      theme: template.theme,
      colorHex: template.colorHex,
    );
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      theme: json['theme'] as String,
      colorHex: json['colorHex'] as String? ?? "FF00BFFF",
      streak: json['streak'] as int? ?? 0,
      dailyTimeSpent: json['dailyTimeSpent'] as int? ?? 0,
      lastWorkedDate: json['lastWorkedDate'] as String?,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((tJson) => Task.fromJson(tJson as Map<String, dynamic>))
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
      'tasks': tasks.map((t) => t.toJson()).toList(),
    };
  }

  Color get color {
    try {
      return Color(int.parse("0xFF$colorHex"));
    } catch (e) {
      return AppTheme.fortniteBlue; // Fallback color
    }
  }
}

class Task {
  String id;
  String name;
  bool completed;
  int currentTimeSpent; // Storing as minutes
  String? completedDate;
  bool isCountable;
  int targetCount;
  int currentCount;
  List<Checkpoint> checkpoints;
  Map<String, double> subskillXp;

  Task({
    required this.id,
    required this.name,
    this.completed = false,
    this.currentTimeSpent = 0,
    this.completedDate,
    this.isCountable = false,
    this.targetCount = 0,
    this.currentCount = 0,
    List<Checkpoint>? checkpoints,
    Map<String, double>? subskillXp,
  })  : checkpoints = checkpoints ?? [],
        subskillXp = subskillXp ?? {};

  factory Task.fromJson(Map<String, dynamic> json) {
    final checkpointsData = json['checkpoints'] ?? json['subSubTasks'];
    
    Map<String, double> finalSubskillXp = {};
    if (json['subskillXp'] != null) {
      finalSubskillXp = (json['subskillXp'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {};
    } else if (json['skillXp'] != null) {
      // Legacy data migration
      final legacySkillXp = json['skillXp'] as Map<String, dynamic>;
      legacySkillXp.forEach((skillId, xpValue) {
        final subskillId = '${skillId}_general';
        finalSubskillXp[subskillId] = (xpValue as num).toDouble();
      });
    }

    return Task(
      id: json['id'] as String,
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      currentTimeSpent: json['currentTimeSpent'] as int? ?? 0,
      completedDate: json['completedDate'] as String?,
      isCountable: json['isCountable'] as bool? ?? false,
      targetCount: json['targetCount'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? 0,
      checkpoints: (checkpointsData as List<dynamic>?)
              ?.map((cpJson) =>
                  Checkpoint.fromJson(cpJson as Map<String, dynamic>))
              .toList() ??
          [],
      subskillXp: finalSubskillXp,
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
      'checkpoints': checkpoints.map((cp) => cp.toJson()).toList(),
      'subskillXp': subskillXp,
    };
  }
}

class Checkpoint {
  String id;
  String name;
  bool completed;
  bool isCountable;
  int targetCount;
  int currentCount;
  String? completionTimestamp;
  Map<String, double> subskillXp;

  Checkpoint({
    required this.id,
    required this.name,
    this.completed = false,
    this.isCountable = false,
    this.targetCount = 0,
    this.currentCount = 0,
    this.completionTimestamp,
    Map<String, double>? subskillXp,
  }) : subskillXp = subskillXp ?? {};

  factory Checkpoint.fromJson(Map<String, dynamic> json) {
     Map<String, double> finalSubskillXp = {};
    if (json['subskillXp'] != null) {
      finalSubskillXp = (json['subskillXp'] as Map<String, dynamic>?)
              ?.map((key, value) => MapEntry(key, (value as num).toDouble())) ??
          {};
    } else if (json['skillXp'] != null) {
      // Legacy data migration
      final legacySkillXp = json['skillXp'] as Map<String, dynamic>;
      legacySkillXp.forEach((skillId, xpValue) {
        final subskillId = '${skillId}_general';
        finalSubskillXp[subskillId] = (xpValue as num).toDouble();
      });
    }

    return Checkpoint(
      id: json['id'] as String,
      name: json['name'] as String,
      completed: json['completed'] as bool? ?? false,
      isCountable: json['isCountable'] as bool? ?? false,
      targetCount: json['targetCount'] as int? ?? 0,
      currentCount: json['currentCount'] as int? ?? 0,
      completionTimestamp: json['completionTimestamp'] as String?,
      subskillXp: finalSubskillXp,
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
      'completionTimestamp': completionTimestamp,
      'subskillXp': subskillXp,
    };
  }
}

class GameSettings {
  bool descriptionsVisible;
  int wakeupTimeHour;
  int wakeupTimeMinute;
  bool tutorialShown;

  GameSettings({
    this.descriptionsVisible = true,
    this.wakeupTimeHour = 7,
    this.wakeupTimeMinute = 0,
    this.tutorialShown = false,
  });

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      descriptionsVisible: json['descriptionsVisible'] as bool? ?? true,
      wakeupTimeHour: json['wakeupTimeHour'] as int? ?? 7,
      wakeupTimeMinute: json['wakeupTimeMinute'] as int? ?? 0,
      tutorialShown: json['tutorialShown'] as bool? ?? false,
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'descriptionsVisible': descriptionsVisible,
      'wakeupTimeHour': wakeupTimeHour,
      'wakeupTimeMinute': wakeupTimeMinute,
      'tutorialShown': tutorialShown,
    };
  }
}

class ActiveTimerInfo {
  DateTime startTime;
  double accumulatedDisplayTime; // In seconds
  bool isRunning;
  String type; // 'task'
  String projectId;

  ActiveTimerInfo({
    required this.startTime,
    this.accumulatedDisplayTime = 0,
    required this.isRunning,
    required this.type,
    required this.projectId,
  });

  factory ActiveTimerInfo.fromJson(Map<String, dynamic> json) {
    return ActiveTimerInfo(
      startTime: DateTime.parse(json['startTime'] as String),
      accumulatedDisplayTime:
          (json['accumulatedDisplayTime'] as num? ?? 0).toDouble(),
      isRunning: json['isRunning'] as bool? ?? false,
      type: json['type'] as String? ?? 'task',
      // Legacy support for 'mainTaskId'
      projectId: json['projectId'] as String? ?? json['mainTaskId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'accumulatedDisplayTime': accumulatedDisplayTime,
      'isRunning': isRunning,
      'type': type,
      'projectId': projectId,
    };
  }
}

class ProjectTemplate {
  final String id;
  final String name;
  final String description;
  final String theme;
  final String colorHex;

  ProjectTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
    this.colorHex = "FF00BFFF", // Default Blue
  });
}

class EmotionLog {
  final DateTime timestamp;
  final double rating; // 1-5

  EmotionLog({required this.timestamp, required this.rating});

  factory EmotionLog.fromJson(Map<String, dynamic> json) {
    return EmotionLog(
      timestamp: DateTime.parse(json['timestamp'] as String),
      rating: (json['rating'] as num? ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'rating': rating,
    };
  }
}

// Chatbot models
enum MessageSender { user, bot }

class ChatbotMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatbotMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  factory ChatbotMessage.fromJson(Map<String, dynamic> json) {
    return ChatbotMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: MessageSender.values
          .firstWhere((e) => e.toString() == json['sender'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ChatbotMemory {
  List<ChatbotMessage> conversationHistory;
  List<String> userRememberedItems;

  ChatbotMemory({
    List<ChatbotMessage>? conversationHistory,
    List<String>? userRememberedItems,
  })  : conversationHistory = conversationHistory ?? [],
        userRememberedItems = userRememberedItems ?? [];

  factory ChatbotMemory.fromJson(Map<String, dynamic> json) {
    return ChatbotMemory(
      conversationHistory: (json['conversationHistory'] as List<dynamic>?)
              ?.map((msgJson) =>
                  ChatbotMessage.fromJson(msgJson as Map<String, dynamic>))
              .toList() ??
          [],
      userRememberedItems: (json['userRememberedItems'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationHistory':
          conversationHistory.map((msg) => msg.toJson()).toList(),
      'userRememberedItems': userRememberedItems,
    };
  }
}

class Subskill {
  String id;
  String name;
  double xp;
  String parentSkillId;

  Subskill({
    required this.id,
    required this.name,
    this.xp = 0,
    required this.parentSkillId,
  });

  int get level {
    int newLevel = 1;
    while (xp >= helper.skillXpForLevel(newLevel + 1)) {
      newLevel++;
    }
    return newLevel;
  }

  factory Subskill.fromJson(Map<String, dynamic> json) {
    return Subskill(
      id: json['id'] as String,
      name: json['name'] as String,
      xp: (json['xp'] as num? ?? 0).toDouble(),
      parentSkillId: json['parentSkillId'] as String? ?? '', // Legacy safety
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'xp': xp,
      'parentSkillId': parentSkillId,
    };
  }
}

class Skill {
  String id; // Will match Project theme
  String name;
  String description;
  String iconName;
  List<Subskill> subskills;

  Skill({
    required this.id,
    required this.name,
    this.description = '',
    this.iconName = 'default',
    List<Subskill>? subskills,
  }) : subskills = subskills ?? [];

  double get xp => subskills.fold(0.0, (prev, s) => prev + s.xp);

  int get level {
    int currentLevel = 1;
    while (xp >= helper.skillXpForLevel(currentLevel + 1)) {
      currentLevel++;
    }
    return currentLevel;
  }

  factory Skill.fromJson(Map<String, dynamic> json) {
    List<Subskill> loadedSubskills = (json['subskills'] as List<dynamic>?)
            ?.map((sJson) => Subskill.fromJson(sJson as Map<String, dynamic>))
            .toList() ??
        [];
    
    // Legacy migration: if skill has XP but no subskills, create a 'General' one.
    if (json.containsKey('xp') && (json['xp'] as num) > 0 && loadedSubskills.isEmpty) {
      final subskillId = '${json['id']}_general';
      loadedSubskills.add(Subskill(
        id: subskillId,
        name: 'General',
        parentSkillId: json['id'] as String,
        xp: (json['xp'] as num).toDouble(),
      ));
    }

    return Skill(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      iconName: json['iconName'] as String? ?? 'default',
      subskills: loadedSubskills,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconName': iconName,
      'subskills': subskills.map((s) => s.toJson()).toList(),
    };
  }
}