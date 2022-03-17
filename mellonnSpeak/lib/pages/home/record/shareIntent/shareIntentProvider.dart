import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/record/recordPageProvider.dart';
import 'package:mellonnSpeak/pages/home/record/shareIntent/shareIntentPage.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

Periods getSharedPeriods(double seconds, UserData userData, String userGroup) {
  double minutes = seconds / 60;
  double qPeriods = minutes / 15;
  int totalPeriods = qPeriods.ceil();
  final int freePeriods = userData.freePeriods;
  int periods = 0;
  int freeLeft = 0;
  bool freeUsed = false;

  if (freePeriods > 0) {
    freeUsed = true;
  }

  if (totalPeriods >= freePeriods) {
    freeLeft = 0;
    periods = totalPeriods - freePeriods;
  } else {
    freeLeft = freePeriods - totalPeriods;
    periods = 0;
  }
  print(
      'totalPeriods: $totalPeriods, freePeriods: $freePeriods, periods: $periods, freeLeft: $freeLeft');
  Periods returnPeriods = Periods(
    total: totalPeriods,
    periods: periods,
    freeLeft: freeLeft,
    freeUsed: freeUsed,
  );

  productDetails = getProductsIAP(
    returnPeriods.total,
    userGroup,
  );
  discountText = getDiscount(
    returnPeriods.total - returnPeriods.periods,
    userGroup,
  );
  print('${productDetails.price}, $discountText');

  return returnPeriods;
}

Future<double> getSharedAudioDuration(String path) async {
  final player = AudioPlayer();
  var duration = await player.setFilePath(path);
  await player.dispose();
  List<String> durationSplit = duration.toString().split(':');
  double hours = double.parse(durationSplit[0]);
  double minutes = double.parse(durationSplit[1]);
  double seconds = double.parse(durationSplit[2]);
  double totalSeconds = 3600 * hours + 60 * minutes + seconds;
  print(totalSeconds);
  return totalSeconds;
}

Future<void> uploadSharedRecording(File file, String title, String description,
    String fileName, int speakerCount, String languageCode) async {
  TemporalDateTime date = TemporalDateTime.now();

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
  fileType = fileName
      .split('.')
      .last
      .toString(); //Gets the filetype of the selected file
  String newFileKey =
      'recordings/${newRecording.id}.$fileType'; //Creates the file key from ID and filetype

  newRecording = newRecording.copyWith(
    fileKey: newFileKey,
  );

  print(
      'newRecording: ${newRecording.name}, ${newRecording.id}, ${newRecording.fileKey}');

  //Creates a new element in DataStore
  try {
    await Amplify.DataStore.save(newRecording);
  } on DataStoreException catch (e) {
    recordEventError('uploadRecording', e.message);
    print(e.message);
  }

  late Directory directory;
  if (Platform.isIOS) {
    directory = await getLibraryDirectory();
  } else {
    directory = await getApplicationDocumentsDirectory();
  }
  localFilePath = directory.path + '/${newRecording.id}.$fileType';

  //Saves the audio file in the app directory, so it doesn't have to be downloaded every time.
  File uploadFile = await file.copy(localFilePath);

  //Uploads the selected file with the file key
  await StorageProvider()
      .uploadFile(uploadFile, newFileKey, title, description);
}
