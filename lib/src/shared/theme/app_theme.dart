import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//
//  AppColors
//
// Theme-aware color class that supports multiple themes
class AppColors {
  // Private constructor
  AppColors._();

  // Current theme mode
  static ThemeMode _themeMode = ThemeMode.dark;

  // Dark and light color schemes
  static final ColorScheme _darkScheme = AppTheme.darkColorScheme;
  static final ColorScheme _lightScheme = AppTheme.lightColorScheme;

  // Get current scheme based on theme mode
  static ColorScheme get current =>
      _themeMode == ThemeMode.light ? _lightScheme : _darkScheme;

  // Method to change theme mode
  static void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    // maybe add notifer here??
  }

  static Color get primary => current.primary;
  static Color get onPrimary => current.onPrimary;
  static Color get secondary => current.secondary;
  static Color get onSecondary => current.onSecondary;
  static Color get tertiary => current.tertiary;
  static Color get onTertiary => current.onTertiary;

  static Color get surface => current.surface;
  static Color get surfaceContainer => current.surfaceContainer;
  static Color get onSurface => current.onSurface;
  static Color get onSurfaceVariant => current.onSurfaceVariant;

  static Color get error => current.error;
  static Color get errorContainer => current.errorContainer;
  static Color get success =>
      _themeMode == ThemeMode.light ? AppTheme.greenLight : AppTheme.greenDark;
  static Color get warning => _themeMode == ThemeMode.light
      ? AppTheme.orangeLight
      : AppTheme.orangeDark;
  static Color get info => current.primary;

  static Color get shadow => current.shadow;
  static Color get outline => current.outline;
  static Color get cardColor => current.surfaceContainer;
}

// Theme-aware text style class that supports multiple themes
class AppTextStyles {
  // Private constructor
  AppTextStyles._();

  // Get current text theme based on theme mode
  static TextTheme get _current => AppColors._themeMode == ThemeMode.light
      ? _getLightTextTheme()
      : _getDarkTextTheme();

  // Dark text theme
  static TextTheme _getDarkTextTheme() => TextTheme(
        displayLarge: AppTheme.displayLarge,
        displayMedium: AppTheme.displayMedium,
        displaySmall: AppTheme.displaySmall,
        headlineLarge: AppTheme.headlineLarge,
        headlineMedium: AppTheme.headlineMedium,
        headlineSmall: AppTheme.headlineSmall,
        titleLarge: AppTheme.titleLarge,
        titleMedium: AppTheme.titleMedium,
        titleSmall: AppTheme.titleSmall,
        bodyLarge: AppTheme.bodyLarge,
        bodyMedium: AppTheme.bodyMedium,
        bodySmall: AppTheme.bodySmall,
        labelLarge: AppTheme.labelLarge,
        labelMedium: AppTheme.labelMedium,
        labelSmall: AppTheme.labelSmall,
      );

  // Light text theme (we'll create these styles later)
  static TextTheme _getLightTextTheme() {
    // For now, using same styles with color adjusted for light theme
    final baseStyle = GoogleFonts.nunito(
      color: AppTheme.black,
      letterSpacing: 0.15,
    );

    return TextTheme(
      displayLarge: AppTheme.displayLarge.copyWith(color: AppTheme.black),
      displayMedium: AppTheme.displayMedium.copyWith(color: AppTheme.black),
      displaySmall: AppTheme.displaySmall.copyWith(color: AppTheme.black),
      headlineLarge: AppTheme.headlineLarge.copyWith(color: AppTheme.black),
      headlineMedium: AppTheme.headlineMedium.copyWith(color: AppTheme.black),
      headlineSmall: AppTheme.headlineSmall.copyWith(color: AppTheme.black),
      titleLarge: AppTheme.titleLarge.copyWith(color: AppTheme.black),
      titleMedium: AppTheme.titleMedium.copyWith(color: AppTheme.black),
      titleSmall: AppTheme.titleSmall.copyWith(color: AppTheme.black),
      bodyLarge: AppTheme.bodyLarge.copyWith(color: AppTheme.black),
      bodyMedium: AppTheme.bodyMedium.copyWith(color: AppTheme.black),
      bodySmall: AppTheme.bodySmall.copyWith(color: AppTheme.black),
      labelLarge: AppTheme.labelLarge.copyWith(color: AppTheme.black),
      labelMedium: AppTheme.labelMedium.copyWith(color: AppTheme.black),
      labelSmall: AppTheme.labelSmall.copyWith(color: AppTheme.black),
    );
  }

