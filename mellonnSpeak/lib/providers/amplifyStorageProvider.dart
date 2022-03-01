import 'dart:convert';
import 'dart:math';

import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';

class StorageProvider with ChangeNotifier {
  //Creating the necessary variables
  String _uploadFileResult = '';
  String _fileName = 'None';
  bool _uploadFailed = false;

  //Providing those variables
  String get uploadFileResult => _uploadFileResult;
  String get fileName => _fileName;
  bool get uploadFailed => _uploadFailed;

  ///
  ///Apparently I need a function for this... It's probably important
  ///
  void setFileName(String fileName) {
    _fileName = fileName;
    notifyListeners();
  }

  ///
  ///This one is quite important tho, it's uploads the given file
  ///
  Future<void> uploadFile(final file, FilePickerResult? pickResult,
      final String key, String name, String desc) async {
    _uploadFailed = false;
    //Starting the upload...
    try {
      //print('In upload');
      Map<String, String> metadata = <String,
          String>{}; //Giving the uploaded file some metadata, in this case a name and description
      metadata['name'] = name;
      metadata['desc'] = desc;
      //Changing the upload options, this one needs to be private, so no other users can see your secret stuff ;)
      S3UploadFileOptions options = S3UploadFileOptions(
          accessLevel: StorageAccessLevel.private, metadata: metadata);

      //Uploading the file and assigning the result to result, wait what!?
      UploadFileResult result = await Amplify.Storage.uploadFile(
        key: key,
        local: file,
        options: options,
      );
      _uploadFileResult = result.key; //Getting the result key
      print('Upload succesful, key: $_uploadFileResult');
      notifyListeners(); //Notifying those damn listeners
    } catch (e) {
      //As always, just in case...
      print('UploadFile Error: ' + e.toString());
      _uploadFailed = true;
      notifyListeners(); //Ya know what it is
    }
  }

  ///
  ///This function downloads the json of a finished transcription from the S3 Storage
  ///
  Future<String> downloadTranscript(String id) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = tempDir.path + '/$id.json';
    final file = File(filePath);
    final key = 'finishedJobs/$id.json';
    final S3DownloadFileOptions options = S3DownloadFileOptions(
      accessLevel: StorageAccessLevel.guest,
    );

    if (await file.exists()) {
      await file.delete();
    }

    try {
      //print('Downloading transcript with key: $key');
      await Amplify.Storage.downloadFile(
        key: key,
        local: file,
        options: options,
        onProgress: (progress) {
          //print("Fraction completed: " +
          //    progress.getFractionCompleted().toString());
        },
      );
      final String contents = file.readAsStringSync();
      //print('Downloaded contents: $contents');
      return contents;
    } on StorageException catch (e) {
      print('Error downloading file: ${e.message}');
      return 'null';
    }
  }

  ///
  ///This function saves a transcription as a json file in the S3 Storage
  ///
  Future<bool> saveTranscription(Transcription transcription, String id) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = tempDir.path + '/new-$id.json';
    final file = File(filePath);
    final key = 'finishedJobs/$id.json';
    final S3UploadFileOptions options = S3UploadFileOptions(
      accessLevel: StorageAccessLevel.guest,
    );

    final json = transcriptionToJson(transcription);

    file.writeAsString(json);

    try {
      //Uploading the file and assigning the result to result, wait what!?
      UploadFileResult result = await Amplify.Storage.uploadFile(
        key: key,
        local: file,
        options: options,
      );
      _uploadFileResult = result.key; //Getting the result key
      print('Upload succesful, key: $_uploadFileResult');
      return true;
    } catch (e) {
      //As always, just in case...
      print('UploadFile Error: ' + e.toString());
      return false;
    }
  }

  ///
  ///This function returns the path to a given audio file
  ///If the file already has been downloaded to the device it will just return that path
  ///Otherwise it will download it to the device
  ///
  Future<String> getAudioPath(String key) async {
    final docDir = await getApplicationDocumentsDirectory();
    final filePath = docDir.path + '/${key.split('/')[1]}';
    File file = File(filePath);
    final S3DownloadFileOptions options = S3DownloadFileOptions(
      accessLevel: StorageAccessLevel.private,
    );

    if (await file.exists()) {
      //print('The file already exists on the device');
      return filePath;
    } else {
      try {
        //print('Downloading audio file with key: $key');
        await Amplify.Storage.downloadFile(
          key: key,
          local: file,
          options: options,
        );
        return filePath;
      } on StorageException catch (e) {
        print('Error downloading file: $e');
        return 'null';
      }
    }
  }
}

