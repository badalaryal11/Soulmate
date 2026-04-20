import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemeTokens {
  static const Color primary = Color(0xFFFE3C72);
  static const Color primaryDeep = Color(0xFFE31D5C);
  static const Color primarySoft = Color(0xFFFFE6ED);
  static const Color accent = Color(0xFFFFB44A);

  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 24;

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
}

class AppTheme {
  static ThemeData light() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppThemeTokens.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppThemeTokens.primary,
          secondary: AppThemeTokens.accent,
          surface: Colors.white,
          surfaceContainerHighest: const Color(0xFFF6F0F2),
          outline: const Color(0xFFEBDDE2),
        );

    final textTheme = _buildTextTheme(Brightness.light);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFFFF8FA),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: Colors.white,
        enabledBorderColor: const Color(0xFFE7DCE0),
        focusedBorderColor: AppThemeTokens.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppThemeTokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
          ),
          elevation: 0,
          shadowColor: Colors.transparent,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppThemeTokens.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppThemeTokens.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppThemeTokens.primary;
          }
          return null;
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
          side: BorderSide(color: colorScheme.outline),
        ),
        backgroundColor: Colors.white,
        selectedColor: AppThemeTokens.primarySoft,
        labelStyle: textTheme.labelMedium ?? const TextStyle(fontSize: 13),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: AppThemeTokens.primaryDeep,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppThemeTokens.primary,
        unselectedItemColor: const Color(0xFF8B8185),
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppThemeTokens.primary,
        inactiveTrackColor: AppThemeTokens.primarySoft,
        thumbColor: AppThemeTokens.primary,
        overlayColor: AppThemeTokens.primary.withValues(alpha: 0.14),
        valueIndicatorColor: AppThemeTokens.primaryDeep,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE7DCE0)),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusLg),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppThemeTokens.primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(0xFFFF5E8A),
          secondary: const Color(0xFFFFC97A),
          surface: const Color(0xFF15171C),
          surfaceContainerHighest: const Color(0xFF252A33),
          outline: const Color(0xFF3A3F49),
        );

    final textTheme = _buildTextTheme(Brightness.dark);
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF0E1015),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: _inputDecorationTheme(
        fillColor: const Color(0xFF1A1D24),
        enabledBorderColor: const Color(0xFF353A44),
        focusedBorderColor: colorScheme.primary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
          ),
          elevation: 0,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
          side: BorderSide(color: colorScheme.outline),
        ),
        backgroundColor: const Color(0xFF1A1D24),
        selectedColor: colorScheme.primary.withValues(alpha: 0.22),
        labelStyle: textTheme.labelMedium ?? const TextStyle(fontSize: 13),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF15171C),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: const Color(0xFF9EA5B2),
        selectedLabelStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelSmall,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.primary.withValues(alpha: 0.24),
        thumbColor: colorScheme.primary,
        overlayColor: colorScheme.primary.withValues(alpha: 0.18),
        valueIndicatorColor: colorScheme.primary,
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF353A44)),
      cardTheme: CardThemeData(
        color: const Color(0xFF15171C),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.radiusLg),
          side: const BorderSide(color: Color(0xFF252A33)),
        ),
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color enabledBorderColor,
    required Color focusedBorderColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF8D8588)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
        borderSide: BorderSide(color: enabledBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
        borderSide: BorderSide(color: focusedBorderColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
        borderSide: const BorderSide(color: Color(0xFFD4405C)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppThemeTokens.radiusMd),
        borderSide: const BorderSide(color: Color(0xFFD4405C), width: 1.4),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme)
        : GoogleFonts.plusJakartaSansTextTheme();
    final display = GoogleFonts.dmSerifDisplayTextTheme(base);

    return base.copyWith(
      headlineLarge: display.headlineLarge?.copyWith(
        fontSize: 32,
        height: 1.15,
        letterSpacing: 0.1,
      ),
      headlineMedium: display.headlineMedium?.copyWith(
        fontSize: 26,
        height: 1.2,
        letterSpacing: 0.1,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
      ),
      titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      bodyLarge: base.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: base.bodyMedium?.copyWith(height: 1.4),
      labelLarge: base.labelLarge?.copyWith(letterSpacing: 0.2),
      labelMedium: base.labelMedium?.copyWith(letterSpacing: 0.2),
      labelSmall: base.labelSmall?.copyWith(letterSpacing: 0.2),
    );
  }
}
