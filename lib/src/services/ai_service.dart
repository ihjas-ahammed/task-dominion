import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:arcane/src/config/api_keys.dart'; // Your API keys file
import 'package:flutter/foundation.dart'; // For kDebugMode

class AIService {
  Future<Map<String, dynamic>> _makeAICall({
    required String prompt,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    if (geminiApiKeys.isEmpty ||
        geminiApiKeys.every((key) => key.startsWith('YOUR_GEMINI_API_KEY'))) {
      const errorMsg =
          "No valid Gemini API keys found. Cannot generate content.";
      onLog(
          "<span style=\"color:var(--fh-accent-red);\">Error: AI content generation failed (No API Key or invalid key).</span>");
      throw Exception(errorMsg);
    }
    if (geminiModelName.isEmpty) {
      const errorMsg =
          "GEMINI_MODEL_NAME not configured. Cannot generate content.";
      onLog(
          "<span style=\"color:var(--fh-accent-red);\">Error: AI content generation failed (GEMINI_MODEL_NAME not configured).</span>");
      throw Exception(errorMsg);
    }

    // Log the full prompt in debug mode
    if (kDebugMode) {
      print("[AIService] AI Prompt:\n$prompt");
    }

    for (int i = 0; i < geminiApiKeys.length; i++) {
      final int keyAttemptIndex =
          (currentApiKeyIndex + i) % geminiApiKeys.length;
      final String apiKey = geminiApiKeys[keyAttemptIndex];

      if (apiKey.startsWith('YOUR_GEMINI_API_KEY')) {
        onLog(
            "<span style=\"color:var(--fh-accent-orange);\">Skipping invalid API key at index $keyAttemptIndex.</span>");
        continue;
      }

      try {
        onLog(
            "Trying API key index $keyAttemptIndex for model $geminiModelName...");
        final model =
            genai.GenerativeModel(model: geminiModelName, apiKey: apiKey);
        final response =
            await model.generateContent([genai.Content.text(prompt)]);

        String? rawResponseText = response.text;
        if (rawResponseText == null || rawResponseText.trim().isEmpty) {
          throw Exception("AI response was empty or null.");
        }

        // Log the raw response in debug mode
        if (kDebugMode) {
          print(
              "[AIService] Raw AI Response (Key Index $keyAttemptIndex):\n$rawResponseText");
        }
        onLog("Raw AI Response received. Attempting to parse JSON...");

        // More robust JSON extraction
        String jsonString = rawResponseText.trim();
        int jsonStart = jsonString.indexOf('{');
        int jsonEnd = jsonString.lastIndexOf('}');

        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          jsonString = jsonString.substring(jsonStart, jsonEnd + 1);
        } else {
          onLog(
              "<span style=\"color:var(--fh-accent-red);\">Error: Could not find valid JSON object delimiters {{ ... }} in AI response.</span>");
          if (kDebugMode) {
            print(
                "[AIService] Failed to find JSON delimiters. Raw response was: $rawResponseText");
          }
          throw Exception("Could not extract JSON object from AI response.");
        }

        // Attempt to remove common non-JSON prefixes/suffixes if any (like markdown code blocks)
        // This is a secondary check if the above { } extraction wasn't perfect
        if (jsonString.startsWith("```json") && jsonString.endsWith("```")) {
          jsonString = jsonString.substring(7, jsonString.length - 3).trim();
        } else if (jsonString.startsWith("```") && jsonString.endsWith("```")) {
          jsonString = jsonString.substring(3, jsonString.length - 3).trim();
        }

        final Map<String, dynamic> generatedData = jsonDecode(jsonString);
        onNewApiKeyIndex(keyAttemptIndex);
        onLog(
            "<span style=\"color:var(--fh-accent-green);\">Successfully processed AI response with API key index $keyAttemptIndex.</span>");
        return generatedData;
      } catch (e) {
        String errorDetail = e.toString();
        if (e is FormatException) {
          errorDetail =
              "JSON FormatException: ${e.message}. Check AI response for syntax errors (e.g., trailing commas, unquoted keys, incorrect string escapes).";
          if (kDebugMode) {
            print(
                "[AIService] JSON Parsing Error: ${e.message}. Offending JSON string part (approx): ${e.source.toString().substring(0, (e.offset ?? e.source.toString().length).clamp(0, e.source.toString().length)).substring(0, 100)}");
          }
        } else if (errorDetail.contains("API key not valid")) {
          errorDetail = "API key not valid. Please check your configuration.";
        } else if (errorDetail.contains("quota")) {
          errorDetail = "API quota exceeded for this key.";
        } else if (errorDetail
            .contains("Candidate was blocked due to SAFETY")) {
          errorDetail =
              "AI response blocked due to safety settings. Try a different prompt or adjust safety settings if possible.";
        }
        onLog(
            "<span style=\"color:var(--fh-accent-red);\">Error with API key index $keyAttemptIndex: $errorDetail</span>");
        if (i == geminiApiKeys.length - 1) {
          throw Exception("All API keys failed. Last error: $errorDetail");
        }
      }
    }
    const finalErrorMsg = "All API keys failed or were invalid.";
    onLog("<span style=\"color:var(--fh-accent-red);\">$finalErrorMsg</span>");
    throw Exception(finalErrorMsg);
  }

