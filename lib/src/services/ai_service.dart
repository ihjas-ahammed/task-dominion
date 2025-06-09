import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart' as genai;
import 'package:arcane/src/config/api_keys.dart';
import 'package:flutter/foundation.dart';
import 'package:arcane/src/models/game_models.dart';

class AIService {
  Future<Map<String, dynamic>> _makeAICall({
    required String prompt,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    if (geminiApiKeys.isEmpty || geminiApiKeys.every((key) => key.startsWith('YOUR_GEMINI_API_KEY'))) {
      throw Exception("No valid Gemini API keys found.");
    }
    if (geminiModelName.isEmpty) {
      throw Exception("GEMINI_MODEL_NAME not configured.");
    }

    if (kDebugMode) print("[AIService] AI Prompt:\n$prompt");

    for (int i = 0; i < geminiApiKeys.length; i++) {
      final int keyAttemptIndex = (currentApiKeyIndex + i) % geminiApiKeys.length;
      final String apiKey = geminiApiKeys[keyAttemptIndex];
      if (apiKey.startsWith('YOUR_GEMINI_API_KEY')) continue;

      try {
        final model = genai.GenerativeModel(model: geminiModelName, apiKey: apiKey);
        final response = await model.generateContent([genai.Content.text(prompt)]);
        String? rawResponseText = response.text;

        if (rawResponseText == null || rawResponseText.trim().isEmpty) throw Exception("AI response was empty.");
        if (kDebugMode) print("[AIService] Raw AI Response (Key Index $keyAttemptIndex):\n$rawResponseText");
        
        String jsonString = rawResponseText.trim();
        int jsonStart = jsonString.indexOf('{');
        int jsonEnd = jsonString.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          jsonString = jsonString.substring(jsonStart, jsonEnd + 1);
        } else {
          throw Exception("Could not extract JSON from AI response.");
        }

        final Map<String, dynamic> generatedData = jsonDecode(jsonString);
        onNewApiKeyIndex(keyAttemptIndex);
        return generatedData;
      } catch (e) {
        String errorDetail = e.toString();
        if (kDebugMode) print("[AIService] Error with API key index $keyAttemptIndex: $errorDetail");
        if (i == geminiApiKeys.length - 1) throw Exception("All API keys failed. Last error: $errorDetail");
      }
    }
    throw Exception("All API keys failed or were invalid.");
  }