  // Display styles
  static TextStyle get displayLarge => _current.displayLarge!;
  static TextStyle get displayMedium => _current.displayMedium!;
  static TextStyle get displaySmall => _current.displaySmall!;

  // Headline styles
  static TextStyle get headlineLarge => _current.headlineLarge!;
  static TextStyle get headlineMedium => _current.headlineMedium!;
  static TextStyle get headlineSmall => _current.headlineSmall!;

  // Title styles
  static TextStyle get titleLarge => _current.titleLarge!;
  static TextStyle get titleMedium => _current.titleMedium!;
  static TextStyle get titleSmall => _current.titleSmall!;

  // Body styles
  static TextStyle get bodyLarge => _current.bodyLarge!;
  static TextStyle get bodyMedium => _current.bodyMedium!;
  static TextStyle get bodySmall => _current.bodySmall!;

  // Label styles
  static TextStyle get labelLarge => _current.labelLarge!;
  static TextStyle get labelMedium => _current.labelMedium!;
  static TextStyle get labelSmall => _current.labelSmall!;

  // Utility styles - these adjust color based on current theme automatically
  static TextStyle get buttonText => AppColors._themeMode == ThemeMode.light
      ? AppTheme.buttonText.copyWith(color: AppTheme.black)
      : AppTheme.buttonText;

  static TextStyle get caption => AppColors._themeMode == ThemeMode.light
      ? AppTheme.caption.copyWith(color: AppTheme.black.withAlpha(179))
      : AppTheme.caption;

  static TextStyle get overline => AppColors._themeMode == ThemeMode.light
      ? AppTheme.overline.copyWith(color: AppTheme.black)
      : AppTheme.overline;

  static TextStyle get error => AppColors._themeMode == ThemeMode.light
      ? AppTheme.error.copyWith(color: AppTheme.pinkDark.withRed(220))
      : AppTheme.error;

  static TextStyle get link => AppColors._themeMode == ThemeMode.light
      ? AppTheme.link.copyWith(color: AppTheme.blueLight)
      : AppTheme.link;
}

//
//  AppTheme
//
class AppTheme {
  // Spacing
  static const double spacing = 8.0;
  static const double padding = 16.0;
  static const double cardPadding = 16.0;
  static const double cardSpacing = 24.0;
  static const double navbarPadding = 8.0;

  //EdgeInsets
  static const EdgeInsets standardCardPadding = EdgeInsets.all(cardPadding);
  static const EdgeInsets standardScreenMargins = EdgeInsets.all(padding);
  static const EdgeInsets navigationBarPadding = EdgeInsets.all(navbarPadding);

  static const Color black = Color(0xFF0A100D);
  static const Color white = Color(0xFFF7F7F9);
  static const Color darkgrey = Color.fromARGB(255, 29, 29, 29);

  // Colors - Dark Theme
  static const Color greyDark = Color.fromARGB(255, 39, 39, 39);
  static const Color lightgreyDark = Color.fromARGB(255, 236, 236, 243);
  static const Color blueDark = Color.fromARGB(255, 59, 170, 255);
  static const Color lightblueDark = Color.fromARGB(255, 176, 221, 250);
  static const Color darkblueDark = Color(0xFF0A1128);
  static const Color orangeDark = Color.fromARGB(255, 238, 154, 37);
  static const Color pinkDark = Color(0xFFCE5374);
  static const Color lightpinkDark = Color.fromARGB(255, 235, 141, 166);
  static const Color greenDark = Color(0xFF4FB286);

