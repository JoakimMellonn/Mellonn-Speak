import 'package:flutter/material.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:transscriber/models/ModelProvider.dart';
import 'package:transscriber/models/Recording.dart';

class DataStoreAppProvider with ChangeNotifier {
  //Creating the necessary variable
  List<Recording> _recordings = [];

  //Providing the variable
  List<Recording> get recordings => _recordings;

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
}
