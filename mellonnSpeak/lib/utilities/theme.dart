import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

double shadowRadius = 10;

var lightModeTheme = ThemeData(
  brightness: Brightness.light,
  fontFamily: GoogleFonts.raleway().fontFamily,
  primarySwatch: Colors.amber,
  backgroundColor: Color(0xFFFFFFFF),
  shadowColor: Color.fromARGB(38, 118, 118, 118),
  colorScheme: colorSchemeLight,
  textTheme: textThemeLight,
  appBarTheme: appBarThemeLight,
  dividerTheme: dividerThemeLight,
  inputDecorationTheme: inputDecorationThemeLight,
  checkboxTheme: checkBoxTheme,
);

var darkModeTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: GoogleFonts.raleway().fontFamily,
  primarySwatch: Colors.amber,
  backgroundColor: Color(0xFF404040),
  shadowColor: Color.fromARGB(38, 118, 118, 118),
  colorScheme: colorSchemeDark,
  textTheme: textThemeDark,
  appBarTheme: appBarThemeDark,
  inputDecorationTheme: inputDecorationThemeDark,
  checkboxTheme: checkBoxTheme,
);

String currentLogo = 'assets/images/logoLightMode.png';
String lightModeLogo = 'assets/images/logoLightMode.png';
String darkModeLogo = 'assets/images/logoDarkMode.png';

///
///ColorSchemes
///
var colorSchemeLight = ColorScheme(
  primary: Color(0xFFFAB228),
  primaryContainer: Color(0xFFFAB228),
  secondary: Color(0xFF505050),
  secondaryContainer: Color.fromARGB(38, 118, 118, 118),
  surface: Color(0xFFF8F8F8),
  background: Color(0xFFFFFFFF),
  error: Colors.red,
  onPrimary: Color(0xFFFAB228),
  onSecondary: Color(0xFF505050),
  onSurface: Color(0xFFA5C644),
  onBackground: Color(0xFFFFFFFF),
  onError: Color(0xFFFAB228),
  brightness: Brightness.light,
);

var colorSchemeDark = ColorScheme(
  primary: Color(0xFFFAB228),
  primaryContainer: Color(0xFFFAB228),
  secondary: Color(0xFFF8F8F8),
  secondaryContainer: Color.fromARGB(38, 118, 118, 118),
  surface: Color.fromARGB(255, 60, 60, 60),
  background: Color.fromARGB(255, 45, 45, 45),
  error: Colors.red,
  onPrimary: Color(0xFFFAB228),
  onSecondary: Color(0xFF505050),
  onSurface: Color(0xFFA5C644),
  onBackground: Color(0xFFFFFFFF),
  onError: Color(0xFFFAB228),
  brightness: Brightness.dark,
);

///
///Text themes
///
double bodyTextSize = 13;
double header1Size = 36;
double header2Size = 18;
double header3Size = 16;

var textThemeLight = TextTheme(
  bodyText1: TextStyle(
    color: Color(0xFF505050),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  bodyText2: TextStyle(
    color: Color(0xFF505050),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline1: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline2: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline3: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline4: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline5: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline6: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
);

var textThemeDark = TextTheme(
  bodyText1: TextStyle(
    color: Color(0xFF505050),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  bodyText2: TextStyle(
    color: Color(0xFFF8F8F8),
    fontSize: bodyTextSize,
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline1: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline2: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline3: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFF505050),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline4: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header1Size,
    color: Color(0xFFF8F8F8),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline5: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header2Size,
    color: Color(0xFFF8F8F8),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
  headline6: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: header3Size,
    color: Color(0xFFF8F8F8),
    shadows: <Shadow>[
      Shadow(
        color: Colors.black26,
        blurRadius: shadowRadius,
      ),
    ],
  ),
);

///
///AppBar themes
///
var appBarThemeLight = AppBarTheme(
  backgroundColor: Color(0xFFFFFFFF),
  elevation: 0,
);

var appBarThemeDark = AppBarTheme(
  backgroundColor: Color(0xFF404040),
  elevation: 0,
);

///
///Divider themes
///
var dividerThemeLight = DividerThemeData(
  space: 25,
  thickness: 1,
  color: Colors.black26,
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
      color: Color(0xFF505050),
    ),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: Color(0xFFFAB228),
    ),
  ),
);

var inputDecorationThemeDark = InputDecorationTheme(
  enabledBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: Color(0xFFF8F8F8),
    ),
  ),
  focusedBorder: UnderlineInputBorder(
    borderSide: BorderSide(
      color: Color(0xFFFAB228),
    ),
  ),
);

var checkBoxTheme = CheckboxThemeData(
  fillColor: MaterialStateProperty.resolveWith((states) {
    if (states.contains(MaterialState.selected)) {
      return Color(0xFFFAB228);
    }
    return null;
  }),
);
