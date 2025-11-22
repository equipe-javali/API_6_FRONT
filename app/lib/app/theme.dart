import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Cores baseadas no wireframe
  static const Color backgroundColor =
      Color(0xFF1A1A1A); // Fundo escuro principal
  static const Color surfaceColor = Color(0xFF2D2D2D); // Cards e superfícies
  static const Color primaryColor = Color(0xFF7968D8); // Roxo dos botões
  static const Color accentColor = Color(0xFF7968D8); // Azul cyan dos ícones
  static const Color textPrimaryColor =
      Color(0xFF7968D8); // Texto principal branco
  static const Color textSecondaryColor =
      Color(0xFFB0B0B0); // Texto secundário cinza
  static const Color borderColor = Color(0xFF404040); // Bordas dos inputs
  static const Color successColor = Color(0xFF4CAF50); // Verde (sucesso)
  static const Color errorColor = Color(0xFFF44336); // Vermelho (erro)
  static const Color neutralWhite = Colors.white; // Branco (alertas)

  // Tema escuro (principal baseado no wireframe)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: accentColor,
      surface: surfaceColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textPrimaryColor,
    ),
    textTheme: GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme.copyWith(
            headlineLarge: const TextStyle(
              color: textPrimaryColor,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            headlineMedium: const TextStyle(
              color: textPrimaryColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
            bodyLarge: const TextStyle(
              color: textPrimaryColor,
              fontSize: 16,
            ),
            bodyMedium: const TextStyle(
              color: textSecondaryColor,
              fontSize: 14,
            ),
          ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textPrimaryColor,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 16.0,
          horizontal: 32.0,
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      // Corrigido: CardTheme → CardThemeData
      color: surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: borderColor, width: 1),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: textSecondaryColor),
      hintStyle: const TextStyle(color: textSecondaryColor),
      prefixIconColor: accentColor,
      suffixIconColor: textSecondaryColor,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(
      textColor: textPrimaryColor,
      iconColor: accentColor,
    ),
  );

  // Tema claro (simplificado para compatibilidade)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: accentColor,
    ),
    textTheme: GoogleFonts.interTextTheme(),
  );
}
