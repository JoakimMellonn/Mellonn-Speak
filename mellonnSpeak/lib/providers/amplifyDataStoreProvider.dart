import 'package:flutter/material.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/models/Recording.dart';

class DataStoreAppProvider with ChangeNotifier {
  //Creating the necessary variable
  List<Recording> _recordings = [];
  UserData _userData = UserData();

  //Providing the variable
  List<Recording> get recordings => _recordings;
  UserData get userData => _userData;

  ///
  ///This will check if there's more than zero recordings in the list.
  ///If there is it will clear the list and the Amplify cache, then it will reload em.
  ///If there isn't it will just send a query to see if there's some goodies in the cloud.
  ///
  Future<void> getRecordings() async {
    if (_recordings.length != 0) {
      bool hasCleared = await clearRecordings();
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
  Future<bool> clearRecordings() async {
    try {
      await Amplify.DataStore.clear();
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
    UserData userData = UserData(
      email: email,
      freePeriods: 1,
    );
    try {
      await Amplify.DataStore.save(userData);
    } on DataStoreException catch (e) {
      print('Create UserData error: ${e.message}');
    }
    await getUserData();
    notifyListeners();
  }

  ///
  ///Fetches the user data and returns the ID of the object
  ///
  Future<String> getUserData() async {
    List<UserData> _listUserData = [];

    try {
      _listUserData = await Amplify.DataStore.query(UserData.classType);
      _userData = _listUserData.first;
      print('Free periods: ${_userData.freePeriods}');
    } on DataStoreException catch (e) {
      print('Get UserData error: ${e.message}');
    }
    notifyListeners();
    return _userData.id;
  }

  ///
  ///Updates the UserData with a given number of free periods (In most cases this would be 0)
  ///
  Future<void> updateUserData(int newFreePeriods) async {
    String userDataID = await getUserData();

    try {
      UserData oldData = (await Amplify.DataStore.query(UserData.classType,
          where: UserData.ID.eq(userDataID)))[0];
      UserData newData = oldData.copyWith(
        freePeriods: newFreePeriods,
      );
      await Amplify.DataStore.save(newData);
    } on DataStoreException catch (e) {
      print('Update UserData error: ${e.message}');
    }
    await getUserData();
    notifyListeners();
  }
}
