//
//  app_theme.dart
//  Theme system
//
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//----------------------------------------------------------------------------
// APP COLORS
//----------------------------------------------------------------------------

/// Theme-aware color provider that adjusts based on current theme mode
class AppColors {
  // Private constructor to prevent instantiation
  AppColors._();

  // Current theme mode
  static ThemeMode _themeMode = ThemeMode.dark;

  // Dark and light color schemes
  static final ColorScheme _darkScheme = AppTheme.darkColorScheme;
  static final ColorScheme _lightScheme = AppTheme.lightColorScheme;

  /// Get current scheme based on theme mode
  static ColorScheme get current =>
      _themeMode == ThemeMode.light ? _lightScheme : _darkScheme;

  /// Method to change theme mode
  static void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    // A notifier could be added here for more reactive theme changes
  }

  // Basic theme colors
  static Color get primary => current.primary;
  static Color get onPrimary => current.onPrimary;
  static Color get secondary => current.secondary;
  static Color get onSecondary => current.onSecondary;
  static Color get tertiary => current.tertiary;
  static Color get onTertiary => current.onTertiary;

  // Surface colors
  static Color get surface => current.surface;
  static Color get surfaceContainer => current.surfaceContainer;
  static Color get onSurface => current.onSurface;
  static Color get onSurfaceVariant => current.onSurfaceVariant;

  // Status colors
  static Color get error => current.error;
  static Color get errorContainer => current.errorContainer;
  static Color get success =>
      _themeMode == ThemeMode.light ? AppTheme.greenLight : AppTheme.greenDark;
  static Color get warning => _themeMode == ThemeMode.light
      ? AppTheme.orangeLight
      : AppTheme.orangeDark;
  static Color get info => current.primary;

  // Medication type colors
  static Color get oralMedication => _themeMode == ThemeMode.light
      ? AppTheme.oralMedColorLight
      : AppTheme.oralMedColorDark;

  static Color get injection => _themeMode == ThemeMode.light
      ? AppTheme.injectionColorLight
      : AppTheme.injectionColorDark;

  // Appointment type colors
  static Color get bloodwork => _themeMode == ThemeMode.light
      ? AppTheme.bloodworkColorLight
      : AppTheme.bloodworkColorDark;

  static Color get doctorAppointment => _themeMode == ThemeMode.light
      ? AppTheme.doctorApptColorLight
      : AppTheme.doctorApptColorDark;

  static Color get surgery => _themeMode == ThemeMode.light
      ? AppTheme.surgeryColorLight
      : AppTheme.surgeryColorDark;

  // Other UI element colors
  static Color get shadow => current.shadow;
  static Color get outline => current.outline;
  static Color get cardColor => current.surfaceContainer;
}

//----------------------------------------------------------------------------
// TEXT STYLES
//----------------------------------------------------------------------------

