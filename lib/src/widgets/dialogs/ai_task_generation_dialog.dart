// lib/src/widgets/dialogs/ai_task_generation_dialog.dart
import 'package:arcane/src/models/game_models.dart';
import 'package:arcane/src/providers/game_provider.dart';
import 'package:arcane/src/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

class AITaskGenerationDialog extends StatelessWidget {
  final Project project;
  const AITaskGenerationDialog({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final aiInputController = TextEditingController();
    final gameProvider = context.watch<GameProvider>();

    return AlertDialog(
      backgroundColor: AppTheme.fnBgMedium,
      title: Row(children: [
        Icon(MdiIcons.creation, color: AppTheme.fortnitePurple),
        const SizedBox(width: 8),
        const Text("Generate Tasks with AI",
            style: TextStyle(color: AppTheme.fortnitePurple)),
      ]),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Provide a plan, outline, or table of contents. The AI will generate a list of actionable tasks for your project '${project.name}'.",
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            TextField(
              controller: aiInputController,
              decoration: const InputDecoration(
                labelText: 'Plan / Outline',
                hintText: 'e.g., Paste a chapter list here...',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton.icon(
          icon: gameProvider.isGeneratingContent
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(MdiIcons.headCogOutline, size: 16),
          label: const Text("Generate"),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fortnitePurple),
          onPressed: gameProvider.isGeneratingContent ||
                  aiInputController.text.trim().isEmpty
              ? null
              : () {
                  gameProvider.triggerAIGenerateTasks(
                      project, aiInputController.text);
                  Navigator.of(context).pop();
                },
        ),
      ],
    );
  }
}