  Future<Map<String, List<Map<String, dynamic>>>> generateGameContent({
    required int levelForContent,
    required bool isManual,
    required bool isInitial,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required String existingEnemyIdsString,
    required String existingArtifactIdsString,
    required String existingLocationIdsString, // New
    required List<String> themes,
    required Function(String) onLog,
  }) async {
    onLog(
        "Attempting to generate themed game content (enemies/artifacts/locations)...");

    final int numEnemiesToGeneratePerTheme = isInitial ? 3 : 3;
    final int totalEnemiesToGenerate =
        themes.length * numEnemiesToGeneratePerTheme + (isInitial ? 2 : 1);
    final int numLocationsToGenerate = isInitial
        ? 2
        : 1; // Generate a couple of locations initially, then one by one

    String artifactInstructions = "";
    for (String themeName in themes) {
      artifactInstructions += """
  - For the theme "$themeName":
    - One 'weapon' artifact with theme: "$themeName".
    - One 'armor' artifact with theme: "$themeName".
    - One 'talisman' artifact with theme: "$themeName".
    - One 'powerup' artifact with theme: "$themeName".
""";
    }

    final String prompt = """
Generate new game content suitable for a player at level $levelForContent in a fantasy RPG.
The player is currently progressing and needs new challenges, rewards, and places to explore.
Provide the output as a single, valid JSON object with three top-level keys: "newEnemies", "newArtifacts", and "newGameLocations".
Ensure there are NO trailing commas in lists or objects. All strings must be properly escaped (e.g. newlines as \\n, quotes as \\").

IMPORTANT:
- Do NOT generate enemies with IDs from this list: [$existingEnemyIdsString].
- Do NOT generate artifacts with IDs from this list: [$existingArtifactIdsString].
- Do NOT generate locations with IDs from this list: [$existingLocationIdsString].
- All generated IDs and names MUST be new and unique.

"newEnemies" should be an array of $totalEnemiesToGenerate enemy objects.
- For each theme in [${themes.map((t) => "'$t'").join(', ')}], generate $numEnemiesToGeneratePerTheme enemy specifically for that theme and a relevant locationKey (see newGameLocations).
- The remaining enemies can be general (theme: null) or pick from the themes.
Each enemy object must have:
- id: string, unique (e.g., "gen_enemy_lvl${levelForContent}_a2f5")
- name: string (e.g., "Shadow Lurker", "Arcane Golem")
- theme: string or null (one of [${themes.map((t) => "'$t'").join(', ')}, null])
- locationKey: string (MUST match one of the 'id's from "newGameLocations" generated in this response, or an existing one if appropriate for theme)
- minPlayerLevel: number (should be $levelForContent or slightly higher, e.g., up to ${levelForContent + 2})
- health: number (range: ${50 + levelForContent * 12} to ${80 + levelForContent * 18})
- attack: number (range: ${8 + (levelForContent * 1.8).floor()} to ${12 + (levelForContent * 2.2).floor()})
- defense: number (range: ${3 + (levelForContent * 0.6).floor()} to ${5 + (levelForContent * 1.1).floor()})
- coinReward: number (range: ${20 + levelForContent * 5} to ${50 + levelForContent * 10})
- xpReward: number (range: ${30 + levelForContent * 8} to ${70 + levelForContent * 15})
- description: string (max 100 chars)

"newArtifacts" should be an array of artifact objects.
$artifactInstructions
Each artifact object must have:
- id: string, unique (e.g., "gen_art_lvl${levelForContent}_tech_wpn_b3c8")
- name: string
- type: string ['weapon', 'armor', 'talisman', 'powerup']
- theme: string (MUST be the theme it was generated for)
- description: string (max 100 chars)
- cost: number (range: ${50 + levelForContent * 10} to ${300 + levelForContent * 25})
- icon: string (a single, relevant emoji)
- For 'weapon', 'armor', 'talisman':
    - baseAtt: number (0 if not applicable)
    - baseRunic: number (0 if not applicable)
    - baseDef: number (0 if not applicable)
    - baseHealth: number (0 if not applicable)
    - baseLuck: number (0-10, integer percentage)
    - baseCooldown: number (0-15, integer percentage)
    - bonusXPMod: number (0.0 to 0.15, decimal for percentage)
    - upgradeBonus: object (e.g., {"att": 2, "luck": 1}). Modest values.
    - maxLevel: number (3, 5, or 7)
- For 'powerup':
    - effectType: string ['direct_damage', 'heal_player']
    - effectValue: number
    - uses: number (typically 1)
    (omit baseStats, upgradeBonus, maxLevel for powerups or set to 0/null)

"newGameLocations" should be an array of $numLocationsToGenerate game location objects.
Each location object must have:
- id: string, unique (e.g., "loc_dark_forest", "loc_crystal_caves_$levelForContent")
- name: string (e.g., "Whispering Woods", "Sunken Temple of Eldoria")
- description: string (short, evocative description, max 150 chars)
- minPlayerLevelToUnlock: number (Based on current level. First one could be $levelForContent, next one ${levelForContent + 3}, etc. Make a progression.)
- iconEmoji: string (a single emoji representing the location, e.g., "🌲", "🏛️", "💎")
- associatedTheme: string or null (e.g., "knowledge", "tech", or null for general, matching one of [${themes.map((t) => "'$t'").join(', ')}, null])
- bossEnemyIdToUnlockNextLocation: string or null (ID of an enemy generated in "newEnemies" that, when defeated, could unlock another location. Can be null.)

Ensure all IDs are unique. Balance stats. Return ONLY the JSON object.
""";
    try {
      final Map<String, dynamic> rawData = await _makeAICall(
        prompt: prompt,
        currentApiKeyIndex: currentApiKeyIndex,
        onNewApiKeyIndex: onNewApiKeyIndex,
        onLog: onLog,
      );

      final List<Map<String, dynamic>> newEnemies =
          (rawData['newEnemies'] as List?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];
      final List<Map<String, dynamic>> newArtifacts =
          (rawData['newArtifacts'] as List?)
                  ?.map((a) => a as Map<String, dynamic>)
                  .toList() ??
              [];
      final List<Map<String, dynamic>> newGameLocations =
          (rawData['newGameLocations'] as List?)
                  ?.map((loc) => loc as Map<String, dynamic>)
                  .toList() ??
              [];

      onLog(
          "AI content generation successful. Parsed ${newEnemies.length} enemies, ${newArtifacts.length} artifacts, ${newGameLocations.length} locations.");

      return {
        'newEnemies': newEnemies,
        'newArtifacts': newArtifacts,
        'newGameLocations': newGameLocations
      };
    } catch (e) {
      onLog(
          "<span style=\"color:var(--fh-accent-red);\">AI Call failed for generateGameContent: ${e.toString()}</span>");
      if (kDebugMode) {
        print("[AIService] generateGameContent caught error: $e");
      }
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> generateAISubquests({
    required String mainTaskName,
    required String mainTaskDescription,
    String? mainTaskTheme,
    required String generationMode,
    required String userInput,
    required int numSubquests,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    onLog(
        "Attempting to generate sub-quests for \"$mainTaskName\"... Mode: $generationMode");

    String modeSpecificInstructions = "";
    switch (generationMode) {
      case "book_chapter":
        modeSpecificInstructions = """
The user is providing details about a book chapter. Input: "$userInput"
Break this down into approximately $numSubquests actionable sub-quests.
For each sub-quest, suggest 1-3 smaller, concrete steps (sub-subtasks).
If a step involves reading pages, make it "countable" with "targetCount". E.g., "Read pages 10-25" -> name: "Read pages 10-25", isCountable: true, targetCount: 16.
""";
        break;
      case "text_list":
        modeSpecificInstructions = """
The user provided a hierarchical text list. Top-level items are sub-quests. Indented items are sub-subtasks. Input:
$userInput
Convert top-level items to sub-quests, indented items to sub-subtasks.
If an item mentions quantity (e.g., "3 sets", "10 pages"), make it "countable" and set "targetCount".
""";
        break;
      case "general_plan":
      default:
        modeSpecificInstructions = """
The user provided a general plan. Input: "$userInput"
Break this into approximately $numSubquests logical sub-quests.
For each sub-quest, suggest 1-3 smaller, concrete steps (sub-subtasks).
Make items "countable" with "targetCount" if they imply quantity.
""";
        break;
    }

    final String prompt = """
You are an assistant for a gamified task management app.
Main quest: "$mainTaskName" (Description: "$mainTaskDescription", Theme: "${mainTaskTheme ?? 'General'}").
AI generation mode: "$generationMode".

$modeSpecificInstructions

Provide the output as a single, valid JSON object with one key: "newSubquests".
"newSubquests" should be an array of sub-quest objects (approx $numSubquests). Each sub-quest object MUST have:
- name: string (concise name)
- isCountable: boolean
- targetCount: number (if isCountable, otherwise 0 or 1)
- subSubTasksData: array of sub-subtask objects. Each sub-subtask object must have:
  - name: string (concise name)
  - isCountable: boolean
  - targetCount: number (if isCountable, otherwise 0 or 1)

Example JSON:
{
  "newSubquests": [
    {
      "name": "Understand Chapter 1 Concepts",
      "isCountable": false,
      "targetCount": 0,
      "subSubTasksData": [
        { "name": "Read pages 1-10", "isCountable": true, "targetCount": 10 },
        { "name": "Summarize key points", "isCountable": false, "targetCount": 1 }
      ]
    }
  ]
}
Create actionable, distinct sub-quests and steps. Ensure names are clear.
If user input is vague for $numSubquests, generate fewer, meaningful ones.
Return ONLY the JSON object, no markdown or comments. NO TRAILING COMMAS.
""";
    try {
      final Map<String, dynamic> rawData = await _makeAICall(
        prompt: prompt,
        currentApiKeyIndex: currentApiKeyIndex,
        onNewApiKeyIndex: onNewApiKeyIndex,
        onLog: onLog,
      );
      final List<Map<String, dynamic>> newSubquests =
          (rawData['newSubquests'] as List?)
                  ?.map((sq) => sq as Map<String, dynamic>)
                  .toList() ??
              [];

      // Basic validation
      bool isValid = newSubquests.every((sq) =>
          sq['name'] is String &&
          sq['isCountable'] is bool &&
          sq['targetCount'] is num &&
          sq['subSubTasksData'] is List &&
          (sq['subSubTasksData'] as List).every((sss) =>
              sss['name'] is String &&
              sss['isCountable'] is bool &&
              sss['targetCount'] is num));

      if (!isValid) {
        onLog(
            "<span style=\"color:var(--fh-accent-orange);\">AI subquest response malformed.</span>");
        if (kDebugMode) {
          print("[AIService] Malformed subquest data: $newSubquests");
        }
        throw Exception("AI subquest response malformed.");
      }
      onLog(
          "AI subquest generation successful. Parsed ${newSubquests.length} subquests.");
      return newSubquests;
    } catch (e) {
      onLog(
          "<span style=\"color:var(--fh-accent-red);\">AI Call failed for generateAISubquests: ${e.toString()}</span>");
      if (kDebugMode) {
        print("[AIService] generateAISubquests caught error: $e");
      }
      rethrow;
    }
  }
}
