import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

double shadowRadius = 10;

var lightModeTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  fontFamily: GoogleFonts.raleway().fontFamily,
  shadowColor: Color.fromARGB(38, 118, 118, 118),
  colorScheme: colorSchemeLight,
  textTheme: textThemeLight,
  appBarTheme: appBarThemeLight,
  dividerTheme: dividerThemeLight,
  inputDecorationTheme: inputDecorationThemeLight,
  checkboxTheme: checkBoxTheme,
  snackBarTheme: snackBarTheme,
  scaffoldBackgroundColor: Color(0xFFFFFFFF),
);

var darkModeTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.raleway().fontFamily,
  primarySwatch: Colors.amber,
  shadowColor: Color.fromARGB(37, 0, 0, 0),
  colorScheme: colorSchemeDark,
  textTheme: textThemeDark,
  appBarTheme: appBarThemeDark,
  inputDecorationTheme: inputDecorationThemeDark,
  checkboxTheme: checkBoxTheme,
  snackBarTheme: snackBarTheme,
  scaffoldBackgroundColor: Color.fromARGB(255, 20, 20, 20),
);

String currentLogo = 'assets/images/logoLightMode.png';
String lightModeLogo = 'assets/images/logoLightMode.png';
String darkModeLogo = 'assets/images/logoDarkMode.png';

///
///ColorSchemes
///
var colorSchemeLight = ColorScheme(
  primary: Color(0xFFFF966C),
  primaryContainer: Color(0xFFFF966C),
  secondary: Color(0xFF262626),
  secondaryContainer: Color.fromARGB(38, 118, 118, 118),
  surface: Color(0xFFFFFFFF),
  background: Color(0xFFFFFFFF),
  error: Color(0xFFFD594D),
  onPrimary: Color(0xFFb4e599),
  onSecondary: Color(0xFF262626),
  onSurface: Color(0xFF262626),
  onBackground: Color(0xFFFFFFFF),
  onError: Color(0xFFFF966C),
  brightness: Brightness.light,
);

var colorSchemeDark = ColorScheme(
  primary: Color(0xFFFF966C),
  primaryContainer: Color(0xFFFF966C),
  secondary: Color(0xFFFFFFFF),
  secondaryContainer: Color.fromARGB(38, 118, 118, 118),
  surface: Color.fromARGB(255, 40, 40, 40),
  background: Color.fromARGB(255, 20, 20, 20),
  error: Color(0xFFFD594D),
  onPrimary: Color(0xFFb4e599),
  onSecondary: Color(0xFF262626),
  onSurface: Color(0xFFFFFFFF),
  onBackground: Color(0xFFFFFFFF),
  onError: Color(0xFFFF966C),
  brightness: Brightness.dark,
);

///
///Text themes
///
double bodyTextSize = 13;
double header1Size = 36;
double header2Size = 18;
double header3Size = 16;

double textShadow = 1;

var textThemeLight = TextTheme(
  bodySmall: TextStyle(
    color: Color(0xFF262626),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  bodyMedium: TextStyle(
    color: Color(0xFF262626),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  displayLarge: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  displayMedium: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  displaySmall: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  headlineLarge: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  headlineMedium: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  headlineSmall: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
);

var textThemeDark = TextTheme(
  bodySmall: TextStyle(
    color: Color(0xFF262626),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  bodyMedium: TextStyle(
    color: Color(0xFFFFFFFF),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  displayLarge: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  displayMedium: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  displaySmall: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  headlineLarge: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFF262626),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  headlineMedium: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFFFFFFFF),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
  headlineSmall: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFFFFFFFF),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: textShadow,
      ),
    ],
  ),
);

///
///AppBar themes
///
var appBarThemeLight = AppBarTheme(
  backgroundColor: colorSchemeLight.surface,
  elevation: 0,
);

var appBarThemeDark = AppBarTheme(
  backgroundColor: colorSchemeDark.surface,
  elevation: 0,
);

///
///Divider themes
///
var dividerThemeLight = DividerThemeData(
  space: 25,
  thickness: 1,
  color: colorSchemeLight.surface,
  indent: 5,
  endIndent: 5,
);

var dividerThemeDark = DividerThemeData(
  space: 25,
  thickness: 1,
  color: colorSchemeDark.secondary,
  indent: 5,
  endIndent: 5,
);

///
///Input decoration themes
///
var inputDecorationThemeLight = InputDecorationTheme(
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: colorSchemeLight.secondary,
    ),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: colorSchemeLight.primary,
    ),
  ),
  labelStyle: TextStyle(
    color: colorSchemeLight.secondary,
  ),
  hintStyle: TextStyle(
    color: colorSchemeLight.secondary,
  ),
  floatingLabelStyle: TextStyle(
    color: colorSchemeLight.secondary,
  ),
);

var inputDecorationThemeDark = InputDecorationTheme(
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: colorSchemeDark.secondary,
    ),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: colorSchemeDark.primary,
    ),
  ),
  labelStyle: TextStyle(
    color: colorSchemeDark.secondary,
  ),
  hintStyle: TextStyle(
    color: colorSchemeDark.secondary,
  ),
  floatingLabelStyle: TextStyle(
    color: colorSchemeDark.secondary,
  ),
);

var checkBoxTheme = CheckboxThemeData(
  fillColor: MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.selected)) {
      return colorSchemeLight.primary;
    }
    return null;
  }),
);

var snackBarTheme = SnackBarThemeData(
  backgroundColor: colorSchemeLight.primary,
);
