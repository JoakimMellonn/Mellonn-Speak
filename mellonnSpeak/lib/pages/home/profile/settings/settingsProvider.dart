import 'dart:math';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/pages/login/loginPage.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:path_provider/path_provider.dart';

class SettingsProvider with ChangeNotifier {
  //Creating the variables
  Settings defaultSettings =
      Settings(themeMode: 'System', languageCode: 'da-DK', jumpSeconds: 3);
  Settings _currentSettings =
      Settings(themeMode: 'System', languageCode: 'da-DK', jumpSeconds: 3);

  //Providing them
  Settings get currentSettings => _currentSettings;

  ///
  ///This function will load the current settings for the one asking
  ///(It will return a Settings element)
  ///
  Future<Settings> getSettings() async {
    final tempDir = await getTemporaryDirectory();
    var rnd = Random(DateTime.now().microsecondsSinceEpoch);
    int rndInt = rnd.nextInt(9999);
    final filePath = tempDir.path + '/settings$rndInt.json';
    File file = new File(filePath);
    final S3DownloadFileOptions options = S3DownloadFileOptions(
      accessLevel: StorageAccessLevel.private,
    );
    String key = 'userData/settings.json';

    while (await file.exists()) {
      int newInt = rnd.nextInt(9999);
      final filePath = tempDir.path + '/settings$newInt.json';
      file = new File(filePath);
    }

    try {
      await Amplify.Storage.downloadFile(
        key: key,
        local: file,
        options: options,
      );
      String downloadedData = await file.readAsString();
      Settings downloadedSettings =
          Settings.fromJson(json.decode(downloadedData));
      return downloadedSettings;
    } on StorageException catch (e) {
      recordEventError('downloadSettings', e.message);
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
    //Getting the folder for the settings.json file and setting the currentSettings
    final tempDir = await getTemporaryDirectory();
    final filePath = tempDir.path + '/settings.json';
    File file = File(filePath);
    final key = 'userData/settings.json';
    final S3UploadFileOptions options = S3UploadFileOptions(
      accessLevel: StorageAccessLevel.private,
    );
    _currentSettings = saveData;

    try {
      String settingsJSON = json.encode(saveData.toJson());
      await file.writeAsString(settingsJSON);
      await Amplify.Storage.uploadFile(local: file, key: key, options: options);
      setCurrentSettings();
      return true;
    } on StorageException catch (err) {
      recordEventError('saveSettings', err.message);
      print('Error while uploading settings: ${err.message}');
      return false;
    } catch (err) {
      recordEventError('saveSettingsOther', err.toString());
      print('Other error: $err');
      return false;
    }
  }

  ///
  ///This function will get the default settings from the json in assets
  ///And then return a Settings element and save it
  ///
  Future<Settings> getDefaultSettings() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = tempDir.path + '/defaultSettings.json';
    File file = File(filePath);
    final key = 'data/settings.json';
    final S3DownloadFileOptions options = S3DownloadFileOptions(
      accessLevel: StorageAccessLevel.guest,
    );

    try {
      var result = await Amplify.Storage.downloadFile(
        key: key,
        local: file,
        options: options,
      );
      String downloadedData = await file.readAsString();
      print('UserData: $downloadedData');
      Settings downloadedSettings =
          Settings.fromJson(json.decode(downloadedData));
      await saveSettings(downloadedSettings);
      return downloadedSettings;
    } on StorageException catch (e) {
      recordEventError('downloadUserData', e.message);
      print('Error downloading UserData: ${e.message}');
      return await getDefaultSettings();
    }
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
      var brightness = SchedulerBinding.instance!.window.platformBrightness;
      bool isDarkMode = brightness == Brightness.dark;
      if (isDarkMode) {
        currentLogo = darkModeLogo;
      } else {
        currentLogo = lightModeLogo;
      }
    } else if (theme == 'Light') {
      Get.changeThemeMode(ThemeMode.light);
      themeMode = ThemeMode.light;
      currentLogo = lightModeLogo;
    } else {
      Get.changeThemeMode(ThemeMode.dark);
      themeMode = ThemeMode.dark;
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
class Settings {
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
}

String getRegion() {
  String countryCode =
      WidgetsBinding.instance?.window.locale.countryCode ?? 'DK';
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
    builder: (BuildContext context) => AlertDialog(
      title: Text('Are you ABSOLUTELY sure?'),
      content: Text(
          'You are about to remove your user and ALL of its associated data, THIS CAN NOT BE UNDONE!'),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                //If they aren't, it will just close the dialog, and they can live happily everafter
                Navigator.pop(context);
              },
              child: Text(
                'No',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.amber,
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 75,
            ),
            TextButton(
              onPressed: () async {
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
              child: Text(
                'Yes',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.amber,
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
