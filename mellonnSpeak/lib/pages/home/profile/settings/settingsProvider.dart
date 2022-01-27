import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:path_provider/path_provider.dart';

class SettingsProvider with ChangeNotifier {
  //Creating the variables
  Settings defaultSettings =
      Settings(themeMode: 'System', languageCode: 'da-DK');
  Settings _currentSettings =
      Settings(themeMode: 'System', languageCode: 'da-DK');

  //Providing them
  Settings get currentSettings => _currentSettings;

  ///
  ///This function will load the current settings for the one asking
  ///(It will return a Settings element)
  ///
  Future<Settings> getSettings() async {
    //Getting the folder for the settings.json file
    final directory = await getApplicationDocumentsDirectory();
    File file = File('${directory.path}/settings.json');

    ///
    ///It will first try and get a settings.json file from the application folder
    ///If this doesn't exist, it will get the default settings from the assets
    ///
    try {
      String loadedSettingsJSON = file.readAsStringSync();
      Settings loadedSettings =
          Settings.fromJson(json.decode(loadedSettingsJSON));

      return loadedSettings;
    } catch (e) {
      print('No settings saved on device...');
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
    //Getting the folder for the settings.json file and setting the currentSettings
    final directory = await getApplicationDocumentsDirectory();
    File file = File('${directory.path}/settings.json');
    _currentSettings = saveData;
    notifyListeners();

    //Converts the provided Settings to json and saving it on the device
    String settingsJSON = json.encode(saveData.toJson());
    file.writeAsString(settingsJSON);
    return true;
  }

  ///
  ///This function will get the default settings from the json in assets
  ///And then return a Settings element and save it
  ///
  Future<Settings> getDefaultSettings() async {
    //Getting the assets file
    String loadedData =
        await rootBundle.loadString("assets/json/settings.json");
    //converting the file to a Settings element
    Settings defaultSettings = Settings.fromJson(json.decode(loadedData));
    //Saves it and returns the element
    saveSettings(defaultSettings);
    return defaultSettings;
  }

  ///
  ///This function will reset the settings to default
  ///This will either be done with the file in assets or with the variable
  ///It will then save the settings
  ///
  Future<bool> setDefaultSettings(bool fromAssets) async {
    if (fromAssets) {
      Settings defaultS = await getDefaultSettings();
      bool saved = await saveSettings(defaultS);
      return saved;
    } else {
      bool saved = await saveSettings(defaultSettings);
      return saved;
    }
  }

  void setTheme(String theme) {
    if (theme == 'System') {
      Get.changeThemeMode(ThemeMode.system);
      themeMode = ThemeMode.system;
    } else if (theme == 'Light') {
      Get.changeThemeMode(ThemeMode.light);
      themeMode = ThemeMode.light;
    } else {
      Get.changeThemeMode(ThemeMode.dark);
      themeMode = ThemeMode.dark;
    }
    notifyListeners();
  }
}

///
///Creating the Settings class
///This is easy to update when there comes more settings
///It also contains the right function for convert it to and from json
///
class Settings {
  Settings({
    required this.themeMode,
    required this.languageCode,
  });

  String themeMode;
  String languageCode;

  factory Settings.fromJson(Map<String, dynamic> json) => Settings(
        themeMode: json["themeMode"],
        languageCode: json["languageCode"],
      );

  Map<String, dynamic> toJson() => {
        "themeMode": themeMode,
        "languageCode": languageCode,
      };
}
