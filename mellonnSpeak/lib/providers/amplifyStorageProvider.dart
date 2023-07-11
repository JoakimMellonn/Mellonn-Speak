import 'dart:convert';
import 'dart:math';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/models/Version.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';

const supportedExtensions = ['amr', 'flac', 'mp3', 'mp4', 'ogg', 'webm', 'wav'];

class StorageProvider with ChangeNotifier {
  //Creating the necessary variables
  String _uploadFileResult = '';
  String _fileName = 'None';
  bool _uploadFailed = false;

  String get uploadFileResult => _uploadFileResult;
  String get fileName => _fileName;
  bool get uploadFailed => _uploadFailed;

  void setFileName(String fileName) {
    _fileName = fileName;
    notifyListeners();
  }

  ///
  ///This one is quite important tho, it's uploads the given file
  ///
  Future<void> uploadFile(File file, String key, String fileType, String id) async {
    final tmpDir = await getTemporaryDirectory();
    late File uploadFile =
        supportedExtensions.contains(fileType.toLowerCase()) ? File('${tmpDir.path}/$id.$fileType') : File('${tmpDir.path}/$id.wav');
    if (await uploadFile.exists()) {
      await uploadFile.delete();
    }

    if (supportedExtensions.contains(fileType.toLowerCase())) {
      await file.copy(uploadFile.path);
    } else {
      File converted = await convertToWAV(file, uploadFile.path);
      if (converted.path == 'error' || converted.path == 'canceled') {
        (await Amplify.DataStore.query(Recording.classType, where: Recording.ID.eq(id))).forEach((element) async {
          await Amplify.DataStore.delete(element);
        });
        return;
      }
    }

    _uploadFailed = false;
    try {
      StorageUploadFileOptions options = StorageUploadFileOptions(
        accessLevel: StorageAccessLevel.private,
      );

      final result = await Amplify.Storage.uploadFile(
        key: key,
        localFile: AWSFile.fromPath(uploadFile.path),
        options: options,
      ).result;
      _uploadFileResult = result.uploadedItem.key;
      print(result.uploadedItem.key);
      notifyListeners();
    } on StorageException catch (e) {
      recordEventError('uploadFile', e.message);
      print('UploadFile Error: ' + e.message);
      _uploadFailed = true;
      notifyListeners();
    }
  }

  ///
  ///Checks if the String is null and returns an empty String ("") if it is.
  ///
  String notNull(String? string, [String valuePrefix = ""]) {
    return (string == null) ? "" : valuePrefix + string;
  }

  ///
  ///Converts any audio file supported by ffmpeg to a wav 16-bit, 16khz file.
  ///
  Future<File> convertToWAV(File inputFile, String outputPath) async {
    print('Converting: $inputFile to $outputPath');
    File outputFile = File(outputPath);
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    await FFmpegKitConfig.enableLogs();
    final result = await FFmpegKit.executeWithArguments(['-i', inputFile.path, '-c:a', 'pcm_s16le', '-ac', '1', '-ar', '16000', outputPath])
        .then((session) async {
      final state = FFmpegKitConfig.sessionStateToString(await session.getState());
      final returnCode = await session.getReturnCode();
      final failStackTrace = await session.getFailStackTrace();
      final logs = await session.getAllLogsAsString();
      print('Duration: ${await session.getDuration()}');

      if (ReturnCode.isSuccess(returnCode)) {
        print('Success');
        return outputFile;
      } else if (ReturnCode.isCancel(returnCode)) {
        print('Cancelled');
        return File('cancelled');
      } else {
        print("Creating AUDIO sample failed with state $state and rc $returnCode.${notNull(failStackTrace, "\n")}");
        if (logs != null) print("Logs for the session:\n" + logs);
        return File('error');
      }
    });
    return result;
  }

  ///
  ///This function downloads the json of a finished transcription from the S3 Storage
  ///
  Future<String> downloadTranscript(String id) async {
    final tempDir = await getTemporaryDirectory();
    final filePath = tempDir.path + '/$id.json';
    final file = File(filePath);
    final key = 'finishedJobs/$id.json';
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
      final String contents = file.readAsStringSync();
      return contents;
    } on StorageException catch (e) {
      recordEventError('downloadTranscription', e.message);
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
    final StorageUploadFileOptions options = StorageUploadFileOptions(
      accessLevel: StorageAccessLevel.guest,
    );

    final json = transcriptionToJson(transcription);

    file.writeAsString(json);

    try {
      final result = await Amplify.Storage.uploadFile(
        key: key,
        localFile: AWSFile.fromPath(file.path),
        options: options,
      ).result;
      _uploadFileResult = result.uploadedItem.key;
      return true;
    } on StorageException catch (e) {
      recordEventError('saveTranscription', e.message);
      print('UploadFile Error: ' + e.message);
      return false;
    }
  }

