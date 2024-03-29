import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';

class DataStoreAppProvider with ChangeNotifier {
  //Creating the necessary variable
  List<Recording> _recordings = [];
  List<Recording> _reversedRecordings = [];
  UserData _userData = UserData(email: '', freePeriods: 0);

  //Providing the variable
  List<Recording> get recordings => _recordings;
  List<Recording> get reversedRecordings => _reversedRecordings;
  UserData get userData => _userData;

  Stream<QuerySnapshot<Recording>> stream = Amplify.DataStore.observeQuery(
    Recording.classType,
    sortBy: [Recording.DATE.descending()],
  );

  ///
  ///This will check if there's more than zero recordings in the list.
  ///If there is it will clear the list and the Amplify cache, then it will reload em.
  ///If there isn't it will just send a query to see if there's some goodies in the cloud.
  ///
  Future<void> getRecordings() async {
    if (_recordings.length != 0) {
      bool hasCleared = await clearRecordings(false);
      if (hasCleared) {
        await recordingsQuery();
        if (_recordings.length == 0) {
          await Future.delayed(Duration(milliseconds: 1000));
          await recordingsQuery();
        }
      } else {
        await getRecordings();
      }
    } else {
      await Future.delayed(Duration(milliseconds: 1000));
      await recordingsQuery();
    }
  }

  ///
  ///This function returns a single recording with the given ID
  ///
  Future<Recording?> getRecording(String id) async {
    try {
      final recording = await Amplify.DataStore.query(Recording.classType, where: Recording.ID.eq(id));
      return recording.first;
    } on DataStoreException catch (e) {
      AnalyticsProvider().recordEventError('getRecording', e.message);
      print('Query failed: $e');
      return null;
    }
  }

  ///
  ///This function asks Amplify kindly to send a list of the recordings that the user has stored
  ///Then it puts everything into a list, how smart
  ///
  Future<void> recordingsQuery() async {
    try {
      _recordings = await Amplify.DataStore.query(
        Recording.classType,
        sortBy: [Recording.DATE.ascending()],
      );
      print('Recordings loaded: ${_recordings.length}');
      notifyListeners();
    } on DataStoreException catch (e) {
      AnalyticsProvider().recordEventError('recordingsQuery', e.message);
      print('Query failed: $e');
      notifyListeners();
    }
  }

  ///
  ///Function for clearing the recordings
  ///
  Future<bool> clearRecordings(bool clearList) async {
    try {
      await Amplify.DataStore.clear();
      if (clearList) {
        _recordings = [];
        notifyListeners();
      }
      return true;
    } catch (e) {
      AnalyticsProvider().recordEventError('clearRecordings', e.toString());
      return false;
    }
  }

  ///
  ///Call this function to get the dataID of the element with the given name
  ///
  Future<String> dataID(String name) async {
    List<Recording> _recordings = [];

    //Gets a list of recordings
    try {
      _recordings = await Amplify.DataStore.query(Recording.classType);
    } on DataStoreException catch (e) {
      AnalyticsProvider().recordEventError('dataID', e.message);
      print('Query failed: $e');
    }

    //Checks if the recording name is equal to the given name and returns the ID if true
    for (Recording recording in _recordings) {
      if (recording.name == name) {
        return recording.id;
      }
    }
    //Returns nothing if nothing
    return '';
  }

  ///
  ///User data stuff
  ///
  Future<void> createUserData(String email) async {
    UserData standardUserData = UserData(email: email, freePeriods: 1);
    await uploadUserData(standardUserData);
    notifyListeners();
  }

  Future<UserData> getUserData(String email) async {
    UserData loadedUserData = UserData(email: email, freePeriods: 0);
    final userAttributes = await Amplify.Auth.fetchUserAttributes();
    bool freePeriodsExists = false;

    for (var element in userAttributes) {
      if (element.userAttributeKey == CognitoUserAttributeKey.custom('freecredits')) {
        loadedUserData.freePeriods = int.parse(element.value);
        freePeriodsExists = true;
      }
    }

    if (!freePeriodsExists) {
      loadedUserData = await downloadUserData();
      if (loadedUserData.email == 'null') {
        print('Creating new userData');
        await createUserData(email);
        loadedUserData = await downloadUserData();
      }
      await Amplify.Auth.updateUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.custom('freeCredits'),
        value: loadedUserData.freePeriods.toString(),
      );
    }

    _userData = loadedUserData;
    notifyListeners();
    return loadedUserData;
  }

  Future<UserData> updateUserData(int newFreePeriods, String email) async {
    UserData newUserData = UserData(email: email, freePeriods: newFreePeriods);
    _userData = newUserData;
    notifyListeners();
    await Amplify.Auth.updateUserAttribute(
      userAttributeKey: CognitoUserAttributeKey.custom('freeCredits'),
      value: newUserData.freePeriods.toString(),
    );
    UserData returnData = await getUserData(email);
    return returnData;
  }
}

///
///Creates a new version's element in the given recording.
///Returns the id of the version.
///
Future<String> saveNewVersion(String recordingID, String editType) async {
  Version newVersion = Version(
    recordingID: recordingID,
    date: TemporalDateTime.now(),
    editType: editType,
  );

  try {
    await Amplify.DataStore.save(newVersion);
  } on DataStoreException catch (e) {
    AnalyticsProvider().recordEventError('saveNewVersion', e.message);
    print('Failed updating version list');
  }

  try {
    List<Version> versions = await Amplify.DataStore.query(
      Version.classType,
      where: Version.RECORDINGID.eq(recordingID),
      sortBy: [Version.DATE.ascending()],
    );

    if (versions.length > 10) {
      (await Amplify.DataStore.query(Version.classType, where: Version.ID.eq(versions[0].id))).forEach(
        (element) async {
          try {
            await Amplify.DataStore.delete(element);
            bool removed = await removeOldVersion(recordingID, element.id);
            if (!removed) {
              print('Failed removing the old version file');
            }
            print('Successfully removed old version');
          } on DataStoreException catch (e) {
            AnalyticsProvider().recordEventError('saveNewVersion-removeOld', e.message);
            print('Error deleting datastore element: ${e.message}');
          }
        },
      );
    }
    return newVersion.id;
  } on DataStoreException catch (e) {
    AnalyticsProvider().recordEventError('saveNewVersion-checkLength', e.message);
    print(e.message);
    return 'null';
  }
}

class UserData {
  String email;
  int freePeriods;

  UserData({
    required this.email,
    required this.freePeriods,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
        email: json["email"],
        freePeriods: json["freePeriods"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "freePeriods": freePeriods,
      };
}
