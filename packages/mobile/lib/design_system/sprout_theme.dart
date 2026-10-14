import 'package:flutter/material.dart';

/// Cross-platform Balance Forward Evergreen Gold palette.
///
/// Keep these values synchronized with packages/web/src/index.css. Product
/// widgets should read from [Theme.of] for normal UI states and use these
/// constants only for stable semantic accents that ColorScheme does not name.
abstract final class SproutColors {
  static const canvas = Color(0xFFF8F3E8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSubtle = Color(0xFFFCFAF5);
  static const ink = Color(0xFF123C35);
  static const inkSoft = Color(0xFF294F47);
  static const muted = Color(0xFF536E67);
  static const mutedSoft = Color(0xFF687F79);
  static const border = Color(0xFFCBD9D2);
  static const borderStrong = Color(0xFFA8C0B6);
  static const brand = Color(0xFF17624F);
  static const brandStrong = Color(0xFF104B3D);
  static const brandBright = Color(0xFF1D755D);
  static const mint = Color(0xFFE4F1EB);
  static const mintStrong = Color(0xFF75B798);
  static const deepSurface = Color(0xFF0D302B);
  static const accent = Color(0xFFA66C00);
  static const accentSoft = Color(0xFFFFF2D2);
  static const warning = Color(0xFF8A5A00);
  static const warningSoft = Color(0xFFFFF2D2);
  static const info = Color(0xFF2C6791);
  static const infoSoft = Color(0xFFE1EEF9);
  static const purple = Color(0xFF6850A0);
  static const purpleSoft = Color(0xFFECE8F8);
  static const danger = Color(0xFFB65033);
  static const onDark = Color(0xFFFFFFFF);
}

/// Shared responsive contract for Apple and Android phone/tablet layouts.
abstract final class SproutLayout {
  static const phoneBreakpoint = 600.0;
  static const tabletBreakpoint = 840.0;
  static const wideBreakpoint = 1200.0;
  static const contentMaxWidth = 1280.0;
  static const readingMaxWidth = 1040.0;
  static const formMaxWidth = 480.0;

  static double pageGutterFor(double width) {
    if (width >= wideBreakpoint) return 48;
    if (width >= phoneBreakpoint) return 32;
    return 20;
  }

  static bool isTablet(double width) => width >= phoneBreakpoint;
}

abstract final class SproutTheme {
  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: SproutColors.brand,
          brightness: Brightness.light,
        ).copyWith(
          primary: SproutColors.brand,
          onPrimary: SproutColors.onDark,
          primaryContainer: SproutColors.mint,
          onPrimaryContainer: SproutColors.ink,
          secondary: SproutColors.accent,
          onSecondary: SproutColors.onDark,
          secondaryContainer: SproutColors.accentSoft,
          onSecondaryContainer: SproutColors.ink,
          surface: SproutColors.surface,
          onSurface: SproutColors.ink,
          error: SproutColors.danger,
          onError: SproutColors.onDark,
          outline: SproutColors.borderStrong,
          outlineVariant: SproutColors.border,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: SproutColors.canvas,
      dividerColor: SproutColors.border,
      appBarTheme: const AppBarTheme(
        backgroundColor: SproutColors.surface,
        foregroundColor: SproutColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: SproutColors.border)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: SproutColors.surface,
        labelStyle: const TextStyle(color: SproutColors.muted),
        hintStyle: const TextStyle(color: SproutColors.mutedSoft),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SproutColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SproutColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: SproutColors.brand, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SproutColors.brand,
          foregroundColor: SproutColors.onDark,
          disabledBackgroundColor: SproutColors.border,
          disabledForegroundColor: SproutColors.muted,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: SproutColors.brand),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: SproutColors.ink,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: SproutColors.ink,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: SproutColors.ink,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: SproutColors.ink),
        bodyMedium: TextStyle(color: SproutColors.ink),
        bodySmall: TextStyle(color: SproutColors.muted),
      ),
    );
  }
}

/// Constrains a screen to the universal content width while preserving a
/// finite height for Column/Expanded layouts. Set [includeGutter] for screens
/// that do not already own their internal horizontal padding.
class SproutResponsiveBody extends StatelessWidget {
  const SproutResponsiveBody({
    super.key,
    required this.child,
    this.maxContentWidth = SproutLayout.contentMaxWidth,
    this.includeGutter = false,
  });

  final Widget child;
  final double maxContentWidth;
  final bool includeGutter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gutter = includeGutter
            ? SproutLayout.pageGutterFor(constraints.maxWidth)
            : 0.0;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: SizedBox(
              width: double.infinity,
              height: constraints.maxHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: gutter),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