  ///
  ///This function returns the path to a given audio file
  ///If the file already has been downloaded to the device it will just return that path
  ///Otherwise it will download it to the device
  ///
  Future<String> getAudioPath(String key) async {
    late Directory docDir;
    if (Platform.isIOS) {
      docDir = await getLibraryDirectory();
    } else {
      docDir = await getApplicationDocumentsDirectory();
    }
    final filePath = docDir.path + '/${key.split('/')[1]}';
    File file = File(filePath);
    final StorageDownloadFileOptions options = StorageDownloadFileOptions(
      accessLevel: StorageAccessLevel.private,
    );

    if (await file.exists()) {
      return filePath;
    } else {
      try {
        await Amplify.Storage.downloadFile(
          key: key,
          localFile: AWSFile.fromPath(file.path),
          options: options,
        ).result;
        return filePath;
      } on StorageException catch (e) {
        recordEventError('getAudioPath', e.message);
        print('Error downloading file: ${e.message}');
        return 'null';
      }
    }
  }

  Future<String> getAudioUrl(String key) async {
    final options = StorageGetUrlOptions(
      accessLevel: StorageAccessLevel.private,
      pluginOptions: S3GetUrlPluginOptions(
        validateObjectExistence: true,
        expiresIn: Duration(hours: 12),
      ),
    );
    try {
      final url = await Amplify.Storage.getUrl(key: key, options: options).result;
      return url.url.toString();
    } on StorageException catch (err) {
      recordEventError('getAudioUrl', err.message);
      print('Error getting audio url: ${err.message}');
      return 'null';
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
  final StorageDownloadFileOptions options = StorageDownloadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );
  String key = 'userData/userData.json';

  while (await file.exists()) {
    int newInt = rnd.nextInt(9999);
    final filePath = tempDir.path + '/userData$newInt.json';
    file = new File(filePath);
  }

  try {
    await Amplify.Storage.downloadFile(
      key: key,
      localFile: AWSFile.fromPath(file.path),
      options: options,
    ).result;
    String downloadedData = await file.readAsString();
    UserData downloadedUserData = UserData.fromJson(json.decode(downloadedData));
    return downloadedUserData;
  } on StorageException catch (e) {
    recordEventError('downloadUserData', e.message);
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
  final StorageUploadFileOptions options = StorageUploadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );
  String key = 'userData/userData.json';

  try {
    print('Uploading userData: ${userData.email}, ${userData.freePeriods}');
    String jsonUserData = json.encode(userData.toJson());
    await file.writeAsString(jsonUserData);
    await Amplify.Storage.uploadFile(
      localFile: AWSFile.fromPath(file.path),
      key: key,
      options: options,
    ).result;
  } on StorageException catch (e) {
    recordEventError('uploadUserData', e.message);
    print('Error uploading UserData: ${e.message}');
  }
}

///
///Uploads a new version to the version history
///
Future<void> uploadVersion(String json, String recordingID, String editType) async {
  String versionID = await saveNewVersion(recordingID, editType);
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/new-$versionID.json';
  final file = File(filePath);
  final key = 'versions/$recordingID/$versionID.json';
  final StorageUploadFileOptions options = StorageUploadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );
  await file.writeAsString(json);

  try {
    await Amplify.Storage.uploadFile(
      key: key,
      localFile: AWSFile.fromPath(file.path),
      options: options,
    ).result;
  } on StorageException catch (e) {
    recordEventError('uploadVersion', e.message);
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
  final StorageDownloadFileOptions options = StorageDownloadFileOptions(
    accessLevel: StorageAccessLevel.private,
  );

  try {
    await Amplify.Storage.downloadFile(
      key: key,
      localFile: AWSFile.fromPath(file.path),
      options: options,
    ).result;
    final String contents = file.readAsStringSync();
    return contents;
  } on StorageException catch (e) {
    recordEventError('downloadVersion', e.message);
    print('Error downloading file: ${e.message}');
    return 'null';
  }
}

///
///Removes a given version of a transcription
///
Future<bool> removeOldVersion(String recordingID, String versionID) async {
  final key = 'versions/$recordingID/$versionID.json';
  final options = StorageRemoveOptions(
    accessLevel: StorageAccessLevel.private,
  );

  try {
    await Amplify.Storage.remove(key: key, options: options).result;
    return true;
  } on StorageException catch (e) {
    recordEventError('removeOldVersion', e.message);
    print('Error while removing file: ${e.message}');
    return false;
  }
}

///
///Checks if the original already exists, if it doesn't it will create it
///
Future<bool> checkOriginalVersion(String recordingID, Transcription transcription) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/original.json';
  final file = File(filePath);
  final key = 'versions/$recordingID/original.json';
  bool originalExists = false;

