import 'package:flutter/foundation.dart';
import 'package:myapp_flutter/src/services/firebase_service.dart' as fb_service;
import 'package:myapp_flutter/src/services/storage_service.dart';
// import 'package:myapp_flutter/src/services/ai_service.dart'; // AIService instance is in AIGenerationActions
import 'package:myapp_flutter/src/utils/constants.dart';
import 'package:myapp_flutter/src/utils/helpers.dart' as helper;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:collection/collection.dart';
import 'dart:async'; // For Timer

// Import models
import 'package:myapp_flutter/src/models/game_models.dart';

// Import action modules
import 'actions/task_actions.dart';
import 'actions/item_actions.dart';
import 'actions/combat_actions.dart';
import 'actions/ai_generation_actions.dart';
import 'actions/timer_actions.dart';


class GameProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  Timer? _periodicUiTimer;
  Timer? _autoSaveTimer;

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool _authLoading = true;
  bool get authLoading => _authLoading;
  bool _isDataLoadingAfterLogin = false;
  bool get isDataLoadingAfterLogin => _isDataLoadingAfterLogin;

  String? _lastLoginDate;
  double _coins = 100;
  double _xp = 0;
  int _playerLevel = 1;
  double _playerEnergy = baseMaxPlayerEnergy;
  List<MainTask> _mainTasks = initialMainTaskTemplates.map((t) => MainTask.fromTemplate(t)).toList();
  Map<String, dynamic> _completedByDay = {};
  List<OwnedArtifact> _artifacts = [];
  List<ArtifactTemplate> _artifactTemplatesList = [];
  List<EnemyTemplate> _enemyTemplatesList = [];

  Map<String, PlayerStat> _playerGameStats = {
    ...Map.from(basePlayerGameStats.map((key, value) => MapEntry(key, PlayerStat(name: value.name, description: value.description, icon: value.icon, value: value.value, base: value.base)))),
    'bonusXPMod': PlayerStat(name: 'XP BONUS', value: 0, base: 0, description: 'Increases XP gained from all sources.', icon: '📈'),
  };

  Map<String, String?> _equippedItems = {'weapon': null, 'armor': null, 'talisman': null};
  List<String> _defeatedEnemyIds = [];
  CurrentGame _currentGame = CurrentGame(playerCurrentHp: basePlayerGameStats['vitality']!.value);
  GameSettings _settings = GameSettings();
  String _currentView = 'task-details';
  String? _selectedTaskId = initialMainTaskTemplates.isNotEmpty ? initialMainTaskTemplates[0].id : null;
  int _apiKeyIndex = 0;
  Map<String, ActiveTimerInfo> _activeTimers = {};

  bool _hasUnsavedChanges = false;
  bool _isManuallySaving = false;
  bool get isManuallySaving => _isManuallySaving;
  bool _isManuallyLoading = false;
  bool get isManuallyLoading => _isManuallyLoading;
  DateTime? _lastSuccessfulSaveTimestamp;
  DateTime? get lastSuccessfulSaveTimestamp => _lastSuccessfulSaveTimestamp;


  bool _isGeneratingGlobalContent = false;
  bool get isGeneratingContent => _isGeneratingGlobalContent;
  bool _isGeneratingSubquestsForTask = false;
  bool get isGeneratingSubquests => _isGeneratingSubquestsForTask;

  String? get lastLoginDate => _lastLoginDate;
  double get coins => _coins;
  double get xp => _xp;
  int get playerLevel => _playerLevel;
  double get playerEnergy => _playerEnergy;
  List<MainTask> get mainTasks => _mainTasks;
  Map<String, dynamic> get completedByDay => _completedByDay;
  List<OwnedArtifact> get artifacts => _artifacts;
  List<ArtifactTemplate> get artifactTemplatesList => _artifactTemplatesList;
  List<EnemyTemplate> get enemyTemplatesList => _enemyTemplatesList;
  Map<String, PlayerStat> get playerGameStats => _playerGameStats;
  Map<String, String?> get equippedItems => _equippedItems;
  List<String> get defeatedEnemyIds => _defeatedEnemyIds;
  CurrentGame get currentGame => _currentGame;
  GameSettings get settings => _settings;
  String get currentView => _currentView;
  String? get selectedTaskId => _selectedTaskId;
  int get apiKeyIndex => _apiKeyIndex;
  Map<String, ActiveTimerInfo> get activeTimers => _activeTimers;

  double get calculatedMaxEnergy => baseMaxPlayerEnergy + (_playerLevel - 1) * playerEnergyPerLevelVitality;
  double get xpNeededForNextLevel => helper.xpToNext(_playerLevel, xpPerLevelBase, xpLevelMultiplier);
  double get currentLevelXPStart => helper.xpForLevel(_playerLevel, xpPerLevelBase, xpLevelMultiplier);
  double get currentLevelXPProgress => _xp - currentLevelXPStart;
  double get xpProgressPercent => xpNeededForNextLevel > 0 ? (currentLevelXPProgress / xpNeededForNextLevel) * 100 : 0;


  late final TaskActions _taskActions;
  late final ItemActions _itemActions;
  late final CombatActions _combatActions;
  late final AIGenerationActions _aiGenerationActions;
  late final TimerActions _timerActions;

  GameProvider() {
    _initialize();
    _taskActions = TaskActions(this);
    _itemActions = ItemActions(this);
    _combatActions = CombatActions(this);
    _aiGenerationActions = AIGenerationActions(this);
    _timerActions = TimerActions(this);

    _periodicUiTimer?.cancel();
    _periodicUiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeTimers.values.any((info) => info.isRunning)) {
        notifyListeners(); // For UI timer updates
      }
    });
  }

  @override
  void dispose() {
    _periodicUiTimer?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _initialize() {
    fb_service.authStateChanges.listen(_onAuthStateChanged);
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_hasUnsavedChanges && _currentUser != null) {
        // print("[GameProvider] Auto-saving changes to cloud..."); // DEBUG
        _performActualSave();
      }
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _authLoading = true;
    notifyListeners();

    if (user != null) {
      _currentUser = user;
      _isDataLoadingAfterLogin = true;
      notifyListeners();

      final data = await _storageService.getUserData(user.uid);
      if (data != null) {
        _loadStateFromMap(data);
        _hasUnsavedChanges = false; // Data just loaded matches cloud
      } else {
        _resetToInitialState(); // This sets _hasUnsavedChanges = true
        await _performActualSave(); // Save this initial state immediately
      }
       _handleDailyReset(); // This might set _hasUnsavedChanges = true
      if (settings.autoGenerateContent && (_enemyTemplatesList.isEmpty || _artifactTemplatesList.isEmpty)) {
          await generateGameContent(_playerLevel, isManual: false, isInitial: true); // This will set _hasUnsavedChanges
      }
      _isDataLoadingAfterLogin = false;
    } else {
      _currentUser = null;
      _resetToInitialState();
      _isDataLoadingAfterLogin = false;
      _hasUnsavedChanges = false; // No user, no unsaved changes relevant to cloud
    }

    _authLoading = false;
    notifyListeners();
  }

  Map<String, dynamic> _gameStateToMap() {
    return {
      'lastLoginDate': _lastLoginDate,
      'coins': _coins,
      'xp': _xp,
      'playerLevel': _playerLevel,
      'playerEnergy': _playerEnergy,
      'mainTasks': _mainTasks.map((mt) => mt.toJson()).toList(),
      'completedByDay': _completedByDay,
      'artifacts': _artifacts.map((a) => a.toJson()).toList(),
      'artifactTemplatesList': _artifactTemplatesList.map((at) => at.toJson()).toList(),
      'enemyTemplatesList': _enemyTemplatesList.map((et) => et.toJson()).toList(),
      'playerGameStats': _playerGameStats.map((key, stat) => MapEntry(key, stat.toJson())),
      'equippedItems': _equippedItems,
      'defeatedEnemyIds': _defeatedEnemyIds,
      'currentGame': _currentGame.toJson(),
      'settings': settings.toJson(),
      'currentView': _currentView,
      'selectedTaskId': _selectedTaskId,
      'apiKeyIndex': _apiKeyIndex,
      'activeTimers': _activeTimers.map((key, value) => MapEntry(key, value.toJson())),
      'lastSuccessfulSaveTimestamp': _lastSuccessfulSaveTimestamp?.toIso8601String(),
    };
  }

  void _loadStateFromMap(Map<String, dynamic> data) {
    _lastLoginDate = data['lastLoginDate'] as String?;
    _coins = (data['coins'] as num? ?? 100).toDouble();
    _xp = (data['xp'] as num? ?? 0).toDouble();
    _playerLevel = data['playerLevel'] as int? ?? 1;
    _playerEnergy = (data['playerEnergy'] as num? ?? baseMaxPlayerEnergy).toDouble();

    _mainTasks = (data['mainTasks'] as List<dynamic>?)
        ?.map((mtJson) => MainTask.fromJson(mtJson as Map<String, dynamic>))
        .toList() ?? initialMainTaskTemplates.map((t) => MainTask.fromTemplate(t)).toList();

    _completedByDay = data['completedByDay'] as Map<String, dynamic>? ?? {};
    _completedByDay.forEach((date, dayDataMap) {
        if (dayDataMap is Map<String, dynamic>) {
            dayDataMap.putIfAbsent('taskTimes', () => <String, int>{});
            dayDataMap.putIfAbsent('subtasksCompleted', () => <Map<String, dynamic>>[]);
            dayDataMap.putIfAbsent('checkpointsCompleted', () => <Map<String, dynamic>>[]);
        }
    });

    _artifacts = (data['artifacts'] as List<dynamic>?)
        ?.map((aJson) => OwnedArtifact.fromJson(aJson as Map<String, dynamic>))
        .toList() ?? [];

    _artifactTemplatesList = (data['artifactTemplatesList'] as List<dynamic>?)
        ?.map((atJson) => ArtifactTemplate.fromJson(atJson as Map<String, dynamic>))
        .toList() ?? [];

    _enemyTemplatesList = (data['enemyTemplatesList'] as List<dynamic>?)
        ?.map((etJson) => EnemyTemplate.fromJson(etJson as Map<String, dynamic>))
        .toList() ?? [];

    final statsData = data['playerGameStats'] as Map<String, dynamic>?;
    _playerGameStats = {
      ...Map.from(basePlayerGameStats.map((key, value) => MapEntry(key, PlayerStat(name: value.name, description: value.description, icon: value.icon, value: value.value, base: value.base)))),
      'bonusXPMod': PlayerStat(name: 'XP BONUS', value: 0, base: 0, description: 'Increases XP gained from all sources.', icon: '📈'),
    };
    if (statsData != null) {
        statsData.forEach((String key, dynamic statJsonValue) {
            if (_playerGameStats.containsKey(key)) {
                 if (statJsonValue is Map<String, dynamic>) {
                     _playerGameStats[key] = PlayerStat.fromJson(statJsonValue);
                 }
            }
        });
    }
    if (!_playerGameStats.containsKey('bonusXPMod')) {
        _playerGameStats['bonusXPMod'] = PlayerStat(name: 'XP BONUS', value: 0, base: 0, description: 'Increases XP gained from all sources.', icon: '📈');
    }

    _equippedItems = Map<String, String?>.from(data['equippedItems'] as Map<dynamic, dynamic>? ?? {'weapon': null, 'armor': null, 'talisman': null});
    _defeatedEnemyIds = (data['defeatedEnemyIds'] as List<dynamic>?)?.map((id) => id as String).toList() ?? [];

    _currentGame = data['currentGame'] != null
        ? CurrentGame.fromJson(data['currentGame'] as Map<String, dynamic>, _enemyTemplatesList)
        : CurrentGame(playerCurrentHp: _playerGameStats['vitality']!.value);

    _settings = data['settings'] != null
        ? GameSettings.fromJson(data['settings'] as Map<String, dynamic>)
        : GameSettings();

    _currentView = data['currentView'] as String? ?? 'task-details';
    _selectedTaskId = data['selectedTaskId'] as String? ?? (_mainTasks.isNotEmpty ? _mainTasks[0].id : null);
    _apiKeyIndex = data['apiKeyIndex'] as int? ?? 0;

    _activeTimers = (data['activeTimers'] as Map<String, dynamic>?)
        ?.map((key, value) => MapEntry(key, ActiveTimerInfo.fromJson(value as Map<String, dynamic>))) ?? {};
    
    final timestampString = data['lastSuccessfulSaveTimestamp'] as String?;
    if (timestampString != null) {
        _lastSuccessfulSaveTimestamp = DateTime.tryParse(timestampString);
    } else {
        _lastSuccessfulSaveTimestamp = null;
    }


    _recalculatePlayerLevel();
    _updatePlayerStatsFromItems();
  }

  void _resetToInitialState() {
    _currentUser = null; 
    _lastLoginDate = null;
    _coins = 100;
    _xp = 0;
    _playerLevel = 1;
    _playerEnergy = baseMaxPlayerEnergy;
    _mainTasks = initialMainTaskTemplates.map((t) => MainTask.fromTemplate(t)).toList();
    _completedByDay = {};
    _artifacts = [];
    _artifactTemplatesList = [];
    _enemyTemplatesList = [];
    _playerGameStats = {
      ...Map.from(basePlayerGameStats.map((key, value) => MapEntry(key, PlayerStat(name: value.name, description: value.description, icon: value.icon, value: value.value, base: value.base)))),
      'bonusXPMod': PlayerStat(name: 'XP BONUS', value: 0, base: 0, description: 'Increases XP gained from all sources.', icon: '📈'),
    };
    _equippedItems = {'weapon': null, 'armor': null, 'talisman': null};
    _defeatedEnemyIds = [];
    _currentGame = CurrentGame(playerCurrentHp: _playerGameStats['vitality']!.value);
    _settings = GameSettings();
    _currentView = 'task-details';
    _selectedTaskId = _mainTasks.isNotEmpty ? _mainTasks[0].id : null;
    _apiKeyIndex = 0;
    _activeTimers = {};
    _lastSuccessfulSaveTimestamp = null; // Reset last save time
    _hasUnsavedChanges = true;
  }

  Future<void> _performActualSave() async {
    if (_currentUser != null) {
      await _storageService.updateUserData(_currentUser!.uid, _gameStateToMap());
      _lastSuccessfulSaveTimestamp = DateTime.now();
      _hasUnsavedChanges = false;
      notifyListeners(); // Notify to update UI with new save time
    }
  }

  Future<void> manuallySaveToCloud() async {
    if (_currentUser == null) throw Exception("Not logged in. Cannot save.");
    _isManuallySaving = true;
    notifyListeners();
    try {
      await _performActualSave();
    } finally {
      _isManuallySaving = false;
      notifyListeners();
    }
  }

  Future<void> manuallyLoadFromCloud() async {
    if (_currentUser == null) throw Exception("Not logged in. Cannot load.");
    _isManuallyLoading = true;
    notifyListeners();
    try {
      final data = await _storageService.getUserData(_currentUser!.uid);
      if (data != null) {
        _loadStateFromMap(data); // This sets _lastSuccessfulSaveTimestamp from loaded data
        _handleDailyReset();
        if (settings.autoGenerateContent && (_enemyTemplatesList.isEmpty || _artifactTemplatesList.isEmpty)) {
          await generateGameContent(_playerLevel, isManual: false, isInitial: true);
        }
        _hasUnsavedChanges = false;
      } else {
        throw Exception("No data found on cloud.");
      }
    } finally {
      _isManuallyLoading = false;
      notifyListeners();
    }
  }

  Future<void> loginUser(String email, String password) async {
    await fb_service.signInWithEmail(email, password);
  }

  Future<void> signupUser(String email, String password) async {
    await fb_service.signUpWithEmail(email, password);
  }

  Future<void> logoutUser() async {
    if (_hasUnsavedChanges && _currentUser != null) {
        await _performActualSave();
    }
    try {
      await fb_service.signOut();
    } catch (e) {
      rethrow;
    }
    _resetToInitialState();
    _hasUnsavedChanges = false;
    notifyListeners();
  }

  Future<void> changePasswordHandler(String newPassword) async {
    if (_currentUser != null) {
      await fb_service.changePassword(newPassword);
       _hasUnsavedChanges = true;
    } else {
      throw Exception("No user is currently signed in.");
    }
  }

  void setCurrentView(String view) {
    _currentView = view;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void setSelectedTaskId(String? taskId) {
    _selectedTaskId = taskId;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void setSettings(GameSettings newSettings) {
    _settings = newSettings;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  String romanize(int num) => helper.romanize(num);

  MainTask? getSelectedTask() {
    if (_selectedTaskId == null) {
      return _mainTasks.firstOrNull;
    }
    return _mainTasks.firstWhereOrNull((t) => t.id == _selectedTaskId) ?? _mainTasks.firstOrNull;
  }


  void _recalculatePlayerLevel() {
    int newLevel = 1;
    double xpAtStartOfLvl = 0;
    while (true) {
        final double xpNeeded = helper.xpToNext(newLevel, xpPerLevelBase, xpLevelMultiplier);
        if (_xp >= xpAtStartOfLvl + xpNeeded) {
            xpAtStartOfLvl += xpNeeded;
            newLevel++;
        } else {
            break;
        }
    }
    if (_playerLevel != newLevel) {
        final oldLevel = _playerLevel;
        _playerLevel = newLevel;
        if (_playerLevel > oldLevel) {
             _handleLevelUpEffect();
        } else {
            _hasUnsavedChanges = true;
            notifyListeners();
        }
    }
  }

  void _handleLevelUpEffect() {
    if (_currentUser == null) return;

    const double strengthIncreasePerLevel = 0.5;
    const double defenseIncreasePerLevel = 0.3;
    const double runicIncreasePerLevel = 0.25;

    _playerGameStats['vitality']!.base = basePlayerGameStats['vitality']!.base + ((_playerLevel -1) * playerEnergyPerLevelVitality);
    _playerGameStats['strength']!.base = basePlayerGameStats['strength']!.base + ((_playerLevel -1) * strengthIncreasePerLevel).roundToDouble();
    _playerGameStats['defense']!.base = basePlayerGameStats['defense']!.base + ((_playerLevel-1) * defenseIncreasePerLevel).roundToDouble();
    _playerGameStats['runic']!.base = basePlayerGameStats['runic']!.base + ((_playerLevel-1) * runicIncreasePerLevel).roundToDouble();

    _updatePlayerStatsFromItems();

    _playerEnergy = calculatedMaxEnergy;
    _currentGame.playerCurrentHp = _playerGameStats['vitality']!.value;

    if (settings.autoGenerateContent) {
        generateGameContent(_playerLevel, isManual: false, isInitial: false);
    } else {
        _currentGame.log = [..._currentGame.log, "<span style=\"color:#${AppTheme.fhAccentLightCyan.value.toRadixString(16).substring(2)}\">You feel a surge of power! New opportunities might await (check settings).</span>"];
    }
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void _handleDailyReset() {
    if (_currentUser == null) return;
    final today = helper.getTodayDateString();
    if (_lastLoginDate != today) {
      _mainTasks = _mainTasks.map((task) {
        int newStreak = task.streak;
        if (_lastLoginDate != null) {
          final yesterday = DateTime.now().subtract(const Duration(days: 1));
          final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
          if (task.dailyTimeSpent < dailyTaskGoalMinutes &&
              task.lastWorkedDate != null &&
              task.lastWorkedDate != today &&
              task.lastWorkedDate != yesterdayStr) {
            newStreak = 0;
          }
        }
        return MainTask(
          id: task.id, name: task.name, description: task.description, theme: task.theme,
          streak: newStreak, dailyTimeSpent: 0, lastWorkedDate: task.lastWorkedDate,
          subTasks: task.subTasks,
        );
      }).toList();

      _playerEnergy = calculatedMaxEnergy;
      _defeatedEnemyIds = [];
      _lastLoginDate = today;
      _hasUnsavedChanges = true;
      notifyListeners();
    }
  }

  void _updatePlayerStatsFromItems() {
    final Map<String, PlayerStat> newStats = {
      ...Map.from(basePlayerGameStats.map((key, bs) => MapEntry(key, PlayerStat(name: bs.name, base: bs.base, value: bs.base, description: bs.description, icon: bs.icon)))),
      'bonusXPMod': PlayerStat(name: 'XP BONUS', value: 0, base: 0, description: 'Increases XP gained from all sources.', icon: '📈'),
    };

    const double strengthIncreasePerLevel = 0.5;
    const double defenseIncreasePerLevel = 0.3;
    const double runicIncreasePerLevel = 0.25;

    newStats['vitality']!.base = basePlayerGameStats['vitality']!.base + ((_playerLevel - 1) * playerEnergyPerLevelVitality);
    newStats['strength']!.base = basePlayerGameStats['strength']!.base + ((_playerLevel - 1) * strengthIncreasePerLevel).roundToDouble();
    newStats['defense']!.base = basePlayerGameStats['defense']!.base + ((_playerLevel-1) * defenseIncreasePerLevel).roundToDouble();
    newStats['runic']!.base = basePlayerGameStats['runic']!.base + ((_playerLevel-1) * runicIncreasePerLevel).roundToDouble();

    newStats.forEach((key, stat) {
      stat.value = stat.base;
    });
    
    _equippedItems.forEach((slot, uniqueId) {
      if (uniqueId != null) {
        final owned = _artifacts.firstWhereOrNull((art) => art.uniqueId == uniqueId);
        if (owned != null) {
          final template = _artifactTemplatesList.firstWhereOrNull((t) => t.id == owned.templateId);
          if (template != null && template.type != 'powerup') {
            final effective = _itemActions.getArtifactEffectiveStats(owned);
            newStats['strength']!.value += effective.baseAtt ?? 0;
            newStats['defense']!.value += effective.baseDef ?? 0;
            newStats['vitality']!.value += effective.baseHealth ?? 0;
            newStats['runic']!.value += effective.baseRunic ?? 0;
            newStats['luck']!.value += effective.baseLuck?.toDouble() ?? 0;
            newStats['cooldown']!.value += effective.baseCooldown?.toDouble() ?? 0;
            newStats['bonusXPMod']!.value += effective.bonusXPMod ?? 0.0;
          }
        }
      }
    });
    newStats['luck']!.value = newStats['luck']!.value.clamp(0, double.infinity).toDouble();
    newStats['bonusXPMod']!.value = newStats['bonusXPMod']!.value.clamp(0, double.infinity).toDouble();

    _playerGameStats = newStats;

    if (_currentGame.playerCurrentHp > _playerGameStats['vitality']!.value) {
      _currentGame.playerCurrentHp = _playerGameStats['vitality']!.value;
    } else if (_currentGame.enemy == null && _currentGame.playerCurrentHp < _playerGameStats['vitality']!.value) {
        _currentGame.playerCurrentHp = _playerGameStats['vitality']!.value;
    }
  }


  Future<void> clearAllGameData() async {
    if (_currentUser == null) return;
    await _storageService.deleteUserData(_currentUser!.uid);
    _resetToInitialState();
    await _performActualSave();

    if (settings.autoGenerateContent) {
       await generateGameContent(1, isManual: true, isInitial: true);
    }
    notifyListeners();
  }

  Future<void> resetPlayerLevelAndProgress() async {
    if (_currentUser == null) return;

    _playerLevel = 1;
    _xp = 0;
    
    _playerGameStats = {
        ...Map.from(basePlayerGameStats.map((key, value) => MapEntry(key, PlayerStat(name: value.name, description: value.description, icon: value.icon, value: value.value, base: value.base)))),
        'bonusXPMod': PlayerStat(name: 'XP BONUS', value: 0, base: 0, description: 'Increases XP gained from all sources.', icon: '📈'),
    };
    _updatePlayerStatsFromItems();
    
    _playerEnergy = calculatedMaxEnergy;
    _currentGame.playerCurrentHp = _playerGameStats['vitality']!.value;

    _defeatedEnemyIds = [];

    if (settings.autoGenerateContent) {
        await generateGameContent(1, isManual: false, isInitial: false);
    }

    _currentGame.log = [..._currentGame.log, "<span style=\"color:${AppTheme.fhAccentOrange.value.toRadixString(16).substring(2)}\">Player level and progress have been reset.</span>"];
    _hasUnsavedChanges = true;
    notifyListeners();
  }


  Future<void> clearDiscoverablePowerUps() async {
    if (_currentUser == null) return;
    final List<String> ownedPowerUpTemplateIds = _artifacts
        .where((owned) {
            final template = _artifactTemplatesList.firstWhereOrNull((t) => t.id == owned.templateId);
            return template != null && template.type == 'powerup';
        })
        .map((owned) => owned.templateId)
        .toSet()
        .toList();

    final List<ArtifactTemplate> newArtifactTemplates = _artifactTemplatesList.where((template) {
        return template.type != 'powerup' || ownedPowerUpTemplateIds.contains(template.id);
    }).toList();

    setProviderState(
        artifactTemplatesList: newArtifactTemplates,
        currentGame: CurrentGame(
            enemy: _currentGame.enemy,
            playerCurrentHp: _currentGame.playerCurrentHp,
            log: [..._currentGame.log, "<span style=\"color:${AppTheme.fhAccentOrange.value.toRadixString(16).substring(2)}\">Discoverable power-up schematics purged. Owned items remain.</span>"]
        )
    );
  }

  Future<void> removeAllEnemyTemplates() async {
    if (_currentUser == null) return;
    setProviderState(
        enemyTemplatesList: [],
        currentGame: CurrentGame(
            enemy: _currentGame.enemy,
            playerCurrentHp: _currentGame.playerCurrentHp,
            log: [..._currentGame.log, "<span style=\"color:${AppTheme.fhAccentOrange.value.toRadixString(16).substring(2)}\">All enemy intelligence wiped from the database.</span>"]
        )
    );
  }

  void logToDailySummary(String type, Map<String, dynamic> data) => _taskActions.logToDailySummary(type, data);
  String addSubtask(String mainTaskId, Map<String, dynamic> subtaskData) => _taskActions.addSubtask(mainTaskId, subtaskData);
  void updateSubtask(String mainTaskId, String subtaskId, Map<String, dynamic> updates) => _taskActions.updateSubtask(mainTaskId, subtaskId, updates);
  bool completeSubtask(String mainTaskId, String subtaskId) => _taskActions.completeSubtask(mainTaskId, subtaskId);
  void deleteSubtask(String mainTaskId, String subtaskId) => _taskActions.deleteSubtask(mainTaskId, subtaskId);
  void duplicateCompletedSubtask(String mainTaskId, String subtaskId) => _taskActions.duplicateCompletedSubtask(mainTaskId, subtaskId);
  void addSubSubtask(String mainTaskId, String parentSubtaskId, Map<String, dynamic> subSubtaskData) => _taskActions.addSubSubtask(mainTaskId, parentSubtaskId, subSubtaskData);
  void updateSubSubtask(String mainTaskId, String parentSubtaskId, String subSubtaskId, Map<String, dynamic> updates) => _taskActions.updateSubSubtask(mainTaskId, parentSubtaskId, subSubtaskId, updates);
  void completeSubSubtask(String mainTaskId, String parentSubtaskId, String subSubtaskId) => _taskActions.completeSubSubtask(mainTaskId, parentSubtaskId, subSubtaskId);
  void deleteSubSubtask(String mainTaskId, String parentSubtaskId, String subSubtaskId) => _taskActions.deleteSubSubtask(mainTaskId, parentSubtaskId, subSubtaskId);

  OwnedArtifact? getArtifactByUniqueId(String uniqueId) => _itemActions.getArtifactByUniqueId(uniqueId);
  ArtifactTemplate? getArtifactTemplateById(String templateId) => _itemActions.getArtifactTemplateById(templateId);
  ArtifactTemplate getArtifactEffectiveStats(OwnedArtifact ownedArtifact) => _itemActions.getArtifactEffectiveStats(ownedArtifact);
  void buyArtifact(String templateId) => _itemActions.buyArtifact(templateId);
  bool upgradeArtifact(String uniqueId) => _itemActions.upgradeArtifact(uniqueId);
  bool sellArtifact(String uniqueId) => _itemActions.sellArtifact(uniqueId);
  void equipArtifact(String uniqueId) => _itemActions.equipArtifact(uniqueId);
  void unequipArtifact(String slot) => _itemActions.unequipArtifact(slot);

  void startGame(String enemyId) => _combatActions.startGame(enemyId);
  void handleFight() => _combatActions.handleFight();
  void usePowerUp(String uniqueId) => _combatActions.usePowerUp(uniqueId);
  void forfeitMatch() => _combatActions.forfeitMatch();

  Future<void> generateGameContent(int level, {bool isManual = false, bool isInitial = false}) =>
    _aiGenerationActions.generateGameContent(level, isManual: isManual, isInitial: isInitial);
  Future<void> triggerAISubquestGeneration(MainTask mainTask, String generationMode, String userInput, int numSubquests) =>
    _aiGenerationActions.triggerAISubquestGeneration(mainTask, generationMode, userInput, numSubquests);

  void startTimer(String id, String type, String mainTaskId) => _timerActions.startTimer(id, type, mainTaskId);
  void pauseTimer(String id) => _timerActions.pauseTimer(id);
  void logTimerAndReset(String id) => _timerActions.logTimerAndReset(id);


  void setProviderState({
    String? lastLoginDate,
    double? coins,
    double? xp,
    double? playerEnergy,
    List<MainTask>? mainTasks,
    Map<String, dynamic>? completedByDay,
    List<OwnedArtifact>? artifacts,
    List<ArtifactTemplate>? artifactTemplatesList,
    List<EnemyTemplate>? enemyTemplatesList,
    Map<String, PlayerStat>? playerGameStats,
    Map<String, String?>? equippedItems,
    List<String>? defeatedEnemyIds,
    CurrentGame? currentGame,
    Map<String, ActiveTimerInfo>? activeTimers,
    DateTime? lastSuccessfulSaveTimestamp, // Added for explicit setting if needed
    bool doNotify = true,
    bool doPersist = true,
  }) {
    bool changed = false;
    int oldLevel = _playerLevel;

    if (lastLoginDate != null && _lastLoginDate != lastLoginDate) { _lastLoginDate = lastLoginDate; changed = true; }
    if (coins != null && _coins != coins) { _coins = coins; changed = true; }
    
    if (xp != null && _xp != xp) {
      _xp = xp;
      _recalculatePlayerLevel();
      changed = true;
    }

    if (playerEnergy != null && _playerEnergy != playerEnergy) { _playerEnergy = playerEnergy.clamp(0, calculatedMaxEnergy); changed = true; }
    if (mainTasks != null && !listEquals(_mainTasks, mainTasks)) { _mainTasks = mainTasks; changed = true; }
    if (completedByDay != null && !mapEquals(_completedByDay, completedByDay)) { _completedByDay = completedByDay; changed = true; }

    bool itemsOrEquippedChanged = false;
    if (artifacts != null && !listEquals(_artifacts, artifacts)) {
      _artifacts = artifacts;
      itemsOrEquippedChanged = true;
      changed = true;
    }
    if (artifactTemplatesList != null && !listEquals(_artifactTemplatesList, artifactTemplatesList)) { _artifactTemplatesList = artifactTemplatesList; changed = true; }
    if (enemyTemplatesList != null && !listEquals(_enemyTemplatesList, enemyTemplatesList)) { _enemyTemplatesList = enemyTemplatesList; changed = true; }

    if (playerGameStats != null && !mapEquals(_playerGameStats, playerGameStats)) {
        playerGameStats.forEach((key, newStat) {
            if (_playerGameStats.containsKey(key)) {
                _playerGameStats[key]!.base = newStat.base;
            } else {
                 _playerGameStats[key] = newStat;
            }
        });
        itemsOrEquippedChanged = true;
        changed = true;
    }

    if (equippedItems != null && !mapEquals(_equippedItems, equippedItems)) {
      _equippedItems = equippedItems;
      itemsOrEquippedChanged = true;
      changed = true;
    }

    if (itemsOrEquippedChanged && oldLevel == _playerLevel) {
         _updatePlayerStatsFromItems();
    }

    if (defeatedEnemyIds != null && !listEquals(_defeatedEnemyIds, defeatedEnemyIds)) { _defeatedEnemyIds = defeatedEnemyIds; changed = true; }
    if (currentGame != null && _currentGame != currentGame) {
        _currentGame = currentGame;
        if (_playerGameStats['vitality'] != null && _currentGame.playerCurrentHp > _playerGameStats['vitality']!.value) {
            _currentGame.playerCurrentHp = _playerGameStats['vitality']!.value;
        }
        changed = true;
    }
    if (activeTimers != null && !mapEquals(_activeTimers, activeTimers)) { _activeTimers = activeTimers; changed = true; }
    if (lastSuccessfulSaveTimestamp != null && _lastSuccessfulSaveTimestamp != lastSuccessfulSaveTimestamp) {
      _lastSuccessfulSaveTimestamp = lastSuccessfulSaveTimestamp;
      changed = true; 
    }


    if (changed) {
      if (doPersist) {
        _hasUnsavedChanges = true;
      }
      if (doNotify) {
        notifyListeners();
      }
    }
  }

  void setProviderAIGlobalLoading(bool isLoading) {
    if (_isGeneratingGlobalContent != isLoading) {
      _isGeneratingGlobalContent = isLoading;
      notifyListeners();
    }
  }
   void setProviderAISubquestLoading(bool isLoading) {
    if (_isGeneratingSubquestsForTask != isLoading) {
      _isGeneratingSubquestsForTask = isLoading;
      notifyListeners();
    }
  }
  void setProviderApiKeyIndex(int index) {
    if (_apiKeyIndex != index) {
      _apiKeyIndex = index;
      notifyListeners();
    }
  }

}