  // Colors - Light Theme
  static const Color greyLight = Color.fromARGB(255, 227, 227, 227);
  static const Color lightgreyLight = Color.fromARGB(255, 229, 229, 229);
  static const Color blueLight = Color.fromARGB(255, 24, 118, 210);
  static const Color lightblueLight = Color.fromARGB(255, 125, 190, 252);
  static const Color darkblueLight = Color(0xFF1A237E);
  static const Color orangeLight = Color.fromARGB(255, 245, 124, 0);
  static const Color pinkLight = Color(0xFFEC407A);
  static const Color lightpinkLight = Color.fromARGB(255, 248, 176, 195);
  static const Color greenLight = Color(0xFF2E7D32);

  // Dark Color Scheme
  static final ColorScheme darkColorScheme = ColorScheme.dark(
    primary: blueDark,
    secondary: pinkDark,
    tertiary: greenDark,
    surface: darkgrey,
    surfaceContainer: greyDark,
    onPrimary: white,
    onSecondary: white,
    onTertiary: white,
    onSurface: white,
    onSurfaceVariant: white,
    error: pinkDark.withRed(220),
    errorContainer: lightpinkDark,
    shadow: black.withAlpha(25),
    outline: greyDark,
  );

  // Light Color Scheme
  static final ColorScheme lightColorScheme = ColorScheme.light(
    primary: blueLight,
    secondary: pinkLight,
    tertiary: greenLight,
    surface: white,
    surfaceContainer: greyLight,
    onPrimary: white,
    onSecondary: white,
    onTertiary: white,
    onSurface: black,
    onSurfaceVariant: black,
    error: pinkLight.withRed(240),
    errorContainer: lightpinkDark,
    shadow: black.withAlpha(15),
    outline: greyLight,
  );

  static const defaultTextFieldDecoration = InputDecoration(
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  );

  // Text Styles
  static final TextStyle _baseTextStyle = GoogleFonts.nunito(
    color: AppColors.onSurface,
    letterSpacing: 0.15,
  );

  // Display Styles
  static final TextStyle displayLarge = _baseTextStyle.copyWith(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static final TextStyle displayMedium = _baseTextStyle.copyWith(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static final TextStyle displaySmall = _baseTextStyle.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline Styles
  static final TextStyle headlineLarge = _baseTextStyle.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.25,
  );

  static final TextStyle headlineMedium = _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.29,
  );

