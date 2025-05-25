// lib/src/utils/constants.dart
import 'package:myapp_flutter/src/models/game_models.dart'; // For PlayerStat, MainTaskTemplate

// Initial Main Task Templates (Moved from game_models.dart)
List<MainTaskTemplate> initialMainTaskTemplates = [
  MainTaskTemplate(
      id: "proj_ui_ai",
      name: "Summer Project",
      description: "Develop UI, integrate AI, and gamify applications.",
      theme: "tech",
      colorHex: "FF00F8F8"), // Cyan
  MainTaskTemplate(
      id: "research_pinn",
      name: "Research on PINNs",
      description: "Deep dive into Physics Informed Neural Networks.",
      theme: "knowledge",
      colorHex: "FF8A2BE2"), // Purple
  MainTaskTemplate(
      id: "study_next_sem",
      name: "Internship and Sem Prep",
      description: "Prepare materials for upcoming academic semester.",
      theme: "learning",
      colorHex: "FFFF7043"), // Orange
  MainTaskTemplate(
      id: "learn_kungfu",
      name: "Lifestyle: Kung Fu",
      description: "Practice Kung Fu forms and techniques.",
      theme: "discipline",
      colorHex: "FFFD4556"), // Red
  MainTaskTemplate(
      id: "build_routine",
      name: "Routine & Reflection",
      description: "Establish routines, track progress, reflect.",
      theme: "order",
      colorHex: "FF4CAF50") // Green
];


Map<String, PlayerStat> basePlayerGameStats = {
  'strength': PlayerStat(name: 'STRENGTH', value: 10, base: 10, description: 'Increases physical damage dealt.', icon: 'mdi-sword'), // MDI Icon
  'runic': PlayerStat(name: 'RUNIC', value: 5, base: 5, description: 'Increases elemental and special attack damage.', icon: 'mdi-fire'), // MDI Icon
  'defense': PlayerStat(name: 'DEFENSE', value: 5, base: 5, description: 'Reduces all damage taken.', icon: 'mdi-shield'), // MDI Icon
  'vitality': PlayerStat(name: 'VITALITY', value: 100, base: 100, description: 'Increases maximum Health.', icon: 'mdi-heart'), // MDI Icon
  'luck': PlayerStat(name: 'LUCK', value: 1, base: 1, description: 'Increases Perk activation, XP, and Coin gains.', icon: 'mdi-clover'), // MDI Icon
  'cooldown': PlayerStat(name: 'COOLDOWN', value: 0, base: 0, description: 'Reduces recharge time of special abilities.', icon: 'mdi-clock-fast'), // MDI Icon
  // bonusXPMod is handled dynamically in GameProvider, not a base displayed stat.
};


// Game constants
// ignore_for_file: constant_identifier_names
const double xpPerLevelBase = 120; 
const double xpLevelMultiplier = 1.18; 
const double baseMaxPlayerEnergy = 100;
const double playerEnergyPerLevelVitality = 5;
const double energyPerAttack = 10;
const double energyRegenPerMinuteTasked = 2;

const double subtaskCompletionXpBase = 5;
const double subtaskCompletionCoinBase = 2;

const double xpPerMinuteSubtask = 0.2;
const double coinsPerMinuteSubtask = 0.05;
const double xpPerCountUnitSubtask = 0.5;
const double coinsPerCountUnitSubtask = 0.1;

const double subSubtaskCompletionXpBase = 1;
const double subSubtaskCompletionCoinBase = 0.5;

const double xpPerCountUnitSubSubtask = 0.1;
const double coinsPerCountUnitSubSubtask = 0.02;

const double blacksmithUpgradeCostMultiplier = 1.5;
const int dailyTaskGoalMinutes = 15;
const double streakBonusCoins = 10;
const double streakBonusXp = 20;
const double artifactSellPercentage = 0.3;