  Future<List<Map<String, dynamic>>> generateTasksFromPlan({
    required Project project,
    required String userInput,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    final String prompt = """
You are an assistant for a gamified task management app. Your job is to break down a user's plan into a single comprehensive task with actionable checkpoints.

**Context:**
- Project: "${project.name}" (Theme/Skill: "${project.theme}")
- User's Plan/Input:
---
$userInput
---

**Your Goal:**
Generate ONE comprehensive task that encapsulates the user's plan, broken down into 3 to 7 specific checkpoints.

**Output Requirements:**
Provide the output as a single, valid JSON object. The JSON object MUST have a single key:
- "tasks": An array containing exactly ONE task object. The task object MUST have:
  - "name": string (A comprehensive task name that encompasses the overall goal, e.g., "Complete Chapter 1 Study Session", "Build Portfolio Website")
  - "isCountable": boolean (Set to true if the overall task involves a clear quantity)
  - "targetCount": number (If countable, the target number; otherwise, 0)
  - "checkpoints": array of checkpoint objects. Each checkpoint object MUST have:
    - "name": string (A specific, actionable checkpoint, e.g., "Read section 1.1", "Set up HTML structure")
    - "isCountable": boolean (Set to true if this checkpoint involves a clear quantity)
    - "targetCount": number (If countable, the target number; otherwise, 0)

**Example JSON Output:**
```json
{
  "tasks": [
    {
      "name": "Complete research paper draft",
      "isCountable": false,
      "targetCount": 0,
      "checkpoints": [
        {
          "name": "Research and gather 10 sources",
          "isCountable": true,
          "targetCount": 10
        },
        {
          "name": "Create detailed outline",
          "isCountable": false,
          "targetCount": 0
        },
        {
          "name": "Write introduction section",
          "isCountable": false,
          "targetCount": 0
        },
        {
          "name": "Write 1500 words for main body",
          "isCountable": true,
          "targetCount": 1500
        },
        {
          "name": "Write conclusion and bibliography",
          "isCountable": false,
          "targetCount": 0
        }
      ]
    }
  ]
}
```

Return ONLY the JSON object. Do not include markdown, comments, or any extra text.
""";
    try {
      final Map<String, dynamic> generatedData = await _makeAICall(
        prompt: prompt,
        currentApiKeyIndex: currentApiKeyIndex,
        onNewApiKeyIndex: onNewApiKeyIndex,
        onLog: onLog,
      );

      if (generatedData.containsKey('tasks') && generatedData['tasks'] is List) {
        return List<Map<String, dynamic>>.from(generatedData['tasks']);
      } else {
        throw Exception("AI response for task generation was malformed.");
      }
    } catch (e) {
      onLog("<span style=\"color:var(--fh-accent-red);\">AI Call failed for generateTasksFromPlan: ${e.toString()}</span>");
      rethrow;
    }
  }


  Future<Map<String, dynamic>> enhanceTaskWithAI({
    required Project project,
    required Task task,
    required String userInput,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
    required List<Skill> allSkills,
  }) async {
    final String taskStr = jsonEncode(task);
    final String allSkillsStr = jsonEncode(allSkills);

    final String prompt = """
You are an assistant for a gamified task management app. Your job is to enhance an existing task by breaking it down into checkpoints and assigning XP to subskills.

**Context:**
- Project: "${project.name}" (Associated Skill/Theme: "${project.theme}")
- Task to Enhance: ${taskStr}
- User's Instructions: "$userInput"
- Existing Skills and Subskills in the system:
${allSkillsStr}

**Your Goal:**
1.  WIth no checkpoints, generate new checkpoints but if there is already checkpoints only assign skills, replace skills if needed
2.  Define XP rewards for completing the overall task, distributed among relevant **subskills**.
3.  For each checkpoint, also assign smaller XP rewards to relevant **subskills**.
4.  If a relevant subskill doesn't exist under the project's theme ("${project.theme}"), you can create a new one.

**Output Requirements:**
Provide a single, valid JSON object. The JSON object MUST have these keys:
- "subskillXp": A JSON object where keys are **subskill IDs** and values are the XP amount (number) for completing the **entire task**.
  - Subskill IDs MUST follow the format `parentSkillId_subskillNameInLowercase`.
  - Example: `{"${project.theme}_research": 5.0, "${project.theme}_writing": 10.0}`.
- "checkpoints": An array of checkpoint objects. Each checkpoint MUST have:
  - "id": A placeholder string like "new_cp_1".
  - "name": A small, concrete action (e.g., "Read pages 1-10").
  - "isCountable": boolean.
  - "targetCount": number (if countable, otherwise 0).
  - "subskillXp": A JSON object where keys are **subskill IDs** and values are XP amounts for this specific checkpoint. XP should be smaller than the parent task's XP.
- "newSubskills": An array of new subskill objects to be created, if any. Each object must have:
  - "name": string.
  - "parentSkillId": string (This MUST be "${project.theme}").

**Example JSON Output:**
```json
{
  "subskillXp": {
    "knowledge_research": 5.0,
    "knowledge_drafting": 10.0
  },
  "checkpoints": [
    {
      "id": "new_cp_1",
      "name": "Research and gather 10 sources",
      "isCountable": true,
      "targetCount": 10,
      "subskillXp": { "knowledge_research": 3.0 }
    },
    {
      "id": "new_cp_2",
      "name": "Write 1500 words for main body",
      "isCountable": true,
      "targetCount": 1500,
      "subskillXp": { "knowledge_drafting": 6.0 }
    }
  ],
  "newSubskills": [
    {
      "name": "Research",
      "parentSkillId": "knowledge"
    },
    {
      "name": "Drafting",
      "parentSkillId": "knowledge"
    }
  ]
}
```

Return ONLY the JSON object. Do not include markdown, comments, or any extra text.
""";
    try {
      final Map<String, dynamic> enhancedData = await _makeAICall(
        prompt: prompt,
        currentApiKeyIndex: currentApiKeyIndex,
        onNewApiKeyIndex: onNewApiKeyIndex,
        onLog: onLog,
      );

      if (enhancedData.containsKey('checkpoints') && enhancedData['checkpoints'] is List) {
        return enhancedData;
      } else {
        throw Exception("AI response for enhancement was malformed. Missing 'checkpoints' list.");
      }
    } catch (e) {
      onLog("<span style=\"color:var(--fh-accent-red);\">AI Call failed for enhanceTaskWithAI: ${e.toString()}</span>");
      rethrow;
    }
  }

  Future<String> getChatbotResponse({
    required ChatbotMemory memory,
    required String userMessage,
    required String completedByDayJsonLast7Days,
    required String olderDaysSummary,
    required int currentApiKeyIndex,
    required Function(int) onNewApiKeyIndex,
    required Function(String) onLog,
  }) async {
    final conversationHistoryString = memory.conversationHistory.map((msg) => "${msg.sender == MessageSender.user ? 'User' : 'Bot'}: ${msg.text}").join('\n');
    
    final String prompt = """
You are Arcane Advisor, a helpful AI assistant in a gamified productivity app.
Your knowledge includes:
1.  Conversation History:
$conversationHistoryString
2.  Logbook Data (Last 7 Days):
$completedByDayJsonLast7Days
3.  Older Logbook Summary:
$olderDaysSummary
4.  User's Remembered Items:
${memory.userRememberedItems.isNotEmpty ? memory.userRememberedItems.join('\n') : "None."}

User's message: "$userMessage"

Based on this, provide a concise, helpful, and encouraging response.
If asked to "Remember X", acknowledge it. If asked to "Forget", acknowledge it. The system handles the memory.
Analyze progress, summaries, emotion trends, or completions using the provided data.
Keep responses short and conversational. Do not use markdown.
"""
        .trim();

    try {
      if (geminiApiKeys.isEmpty || geminiApiKeys.every((key) => key.startsWith('YOUR_GEMINI_API_KEY'))) {
        throw Exception("No valid Gemini API keys found.");
      }
      if (geminiModelName.isEmpty) {
        throw Exception("GEMINI_MODEL_NAME not configured.");
      }
      
      if (kDebugMode) print("[AIService - Chatbot] Prompt:\n$prompt");

      for (int i = 0; i < geminiApiKeys.length; i++) {
        final int keyAttemptIndex = (currentApiKeyIndex + i) % geminiApiKeys.length;
        final String apiKey = geminiApiKeys[keyAttemptIndex];
        if (apiKey.startsWith('YOUR_GEMINI_API_KEY')) continue;

        try {
          final model = genai.GenerativeModel(model: 'gemini-2.0-flash-lite', apiKey: apiKey);
          final response = await model.generateContent([genai.Content.text(prompt)]);
          String? rawResponseText = response.text;
          if (rawResponseText == null || rawResponseText.trim().isEmpty) throw Exception("Chatbot AI response was empty.");
          
          if (kDebugMode) print("[AIService - Chatbot] Raw AI Response (Key Index $keyAttemptIndex):\n$rawResponseText");
          onNewApiKeyIndex(keyAttemptIndex);
          return rawResponseText.trim();
        } catch (e) {
          String errorDetail = e.toString();
          if (e is genai.GenerativeAIException && e.message.contains("USER_LOCATION_INVALID")) errorDetail = "Geographic location restriction.";
          else if (errorDetail.contains("API key not valid")) errorDetail = "Invalid API key.";
          else if (errorDetail.contains("quota")) errorDetail = "API quota exceeded.";
          else if (errorDetail.contains("Candidate was blocked due to SAFETY")) errorDetail = "Response blocked due to safety settings.";
          
          if (kDebugMode) print("[AIService - Chatbot] Error with API key index $keyAttemptIndex: $errorDetail");
          if (i == geminiApiKeys.length - 1) return "I'm having trouble connecting. Please try again later. (Error: $errorDetail)";
        }
      }
    } catch (e) {
       return "I'm currently unable to process requests due to a configuration issue.";
    }
    return "I seem to be experiencing technical difficulties. Please check back soon.";
  }
}