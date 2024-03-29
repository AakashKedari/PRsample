
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class CustomTheme with ChangeNotifier {
  ThemeMode currentTheme = ThemeMode.system;

  void setTheme(ThemeMode themeMode) {
    currentTheme = themeMode;
    notifyListeners();
  }

  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: primarySwatch),
// elevatedButtonTheme: ElevatedButtonThemeData(style: ButtonStyle(backgroundColor: primarySwatch)),
        // colorScheme: ColorScheme.light(), // Make sure it's compatible with Brightness.light
        useMaterial3: false,
        primarySwatch: primarySwatch,
        primaryColor: Colors.white,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.poppinsTextTheme(
          TextTheme(
            bodyLarge: TextStyle(
              color: drawerTextColorsLightTheme,
            ),
            bodyMedium: TextStyle(color: drawerTextColorsLightTheme),
            bodySmall: TextStyle(color: drawerTextColorsLightTheme),
            titleLarge: TextStyle(color: drawerTextColorsLightTheme),
            titleMedium: TextStyle(color: drawerTextColorsLightTheme),
            titleSmall: TextStyle(color: drawerTextColorsLightTheme),
          ),
        ).copyWith(),
        appBarTheme: const AppBarTheme(
            backgroundColor: drawerColorsLightTheme,
            titleTextStyle: TextStyle(color: drawerTextColorsLightTheme),
            iconTheme: IconThemeData(color: drawerTextColorsLightTheme)),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: drawerColorsLightTheme,
        ),
        drawerTheme:
            const DrawerThemeData(backgroundColor: drawerColorsLightTheme),
        // dialogTheme: DialogTheme(backgroundColor: Colors.grey.shade400),
        iconTheme: const IconThemeData(color: drawerIconColorsLightTheme),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: drawerColorsLightTheme),
        dropdownMenuTheme: const DropdownMenuThemeData(
            inputDecorationTheme: InputDecorationTheme()));
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
        useMaterial3: false,
        primarySwatch: primarySwatch,
        primaryColor: Colors.black,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        // Define other dark theme properties
        textTheme: GoogleFonts.poppinsTextTheme(const TextTheme(
          bodyLarge: TextStyle(color: drawerTextColorsDarkTheme),
          bodyMedium: TextStyle(color: drawerTextColorsDarkTheme),
          bodySmall: TextStyle(color: drawerTextColorsDarkTheme),
          titleLarge: TextStyle(color: drawerTextColorsDarkTheme),
          titleMedium: TextStyle(color: drawerTextColorsDarkTheme),
          titleSmall: TextStyle(color: drawerTextColorsDarkTheme),
        )),
        appBarTheme: const AppBarTheme(
            backgroundColor: drawerColorsDarkTheme,
            titleTextStyle: TextStyle(color: drawerTextColorsDarkTheme),
            iconTheme: IconThemeData(color: drawerTextColorsDarkTheme)),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: drawerColorsDarkTheme,
        ),
        drawerTheme:
            const DrawerThemeData(backgroundColor: drawerColorsDarkTheme),
        dialogTheme: DialogTheme(backgroundColor: Colors.grey.shade400),
        iconTheme: const IconThemeData(color: drawerIconColorsDarkTheme),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: drawerColorsDarkTheme),
        dropdownMenuTheme: const DropdownMenuThemeData(
            inputDecorationTheme: InputDecorationTheme()));
  }
}
