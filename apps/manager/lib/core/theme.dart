import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

enum AppThemeOption { dark, cream }

class TbnColors {
  // Dark
  static const darkBackground = Color(0xFF0F1115);
  static const darkSurface = Color(0xFF171A20);
  static const darkSurface2 = Color(0xFF1F232B);
  static const darkBorder = Color(0xFF2A2F39);

  // Light ("cream")
  static const creamBackground = Color(0xFFF5F1EA);
  static const creamSurface = Color(0xFFFFFFFF);
  static const creamSurface2 = Color(0xFFF0EBE2);
  static const creamBorder = Color(0xFFE5DECF);

  // Brand + semantic
  static const accent = Color(0xFFC45F80);
  static const success = Color(0xFF3FAE7A);
  static const warning = Color(0xFFD9A045);
  static const danger = Color(0xFFD65C5C);
  static const info = Color(0xFF6C8FC4);
  static const mutedDark = Color(0xFF9AA3B2);
  static const mutedCream = Color(0xFF6F675B);
}

class _Palette {
  const _Palette({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.border,
    required this.text,
    required this.muted,
  });

  final Brightness brightness;
  final Color bg;
  final Color surface;
  final Color surface2;
  final Color border;
  final Color text;
  final Color muted;
}

const _darkPalette = _Palette(
  brightness: Brightness.dark,
  bg: TbnColors.darkBackground,
  surface: TbnColors.darkSurface,
  surface2: TbnColors.darkSurface2,
  border: TbnColors.darkBorder,
  text: Color(0xFFF3F4F6),
  muted: TbnColors.mutedDark,
);

const _creamPalette = _Palette(
  brightness: Brightness.light,
  bg: TbnColors.creamBackground,
  surface: TbnColors.creamSurface,
  surface2: TbnColors.creamSurface2,
  border: TbnColors.creamBorder,
  text: Color(0xFF1F1B16),
  muted: TbnColors.mutedCream,
);

ThemeData buildDarkTheme() => _build(_darkPalette);
ThemeData buildCreamTheme() => _build(_creamPalette);

TextTheme _textTheme(_Palette p) {
  final base = ThemeData(
    brightness: p.brightness,
    fontFamily: 'Inter',
  ).textTheme.apply(bodyColor: p.text, displayColor: p.text);

  TextStyle s(
    TextStyle? from,
    double size,
    FontWeight weight, {
    double letterSpacing = 0,
    double height = 1.3,
    Color? color,
  }) {
    return (from ?? const TextStyle()).copyWith(
      fontFamily: 'Inter',
      fontSize: size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      height: height,
      color: color ?? p.text,
    );
  }

  return base.copyWith(
    headlineLarge:
        s(base.headlineLarge, 30, FontWeight.w700, letterSpacing: -0.8),
    headlineMedium:
        s(base.headlineMedium, 26, FontWeight.w700, letterSpacing: -0.6),
    headlineSmall:
        s(base.headlineSmall, 22, FontWeight.w700, letterSpacing: -0.4),
    titleLarge:
        s(base.titleLarge, 20, FontWeight.w600, letterSpacing: -0.3),
    titleMedium: s(base.titleMedium, 16, FontWeight.w600),
    titleSmall: s(base.titleSmall, 14.5, FontWeight.w600),
    bodyLarge: s(base.bodyLarge, 16, FontWeight.w400, height: 1.45),
    bodyMedium: s(base.bodyMedium, 14, FontWeight.w400, height: 1.4),
    bodySmall: s(base.bodySmall, 12.5, FontWeight.w400,
        height: 1.35, color: p.muted),
    labelLarge: s(base.labelLarge, 14, FontWeight.w600),
    labelMedium: s(base.labelMedium, 12, FontWeight.w600,
        letterSpacing: 0.2),
    labelSmall: s(base.labelSmall, 11, FontWeight.w600,
        letterSpacing: 0.3, color: p.muted),
  );
}

OutlineInputBorder _inputBorder(Color color, [double width = 1]) {
  return OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: width),
  );
}

ThemeData _build(_Palette p) {
  final textTheme = _textTheme(p);
  final accentSoft = TbnColors.accent.withValues(alpha: 0.16);

  final scheme = ColorScheme(
    brightness: p.brightness,
    primary: TbnColors.accent,
    onPrimary: Colors.white,
    secondary: TbnColors.accent,
    onSecondary: Colors.white,
    error: TbnColors.danger,
    onError: Colors.white,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.muted,
    outline: p.border,
    outlineVariant: p.border,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface2,
    surfaceContainerHighest: p.surface2,
  );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    fontFamily: 'Inter',
    textTheme: textTheme,
    visualDensity: VisualDensity.standard,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        TargetPlatform.fuchsia: ZoomPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
      iconTheme: IconThemeData(color: p.text),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: p.border,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      iconColor: p.muted,
      titleTextStyle: textTheme.titleSmall,
      subtitleTextStyle: textTheme.bodySmall,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _inputBorder(Colors.transparent),
      enabledBorder: _inputBorder(p.border),
      focusedBorder: _inputBorder(TbnColors.accent, 1.5),
      errorBorder: _inputBorder(TbnColors.danger),
      focusedErrorBorder: _inputBorder(TbnColors.danger, 1.5),
      labelStyle: TextStyle(color: p.muted),
      hintStyle: TextStyle(color: p.muted),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: buttonShape,
        foregroundColor: p.text,
        side: BorderSide(color: p.border),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TbnColors.accent,
        shape: buttonShape,
        textStyle: textTheme.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: p.text),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: accentSoft,
      side: BorderSide(color: p.border),
      shape: const StadiumBorder(),
      showCheckmark: false,
      labelStyle: textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        side: BorderSide(color: p.border),
        selectedBackgroundColor: accentSoft,
        selectedForegroundColor: p.text,
        foregroundColor: p.muted,
        textStyle: textTheme.labelLarge,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: p.border),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surface,
      modalBackgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.surface2,
      contentTextStyle: textTheme.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: accentSoft,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontFamily: 'Inter',

          fontSize: 10.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? p.text : p.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          size: 24,
          color: selected ? TbnColors.accent : p.muted,
        );
      }),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: p.surface,
      useIndicator: true,
      indicatorColor: accentSoft,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minExtendedWidth: 220,
      selectedIconTheme: const IconThemeData(color: TbnColors.accent),
      unselectedIconTheme: IconThemeData(color: p.muted),
      selectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',

        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: p.text,
      ),
      unselectedLabelTextStyle: TextStyle(
          fontFamily: 'Inter',

        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: p.muted,
      ),
    ),
  );
}
