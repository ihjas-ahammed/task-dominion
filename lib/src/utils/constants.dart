// lib/src/utils/constants.dart
import 'package:myapp_flutter/src/models/game_models.dart'; // Moved to top

// DATA_KEY_REACT is not needed in Flutter as Firestore path is per-user.

class MainTaskTemplate {
  final String id;
  final String name;
  final String description;
  final String theme;
  // Flutter specific properties can be added, e.g., IconData

  MainTaskTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.theme,
  });
}

List<MainTaskTemplate> initialMainTaskTemplates = [
  MainTaskTemplate(
      id: "proj_ui_ai",
      name: "Summer Project",
      description: "Develop UI, integrate AI, and gamify applications.",
      theme: "tech"),
  MainTaskTemplate(
      id: "research_pinn",
      name: "Research on PINNs",
      description: "Deep dive into Physics Informed Neural Networks.",
      theme: "knowledge"),
  MainTaskTemplate(
      id: "study_next_sem",
      name: "Internship and Sem Prep",
      description: "Prepare materials for upcoming academic semester.",
      theme: "learning"),
  MainTaskTemplate(
      id: "learn_kungfu",
      name: "Lifestyle: Kung Fu",
      description: "Practice Kung Fu forms and techniques.",
      theme: "discipline"),
  MainTaskTemplate(
      id: "build_routine",
      name: "Routine & Reflection",
      description: "Establish routines, track progress, reflect.",
      theme: "order")
];

// PlayerStat class has been moved to lib/src/models/game_models.dart
// ArtifactTemplate class has been moved to lib/src/models/game_models.dart
// EnemyTemplate class has been moved to lib/src/models/game_models.dart

// Base player game stats are still defined here as they are initial constant values
// The PlayerStat class itself is now imported from game_models.dart
// import 'package:myapp_flutter/src/models/game_models.dart'; // Already at the top

Map<String, PlayerStat> basePlayerGameStats = {
  'strength': PlayerStat(
      name: 'STRENGTH',
      value: 10,
      base: 10,
      description: 'Increases physical damage dealt.',
      icon: '✊'),
  'runic': PlayerStat(
      name: 'RUNIC',
      value: 5,
      base: 5,
      description: 'Increases elemental and special attack damage.',
      icon: '🌀'),
  'defense': PlayerStat(
      name: 'DEFENSE',
      value: 5,
      base: 5,
      description: 'Reduces all damage taken.',
      icon: '🛡️'),
  'vitality': PlayerStat(
      name: 'VITALITY',
      value: 100,
      base: 100,
      description: 'Increases maximum Health.',
      icon: '❤️'),
  'luck': PlayerStat(
      name: 'LUCK',
      value: 1,
      base: 1,
      description: 'Increases Perk activation, XP, and Coin gains.',
      icon: '🎲'),
  'cooldown': PlayerStat(
      name: 'COOLDOWN',
      value: 0,
      base: 0,
      description: 'Reduces recharge time of special abilities.',
      icon: '⏳')
};


// Game constants
// ignore_for_file: constant_identifier_names
const double xpPerLevelBase = 100;
const double xpLevelMultiplier = 1.15;
const double baseMaxPlayerEnergy = 100;
const double playerEnergyPerLevelVitality = 5; // Renamed from playerEnergyPerLevel for clarity, as it primarily affects Vitality/MaxEnergy
const double energyPerAttack = 10;
const double energyRegenPerMinuteTasked = 2; // Energy gained per minute spent on a main task via subtask completion

// Base rewards for subtask completion (these are flat amounts before proportional additions)
const double subtaskCompletionXpBase = 5;
const double subtaskCompletionCoinBase = 2;

// Proportional reward multipliers for subtasks
const double xpPerMinuteSubtask = 0.2;        // e.g., 0.2 XP per minute logged for the subtask
const double coinsPerMinuteSubtask = 0.05;     // e.g., 0.05 Coins per minute logged
const double xpPerCountUnitSubtask = 0.5;     // e.g., 0.5 XP per item counted for the subtask
const double coinsPerCountUnitSubtask = 0.1;  // e.g., 0.1 Coins per item counted

// Base rewards for sub-subtask (checkpoint) completion
const double subSubtaskCompletionXpBase = 1; // Reduced base for smaller steps
const double subSubtaskCompletionCoinBase = 0.5;

// Proportional reward multipliers for sub-subtasks (if countable)
const double xpPerCountUnitSubSubtask = 0.1;   // e.g., 0.1 XP per item counted for the sub-subtask
const double coinsPerCountUnitSubSubtask = 0.02; // e.g., 0.02 Coins per item counted

const double blacksmithUpgradeCostMultiplier = 1.5;
const int dailyTaskGoalMinutes = 15; // Time in minutes to work on a MainTask to get streak bonus
const double streakBonusCoins = 10;
const double streakBonusXp = 20;
const double artifactSellPercentage = 0.3;