import 'package:flutter/material.dart';
import 'package:myapp_flutter/src/screens/home_screen.dart';
import 'package:myapp_flutter/src/screens/login_screen.dart';
import 'package:myapp_flutter/src/providers/game_provider.dart';
import 'package:myapp_flutter/src/theme/app_theme.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print("[MyApp] Building MaterialApp"); // DEBUG
    return MaterialApp(
      title: 'Task Dominion',
      theme: AppTheme.getThemeData(primaryAccent: AppTheme.fhAccentTealFixed),
      debugShowCheckedModeBanner: false,
      home: Consumer<GameProvider>(
        builder: (context, gameProvider, child) {
          print("[MyApp Consumer] AuthLoading: ${gameProvider.authLoading}, CurrentUser: ${gameProvider.currentUser?.uid}, DataLoadingAfterLogin: ${gameProvider.isDataLoadingAfterLogin}"); // DEBUG
          if (gameProvider.authLoading || (gameProvider.currentUser != null && gameProvider.isDataLoadingAfterLogin)) {
            print("[MyApp Consumer] Showing loading indicator"); // DEBUG
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (gameProvider.currentUser == null) {
            print("[MyApp Consumer] Showing LoginScreen"); // DEBUG
            return const LoginScreen();
          }
          print("[MyApp Consumer] Showing HomeScreen"); // DEBUG
          return const HomeScreen();
        },
      ),
    );
  }
}