  try {
    final StorageDownloadFileOptions options = StorageDownloadFileOptions(
      accessLevel: StorageAccessLevel.private,
    );
    await Amplify.Storage.downloadFile(
      key: key,
      localFile: AWSFile.fromPath(file.path),
      options: options,
    ).result;
    originalExists = true;
    // ignore: unused_catch_clause
  } on StorageException catch (err) {
    print('The original transcript have not been saved yet... Saving.');

    try {
      final StorageUploadFileOptions options = StorageUploadFileOptions(
        accessLevel: StorageAccessLevel.private,
      );
      String json = transcriptionToJson(transcription);
      await file.writeAsString(json);
      final result = await Amplify.Storage.uploadFile(
        key: key,
        localFile: AWSFile.fromPath(file.path),
        options: options,
      ).result;
      print('Uploaded original file with key: ${result.uploadedItem.key}');
      originalExists = true;
    } on StorageException catch (e) {
      recordEventError('checkOriginalVersion-save', e.message);
      print('Error saving original: ${e.message}');
      originalExists = false;
    } catch (e) {
      recordEventError('checkOriginalVersion-other', e.toString());
      print('Other error saving original: $e');
      originalExists = false;
    }
  }
  return originalExists;
}

///
///Removes all files associated with a recording
///
Future<void> removeRecording(String id, String fileKey) async {
  final privateOptions = StorageRemoveOptions(
    accessLevel: StorageAccessLevel.private,
  );
  final guestOptions = StorageRemoveOptions(
    accessLevel: StorageAccessLevel.guest,
  );
  //first we remove all versions
  try {
    List<Version> versions = await Amplify.DataStore.query(Version.classType, where: Version.RECORDINGID.eq(id));

    for (Version version in versions) {
      try {
        final versionKey = 'versions/$id/${version.id}.json';
        await Amplify.Storage.remove(key: versionKey, options: privateOptions).result;
      } on StorageException catch (e) {
        recordEventError('removeRecording-versions', e.message);
        print(e.message);
      }
    }
    final originalKey = 'versions/$id/original.json';
    await Amplify.Storage.remove(key: originalKey, options: privateOptions).result;
  } on DataStoreException catch (e) {
    recordEventError('removeRecording-DataStore', e.message);
    print(e.message);
  } on StorageException catch (e) {
    recordEventError('removeRecording-original', e.message);
    print(e.message);
  }

  //now we remove the audio and the transcription
  try {
    final transcriptKey = 'finishedJobs/$id.json';
    await Amplify.Storage.remove(key: transcriptKey, options: guestOptions).result;
    await Amplify.Storage.remove(key: fileKey, options: privateOptions).result;
  } on StorageException catch (e) {
    recordEventError('removeRecording-TranscriptRecording', e.message);
    print(e.message);
  }
}

Future<void> removeUserFiles() async {
  //Removing all recordings associated with the user
  try {
    List<Recording> recordings = await Amplify.DataStore.query(Recording.classType);
    for (var recording in recordings) {
      try {
        final options = StorageRemoveOptions(
          accessLevel: StorageAccessLevel.guest,
        );
        final key = 'finishedJobs/${recording.id}.json';
        await Amplify.Storage.remove(key: key, options: options).result;
      } on StorageException catch (e) {
        recordEventError('removeUserFiles-finishedJobs', e.message);
        print(e.message);
      }
      await Amplify.DataStore.delete(recording);
    }
  } on DataStoreException catch (e) {
    recordEventError('removeUserFiles-DataStore', e.message);
    print(e.message);
  }

  //Removing all private files associated with the user
  try {
    final listOptions = StorageListOptions(
      accessLevel: StorageAccessLevel.private,
    );
    final result = await Amplify.Storage.list(options: listOptions).result;
    List<StorageItem> items = result.items;

    for (StorageItem item in items) {
      final options = StorageRemoveOptions(
        accessLevel: StorageAccessLevel.private,
      );
      await Amplify.Storage.remove(key: item.key, options: options).result;
    }
  } on StorageException catch (e) {
    recordEventError('removeUserFiles-Storage', e.message);
    print(e.message);
  }
}
