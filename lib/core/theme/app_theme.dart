import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Tema central do Guardião — light, paleta 60/30/10.
///
/// Definido como top-level `final` conforme spec do Stage 2.
final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.linho,
  colorScheme: const ColorScheme.light(
    primary: AppColors.petroleo,
    secondary: AppColors.ambar,
    error: AppColors.panico,
    surface: AppColors.linho,
    onPrimary: AppColors.linho,
    onSecondary: AppColors.petroleo,
    onSurface: AppColors.petroleo,
    onError: AppColors.linho,
  ),
  textTheme: GoogleFonts.atkinsonHyperlegibleTextTheme(),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.linho,
    elevation: 0,
    scrolledUnderElevation: 0.5,
    centerTitle: true,
    iconTheme: IconThemeData(color: AppColors.petroleo),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.petroleo,
    ),
  ),
  cardTheme: CardThemeData(
    color: AppColors.linho,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: AppColors.linhoEscuro),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.linhoEscuro),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.linhoEscuro),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.petroleo, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.cinzaTexto),
    ),
    labelStyle: const TextStyle(color: AppColors.cinzaTexto),
    hintStyle: TextStyle(color: AppColors.cinzaTexto.withValues(alpha: 0.6)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.ambar,
      foregroundColor: AppColors.petroleo,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: AppColors.ambar,
    foregroundColor: AppColors.petroleo,
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.linhoEscuro,
    thickness: 1,
  ),
  chipTheme: ChipThemeData(
    selectedColor: AppColors.petroleo,
    backgroundColor: Colors.white,
    labelStyle: const TextStyle(color: AppColors.petroleo),
    secondaryLabelStyle: const TextStyle(color: AppColors.linho),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.linhoEscuro),
    ),
  ),
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.linho,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
);
