import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
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
  Future<String> createDocxFromTranscription(String recordingName,
      List<SpeakerWithWords> speakerWithWords, List<String> labels) async {
    final data = await rootBundle.load('assets/docs/template.docx');
    final bytes = data.buffer.asUint8List();
    final docx = await DocxTemplate.fromBytes(bytes);

    var contentList = <Content>[];

    for (var e in speakerWithWords) {
      String startTime = getMinSec(e.startTime);
      String endTime = getMinSec(e.endTime);

      final c = PlainContent("value")
        ..add(TextContent("spk",
            "${labels[getNumber(e.speakerLabel)]} (Time: $startTime to $endTime): "))
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
}
