import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:flutter/material.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';

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

  void listenToStream() {
    // initialize a boolean indicating if the sync process has completed
    bool isSynced = false;

    // update local variables each time a new snapshot is received
    stream.listen((QuerySnapshot<Recording> snapshot) {
      _reversedRecordings = snapshot.items;
      isSynced = snapshot.isSynced;
      print('Something happened');
      notifyListeners();
    });
  }

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
  ///This function asks Amplify kindly to send a list of the recordings that the user has stored
  ///Then it puts everything into a list, how smart
  ///
  Future<void> recordingsQuery() async {
    try {
      _recordings = await Amplify.DataStore.query(
        Recording.classType,
        sortBy: [Recording.DATE.ascending()],
      ); //Query for the recordings
      print('Recordings loaded: ${_recordings.length}');
      notifyListeners(); //Notifying that dinner is ready
    } on DataStoreException catch (e) {
      print('Query failed: $e');
      notifyListeners(); //Notifying that something went wrong :(
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
  ///Creates the user data, which contains how many free periods of 15 mins a user has
  ///
  Future<void> createUserData(String email) async {
    UserData standardUserData = UserData(email: email, freePeriods: 1);
    await uploadUserData(standardUserData);
    notifyListeners();
  }

  ///
  ///Fetches the user data and returns the ID of the object
  ///
  Future<UserData> getUserData(String email) async {
    UserData loadedUserData = await downloadUserData();

    if (loadedUserData.email == 'null') {
      print('Creating new userData');
      await createUserData(email);
      loadedUserData = await downloadUserData();
    }

    _userData = loadedUserData;
    notifyListeners();
    return loadedUserData;
  }

  ///
  ///Updates the UserData with a given number of free periods (In most cases this would be 0)
  ///
  Future<UserData> updateUserData(int newFreePeriods, String email) async {
    UserData newUserData = UserData(email: email, freePeriods: newFreePeriods);
    _userData = newUserData;
    notifyListeners();
    await uploadUserData(newUserData);
    await Future.delayed(Duration(milliseconds: 1500));
    UserData returnData = await getUserData(email);
    return returnData;
  }
}

///
///Creates a new version's element in the given recording.
///Returns the id of the version.
///
Future<String> saveNewVersion(String recordingID) async {
  Recording oldRecording = (await Amplify.DataStore.query(Recording.classType,
      where: Recording.ID.eq(recordingID)))[0];
  List<Version> versionList = oldRecording.versions ?? [];
  Version newVersion = Version(
    recordingID: recordingID,
    date: TemporalDateTime.now(),
  );

  if (versionList.length >= 10) {
    String oldFileKey = 'versions/${versionList[0].id}.json';
    try {
      RemoveResult removeRes = await Amplify.Storage.remove(key: oldFileKey);
      print('Version file removed successfully: ${removeRes.toString()}');
    } on StorageException catch (e) {
      print('Version file error while removing: ${e.message}');
    }
    versionList.add(newVersion);
  } else {
    versionList.add(newVersion);
  }
  try {
    Recording newRecording = oldRecording.copyWith(
      versions: versionList,
    );
    var result = await Amplify.DataStore.save(newRecording);
    return newVersion.id;
  } on DataStoreException catch (e) {
    print('Failed updating version list');
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
        freePeriods: json["freePeriods"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "freePeriods": freePeriods,
      };
}
