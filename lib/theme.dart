import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF0F1117);
  static const surface = Color(0xFF1A1D27);
  static const surface2 = Color(0xFF22263A);
  static const border = Color(0xFF2E3249);
  static const accent = Color(0xFF4F6EF7);
  static const danger = Color(0xFFE05A5A);
  static const success = Color(0xFF3EC97C);
  static const warning = Color(0xFFF0A732);
  static const text = Color(0xFFE8EAF6);
  static const muted = Color(0xFF8B90A8);
}

ThemeData buildTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: C.accent,
        surface: C.surface,
        onPrimary: Colors.white,
        onSurface: C.text,
      ),
      scaffoldBackgroundColor: C.bg,
      appBarTheme: const AppBarTheme(
        backgroundColor: C.surface,
        foregroundColor: C.text,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: C.text),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: C.surface,
        indicatorColor: C.accent.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, color: C.muted)),
        iconTheme: WidgetStateProperty.all(
            const IconThemeData(color: C.muted)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: C.surface2,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: C.accent, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: C.danger)),
        labelStyle: const TextStyle(color: C.muted, fontSize: 13),
        hintStyle: const TextStyle(color: C.muted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: C.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: C.accent.withOpacity(0.4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: C.muted,
          side: const BorderSide(color: C.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
          textStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: C.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: C.border),
        ),
        margin: EdgeInsets.zero,
      ),
    );
