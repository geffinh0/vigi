import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'vigi_palette.dart';
import 'vigi_tokens.dart';

/// Tema claro do Vigi: Linho domina, Petróleo estrutura, Âmbar chama atenção.
final ThemeData appTheme = _buildTheme(
  brightness: Brightness.light,
  palette: VigiPalette.light,
);

/// Tema noturno: ativado pelo modo Sono, ou pelo tema escuro do sistema.
final ThemeData vigiNightTheme = _buildTheme(
  brightness: Brightness.dark,
  palette: VigiPalette.night,
);

ThemeData _buildTheme({
  required Brightness brightness,
  required VigiPalette palette,
}) {
  final isDark = brightness == Brightness.dark;
  final textTheme = AppTypography.textTheme(palette.text, palette.textMuted);

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: palette.fill,
    onPrimary: palette.onFill,
    secondary: VigiColors.ambar500,
    onSecondary: VigiColors.petroleo800,
    // Erro de formulário nunca é vermelho: o vermelho é só de socorro.
    error: palette.textMuted,
    onError: palette.surface,
    surface: palette.background,
    onSurface: palette.text,
    onSurfaceVariant: palette.textMuted,
    outline: palette.fieldBorder,
    outlineVariant: palette.border,
    surfaceContainerLowest: palette.surface,
    surfaceContainerLow: palette.surface,
    surfaceContainer: palette.surface,
    surfaceContainerHigh: palette.surface,
    surfaceContainerHighest: palette.chip,
    surfaceTint: Colors.transparent,
  );

  OutlineInputBorder fieldBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(VigiRadius.sm),
        borderSide: BorderSide(color: color, width: width),
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(VigiRadius.md),
  );
  const buttonPadding = EdgeInsets.symmetric(
    horizontal: VigiSpace.x6,
    vertical: VigiSpace.x4,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: AppTypography.bodyFamily,
    scaffoldBackgroundColor: palette.background,
    canvasColor: palette.background,
    colorScheme: colorScheme,
    textTheme: textTheme,
    extensions: [palette],
    splashColor: palette.text.withValues(alpha: 0.08),
    highlightColor: palette.text.withValues(alpha: 0.06),
    iconTheme: IconThemeData(color: palette.text, size: VigiSizes.icon),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.background,
      foregroundColor: palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: VigiSizes.button,
      titleSpacing: VigiSpace.x2,
      iconTheme: IconThemeData(color: palette.text, size: VigiSizes.icon),
      titleTextStyle: AppTypography.h2.copyWith(color: palette.text),
    ),
    // Elevação é feita por cor, não por sombra.
    cardTheme: CardThemeData(
      color: palette.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VigiRadius.md),
        side: BorderSide(color: palette.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surface,
      constraints: const BoxConstraints(minHeight: VigiSizes.button),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: VigiSpace.x4,
        vertical: 18,
      ),
      border: fieldBorder(palette.fieldBorder),
      enabledBorder: fieldBorder(palette.fieldBorder),
      focusedBorder: fieldBorder(palette.text, 2),
      errorBorder: fieldBorder(palette.textMuted, 2),
      focusedErrorBorder: fieldBorder(palette.text, 2),
      hintStyle: AppTypography.bodyLarge.copyWith(color: palette.textMuted),
      errorStyle: AppTypography.caption.copyWith(
        color: palette.textMuted,
        fontWeight: FontWeight.w700,
      ),
      helperStyle: AppTypography.caption.copyWith(color: palette.textMuted),
      errorMaxLines: 3,
      helperMaxLines: 3,
      suffixIconColor: palette.textMuted,
      prefixIconColor: palette.text,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.fill,
        foregroundColor: palette.onFill,
        elevation: 0,
        minimumSize: const Size(VigiSizes.button, VigiSizes.button),
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: AppTypography.label,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.fill,
        foregroundColor: palette.onFill,
        minimumSize: const Size(VigiSizes.button, VigiSizes.button),
        padding: buttonPadding,
        shape: buttonShape,
        textStyle: AppTypography.label,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.text,
        minimumSize: const Size(VigiSizes.button, VigiSizes.button),
        padding: buttonPadding,
        side: BorderSide(color: palette.text, width: 2),
        shape: buttonShape,
        textStyle: AppTypography.label,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.text,
        minimumSize: const Size(VigiSizes.touch, VigiSizes.touch),
        padding: const EdgeInsets.symmetric(
          horizontal: VigiSpace.x4,
          vertical: VigiSpace.x3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VigiRadius.sm),
        ),
        textStyle: AppTypography.label,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.text,
        minimumSize: const Size(VigiSizes.touch, VigiSizes.touch),
        iconSize: VigiSizes.icon,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.fill,
      foregroundColor: palette.onFill,
      elevation: 0,
    ),
    dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.text),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VigiRadius.lg),
        side: BorderSide(color: palette.border),
      ),
      titleTextStyle: AppTypography.h3.copyWith(color: palette.text),
      contentTextStyle: AppTypography.bodyLarge.copyWith(color: palette.text),
      actionsPadding: const EdgeInsets.fromLTRB(
        VigiSpace.x4,
        0,
        VigiSpace.x4,
        VigiSpace.x4,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.background,
      modalBackgroundColor: palette.background,
      elevation: 0,
      modalElevation: 0,
      showDragHandle: true,
      dragHandleColor: palette.fieldBorder,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VigiRadius.lg),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.fill,
      contentTextStyle: AppTypography.bodyMedium.copyWith(
        color: palette.onFill,
      ),
      actionTextColor: isDark ? VigiColors.ambar700 : VigiColors.ambar500,
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VigiRadius.sm),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 76,
      indicatorColor: palette.chip,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => AppTypography.caption.copyWith(
          color: palette.text,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w400,
        ),
      ),
      iconTheme: WidgetStateProperty.all(
        IconThemeData(color: palette.text, size: VigiSizes.icon),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: palette.text,
      textColor: palette.text,
      titleTextStyle: AppTypography.bodyLarge.copyWith(color: palette.text),
      subtitleTextStyle: AppTypography.bodyMedium.copyWith(
        color: palette.textMuted,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.chip,
      selectedColor: palette.fill,
      labelStyle: AppTypography.bodyMedium.copyWith(color: palette.text),
      secondaryLabelStyle: AppTypography.bodyMedium.copyWith(
        color: palette.onFill,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(VigiRadius.sm),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: palette.fill,
        borderRadius: BorderRadius.circular(VigiRadius.sm),
      ),
      textStyle: AppTypography.caption.copyWith(color: palette.onFill),
    ),
  );
}
