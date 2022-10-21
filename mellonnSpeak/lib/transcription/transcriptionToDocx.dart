import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:permission_handler/permission_handler.dart';

class TranscriptionToDocx {
  String getMinSec(double seconds) {
    double minDouble = seconds / 60;
    int minInt = minDouble.floor();
    double secDouble = seconds - (minInt * 60);
    int secInt = secDouble.floor();

    String minSec = '${minInt}m ${secInt}s';
    String sec = '${secInt}s';

    if (minInt == 0) {
      return sec;
    } else {
      return minSec;
    }
  }

  /*
  * Creating a Future bool function, that exports a word document and returns true if it succeeds.
  * Of course it returns false if it doesn't, but you probably knew that...
  * 
  * It requires the name of the recording and then of course the recording transcription.
  */
  Future<String> createDocxFromTranscription(String recordingName, List<SpeakerWithWords> speakerWithWords, List<String> labels) async {
    final data = await rootBundle.load('assets/docs/template.docx');
    final bytes = data.buffer.asUint8List();
    final docx = await DocxTemplate.fromBytes(bytes);

    var contentList = <Content>[];

    for (var e in speakerWithWords) {
      String startTime = getMinSec(e.startTime);
      String endTime = getMinSec(e.endTime);

      final c = PlainContent("value")
        ..add(TextContent("spk", "${labels[getNumber(e.speakerLabel)]} (Time: $startTime to $endTime): "))
        ..add(TextContent("words", "${e.pronouncedWords}\n"));
      contentList.add(c);
    }

    Content c = Content();

    c..add(TextContent("title", "$recordingName"));
    c..add(ListContent("listnested", contentList));

    if (Platform.isIOS) {
      Directory dir = await getApplicationDocumentsDirectory();
      String dirPath = dir.path;
      final d = await docx.generate(c);
      final of = File('$dirPath/$recordingName.docx');
      if (d != null) await of.writeAsBytes(d);
      return 'true';
    } else {
      bool permission = await checkStoragePermission();
      if (!permission) {
        return 'You need to give permission to save the document.';
      }
      Directory tempDir = await getTemporaryDirectory();
      final d = await docx.generate(c);
      final of = File('${tempDir.path}/$recordingName.docx');
      if (d != null) await of.writeAsBytes(d);

      try {
        final params = SaveFileDialogParams(
          sourceFilePath: of.path,
        );
        final filePath = await FlutterFileDialog.saveFile(params: params);
        if (filePath == 'null' || filePath == null) {
          return 'You need to select a location for the document to be stored.';
        } else {
          return 'true';
        }
      } catch (e) {
        return 'Something went wrong while trying to export the document, if the problem persists please contact Mellonn';
      }
    }
  }

  Future<bool> checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      var askResult = await Permission.storage.request();
      if (askResult.isGranted) {
        return true;
      } else {
        return false;
      }
    } else if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  int getNumber(String speakerLabel) {
    return int.parse(speakerLabel.split('_').last);
  }

  Future createDocxInCloud(Recording recording, List<SpeakerWithWords> sww) async {
    final DocxCreation docx = new DocxCreation(recording: recording, sww: sww);
    final options = RestOptions(
      apiName: 'export',
      path: '/docx',
      body: docx.toUint8List(),
    );
    //print('{"recording":"${recording.toJson()}","sww":${List<dynamic>.from(sww.map((x) => x.toJsonString()))}}');

    try {
      final operation = Amplify.API.post(restOptions: options);
      final result = await operation.response;
      final S3DownloadFileOptions s3Options = S3DownloadFileOptions(
        accessLevel: StorageAccessLevel.guest,
      );

      print(result.body);
      final key = 'exports/${recording.id}.docx';

      if (Platform.isIOS) {
        Directory dir = await getApplicationDocumentsDirectory();
        final filePath = dir.path + '/${recording.name}.docx';
        final file = File(filePath);

        if (await file.exists()) {
          await file.delete();
        }

        try {
          await Amplify.Storage.downloadFile(
            key: key,
            local: file,
            options: s3Options,
          );
          await Amplify.Storage.remove(key: key);
          return 'true';
        } on StorageException catch (err) {
          print(err.message);
          return 'Something went wrong while trying to export the document, if the problem persists please contact Mellonn';
        }
      } else {
        bool permission = await checkStoragePermission();
        if (!permission) {
          return 'You need to give permission to save the document.';
        }
        Directory tempDir = await getTemporaryDirectory();
        final filePath = tempDir.path + '/${recording.name}.docx';
        final tempFile = File(filePath);

        if (await tempFile.exists()) {
          await tempFile.delete();
        }

        try {
          await Amplify.Storage.downloadFile(
            key: key,
            local: tempFile,
            options: s3Options,
          );
        } on StorageException catch (err) {
          print(err.message);
          return 'Something went wrong while trying to export the document, if the problem persists please contact Mellonn';
        }

        try {
          final params = SaveFileDialogParams(
            sourceFilePath: tempFile.path,
          );
          final filePath = await FlutterFileDialog.saveFile(params: params);
          if (filePath == 'null' || filePath == null) {
            return 'You need to select a location for the document to be stored.';
          } else {
            await Amplify.Storage.remove(key: key);
            return 'true';
          }
        } catch (e) {
          return 'Something went wrong while trying to export the document, if the problem persists please contact Mellonn';
        }
      }
    } on RestException catch (err) {
      print(err.message);
      return 'Something went wrong while trying to export the document, if the problem persists please contact Mellonn';
    }
  }
}

class DocxCreation {
  DocxCreation({
    required this.recording,
    required this.sww,
  });

  Recording recording;
  List<SpeakerWithWords> sww;

  factory DocxCreation.fromJson(Map<String, dynamic> json) => DocxCreation(
        recording: json["recording"],
        sww: List<SpeakerWithWords>.from(json["sww"].map((x) => SpeakerWithWords.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "recording": recording.toJson(),
        "sww": List<dynamic>.from(sww.map((x) => x.toJson())),
      };

  Uint8List toUint8List() {
    return Uint8List.fromList('{"recording":${recordingJson()},"sww":${List<dynamic>.from(sww.map((x) => x.toJsonString()))}}'.codeUnits);
  }

  String recordingJson() {
    final id = recording.id;
    final name = recording.name;
    final labels = recording.labels ?? [];

    return '{"id":"$id","name":"$name","labels":${List<dynamic>.from(labels.map((e) => '"$e"'))}}';
  }
}