// Initial Game Locations (Moved from game_models.dart and made part of constants for pre-build)
// AI can add to this list via GameProvider.
List<GameLocation> initialGameLocations = [
  GameLocation(id: "loc_dark_forest", name: "Dark Forest", description: "A menacing forest teeming with shadowy beasts.", minPlayerLevelToUnlock: 1, iconEmoji: "🌲", associatedTheme: "nature", bossEnemyIdToUnlockNextLocation: "enemy_forest_guardian"),
  GameLocation(id: "loc_ruined_temple", name: "Ruined Temple", description: "Ancient ruins guarded by forgotten constructs.", minPlayerLevelToUnlock: 3, iconEmoji: "🏛️", associatedTheme: "ancient", bossEnemyIdToUnlockNextLocation: "enemy_temple_golem"),
  // AI can generate more, or they can be added here.
];

// Initial Enemy Templates
List<EnemyTemplate> initialEnemyTemplates = [
  EnemyTemplate(id: "enemy_goblin_scout", name: "Goblin Scout", theme: "nature", locationKey: "loc_dark_forest", minPlayerLevel: 1, health: 40, attack: 6, defense: 2, coinReward: 10, xpReward: 15, description: "A nimble but weak forest scout."),
  EnemyTemplate(id: "enemy_forest_spider", name: "Giant Forest Spider", theme: "nature", locationKey: "loc_dark_forest", minPlayerLevel: 1, health: 60, attack: 8, defense: 3, coinReward: 15, xpReward: 25, description: "A large, venomous arachnid."),
  EnemyTemplate(id: "enemy_forest_guardian", name: "Forest Guardian (Boss)", theme: "nature", locationKey: "loc_dark_forest", minPlayerLevel: 2, health: 150, attack: 12, defense: 5, coinReward: 50, xpReward: 70, description: "An ancient protector of the woods."),
  EnemyTemplate(id: "enemy_stone_servant", name: "Stone Servant", theme: "ancient", locationKey: "loc_ruined_temple", minPlayerLevel: 3, health: 80, attack: 10, defense: 8, coinReward: 25, xpReward: 40, description: "A magically animated stone guard."),
  EnemyTemplate(id: "enemy_temple_golem", name: "Temple Golem (Boss)", theme: "ancient", locationKey: "loc_ruined_temple", minPlayerLevel: 4, health: 200, attack: 15, defense: 10, coinReward: 80, xpReward: 100, description: "The formidable guardian of the temple's heart."),
];

// Initial Artifact Templates
List<ArtifactTemplate> initialArtifactTemplates = [
  // Weapons
  ArtifactTemplate(id: "art_rusty_sword", name: "Rusty Sword", type: "weapon", theme: null, description: "A basic, somewhat worn sword.", cost: 20, icon: "mdi-sword", baseAtt: 2, maxLevel: 3, upgradeBonus: {"att": 1}),
  ArtifactTemplate(id: "art_hunter_bow", name: "Hunter's Bow", type: "weapon", theme: "nature", description: "A simple bow, good for hunting.", cost: 50, icon: "mdi-bow-arrow", baseAtt: 3, baseLuck: 1, maxLevel: 5, upgradeBonus: {"att": 1, "luck": 1}),
  // Armor
  ArtifactTemplate(id: "art_leather_jerkin", name: "Leather Jerkin", type: "armor", theme: null, description: "Basic leather protection.", cost: 30, icon: "mdi-tshirt-crew-outline", baseDef: 1, baseHealth: 5, maxLevel: 3, upgradeBonus: {"def": 1, "health": 5}),
  ArtifactTemplate(id: "art_iron_greaves", name: "Iron Greaves", type: "armor", theme: "tech", description: "Sturdy leg protection.", cost: 60, icon: "mdi-shoe-sneaker", baseDef: 2, baseHealth: 10, maxLevel: 5, upgradeBonus: {"def": 1, "health": 8}), // Changed icon to mdi-shoe-sneaker
  // Talismans
  ArtifactTemplate(id: "art_lucky_clover", name: "Lucky Clover", type: "talisman", theme: "nature", description: "Might bring good fortune.", cost: 40, icon: "mdi-clover", baseLuck: 2, bonusXPMod: 0.02, maxLevel: 3, upgradeBonus: {"luck": 1, "bonusXPMod": 0}),
  // Powerups
  ArtifactTemplate(id: "art_healing_draught", name: "Healing Draught", type: "powerup", theme: null, description: "Restores a small amount of health.", cost: 25, icon: "mdi-bottle-tonic-plus", effectType: "heal_player", effectValue: 30, uses: 1),
];