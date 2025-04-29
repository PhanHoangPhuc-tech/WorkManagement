import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // --- Static Getters for Themes ---
  static ThemeData get lightTheme => ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF005AE0),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF005AE0),
      primary: const Color(0xFF005AE0),
      brightness: Brightness.light,
      secondary: Colors.amber.shade700,
      surface: Colors.white,
      error: Colors.red.shade700,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFFFAFAFA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF005AE0),
      foregroundColor: Colors.white,
      elevation: 1,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF005AE0),
      foregroundColor: Colors.white,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF005AE0);
        }
        return null;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: WidgetStateBorderSide.resolveWith((states) {
        if (!states.contains(WidgetState.selected)) {
          return BorderSide(color: Colors.grey[600]!, width: 2);
        }
        return null;
      }),
    ),
    listTileTheme: const ListTileThemeData(iconColor: Color(0xFF5f6368)),
    dividerTheme: DividerThemeData(
      color: Colors.grey[300],
      space: 1,
      thickness: 1,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey.shade200,
      disabledColor: Colors.grey.shade400,
      selectedColor: const Color(0xFF005AE0),
      secondarySelectedColor: const Color(0xFF005AE0),
      labelStyle: const TextStyle(color: Colors.black87),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      brightness: Brightness.light,
      side: BorderSide.none,
      showCheckmark: true,
      checkmarkColor: Colors.white,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF005AE0),
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed,
      elevation: 4.0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      labelStyle: TextStyle(color: Colors.grey.shade700),
      border: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF005AE0), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade400, width: 1.0),
      ),
      prefixIconColor: Colors.grey.shade600,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF005AE0)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF005AE0),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF005AE0),
        side: const BorderSide(color: Color.fromRGBO(0, 90, 224, 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    cardTheme: CardTheme(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
    ),
  );

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF699EF7),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF005AE0),
      primary: const Color(0xFF699EF7),
      brightness: Brightness.dark,
      secondary: Colors.amberAccent[100]!,
      surface: const Color(0xFF2A2A2A),
      error: Colors.redAccent[100]!,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onError: Colors.black,
    ),
    scaffoldBackgroundColor: const Color(0xFF1E1E1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2A2A2A),
      foregroundColor: Colors.white,
      elevation: 1,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF699EF7),
      foregroundColor: Colors.black,
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF699EF7);
        }
        return Colors.grey[700];
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: BorderSide(color: Colors.grey[600]!),
    ),
    listTileTheme: ListTileThemeData(iconColor: Colors.grey[400]),
    dividerTheme: DividerThemeData(
      color: Colors.grey[800],
      space: 1,
      thickness: 1,
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: Colors.grey[400],
      collapsedIconColor: Colors.grey[500],
      textColor: Colors.white,
      collapsedTextColor: Colors.grey[300],
      backgroundColor: const Color(0xFF2A2A2A),
      collapsedBackgroundColor: Colors.transparent,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: const Color(0xFF2A2A2A),
      selectedItemColor: const Color(0xFF699EF7),
      unselectedItemColor: Colors.grey[500],
      type: BottomNavigationBarType.fixed,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.grey[800],
      disabledColor: Colors.grey[600],
      selectedColor: const Color(0xFF699EF7),
      secondarySelectedColor: const Color(0xFF699EF7),
      labelStyle: TextStyle(color: Colors.grey[300]),
      secondaryLabelStyle: const TextStyle(color: Colors.black),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      brightness: Brightness.dark,
      side: BorderSide.none,
      showCheckmark: true,
      checkmarkColor: Colors.black,
    ),
    textTheme: Typography.whiteMountainView.apply(
      bodyColor: Colors.grey[200],
      displayColor: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.grey[400]),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF699EF7)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF699EF7),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF699EF7),
        side: const BorderSide(color: Color.fromRGBO(105, 158, 247, 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
    ),
    dialogTheme: DialogTheme(
      backgroundColor: const Color(0xFF2A2A2A),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      contentTextStyle: TextStyle(color: Colors.grey[300]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF333333),
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: const Color(0xFF333333),
      textStyle: TextStyle(color: Colors.grey[200]),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF2A2A2A),
      modalBackgroundColor: Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF699EF7);
        }
        return Colors.grey[400];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF699EF7).withAlpha(128);
        }
        return Colors.grey[800];
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      labelStyle: TextStyle(color: Colors.grey.shade400),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Color(0xFF699EF7), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey.shade700, width: 1.0),
      ),
      prefixIconColor: Colors.grey.shade400,
    ),
    cardTheme: CardTheme(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: const Color(0xFF2A2A2A),
    ),
  );
}
