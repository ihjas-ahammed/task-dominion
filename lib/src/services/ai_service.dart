import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:myapp_flutter/src/config/api_keys.dart'; // Your API keys file

class AIService {
  Future<Map<String, dynamic>> _makeAICall({
    required String prompt,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    if (geminiApiKeys.isEmpty || geminiApiKeys.every((key) => key.startsWith('YOUR_GEMINI_API_KEY'))) {
      const errorMsg = "No valid Gemini API keys found. Cannot generate content.";
      // print(errorMsg);
      onLog("<span style=\"color:var(--fh-accent-red);\">Error: AI content generation failed (No API Key or invalid key).</span>");
      throw Exception(errorMsg);
    }
    if (geminiModelName.isEmpty) {
      const errorMsg = "GEMINI_MODEL_NAME not configured. Cannot generate content.";
      // print(errorMsg);
      onLog("<span style=\"color:var(--fh-accent-red);\">Error: AI content generation failed (GEMINI_MODEL_NAME not configured).</span>");
      throw Exception(errorMsg);
    }

    for (int i = 0; i < geminiApiKeys.length; i++) {
      final int keyAttemptIndex = (currentApiKeyIndex + i) % geminiApiKeys.length;
      final String apiKey = geminiApiKeys[keyAttemptIndex];

      if (apiKey.startsWith('YOUR_GEMINI_API_KEY')) {
        onLog("<span style=\"color:var(--fh-accent-orange);\">Skipping invalid API key at index $keyAttemptIndex.</span>");
        continue;
      }

      try {
        onLog("Trying API key index $keyAttemptIndex...");
        final genAI = GenerativeModel(model: geminiModelName, apiKey: apiKey);
        final response = await genAI.generateContent([Content.text(prompt)]);

        String? jsonString = response.text;
        if (jsonString == null) throw Exception("AI response was empty.");

        if (jsonString.startsWith("```json")) jsonString = jsonString.substring(7);
        if (jsonString.endsWith("```")) jsonString = jsonString.substring(0, jsonString.length - 3);
        jsonString = jsonString.trim();

        final Map<String, dynamic> generatedData = jsonDecode(jsonString);
        onNewApiKeyIndex(keyAttemptIndex);
        onLog("<span style=\"color:var(--fh-accent-green);\">Successfully processed AI response with API key index $keyAttemptIndex.</span>");
        return generatedData;

      } catch (error) {
        // print("Error with API key index $keyAttemptIndex: $error");
        String errorDetail = error.toString();
        if (error.toString().contains("API key not valid")) {
            errorDetail = "API key not valid. Please check your configuration.";
        } else if (error.toString().contains("quota")) {
            errorDetail = "API quota exceeded for this key.";
        }
        onLog("<span style=\"color:var(--fh-accent-red);\">Error with API key index $keyAttemptIndex: $errorDetail</span>");
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
    required List<String> themes, // e.g., ['tech', 'knowledge', 'learning']
    required Function(String) onLog,
  }) async {
    onLog("Attempting to generate themed game content (enemies/artifacts)...");

    final int numEnemiesToGeneratePerTheme = isInitial ? 1 : 1; // 1 enemy per theme
    final int totalEnemiesToGenerate = themes.length * numEnemiesToGeneratePerTheme + (isInitial ? 2 : 1); // + some general enemies

    // Construct artifact generation instructions per theme
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
The player is currently progressing and needs new challenges and rewards.
Provide the output as a single JSON object with two keys: "newEnemies" and "newArtifacts".

IMPORTANT: Do NOT generate enemies with the following IDs: [$existingEnemyIdsString].
IMPORTANT: Do NOT generate artifacts with the following IDs: [$existingArtifactIdsString].
All generated IDs and artifact names MUST be new and unique.

"newEnemies" should be an array of $totalEnemiesToGenerate enemy objects.
- For each theme in [${themes.map((t) => "'$t'").join(', ')}], generate $numEnemiesToGeneratePerTheme enemy specifically for that theme.
- The remaining enemies can be general (theme: null) or pick from the themes.
Each enemy object must have:
- id: string, unique (MUST NOT be one of the existing IDs provided above), format 'gen_enemy_lvl${levelForContent}_<short_random_hash>' (e.g., gen_enemy_lvl${levelForContent}_a2f5)
- name: string (e.g., "Shadow Lurker", "Arcane Golem")
- theme: string, one of [${themes.map((t) => "'$t'").join(', ')}, null] (null for General. Ensure themed enemies match their intended theme.)
- minPlayerLevel: number, should be $levelForContent
- health: number (balanced for level $levelForContent, range: ${50 + levelForContent * 12} to ${80 + levelForContent * 18})
- attack: number (balanced for level $levelForContent, range: ${8 + (levelForContent * 1.8).floor()} to ${12 + (levelForContent * 2.2).floor()})
- defense: number (balanced for level $levelForContent, range: ${3 + (levelForContent * 0.6).floor()} to ${5 + (levelForContent * 1.1).floor()})
- coinReward: number (range: ${20 + levelForContent * 5} to ${50 + levelForContent * 10})
- xpReward: number (range: ${30 + levelForContent * 8} to ${70 + levelForContent * 15})
- description: string (a short, flavorful description, max 100 characters)

"newArtifacts" should be an array of artifact objects. Generate artifacts as specified below:
$artifactInstructions
Each artifact object must have:
- id: string, unique (MUST NOT be one of the existing IDs provided above), format 'gen_art_lvl${levelForContent}_<theme_short>_<type_short>_<hash>' (e.g., gen_art_lvl${levelForContent}_tech_wpn_b3c8)
- name: string (e.g., "Tech Blade", "Knowledge Potion"). The name should subtly hint at its theme and type.
- type: string, one of ['weapon', 'armor', 'talisman', 'powerup'] as specified.
- theme: string, MUST be the theme it was generated for (e.g., "tech", "knowledge").
- description: string (max 100 characters, reflecting its theme and function)
- cost: number (for purchasing in a shop, range: ${50 + levelForContent * 10} to ${300 + levelForContent * 25})
- icon: string (a single, relevant emoji that fits the theme and type)
- For 'weapon', 'armor', 'talisman' types:
    - baseAtt: number (0 if not applicable)
    - baseRunic: number (0 if not applicable)
    - baseDef: number (0 if not applicable)
    - baseHealth: number (0 if not applicable)
    - baseLuck: number (0 if not applicable, integer representing percentage, e.g. 5 for 5%)
    - baseCooldown: number (0 if not applicable, integer representing percentage, e.g. 10 for 10%)
    - bonusXPMod: number (0 if not applicable, otherwise a decimal like 0.05 for 5%)
    - upgradeBonus: object, detailing per-level stat increases (e.g., {"att": 2, "luck": 1} or {"health": 10}). Include at least one stat relevant to the item type. Values should be modest (1-3 for attack/defense, 5-15 for health, 1-2 for luck/cooldown percentages, 0.01-0.03 for XPMod).
    - maxLevel: number (typically 3, 5 or 7)
- For 'powerup' type:
    - effectType: string, one of ['direct_damage', 'heal_player']
    - effectValue: number (e.g., for 'direct_damage', a value like ${20 + levelForContent * 5}; for 'heal_player', a value like ${30 + levelForContent * 8})
    - uses: number (typically 1 for consumables)
    - (baseAtt, baseRunic, etc., upgradeBonus, maxLevel are NOT applicable for powerups and should be omitted or set to 0/null)

Ensure all string IDs are unique and not present in the provided exclusion lists. Balance the stats appropriately for the given player level.
The "newArtifacts" array should be a flat list containing all generated artifacts.
Return only the JSON object, without any markdown formatting or explanatory text.
""";
    try {
      final Map<String, dynamic> rawData = await _makeAICall(
        prompt: prompt,
        currentApiKeyIndex: currentApiKeyIndex,
        onNewApiKeyIndex: onNewApiKeyIndex,
        onLog: onLog,
      );

      final List<Map<String, dynamic>> newEnemies = (rawData['newEnemies'] as List?)
          ?.map((e) => e as Map<String, dynamic>).toList() ?? [];
      final List<Map<String, dynamic>> newArtifacts = (rawData['newArtifacts'] as List?)
          ?.map((a) => a as Map<String, dynamic>).toList() ?? [];

      return {'newEnemies': newEnemies, 'newArtifacts': newArtifacts};

    } catch (e) {
      onLog("<span style=\"color:var(--fh-accent-red);\">AI Call failed for generateAIContent: ${e.toString()}</span>");
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
    onLog("Attempting to generate sub-quests for \"$mainTaskName\"... Mode: $generationMode");

    String modeSpecificInstructions = "";
    switch (generationMode) {
        case "book_chapter":
            modeSpecificInstructions = """
The user is providing details about a book chapter they are reading.
Input: "$userInput"
Break this down into approximately $numSubquests actionable sub-quests. Each sub-quest should represent a significant part of reading/understanding the chapter.
For each sub-quest, suggest 1-3 smaller, concrete steps (sub-subtasks).
If a step involves reading a number of pages, make it a "countable" sub-subtask with the number of pages as "targetCount".
Example: "Read pages 10-25" -> name: "Read pages", isCountable: true, targetCount: 16.
Sub-quests themselves can also be countable if appropriate (e.g. "Complete 3 exercises").
""";
            break;
        case "text_list":
            modeSpecificInstructions = """
The user has provided a hierarchical text list. Top-level items are sub-quests. Indented items are small steps (sub-subtasks).
Input:
$userInput
Interpret this list. Convert each top-level item into a sub-quest and its indented items into sub-subtasks.
If an item mentions a quantity (e.g., "3 sets", "10 pages", "2 pomodoros"), make it "countable" and set "targetCount".
""";
            break;
        case "general_plan":
        default:
            modeSpecificInstructions = """
The user has provided a general plan or goal.
Input: "$userInput"
Break this down into approximately $numSubquests logical sub-quests to achieve the plan.
For each sub-quest, suggest 1-3 smaller, concrete steps (sub-subtasks).
Make items "countable" with a "targetCount" if they clearly imply a quantity.
""";
            break;
    }

    final String prompt = """
You are an assistant for a gamified task management app. The user wants to break down a larger goal into sub-quests and smaller steps.
The main quest is: "$mainTaskName" (Description: "$mainTaskDescription", Theme: "${mainTaskTheme ?? 'General'}").
Current AI generation mode: "$generationMode".

$modeSpecificInstructions

Provide the output as a single JSON object with one key: "newSubquests".
"newSubquests" should be an array of sub-quest objects (approx $numSubquests, but adapt to input). Each sub-quest object MUST have:
- name: string (concise name for the sub-quest)
- isCountable: boolean (true if the sub-quest itself is a countable item, e.g., "Write 3 articles", "Complete 5 exercises")
- targetCount: number (if isCountable is true, otherwise 0 or 1; ensure it's reasonable if derived from input like "3 articles" -> targetCount: 3)
- subSubTasksData: array of sub-subtask objects. Each sub-subtask object must have:
  - name: string (concise name for the small step)
  - isCountable: boolean (true if the step implies a quantity, e.g. "Read pages 1-10", "Do 15 pushups")
  - targetCount: number (if isCountable is true, derive from input like "10 pages" -> 10, "15 pushups" -> 15; otherwise 0 or 1)

Example of desired JSON structure:
{
  "newSubquests": [
    {
      "name": "Understand Chapter 1 Concepts",
      "isCountable": false,
      "targetCount": 0,
      "subSubTasksData": [
        { "name": "Read pages 1-10", "isCountable": true, "targetCount": 10 },
        { "name": "Summarize key points", "isCountable": false, "targetCount": 1 },
        { "name": "Do 3 practice problems", "isCountable": true, "targetCount": 3 }
      ]
    },
    {
      "name": "Outline Project Proposal",
      "isCountable": false,
      "targetCount": 0,
      "subSubTasksData": []
    }
  ]
}
Focus on creating actionable, distinct sub-quests and steps. Ensure names are clear and concise.
If the user input is very short or vague for the number of subquests requested, generate fewer, more meaningful ones rather than padding with trivial items.
Return only the JSON object, without any markdown formatting or explanatory text.
""";
    try {
      final Map<String, dynamic> rawData = await _makeAICall(
        prompt: prompt,
        currentApiKeyIndex: currentApiKeyIndex,
        onNewApiKeyIndex: onNewApiKeyIndex,
        onLog: onLog,
      );
      final List<Map<String, dynamic>> newSubquests = (rawData['newSubquests'] as List?)
          ?.map((sq) => sq as Map<String, dynamic>).toList() ?? [];

      // Basic validation
      bool isValid = newSubquests.every((sq) =>
        sq['name'] is String &&
        sq['isCountable'] is bool &&
        sq['targetCount'] is num &&
        sq['subSubTasksData'] is List &&
        (sq['subSubTasksData'] as List).every((sss) =>
            sss['name'] is String &&
            sss['isCountable'] is bool &&
            sss['targetCount'] is num
        )
      );

      if (!isValid) {
        onLog("<span style=\"color:var(--fh-accent-orange);\">AI subquest response malformed.</span>");
        throw Exception("AI subquest response malformed.");
      }
      return newSubquests;

    } catch (e) {
      onLog("<span style=\"color:var(--fh-accent-red);\">AI Call failed for generateAISubquests: ${e.toString()}</span>");
      rethrow;
    }
  }
}