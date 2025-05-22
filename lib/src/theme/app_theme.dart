import 'package:flutter/material.dart';

class AppTheme {
  // New color palette inspired by the screenshot
  static const Color fhBgDark = Color(0xFF0A192F); // Deep navy blue
  static const Color fhBgMedium = Color(0xFF172A46); // Dark slate blue
  static const Color fhBgLight = Color(0xFF243B68); // Lighter slate blue, for card/element backgrounds
  static const Color fhBorderColor = Color(0xFF3A506B); // Muted blue for borders

  static const Color fhTextPrimary = Color(0xFFE0E1DD); // Off-white/Light cyan for primary text
  static const Color fhTextSecondary = Color(0xFFA9B4C2); // Light grayish blue for secondary text

  static const Color fhAccentTeal = Color(0xFF64FFDA); // Bright teal/cyan - primary accent
  static const Color fhAccentLightCyan = Color(0xFF7DF9FF); // Lighter cyan/aqua - secondary accent
  static const Color fhAccentOrange = Color(0xFFFF9F1C); // Orange for warnings/highlights
  static const Color fhAccentPurple = Color(0xFF9D79D9); // A distinct purple/lavender
  static const Color fhAccentBrightBlue = Color(0xFF50A0FF); // A general bright blue
  static const Color fhAccentGreen = Color(0xFF2ECC71); // Green for success/positive
  static const Color fhAccentRed = Color(0xFFE74C3C); // Red for error/negative

  // Retaining original font names, styling will be adjusted
  static const String fontMain = 'RobotoCondensed';
  static const String fontBody = 'OpenSans';

