import 'package:flutter/material.dart';

class AppTheme {
  static const Color accent = Color(0xFF0F6CBD);

  static final ThemeData light = _build(Brightness.light);
  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF202020)
        : const Color(0xFFF5F5F5);
    final surface = isDark ? const Color(0xFF292929) : const Color(0xFFFFFFFF);
    final subtleSurface = isDark
        ? const Color(0xFF323232)
        : const Color(0xFFFAFAFA);
    final outline = isDark ? const Color(0xFF484848) : const Color(0xFFD1D1D1);
    final onSurface = isDark
        ? const Color(0xFFF5F5F5)
        : const Color(0xFF242424);
    final onSurfaceVariant = isDark
        ? const Color(0xFFC7C7C7)
        : const Color(0xFF616161);
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          onPrimary: Colors.white,
          surface: surface,
          onSurface: onSurface,
          onSurfaceVariant: onSurfaceVariant,
          outline: outline,
          outlineVariant: outline.withValues(alpha: 0.72),
        );
    const controlRadius = BorderRadius.all(Radius.circular(6));
    const surfaceRadius = BorderRadius.all(Radius.circular(10));

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Segoe UI',
      scaffoldBackgroundColor: background,
      canvasColor: background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FluentPageTransitionsBuilder(),
          TargetPlatform.windows: _FluentPageTransitionsBuilder(),
          TargetPlatform.linux: _FluentPageTransitionsBuilder(),
          TargetPlatform.macOS: _FluentPageTransitionsBuilder(),
          TargetPlatform.iOS: _FluentPageTransitionsBuilder(),
          TargetPlatform.fuchsia: _FluentPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: background,
        foregroundColor: onSurface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontFamily: 'Segoe UI',
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.all(12),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: surfaceRadius,
          side: BorderSide(color: outline.withValues(alpha: 0.82)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: subtleSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: controlRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: outline.withValues(alpha: 0.72),
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(40, 42),
          shape: const RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(40, 42),
          side: BorderSide(color: outline),
          shape: const RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: controlRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: const RoundedRectangleBorder(borderRadius: controlRadius),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: accent.withValues(alpha: isDark ? 0.32 : 0.16),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: controlRadius,
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
            fontSize: 12,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: accent.withValues(alpha: isDark ? 0.32 : 0.16),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: controlRadius,
        ),
        selectedIconTheme: const IconThemeData(color: accent),
        selectedLabelTextStyle: const TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: const RoundedRectangleBorder(borderRadius: surfaceRadius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFFF5F5F5)
            : const Color(0xFF242424),
        contentTextStyle: TextStyle(
          color: isDark ? const Color(0xFF242424) : const Color(0xFFF5F5F5),
        ),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
      ),
      listTileTheme: const ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: controlRadius),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: surfaceRadius),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: controlRadius),
          ),
          side: WidgetStatePropertyAll(BorderSide(color: outline)),
        ),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? accent : outline,
        ),
        thumbColor: const WidgetStatePropertyAll(Colors.white),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      chipTheme: ChipThemeData(
        backgroundColor: subtleSurface,
        selectedColor: accent.withValues(alpha: isDark ? 0.32 : 0.16),
        side: BorderSide(color: outline),
        shape: const RoundedRectangleBorder(borderRadius: controlRadius),
      ),
    );
  }
}

class _FluentPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FluentPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.018, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