/// Theme-aware text styles that adjust based on current theme mode
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  /// Get current text theme based on theme mode
  static TextTheme get _current => AppColors._themeMode == ThemeMode.light
      ? _getLightTextTheme()
      : _getDarkTextTheme();

  /// Create the dark theme text styles
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

  /// Create the light theme text styles with adjusted colors
  static TextTheme _getLightTextTheme() {
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

//----------------------------------------------------------------------------
// MAIN THEME CONFIGURATION
//----------------------------------------------------------------------------

/// Main theme class with comprehensive style definitions
class AppTheme {
  //----------------------------------------------------------------------------
  // SPACING CONSTANTS
  //----------------------------------------------------------------------------

  /// Standard spacing unit for margins, padding, etc.
  static const double spacing = 8.0;

  /// Standard padding for containers
  static const double padding = 16.0;

  /// Standard padding for cards
  static const double cardPadding = 16.0;

  /// Standard spacing between cards
  static const double cardSpacing = 24.0;

  /// Standard padding for navigation elements
  static const double navbarPadding = 8.0;

  //----------------------------------------------------------------------------
  // STANDARD EDGE INSETS
  //----------------------------------------------------------------------------

  /// Standard padding for cards
  static const EdgeInsets standardCardPadding = EdgeInsets.all(cardPadding);

  /// Standard margins for screens
  static const EdgeInsets standardScreenMargins = EdgeInsets.all(padding);

  /// Standard padding for navigation bar icons
  static const EdgeInsets navigationBarPadding = EdgeInsets.all(navbarPadding);

  //----------------------------------------------------------------------------
  // BASE COLORS
  //----------------------------------------------------------------------------

  static const Color black = Color(0xFF1A1A2E); // Deep navy-black
  static const Color white = Color(0xFFF9F9F9); // Soft white
  static const Color darkgrey = Color(0xFF2C2C44); // Deep blue-grey

  //----------------------------------------------------------------------------
  // NOTIFICATION TYPE COLORS
  //----------------------------------------------------------------------------
  // Dark theme colors for medication types
  static const oralMedColorDark = Color(0xFFc576e5); // Vibrant purple
  static const injectionColorDark = Color(0xFF81f7e5); // Fluorescent cyan

  // Light theme colors for medication types
  static const oralMedColorLight = Color(0xFF9331ae); // Rich violet
  static const injectionColorLight = Color(0xFF00b3a0); // Deeper teal

  // Dark theme colors for appointment types
  static const bloodworkColorDark = Color(0xFFff9fb3); // Soft pink
  static const doctorApptColorDark = Color.fromARGB(255, 241, 169, 111);
  static const surgeryColorDark = Color(0xFFf2d0a4); // Soft gold
  // Light theme colors for appointment types
  static const bloodworkColorLight = Color(0xFFe6536e); // Deeper pink
  static const doctorApptColorLight = Color.fromARGB(255, 223, 119, 33);
  static const surgeryColorLight = Color(0xFFd4a241); // Amber gold

  //----------------------------------------------------------------------------
  // DARK THEME COLORS
  //----------------------------------------------------------------------------
  static const Color greyDark =
      Color.fromARGB(255, 58, 58, 88); // Deep blue-grey
  static const Color lightgreyDark = Color(0xFF9090A0); // Muted lavender-grey
  static const Color blueDark = Color(0xFFb6dcfe); // Uranian blue
  static const Color lightblueDark = Color(0xFFcdedfd); // Columbia blue
  static const Color darkblueDark = Color(0xFF5785c1); // Deeper blue
  static const Color orangeDark = Color(0xFFffbe7d); // Soft orange
  static const Color pinkDark = Color(0xFFff9fb3); // Soft pink
  static const Color lightpinkDark = Color(0xFFffccd6); // Lighter pink
  static const Color greenDark = Color(0xFFa8e6cf); // Soft mint

  //----------------------------------------------------------------------------
  // LIGHT THEME COLORS
  //----------------------------------------------------------------------------
  static const Color greyLight = Color(0xFFDCDCE8); // Pale blue-grey
  static const Color lightgreyLight = Color(0xFFF5F5F9); // Nearly white
  static const Color blueLight = Color(0xFF4a91db); // Medium blue
  static const Color lightblueLight = Color(0xFF8fc4f3); // Light medium blue
  static const Color darkblueLight = Color(0xFF245a92); // Deep navy blue
  static const Color orangeLight = Color(0xFFf39c63); // Medium orange
  static const Color pinkLight = Color(0xFFe6536e); // Medium pink
  static const Color lightpinkLight = Color(0xFFf38ea0); // Light medium pink
  static const Color greenLight = Color(0xFF5ab890); // Medium mint

  //----------------------------------------------------------------------------
  // COLOR SCHEMES
  //----------------------------------------------------------------------------

  /// Dark mode color scheme
  static final ColorScheme darkColorScheme = ColorScheme.dark(
    primary: blueDark,
    secondary: pinkDark,
    tertiary: greenDark,
    surface: darkgrey,
    surfaceContainer: greyDark.withAlpha(200),
    onPrimary: black,
    onSecondary: black,
    onTertiary: black,
    onSurface: white,
    onSurfaceVariant: lightgreyDark,
    error: pinkDark.withRed(220),
    errorContainer: lightpinkDark,
    shadow: black.withAlpha(25),
    outline: lightgreyDark.withAlpha(100),
  );

  /// Light mode color scheme
  static final ColorScheme lightColorScheme = ColorScheme.light(
    primary: darkblueLight, // Darker blue for better text contrast
    secondary: pinkLight,
    tertiary: greenLight,
    surface: white,
    surfaceContainer: greyLight, // More distinct from white
    onPrimary: white,
    onSecondary: white,
    onTertiary: white,
    onSurface: black,
    onSurfaceVariant: darkgrey.withOpacity(0.7),
    error: pinkLight.withRed(240),
    errorContainer: lightpinkDark,
    shadow: black.withAlpha(15),
    outline: greyLight.withOpacity(0.7),
  );

  /// Default text field decoration used throughout the app
  static const defaultTextFieldDecoration = InputDecoration(
    border: OutlineInputBorder(),
    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  );

  //----------------------------------------------------------------------------
  // TEXT STYLES
  //----------------------------------------------------------------------------

  /// Base text style for the application
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

  //----------------------------------------------------------------------------
  // THEME DATA CONFIGURATION
  //----------------------------------------------------------------------------

  /// Get ThemeData based on specified theme mode
  static ThemeData getTheme(ThemeMode mode) {
    return mode == ThemeMode.light ? lightTheme : darkTheme;
  }

  //----------------------------------------------------------------------------
  // DARK THEME
  //----------------------------------------------------------------------------

  /// Dark theme configuration
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
      foregroundColor:
          darkColorScheme.onPrimary, // Now using black on bright blue
      elevation: 0,
      centerTitle: true,
      titleTextStyle: headlineSmall.copyWith(color: darkColorScheme.onPrimary),
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
        foregroundColor: blueDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: buttonText,
        backgroundColor: blueDark,
        foregroundColor: black, // Better contrast
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: buttonText,
        foregroundColor: blueDark,
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
      headerHeadlineStyle:
          headlineSmall.copyWith(color: darkColorScheme.onPrimary),
      headerHelpStyle: labelMedium.copyWith(color: darkColorScheme.onPrimary),
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
        return darkColorScheme.onSurface;
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
      backgroundColor:
          darkgrey.withOpacity(0.9), // Better contrast with content
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

  //----------------------------------------------------------------------------
  // LIGHT THEME
  //----------------------------------------------------------------------------

  /// Light theme configuration
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
        foregroundColor: darkblueLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        textStyle: buttonText.copyWith(color: white),
        backgroundColor: darkblueLight,
        foregroundColor: white,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        textStyle: buttonText.copyWith(color: black),
        foregroundColor: darkblueLight,
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
      backgroundColor:
          greyLight.withOpacity(0.9), // Better contrast with content
      height: 56,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(
            color: darkblueLight,
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
          return labelSmall.copyWith(color: darkblueLight);
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
      actionTextColor: white,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),

    // Light - TabBar Theme
    tabBarTheme: TabBarTheme(
      labelStyle: labelLarge.copyWith(color: darkblueLight),
      unselectedLabelStyle: labelLarge.copyWith(
        color: black.withAlpha(179),
      ),
      indicatorColor: darkblueLight,
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

  //----------------------------------------------------------------------------
  // THEME HELPER METHODS
  //----------------------------------------------------------------------------

  /// Toggle between light and dark theme mode
  static ThemeMode toggleThemeMode(ThemeMode current) {
    ThemeMode newMode =
        current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;

    AppColors.setThemeMode(newMode);
    return newMode;
  }
}
