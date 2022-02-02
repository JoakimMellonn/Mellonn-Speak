import 'dart:io';

import 'package:amplify_flutter/amplify.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/record/recordPage.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:path_provider/path_provider.dart';

double pricePerQ = 50.0;

class RecordPageProvider with ChangeNotifier {}

Future<double> getAudioDuration(String path) async {
  final player = AudioPlayer();
  var duration = await player.setFilePath(path);
  List<String> durationSplit = duration.toString().split(':');
  double hours = double.parse(durationSplit[0]);
  double minutes = double.parse(durationSplit[1]);
  double seconds = double.parse(durationSplit[2]);
  double totalSeconds = 3600 * hours + 60 * minutes + seconds;
  return totalSeconds;
}

double getPrice(double seconds, String userGroup) {
  double minutes = seconds / 60;
  double qPeriods = minutes.round() / 15;
  int periods = qPeriods.ceil();
  if (userGroup == "benefit") {
    pricePerQ = 40.0;
  } else if (userGroup == "dev") {
    pricePerQ = 0.0;
  } else {
    pricePerQ = 50.0;
  }
  double price = pricePerQ * periods;
  return price;
}

///
///This function first creates a new element in datastore
///Then it gets the ID of that element
///After that it uploads the selected file with the ID as the key (fancy word for filename)
///
void uploadRecording(Function() clearFilePicker) async {
  print(
      'Uploading recording with title: $title, path: $filePath, description: $description and date: $date...');
  Recording newRecording = Recording(
    name: title,
    description: description,
    date: date,
    fileName: fileName,
    fileKey: '',
    speakerCount: speakerCount,
    languageCode: languageCode,
  );
  fileType =
      key.split('.').last.toString(); //Gets the filetype of the selected file
  String newFileKey =
      '${newRecording.id}.$fileType'; //Creates the filekey from ID and filetype

  newRecording = newRecording.copyWith(
    fileKey: newFileKey,
  );

  print(
      'newRecording1: ${newRecording.name}, ${newRecording.id}, ${newRecording.fileKey}');

  //Creates a new element in DataStore
  await Amplify.DataStore.save(newRecording);

  clearFilePicker(); //clears the filepicker, doesn't work tho...

  //Saves the audio file in the app directory, so it doesn't have to be downloaded every time.
  final docDir = await getApplicationDocumentsDirectory();
  final localFilePath = docDir.path + '/$key';
  await File(filePath).copy(localFilePath);

  //Uploads the selected file with the filekey
  StorageProvider()
      .uploadFile(File(localFilePath), result, newFileKey, title, description);
}

///
///This function opens the filepicker and let's the user pick an audio file (not audiophile, that would be human trafficing)
///
void pickFile(Function() resetState, StateSetter setSheetState) async {
  resetState(); //Resets all variables to ZERO (not actually but it sounds cool)
  try {
    result = await FilePicker.platform.pickFiles(
        type: pickingType); //Opens the file picker, and only shows audio files

    ///
    ///Checks if the result isn't null, which means the user actually picked something, HURRAY!
    ///
    if (result != null) {
      //Defines all the necessary variables, and some that isn't but f**k that
      filePicked = true;
      final platformFile = result!.files.single;
      final path = platformFile.path!;
      filePath = path;
      fileName = platformFile.name;
      key = '${platformFile.name}';
      key = key.replaceAll(' ', '');
      file = File(path);
      await getAudioDuration(path);
      StorageProvider().setFileName('$fileName');
      setSheetState(() {});
    }
  } on PlatformException catch (e) {
    //If error return error message
    print('Unsupported operation' + e.toString());
  } catch (e) {
    print(e.toString());
  }
  return;
}
