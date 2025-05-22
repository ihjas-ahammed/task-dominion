// lib/src/widgets/views/settings_view.dart
import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuthException
import 'package:intl/intl.dart'; // For date formatting

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _passwordChangeLoading = false;
  String _passwordChangeError = '';
  String _passwordChangeSuccess = '';
  bool _logoutLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword(GameProvider gameProvider) async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _passwordChangeError = "Passwords do not match.");
      return;
    }
    if (_newPasswordController.text.length < 6) {
      setState(() => _passwordChangeError = "Password should be at least 6 characters long.");
      return;
    }
    setState(() {
      _passwordChangeLoading = true;
      _passwordChangeError = '';
      _passwordChangeSuccess = '';
    });
    try {
      await gameProvider.changePasswordHandler(_newPasswordController.text);
      setState(() {
        _passwordChangeSuccess = "Password changed successfully!";
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      if (e is FirebaseAuthException) {
        setState(() => _passwordChangeError = e.message ?? "Failed to change password.");
      } else {
        setState(() => _passwordChangeError = "An unexpected error occurred while changing password.");
      }
    } finally {
      if (mounted) {
        setState(() => _passwordChangeLoading = false);
      }
    }
  }

  Future<void> _handleLogout(GameProvider gameProvider, BuildContext pageContext) async {
    setState(() {
      _logoutLoading = true;
    });
    try {
        await gameProvider.logoutUser();
        // Navigation handled by listener in app.dart
    } catch (e) {
        // ignore: use_build_context_synchronously
        if (!mounted) return;
        ScaffoldMessenger.of(pageContext).showSnackBar(
            SnackBar(content: Text('Logout failed: ${e.toString()}'), backgroundColor: AppTheme.fhAccentRed)
        );
    } finally {
       if (mounted) {
          setState(() {
            _logoutLoading = false;
          });
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    String lastSavedString = "Not synced yet.";
    if (gameProvider.lastSuccessfulSaveTimestamp != null) {
        lastSavedString = "Last synced: ${DateFormat('MMM d, yyyy, hh:mm:ss a').format(gameProvider.lastSuccessfulSaveTimestamp!.toLocal())}";
    }


    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(MdiIcons.cogOutline, color: AppTheme.fhAccentTeal, size: 36),
                const SizedBox(width: 12),
                Text("System Configuration", style: theme.textTheme.displaySmall?.copyWith(color: AppTheme.fhAccentTeal)),
              ],
            ),
          ),

          _buildSettingsSection(
            theme,
            icon: MdiIcons.cloudSyncOutline,
            title: 'Cloud Synchronization',
            children: [
                ElevatedButton.icon(
                    icon: gameProvider.isManuallySaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.fhBgDark)) : Icon(MdiIcons.cloudUploadOutline, size: 18),
                    label: const Text('SAVE TO CLOUD NOW'),
                    onPressed: gameProvider.isManuallySaving || gameProvider.isManuallyLoading ? null : () async {
                        try {
                            await gameProvider.manuallySaveToCloud();
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data saved to cloud.'), backgroundColor: AppTheme.fhAccentGreen));
                        } catch (e) {
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud save failed: ${e.toString()}'), backgroundColor: AppTheme.fhAccentRed));
                        }
                    },
                     style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                    icon: gameProvider.isManuallyLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.fhBgDark)) : Icon(MdiIcons.cloudDownloadOutline, size: 18),
                    label: const Text('LOAD FROM CLOUD NOW'),
                    onPressed: gameProvider.isManuallySaving || gameProvider.isManuallyLoading ? null : () async {
                        final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.fhBgDark,
                                title: Row(children: [Icon(MdiIcons.cloudQuestionOutline, color: AppTheme.fhAccentOrange), const SizedBox(width:10),const Text('Confirm Load', style: TextStyle(color: AppTheme.fhAccentOrange))]),
                                content: const Text('This will overwrite any local unsaved changes with data from the cloud. Are you sure?'),
                                actionsAlignment: MainAxisAlignment.spaceBetween,
                                actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.fhTextSecondary))),
                                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentOrange), child: const Text('CONFIRM LOAD', style: TextStyle(color: AppTheme.fhBgDark))),
                                ],
                            ),
                        );
                        if (confirm == true) {
                            try {
                                await gameProvider.manuallyLoadFromCloud();
                                if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data loaded from cloud.'), backgroundColor: AppTheme.fhAccentGreen));
                            } catch (e) {
                                if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cloud load failed: ${e.toString()}'), backgroundColor: AppTheme.fhAccentRed));
                            }
                        }
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                      lastSavedString,
                      style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.fhTextSecondary.withOpacity(0.8), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                    "Note: Game progress is auto-saved to the cloud periodically (approx. every minute if changes are detected). Use these options for immediate synchronization or recovery.",
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhTextSecondary.withOpacity(0.8), fontSize: 10),
                ),
            ]
          ),


          _buildSettingsSection(
            theme,
            icon: MdiIcons.brain,
            title: 'Cognitive Matrix (AI)',
            children: [
              SwitchListTile.adaptive(
                title: const Text('Dynamic Content Adaptation (Level Up)', style: TextStyle(fontSize: 14, color: AppTheme.fhTextPrimary, fontFamily: AppTheme.fontBody)),
                subtitle: const Text('Automatically generate new challenges and items upon leveling up.', style: TextStyle(fontSize: 11, color: AppTheme.fhTextSecondary, fontFamily: AppTheme.fontBody)),
                value: gameProvider.settings.autoGenerateContent,
                onChanged: (value) => gameProvider.setSettings(gameProvider.settings..autoGenerateContent = value),
                activeColor: AppTheme.fhAccentTeal,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 12),
              Text(
                'Manually initiate content generation protocol for current operational level (${gameProvider.playerLevel}). This may consume significant resources.',
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhTextSecondary),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: gameProvider.isGeneratingContent
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.fhBgDark))
                    : Icon(MdiIcons.creationOutline, size: 18),
                label: Text(gameProvider.isGeneratingContent ? 'PROTOCOL ACTIVE...' : 'INITIATE GENERATION'),
                onPressed: gameProvider.isGeneratingContent ? null : () => gameProvider.generateGameContent(gameProvider.playerLevel, isManual: true),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
              ),
              if (gameProvider.isGeneratingContent)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    'Cognitive matrix recalculating... please standby.',
                    style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: AppTheme.fhAccentLightCyan.withOpacity(0.8)),
                  ),
                ),
            ],
          ),

          _buildSettingsSection(
            theme,
            icon: MdiIcons.layersTripleOutline,
            title: 'Content Matrix Control',
            children: [
              Text(
                'Manage generated game content. These actions are specific and do not affect player progress directly, but may alter game balance or availability of items/enemies.',
                 style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhTextSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(MdiIcons.flaskEmptyRemoveOutline, size: 18, color: AppTheme.fhBgDark),
                label: const Text('PURGE POWER-UPS', style: TextStyle(color: AppTheme.fhBgDark)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.fhBgDark,
                      title: Row(children: [Icon(MdiIcons.alertOutline, color: AppTheme.fhAccentOrange), const SizedBox(width:10),const Text('Confirm Purge Schematics', style: TextStyle(color: AppTheme.fhAccentOrange))]),
                      content: const Text('This will remove all power-up templates that you do not currently own. This action cannot be undone. Are you sure?'),
                      actionsAlignment: MainAxisAlignment.spaceBetween,
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.fhTextSecondary))),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentOrange, foregroundColor: AppTheme.fhBgDark),
                          child: const Text('CONFIRM PURGE')
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    gameProvider.clearDiscoverablePowerUps();
                     if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Discoverable power-up schematics purged.'), backgroundColor: AppTheme.fhAccentGreen));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentOrange, foregroundColor: AppTheme.fhBgDark, minimumSize: const Size(double.infinity, 44)),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: Icon(MdiIcons.skullCrossbonesOutline, size: 18, color: AppTheme.fhBgDark),
                label: const Text('DECOMMISSION ENEMIES', style: TextStyle(color: AppTheme.fhBgDark)),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.fhBgDark,
                       title: Row(children: [Icon(MdiIcons.alertOutline, color: AppTheme.fhAccentOrange), const SizedBox(width:10),const Text('Confirm', style: TextStyle(color: AppTheme.fhAccentOrange),softWrap: true,)]),
                      content: const Text('This removes all enemy templates. The Arena might be empty until new content is generated. This action cannot be undone. Are you sure?'),
                      actionsAlignment: MainAxisAlignment.spaceBetween,
                       actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.fhTextSecondary))),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentOrange, foregroundColor: AppTheme.fhBgDark),
                          child: const Text('CONFIRM DECOMMISSION')
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    gameProvider.removeAllEnemyTemplates();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All enemy signatures decommissioned.'), backgroundColor: AppTheme.fhAccentGreen));
                  }
                },
                 style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentOrange, foregroundColor: AppTheme.fhBgDark, minimumSize: const Size(double.infinity, 44)),
              ),
            ]
          ),


          _buildSettingsSection(
            theme,
            icon: MdiIcons.eyeSettingsOutline,
            title: 'User Interface Config',
            children: [
               SwitchListTile.adaptive(
                title: const Text('Verbose Data Display', style: TextStyle(fontSize: 14, color: AppTheme.fhTextPrimary, fontFamily: AppTheme.fontBody)),
                subtitle: const Text('Show detailed descriptions for stats and items throughout the interface.', style: TextStyle(fontSize: 11, color: AppTheme.fhTextSecondary, fontFamily: AppTheme.fontBody)),
                value: gameProvider.settings.descriptionsVisible,
                onChanged: (value) => gameProvider.setSettings(gameProvider.settings..descriptionsVisible = value),
                activeColor: AppTheme.fhAccentLightCyan,
                contentPadding: EdgeInsets.zero,
              ),
            ]
          ),

          if (gameProvider.currentUser != null)
            _buildSettingsSection(
              theme,
              icon: MdiIcons.shieldAccountOutline,
              title: 'Access Credentials',
              children: [
                TextField(
                  controller: _newPasswordController,
                  decoration: InputDecoration(labelText: 'New Passcode Sequence', prefixIcon: Icon(MdiIcons.formTextboxPassword, size: 20)),
                  obscureText: true,
                   style: const TextStyle(fontFamily: AppTheme.fontBody),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(labelText: 'Confirm Passcode Sequence', prefixIcon: Icon(MdiIcons.formTextboxPassword, size: 20)),
                  obscureText: true,
                   style: const TextStyle(fontFamily: AppTheme.fontBody),
                ),
                if (_passwordChangeError.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(_passwordChangeError, style: const TextStyle(color: AppTheme.fhAccentRed, fontSize: 12, fontFamily: AppTheme.fontBody)),
                  ),
                if (_passwordChangeSuccess.isNotEmpty)
                   Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Text(_passwordChangeSuccess, style: const TextStyle(color: AppTheme.fhAccentGreen, fontSize: 12, fontFamily: AppTheme.fontBody)),
                  ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: _passwordChangeLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.fhBgDark))
                      : Icon(MdiIcons.keyChange, size: 18, color: AppTheme.fhBgDark),
                  label: const Text('UPDATE PASSCODE', style: TextStyle(color: AppTheme.fhBgDark)),
                  onPressed: _passwordChangeLoading ? null : () => _handleChangePassword(gameProvider),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentLightCyan, minimumSize: const Size(double.infinity, 44)),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                    icon: _logoutLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppTheme.fhAccentOrange))
                        : Icon(MdiIcons.logoutVariant, size: 18),
                    label: const Text('TERMINATE SESSION'),
                    onPressed: _logoutLoading ? null : () => _handleLogout(gameProvider, context),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.fhAccentOrange, side: const BorderSide(color: AppTheme.fhAccentOrange, width: 1.5), minimumSize: const Size(double.infinity, 44)),
                ),
              ]
            ),

          _buildSettingsSection(
            theme,
            icon: MdiIcons.databaseRemoveOutline,
            title: 'Data & System Reset',
            children: [
                ElevatedButton.icon(
                    icon: Icon(MdiIcons.undoVariant, size: 18),
                    label: const Text('RESET PLAYER LEVEL'),
                    onPressed: () async {
                        final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                                backgroundColor: AppTheme.fhBgDark,
                                title: Row(children: [Icon(MdiIcons.alertOutline, color: AppTheme.fhAccentOrange), const SizedBox(width:10), const Text('Confirm Level Reset', style: TextStyle(color: AppTheme.fhAccentOrange))]),
                                content: const Text('This will reset your player level to 1, XP to 0, and clear defeated enemies for the current level. Your tasks, items, and coins will remain. Are you sure?'),
                                actionsAlignment: MainAxisAlignment.spaceBetween,
                                actions: [
                                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.fhTextSecondary))),
                                    ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentOrange, foregroundColor: AppTheme.fhBgDark), child: const Text('CONFIRM RESET')),
                                ],
                            ),
                        );
                        if (confirm == true) {
                            gameProvider.resetPlayerLevelAndProgress();
                            if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Player level and progress reset.'), backgroundColor: AppTheme.fhAccentGreen));
                        }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentOrange, foregroundColor: AppTheme.fhBgDark, minimumSize: const Size(double.infinity, 44)),
              ),
              const SizedBox(height: 16),
              Text(
                'WARNING: The "Purge All Data" protocol will erase all operational data, including quest logs, experience, currency, and acquired assets. This action is irreversible and will reset the system to factory defaults.',
                 style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.fhTextSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: Icon(MdiIcons.alertOctagonOutline, size: 18),
                label: const Text('PURGE ALL DATA'),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppTheme.fhBgDark,
                      title: Row(children: [Icon(MdiIcons.alertOutline, color: AppTheme.fhAccentRed), const SizedBox(width:10),const Text('Confirm System Purge', style: TextStyle(color: AppTheme.fhAccentRed))]),
                      content: const Text('Are you absolutely certain you wish to erase all data? This operation cannot be undone and will result in total loss of progress.'),
                      actionsAlignment: MainAxisAlignment.spaceBetween,
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('CANCEL', style: TextStyle(color: AppTheme.fhTextSecondary))),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentRed, foregroundColor: AppTheme.fhTextPrimary),
                          child: const Text('CONFIRM PURGE')
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    gameProvider.clearAllGameData();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All game data has been purged.'), backgroundColor: AppTheme.fhAccentGreen));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fhAccentRed, foregroundColor: AppTheme.fhTextPrimary, minimumSize: const Size(double.infinity, 44)),
              ),
            ]
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, {required IconData icon, required String title, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: AppTheme.fhBgLight.withOpacity(0.7),
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
        side: BorderSide(color: AppTheme.fhBorderColor.withOpacity(0.7), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.fhAccentTeal, size: 20),
                const SizedBox(width: 10),
                Text(title, style: theme.textTheme.headlineSmall?.copyWith(color: AppTheme.fhTextPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
            Divider(height: 20, thickness: 0.5, color: AppTheme.fhBorderColor.withOpacity(0.5)),
            ...children,
          ],
        ),
      ),
    );
  }
}