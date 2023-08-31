import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mellonnSpeak/pages/login/loginPage.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:mellonnSpeak/models/Settings.dart';

class SettingsProvider with ChangeNotifier {
  //Creating the variables
  Settings defaultSettings = new Settings(themeMode: 'System', languageCode: 'en-US', jumpSeconds: 3);
  Settings _currentSettings = new Settings(themeMode: 'System', languageCode: 'en-US', jumpSeconds: 3);

  Settings get currentSettings => _currentSettings;
  String get themeMode => _currentSettings.themeMode;
  String get languageCode => _currentSettings.languageCode;
  int get jumpSeconds => _currentSettings.jumpSeconds;

  set themeMode(String themeMode) {
    saveSettings(_currentSettings.copyWith(themeMode: themeMode));
    notifyListeners();
  }

  set languageCode(String languageCode) {
    saveSettings(_currentSettings.copyWith(languageCode: languageCode));
    notifyListeners();
  }

  set jumpSeconds(int jumpSeconds) {
    saveSettings(_currentSettings.copyWith(jumpSeconds: jumpSeconds));
    notifyListeners();
  }

  ///
  ///This function will load the current settings for the one asking
  ///(It will return a Settings element)
  ///
  Future<Settings> getSettings() async {
    print('Get settings...');
    try {
      Settings downloadedSettings = defaultSettings;
      List<Settings> settings = await Amplify.DataStore.query(Settings.classType);
      if (settings.length == 0) {
        downloadedSettings = await getDefaultSettings();
        await saveSettings(downloadedSettings);
      } else {
        if (settings.length > 1) {
          for (int i = settings.length; i > 1; i--) {
            await Amplify.DataStore.delete(settings[i - 1]);
          }
          settings = await Amplify.DataStore.query(Settings.classType);
        }
        downloadedSettings = settings.first;
      }
      return downloadedSettings;
    } on DataStoreException catch (e) {
      AnalyticsProvider().recordEventError('downloadSettings', e.message);
      print('Error downloading Settings: ${e.message}');
      return await getDefaultSettings();
    }
  }

  ///
  ///This function will update the provided currentSettings
  ///It will update it with the loaded settings from device data
  ///
  Future<void> setCurrentSettings() async {
    _currentSettings = await getSettings();
    setTheme(_currentSettings.themeMode);
    notifyListeners();
  }

  ///
  ///This function can be called to save the settings
  ///It requires a Settings element, which it will convert to a json and save
  ///The function will then return a true when done
  ///
  Future<bool> saveSettings(Settings saveData) async {
    _currentSettings = saveData;
    notifyListeners();
    try {
      await Amplify.DataStore.save(saveData);
      setTheme(saveData.themeMode);
      notifyListeners();
      return true;
    } on DataStoreException catch (err) {
      AnalyticsProvider().recordEventError('saveSettings', err.message);
      print('Error uploading settings: ${err.message}');
      return false;
    }
  }

  ///
  ///This function will get the default settings from the json in assets
  ///And then return a Settings element and save it
  ///
  Future<Settings> getDefaultSettings() async {
    print('Get default settings...');
    try {
      final settings = await Amplify.DataStore.query(Settings.classType);
      final countryCode = Platform.localeName;
      if (LanguageProvider().languageCodeList.contains(countryCode)) {
        if (settings.length != 0) {
          Settings returnSettings = settings.first.copyWith(
            themeMode: defaultSettings.themeMode,
            languageCode: countryCode,
            jumpSeconds: defaultSettings.jumpSeconds,
          );
          return returnSettings;
        } else {
          return defaultSettings.copyWith(languageCode: countryCode);
        }
      } else {
        if (settings.length != 0) {
          Settings returnSettings = settings.first.copyWith(
            themeMode: defaultSettings.themeMode,
            languageCode: defaultSettings.languageCode,
            jumpSeconds: defaultSettings.jumpSeconds,
          );
          return returnSettings;
        } else {
          return defaultSettings;
        }
      }
    } on DataStoreException catch (e) {
      AnalyticsProvider().recordEventError('getSettings', e.message);
      print('Error downloading Settings: ${e.message}');
      return defaultSettings;
    }
  }

  Future<Settings> setDefaultSettings() async {
    Settings defaultS = await getDefaultSettings();
    await saveSettings(defaultS);
    return defaultS;
  }

  void setTheme(String theme) {
    if (theme == 'System') {
      Get.changeThemeMode(ThemeMode.system);
      var brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      bool isDarkMode = brightness == Brightness.dark;
      if (isDarkMode) {
        currentLogo = darkModeLogo;
      } else {
        currentLogo = lightModeLogo;
      }
    } else if (theme == 'Light') {
      Get.changeThemeMode(ThemeMode.light);
      currentLogo = lightModeLogo;
    } else {
      Get.changeThemeMode(ThemeMode.dark);
      currentLogo = darkModeLogo;
    }
    notifyListeners();
  }
}

///
///Creating the Settings class
///This is easy to update when there comes more settings
///It also contains the right function for convert it to and from json
///
/*class Settings {
  Settings({
    required this.themeMode,
    required this.languageCode,
    required this.jumpSeconds,
  });

  String themeMode;
  String languageCode;
  int jumpSeconds;

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        themeMode: json["themeMode"],
        languageCode: json["languageCode"],
        jumpSeconds: json["jumpSeconds"] ?? 3,
      );

  Map<String, dynamic> toJson() => {
        "themeMode": themeMode,
        "languageCode": languageCode,
        "jumpSeconds": jumpSeconds,
      };
}*/

String getRegion() {
  String countryCode = WidgetsBinding.instance.platformDispatcher.locale.countryCode ?? 'DK';
  List<String> euCountries = [
    'BE',
    'BG',
    'CZ',
    'DE',
    'EE',
    'IE',
    'EL',
    'ES',
    'FR',
    'HR',
    'IT',
    'CY',
    'LV',
    'LT',
    'LU',
    'HU',
    'MT',
    'NL',
    'AT',
    'PL',
    'PT',
    'RO',
    'SI',
    'SK',
    'FI',
    'SE',
  ];
  String region = '';

  if (countryCode == 'DK') {
    region = 'dk';
  } else if (euCountries.contains(countryCode)) {
    region = 'eu';
  } else {
    region = 'intl';
  }
  return region;
}

Future<void> removeUser(context) async {
  showDialog(
    context: context,
    builder: (BuildContext context) => SureDialog(
      onYes: () async {
        await removeUserFiles();
        await Amplify.Auth.deleteUser();
        await Amplify.DataStore.clear();
        Navigator.pop(context);
        //Sends the user back to the login screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ),
        );
      },
      text: 'You are about to remove your user and ALL of its associated data, THIS CAN NOT BE UNDONE!',
    ),
  );
}
