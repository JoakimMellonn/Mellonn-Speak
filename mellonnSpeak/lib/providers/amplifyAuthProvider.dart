import 'dart:convert';
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:path_provider/path_provider.dart';

class AuthAppProvider with ChangeNotifier {
  String _email = "Couldn't get your email";
  String _firstName = "First name";
  String _lastName = "Last name";
  String _userGroup = "none";
  String _referrer = "none";
  String _referGroup = "none";
  bool _superDev = false;
  int _freePeriods = 0;

  String get email => _email;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get userGroup => _userGroup;
  String get referrer => _referrer;
  String get referGroup => _referGroup;
  bool get superDev => _superDev;
  int get freePeriods => _freePeriods;

  /*
  * Creating the function that gets the user attributes
  */
  Future<void> getUserAttributes() async {
    try {
      var res = await Amplify.Auth.fetchUserAttributes();

      res.forEach((element) async {
        if (element.userAttributeKey == CognitoUserAttributeKey.email) {
          _email = element.value;
        } else if (element.userAttributeKey == CognitoUserAttributeKey.name) {
          _firstName = element.value;
        } else if (element.userAttributeKey == CognitoUserAttributeKey.familyName) {
          _lastName = element.value;
        } else if (element.userAttributeKey == CognitoUserAttributeKey.custom('group')) {
          _userGroup = element.value;
        } else if (element.userAttributeKey == CognitoUserAttributeKey.custom('superdev')) {
          if (element.value == 'true') {
            print('Super Dev!');
            _superDev = true;
          } else {
            _superDev = false;
          }
        } else if (element.userAttributeKey == CognitoUserAttributeKey.custom('freecredits')) {
          _freePeriods = int.parse(element.value);
        } else if (element.userAttributeKey == CognitoUserAttributeKey.custom('referrer')) {
          _referrer = element.value;
          print('Referrer: ${element.value}');
        } else if (element.userAttributeKey == CognitoUserAttributeKey.custom('refergroup')) {
          _referGroup = element.value;
        }
      });
      if (_userGroup != 'dev') {
        bool isUserBenefit = await checkBenefit(_email);
        print('Benefit user: $isUserBenefit');
        if (_userGroup == 'user' && !isUserBenefit || _userGroup == 'benefit' && isUserBenefit) {
          _userGroup = _userGroup;
        } else {
          await changeBenefit(isUserBenefit);
          _userGroup = isUserBenefit ? 'benefit' : 'user';
        }
      } else {
        _userGroup = _userGroup;
      }
      UserData data = await DataStoreAppProvider().getUserData(_email);
      _freePeriods = data.freePeriods;
      notifyListeners();
    } on AuthException catch (e) {
      recordEventError('getUserAttributes', e.message);
      print(e.message);
    }
  }

  void signOut() {
    _email = "Couldn't get your email";
    _firstName = "First name";
    _lastName = "Last name";
    _userGroup = "none";
    _referrer = "none";
    _referGroup = "none";
    _superDev = false;
    _freePeriods = 0;
    notifyListeners();
  }
}

///
///Check if the user with given email is a benefit user
///
Future<bool> checkBenefit(String email) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/benefitUsers.json';
  final file = File(filePath);
  final key = 'data/benefitUsers.json';
  final StorageDownloadFileOptions options = StorageDownloadFileOptions(
    accessLevel: StorageAccessLevel.guest,
  );
  bool returnElement = false;

  if (await file.exists()) {
    await file.delete();
  }

  try {
    await Amplify.Storage.downloadFile(
      key: key,
      localFile: AWSFile.fromPath(file.path),
      options: options,
    ).result;
    String loadedJson = await file.readAsString();
    BenefitUsers benefitUsers = BenefitUsers.fromJson(json.decode(loadedJson));

    for (String benefitEmail in benefitUsers.emails) {
      if (benefitEmail == email) {
        returnElement = true;
        break;
      }
    }
  } on StorageException catch (e) {
    recordEventError('isBenefit', e.message);
    print('ERROR: ${e.message}');
    return false;
  }
  return returnElement;
}

///
///Adds a user to the benefit list
///
Future<void> addBenefit(String email) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/benefitUsers.json';
  final file = File(filePath);
  final key = 'data/benefitUsers.json';
  final StorageDownloadFileOptions options = StorageDownloadFileOptions(
    accessLevel: StorageAccessLevel.guest,
  );

  if (await file.exists()) {
    await file.delete();
  }

  try {
    await Amplify.Storage.downloadFile(
      key: key,
      localFile: AWSFile.fromPath(file.path),
      options: options,
    ).result;
    String loadedJson = await file.readAsString();
    BenefitUsers benefitUsers = BenefitUsers.fromJson(json.decode(loadedJson));

    List<String> newEmails = benefitUsers.emails;
    newEmails.add(email);
    BenefitUsers newBenefitUsers = BenefitUsers(emails: newEmails);
    await file.writeAsString(json.encode(newBenefitUsers.toJson()));

    try {
      final uploadOptions = StorageUploadFileOptions(
        accessLevel: StorageAccessLevel.guest,
      );
      await Amplify.Storage.uploadFile(
        localFile: AWSFile.fromPath(file.path),
        key: key,
        options: uploadOptions,
      ).result;
    } on StorageException catch (e) {
      recordEventError('addBenefit-upload', e.message);
      print('ERROR: ${e.message}');
    }
  } on StorageException catch (e) {
    recordEventError('addBenefit-download', e.message);
    print('ERROR: ${e.message}');
  }
}

///
///Changes the current user to be either benefit or not
///
Future<void> changeBenefit(bool isBenefit) async {
  try {
    var attributes = [
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.custom("group"),
        value: isBenefit ? 'benefit' : 'user',
      ),
    ];

    await Amplify.Auth.updateUserAttributes(attributes: attributes);
  } on AuthException catch (e) {
    recordEventError('changeBenefit', e.message);
    print(e.message);
  }
}

class BenefitUsers {
  List<String> emails;

  BenefitUsers({
    required this.emails,
  });

  factory BenefitUsers.fromJson(Map<String, dynamic> json) => BenefitUsers(
        emails: json["emails"].cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        "emails": emails,
      };
}
