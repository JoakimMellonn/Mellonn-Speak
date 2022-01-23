import 'package:flutter/material.dart';

class ColorProvider with ChangeNotifier {
  //Creating all the beautiful colors
  bool _isDarkMode = false;
  Color _backgroundColor = Color(0xFFFFFFFF);
  Color _colorText = Color(0xFF505050);
  Color _colorDarkText = Color(0xFF505050);
  Color _colorObject = Color(0xFFF8F8F8);
  Color _colorOrange = Color(0xFFFAB228);
  Color _colorShadow = Colors.black26;
  Color _colorGreen = Color(0xFFA5C644);
  Color _selectedBackground = Color(0xFFFAB228);
  String _currentLogo = 'assets/images/logoLightMode.png'; //and logo...

  //Providing those colors
  bool get isDarkMode => _isDarkMode;
  Color get backGround => _backgroundColor;
  Color get text => _colorText;
  Color get darkText => _colorDarkText;
  Color get object => _colorObject;
  Color get orange => _colorOrange;
  Color get shadow => _colorShadow;
  Color get green => _colorGreen;
  Color get selectedBackground => _selectedBackground;
  String get currentLogo => _currentLogo; //and logo... again...

  /*
  * Function for toggling darkmode
  * First checks wether it's in dark- og lightmode already
  * Then changes it to the opposite
  */
  void toggleDarkMode() {
    if (_isDarkMode) {
      setLightMode(); //If darkmode, set lightmode
    } else {
      setDarkMode(); //If lightmode, set darkmode
    }
    notifyListeners(); //You get it, don't you?
  }

  /*
  * Function for changing all the colors to the correct ones for darkmode
  */
  void setDarkMode() {
    _isDarkMode = true;
    _backgroundColor = Color(0xFF404040);
    _colorText = Color(0xFFF8F8F8);
    _colorDarkText = Color(0xFF505050);
    _colorObject = Color(0xFF505050);
    _colorOrange = Color(0xFFFAB228);
    _colorShadow = Color(0x42000000);
    _colorGreen = Color(0xFFA5C644);
    _currentLogo = 'assets/images/logoDarkMode.png'; //And logo..
    notifyListeners(); //You know what's happening here...
  }

  /*
  * Same thing as the last function, just for lightmode instead...
  */
  void setLightMode() {
    _isDarkMode = false;
    _backgroundColor = Color(0xFFFFFFFF);
    _colorText = Color(0xFF505050);
    _colorDarkText = Color(0xFF505050);
    _colorObject = Color(0xFFF8F8F8);
    _colorOrange = Color(0xFFFAB228);
    _colorShadow = Color(0x42000000);
    _colorGreen = Color(0xFFA5C644);
    _currentLogo = 'assets/images/logoLightMode.png';
    notifyListeners();
  }

  /*
  * This will soon be unnecessary... hopefully
  */
  void setBGColor(int index) {
    if (index == 1) {
      _selectedBackground = Color(0xFFFAB228);
      notifyListeners();
    } else {
      _selectedBackground = _backgroundColor;
      notifyListeners();
    }
  }
}