  static final ThemeData themeData = ThemeData(
    brightness: Brightness.dark,
    primaryColor: fhAccentTeal, // Main accent color
    colorScheme: const ColorScheme.dark(
      primary: fhAccentTeal,
      secondary: fhAccentLightCyan,
      surface: fhBgMedium, 
      error: fhAccentRed,
      onPrimary: fhBgDark, // Text on primary accent buttons
      onSecondary: fhBgDark, 
      onSurface: fhTextPrimary,
    ),
    scaffoldBackgroundColor: fhBgDark,
    appBarTheme: AppBarTheme(
      backgroundColor: fhBgDark.withOpacity(0.85),
      elevation: 0, // Flatter look like screenshot
      iconTheme: const IconThemeData(color: fhTextSecondary, size: 22),
      titleTextStyle: const TextStyle(fontFamily: fontMain, color: fhAccentTeal, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: fontBody, color: fhTextPrimary, fontSize: 15, height: 1.4),
      bodyMedium: TextStyle(fontFamily: fontBody, color: fhTextPrimary, fontSize: 13, height: 1.4),
      bodySmall: TextStyle(fontFamily: fontBody, color: fhTextSecondary, fontSize: 11, height: 1.3),
      
      displayLarge: TextStyle(fontFamily: fontMain, color: fhAccentTeal, fontWeight: FontWeight.w600, fontSize: 28),
      displayMedium: TextStyle(fontFamily: fontMain, color: fhAccentTeal, fontWeight: FontWeight.w600, fontSize: 24),
      displaySmall: TextStyle(fontFamily: fontMain, color: fhAccentTeal, fontWeight: FontWeight.w500, fontSize: 20),

      headlineLarge: TextStyle(fontFamily: fontMain, color: fhTextPrimary, fontWeight: FontWeight.bold, fontSize: 20),
      headlineMedium: TextStyle(fontFamily: fontMain, color: fhTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      headlineSmall: TextStyle(fontFamily: fontMain, color: fhTextPrimary, fontWeight: FontWeight.w500, fontSize: 16),
      
      titleLarge: TextStyle(fontFamily: fontMain, color: fhTextPrimary, fontWeight: FontWeight.bold, fontSize: 15),
      titleMedium: TextStyle(fontFamily: fontBody, color: fhTextPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      titleSmall: TextStyle(fontFamily: fontBody, color: fhTextSecondary, fontSize: 12),
      
      labelLarge: TextStyle(fontFamily: fontMain, color: fhBgDark, fontWeight: FontWeight.bold, letterSpacing: 0.8, fontSize: 14), // For buttons
      labelMedium: TextStyle(fontFamily: fontMain, color: fhTextSecondary, letterSpacing: 0.6, fontSize: 11),
      labelSmall: TextStyle(fontFamily: fontMain, color: fhTextSecondary, letterSpacing: 0.5, fontSize: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: fhAccentTeal,
        foregroundColor: fhBgDark, // Dark text on light accent button
        textStyle: const TextStyle(fontFamily: fontMain, letterSpacing: 0.8, fontWeight: FontWeight.bold, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
        elevation: 2,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: fhAccentTeal, width: 1.5),
        foregroundColor: fhAccentTeal,
        textStyle: const TextStyle(fontFamily: fontMain, letterSpacing: 0.8, fontWeight: FontWeight.bold, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: fhAccentLightCyan,
        textStyle: const TextStyle(fontFamily: fontMain, letterSpacing: 0.5, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: fhBgMedium.withOpacity(0.7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      hintStyle: const TextStyle(color: fhTextSecondary, fontFamily: fontBody, fontSize: 13),
      labelStyle: const TextStyle(color: fhTextSecondary, fontFamily: fontBody, fontSize: 13, fontWeight: FontWeight.w500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: const BorderSide(color: fhBorderColor, width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: const BorderSide(color: fhBorderColor, width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: const BorderSide(color: fhAccentTeal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: const BorderSide(color: fhAccentRed, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4.0),
        borderSide: const BorderSide(color: fhAccentRed, width: 1.5),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: fhAccentTeal,
      linearTrackColor: fhBgLight,
      circularTrackColor: fhBgLight,
      linearMinHeight: 6,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: fhBgLight,
      labelStyle: const TextStyle(color: fhTextPrimary, fontFamily: fontMain, fontSize: 11),
      selectedColor: fhAccentTeal,
      secondarySelectedColor: fhAccentTeal,
      disabledColor: fhBorderColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: Colors.transparent), // No border by default
    ),
    tabBarTheme: const TabBarTheme(
      labelColor: fhAccentTeal,
      unselectedLabelColor: fhTextSecondary,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: fhAccentTeal, width: 3.0),
      ),
      labelStyle: TextStyle(fontFamily: fontMain, fontWeight: FontWeight.bold, letterSpacing: 0.7, fontSize: 13),
      unselectedLabelStyle: TextStyle(fontFamily: fontMain, letterSpacing: 0.7, fontSize: 13),
      indicatorSize: TabBarIndicatorSize.label, // Indicator only under the label
    ),
    iconTheme: const IconThemeData(
      color: fhTextSecondary,
      size: 20,
    ),
    tooltipTheme: TooltipThemeData(
      preferBelow: false,
      textStyle: const TextStyle(fontSize: 11, color: fhBgDark, fontFamily: fontBody, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: fhAccentLightCyan.withOpacity(0.95),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: fhBorderColor.withOpacity(0.6),
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardTheme(
      color: fhBgLight, // Use lighter background for cards
      elevation: 0, // Flatter design
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6.0),
        side: BorderSide(color: fhBorderColor.withOpacity(0.7), width: 1), // Subtle border
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0), // Default card margin
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: fhTextSecondary,
      textColor: fhTextPrimary,
      titleTextStyle: TextStyle(fontFamily: fontBody, fontSize: 14, fontWeight: FontWeight.w500),
      subtitleTextStyle: TextStyle(fontFamily: fontBody, fontSize: 12, color: fhTextSecondary),
      minVerticalPadding: 10,
      dense: false, // Less dense for clearer items
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return fhAccentTeal;
        }
        return fhTextSecondary.withOpacity(0.8);
      }),
      trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          return fhAccentTeal.withOpacity(0.4);
        }
        return fhBorderColor.withOpacity(0.5);
      }),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: fhBgMedium,
      titleTextStyle: const TextStyle(fontFamily: fontMain, color: fhTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      contentTextStyle: const TextStyle(fontFamily: fontBody, color: fhTextPrimary, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 4,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: fhBgDark.withOpacity(0.95), // Darker, slightly transparent
        selectedItemColor: fhAccentTeal,
        unselectedItemColor: fhTextSecondary.withOpacity(0.7),
        selectedLabelStyle: const TextStyle(fontSize: 10, fontFamily: AppTheme.fontMain, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10, fontFamily: AppTheme.fontMain),
        type: BottomNavigationBarType.fixed,
        elevation: 2, // Subtle elevation
    )
  );
}