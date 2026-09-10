import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design tokens and Material 3 themes for Shiftly.
class AppTheme {
  AppTheme._();

  // ── Brand & surfaces ──────────────────────────────────────────────
  static const Color primary = Color(0xFF38BDF8);
  static const Color primaryDark = Color(0xFF0EA5E9);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);

  // ── Semantic ──────────────────────────────────────────────────────
  static const Color profit = Color(0xFF22C55E);
  static const Color profitSoft = Color(0xFF16A34A);
  static const Color expense = Color(0xFFF87171);
  static const Color expenseSoft = Color(0xFFEF4444);
  static const Color warning = Color(0xFFFBBF24);
  static const Color warningSoft = Color(0xFFF59E0B);

  // ── Spacing scale ─────────────────────────────────────────────────
  static const double spaceXs = 8;
  static const double spaceSm = 16;
  static const double spaceMd = 24;
  static const double spaceLg = 32;
  static const double spaceXl = 40;

  // ── Radii ─────────────────────────────────────────────────────────
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // ── Typography helpers ────────────────────────────────────────────
  static const TextStyle monoNumber = TextStyle(
    fontFamily: 'monospace',
    fontFeatures: [FontFeature.tabularFigures()],
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      surface: isDark ? darkBackground : lightBackground,
      onSurface: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
      surfaceContainerHighest: isDark
          ? const Color(0xFF334155)
          : const Color(0xFFE2E8F0),
      outline: isDark ? darkBorder : lightBorder,
      outlineVariant: isDark ? darkBorder.withValues(alpha: 0.6) : lightBorder,
      error: expenseSoft,
    ).copyWith(secondary: primaryDark, tertiary: profit);

    final cardColor = isDark ? darkCard : lightCard;
    final borderColor = isDark ? darkBorder : lightBorder;
    final inputFill = isDark
        ? darkCard.withValues(alpha: 0.7)
        : const Color(0xFFF1F5F9);

    final baseText = Typography.material2021(platform: TargetPlatform.android)
        .black
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      textTheme: baseText.copyWith(
        displayLarge: baseText.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -1,
        ),
        displayMedium: baseText.displayMedium?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        headlineLarge: baseText.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        headlineMedium: baseText.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: baseText.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 14),
        bodySmall: baseText.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface.withValues(alpha: 0.65),
        ),
        labelLarge: baseText.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: colorScheme.onSurface,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          side: BorderSide(color: borderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceSm,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: expense, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: expenseSoft, width: 1.5),
        ),
        labelStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primary,
          foregroundColor: const Color(0xFF0F172A),
          // Size.fromHeight(h) is Size(infinity, h) and breaks buttons in Rows.
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: spaceMd),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: spaceMd),
          side: BorderSide(color: borderColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusSm),
            ),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide.none,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      dividerTheme: DividerThemeData(
        color: borderColor.withValues(alpha: 0.6),
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        backgroundColor: cardColor,
        elevation: 8,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceSm,
          vertical: 4,
        ),
      ),
      expansionTileTheme: ExpansionTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        tilePadding: const EdgeInsets.symmetric(
          horizontal: spaceSm + 4,
          vertical: spaceXs,
        ),
        childrenPadding: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.35);
          }
          return null;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: colorScheme.onSurface.withValues(alpha: 0.5),
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  /// Soft section container used to group form fields.
  static BoxDecoration sectionDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark
          ? darkCard.withValues(alpha: 0.55)
          : Colors.white.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radiusMd),
      border: Border.all(color: isDark ? darkBorder : lightBorder, width: 1),
    );
  }

  static IconData iconForJobName(String? name) {
    if (name == null) return Icons.work_outline_rounded;
    if (name.contains('מזנון')) return Icons.restaurant_rounded;
    if (name.contains('סדרן')) return Icons.confirmation_number_outlined;
    return Icons.work_outline_rounded;
  }
}

/// Scales down slightly on press for tactile micro-interaction.
class ScalePress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const ScalePress({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  @override
  State<ScalePress> createState() => _ScalePressState();
}

class _ScalePressState extends State<ScalePress> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