  static final TextStyle headlineSmall = _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title Styles
  static final TextStyle titleLarge = _baseTextStyle.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.27,
  );

  static final TextStyle titleMedium = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static final TextStyle titleSmall = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Label Styles
  static final TextStyle labelLarge = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static final TextStyle labelMedium = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static final TextStyle labelSmall = _baseTextStyle.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Body Styles
  static final TextStyle bodyLarge = _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static final TextStyle bodyMedium = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static final TextStyle bodySmall = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Additional Utility Text Styles
  static final TextStyle buttonText = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    height: 1.43,
  );

  static final TextStyle caption = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
    color: AppColors.onSurfaceVariant.withAlpha(180),
  );

  static final TextStyle overline = _baseTextStyle.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1.5,
    height: 1.6,
    textBaseline: TextBaseline.alphabetic,
  );

  // Helper Styles
  static final TextStyle error = _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error.withRed(220),
    letterSpacing: 0.4,
    height: 1.33,
  );

  static final TextStyle link = _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    letterSpacing: 0.25,
    height: 1.43,
  );

  // Method to get current ThemeData based on theme mode
  static ThemeData getTheme(ThemeMode mode) {
    return mode == ThemeMode.light ? lightTheme : darkTheme;
  }

  // Dark Theme
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: darkColorScheme,

    // Dark - Text Theme
    textTheme: TextTheme(
      displayLarge: displayLarge,
      displayMedium: displayMedium,
      displaySmall: displaySmall,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    ),

    // Dark - AppBar Theme
    appBarTheme: AppBarTheme(
      toolbarHeight: 48,
      backgroundColor: darkColorScheme.primary,
      foregroundColor: darkColorScheme.onPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineSmall,
      //iconTheme: IconThemeData(color: darkColorScheme.onPrimary),
    ),

    // Dark - Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      color: darkColorScheme.surfaceContainer,
      shadowColor: black.withAlpha(25),
    ),

    // Dark - Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkColorScheme.secondary,
      foregroundColor: darkColorScheme.onSecondary,
      elevation: 4,
    ),

    // Dark - Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: blueDark.withAlpha(25),
      labelStyle: labelLarge.copyWith(color: blueDark),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Dark - Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashRadius: 24, // for better touch feedback
      visualDensity: VisualDensity.comfortable,
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return greenDark;
        }
        return black.withAlpha(40);
      }),

      // Smooth size animation on click
      side: BorderSide(
        width: 1,
        color: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return greenDark;
          }
          return black.withAlpha(40);
        }),
      ),
    ),

    // Dark - Dialog Theme
    dialogTheme: DialogTheme(
      elevation: 4,
      backgroundColor: darkColorScheme.surface,
      titleTextStyle: headlineSmall,
      contentTextStyle: bodyMedium,
    ),

    // Dark - Button Themes
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: buttonText,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: buttonText,
      ),
    ),

    // Dark - Input Theme
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: labelMedium,
      hintStyle: bodyMedium.copyWith(color: white.withAlpha(128)),
      errorStyle: error,
    ),

    // Dark - Date picker theme
    datePickerTheme: DatePickerThemeData(
      backgroundColor: darkColorScheme.surface,
      headerBackgroundColor: darkColorScheme.primary,
      headerForegroundColor: darkColorScheme.onPrimary,
      headerHeadlineStyle: headlineSmall,
      headerHelpStyle: labelMedium,
      dayBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return darkColorScheme.primary;
        }
        return Colors.transparent;
      }),
      dayForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return darkColorScheme.onPrimary;
        } else if (states.contains(WidgetState.disabled)) {
          return lightgreyDark;
        }
        return darkColorScheme.onSurface;
      }),
      dayStyle: bodyMedium,
      todayBackgroundColor:
          WidgetStateProperty.all(darkColorScheme.primary.withAlpha(25)),
      todayForegroundColor: WidgetStateProperty.all(darkColorScheme.primary),
      todayBorder: const BorderSide(color: white, width: 1.5),
      yearBackgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return darkColorScheme.primary;
        }
        return Colors.transparent;
      }),
      yearForegroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return darkColorScheme.onPrimary;
        }
        return black;
      }),
      yearStyle: bodyMedium,
    ),

    // Dark - Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: white,
      modalBackgroundColor: darkgrey,
      modalBarrierColor: black.withAlpha(128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      surfaceTintColor: darkColorScheme.primary,
    ),

    // Dark - Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: black,
      height: 56,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: blueDark,
            size: 28,
          );
        }
        return const IconThemeData(
          color: white,
          size: 28,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return labelSmall.copyWith(color: blueDark);
        }
        return labelSmall;
      }),
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    ),

    // Dark - Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkblueDark,
      contentTextStyle: bodyMedium.copyWith(color: white),
      actionTextColor: blueDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Dark - TabBar Theme
    tabBarTheme: TabBarTheme(
      labelStyle: labelLarge,
      unselectedLabelStyle: labelLarge.copyWith(
        color: white.withAlpha(200),
      ),
      indicatorColor: blueDark,
      dividerColor: Colors.transparent,
    ),

    // Dark - Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: darkblueDark.withAlpha(230),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: bodySmall.copyWith(color: white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );

  // Light Theme
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: lightColorScheme,

    // Light - Text Theme
    textTheme: TextTheme(
      displayLarge: displayLarge.copyWith(color: black),
      displayMedium: displayMedium.copyWith(color: black),
      displaySmall: displaySmall.copyWith(color: black),
      headlineLarge: headlineLarge.copyWith(color: black),
      headlineMedium: headlineMedium.copyWith(color: black),
      headlineSmall: headlineSmall.copyWith(color: black),
      titleLarge: titleLarge.copyWith(color: black),
      titleMedium: titleMedium.copyWith(color: black),
      titleSmall: titleSmall.copyWith(color: black),
      bodyLarge: bodyLarge.copyWith(color: black),
      bodyMedium: bodyMedium.copyWith(color: black),
      bodySmall: bodySmall.copyWith(color: black),
      labelLarge: labelLarge.copyWith(color: black),
      labelMedium: labelMedium.copyWith(color: black),
      labelSmall: labelSmall.copyWith(color: black),
    ),

    // Light - AppBar Theme
    appBarTheme: AppBarTheme(
      toolbarHeight: 48,
      backgroundColor: lightColorScheme.primary,
      foregroundColor: lightColorScheme.onPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineSmall.copyWith(color: white),
    ),

    // Light - Card Theme
    cardTheme: CardTheme(
      elevation: 2,
      color: lightColorScheme.surfaceContainer,
      shadowColor: black.withAlpha(25),
    ),

    // Light - Floating Action Button Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: lightColorScheme.secondary,
      foregroundColor: lightColorScheme.onSecondary,
      elevation: 4,
    ),

    // Light - Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: blueLight.withAlpha(25),
      labelStyle: labelLarge.copyWith(color: blueLight),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Light - Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashRadius: 24,
      visualDensity: VisualDensity.comfortable,
      fillColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.selected)) {
          return greenLight;
        }
        return black.withAlpha(40);
      }),
      side: BorderSide(
        width: 1,
        color: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return greenLight;
          }
          return black.withAlpha(40);
        }),
      ),
    ),

    // Light - Dialog Theme
    dialogTheme: DialogTheme(
      elevation: 4,
      backgroundColor: lightColorScheme.surface,
      titleTextStyle: headlineSmall.copyWith(color: black),
      contentTextStyle: bodyMedium.copyWith(color: black),
    ),

    // Light - Button Themes
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: buttonText.copyWith(color: black),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: buttonText.copyWith(color: black),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: buttonText.copyWith(color: black),
      ),
    ),

    // Light - Input Theme
    inputDecorationTheme: InputDecorationTheme(
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: labelMedium.copyWith(color: black),
      hintStyle: bodyMedium.copyWith(color: black.withAlpha(128)),
      errorStyle: error.copyWith(color: pinkLight.withRed(240)),
    ),

    // Light - Bottom Sheet Theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: white,
      modalBackgroundColor: white,
      modalBarrierColor: black.withAlpha(128),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      surfaceTintColor: lightColorScheme.primary,
    ),

    // Light - Navigation Bar Theme
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: white,
      height: 56,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: blueLight,
            size: 28,
          );
        }
        return const IconThemeData(
          color: black,
          size: 28,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return labelSmall.copyWith(color: blueLight);
        }
        return labelSmall;
      }),
      indicatorColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
    ),

    // Light - Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkblueLight,
      contentTextStyle: bodyMedium.copyWith(color: white),
      actionTextColor: blueLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Light - TabBar Theme
    tabBarTheme: TabBarTheme(
      labelStyle: labelLarge.copyWith(color: blueLight),
      unselectedLabelStyle: labelLarge.copyWith(
        color: black.withAlpha(179),
      ),
      indicatorColor: blueLight,
      dividerColor: Colors.transparent,
    ),

    // Light - Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: darkblueLight.withAlpha(230),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: bodySmall.copyWith(color: white),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
  );

  // Helper method to toggle theme
  static ThemeMode toggleThemeMode(ThemeMode current) {
    ThemeMode newMode =
        current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    AppColors.setThemeMode(newMode);
    return newMode;
  }
}