///
///Downloads the userData file from cloud.
///
Future<UserData> downloadUserData() async {
  final tempDir = await getTemporaryDirectory();
  var rnd = Random(DateTime.now().microsecondsSinceEpoch);
  int rndInt = rnd.nextInt(9999);
  final filePath = tempDir.path + '/userData$rndInt.json';
  File file = new File(filePath);
  final S3DownloadFileOptions options = S3DownloadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );
  String key = 'userData/userData.json';

  while (await file.exists()) {
    int newInt = rnd.nextInt(9999);
    final filePath = tempDir.path + '/userData$newInt.json';
    file = new File(filePath);
  }

  try {
    print('Downloading userData');

    var result = await Amplify.Storage.downloadFile(
      key: key,
      local: file,
      options: options,
    );
    //String downloadedData = await rootBundle.loadString(result.file.path);
    String downloadedData = await file.readAsString();
    UserData downloadedUserData =
        UserData.fromJson(json.decode(downloadedData));
    return downloadedUserData;
  } on StorageException catch (e) {
    print('Error downloading UserData: ${e.message}');
    return UserData(email: 'null', freePeriods: 0);
  }
}

///
///Uploads UserData to cloud
///
Future<void> uploadUserData(UserData userData) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/userData.json';
  File file = File(filePath);
  final S3UploadFileOptions options = S3UploadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );
  String key = 'userData/userData.json';

  try {
    print('Uploading userData: ${userData.email}, ${userData.freePeriods}');
    String jsonUserData = json.encode(userData.toJson());
    await file.writeAsString(jsonUserData);
    await Amplify.Storage.uploadFile(
      local: file,
      key: key,
      options: options,
    );
    print('Upload successful');
  } on StorageException catch (e) {
    print('Error uploading UserData: ${e.message}');
  }
}

///
///Uploads a new version to the version history
///
Future<void> uploadVersion(
    String json, String recordingID, String editType) async {
  String versionID = await saveNewVersion(recordingID, editType);
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/new-$versionID.json';
  final file = File(filePath);
  final key = 'versions/$recordingID/$versionID.json';
  final S3UploadFileOptions options = S3UploadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );
  await file.writeAsString(json);

  try {
    UploadFileResult result = await Amplify.Storage.uploadFile(
      key: key,
      local: file,
      options: options,
    );
    //print('Upload succesful, key: ${result.key}');
  } on StorageException catch (e) {
    print('UploadFile Error: ${e.message}');
  }
}

///
///Downloads a given version of a transcription
///
Future<String> downloadVersion(String recordingID, String versionID) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/new-$versionID.json';
  final file = File(filePath);
  final key = 'versions/$recordingID/$versionID.json';
  final S3DownloadFileOptions options = S3DownloadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );

  try {
    var result = await Amplify.Storage.downloadFile(
      key: key,
      local: file,
      options: options,
    );
    final String contents = result.file.readAsStringSync();
    //print('Successfully downloaded version');
    return contents;
  } on StorageException catch (e) {
    print('Error downloading file: ${e.message}');
    return 'null';
  }
}

Future<bool> removeOldVersion(String recordingID, String versionID) async {
  final key = 'versions/$recordingID/$versionID.json';
  final RemoveOptions options = RemoveOptions(
    accessLevel: StorageAccessLevel.private,
  );

  try {
    var result = await Amplify.Storage.remove(key: key, options: options);
    //print('File removed successfully');
    return true;
  } on StorageException catch (e) {
    print('Error while removing file: ${e.message}');
    return false;
  }
}

///
///Checks if the original already exists, if it doesn't it will create it
///
Future<bool> checkOriginalVersion(
    String recordingID, Transcription transcription) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/original.json';
  final file = File(filePath);
  final key = 'versions/$recordingID/original.json';
  bool originalExists = false;

  try {
    final S3DownloadFileOptions options = S3DownloadFileOptions(
      accessLevel: StorageAccessLevel.private,
    );
    await Amplify.Storage.downloadFile(
      key: key,
      local: file,
      options: options,
    );
    originalExists = true;
  } on StorageException catch (e) {
    print('The original transcript have not been saved yet... Saving.');

    try {
      final S3UploadFileOptions options = S3UploadFileOptions(
        accessLevel: StorageAccessLevel.private,
      );
      String json = transcriptionToJson(transcription);
      await file.writeAsString(json);
      UploadFileResult result = await Amplify.Storage.uploadFile(
        key: key,
        local: file,
        options: options,
      );
      print('Uploaded original file with key: ${result.key}');
      originalExists = true;
    } on StorageException catch (e) {
      print('Error saving original: ${e.message}');
      originalExists = false;
    } catch (e) {
      print('Other error saving original: $e');
      originalExists = false;
    }
  }
  return originalExists;
}
