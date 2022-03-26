import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:docx_template/src/template.dart';
import 'package:docx_template/src/model.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:permission_handler/permission_handler.dart';

class TranscriptionToDocx {
  /*
  * Send this function an amount of seconds and it will return it in format: *m *s
  */
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
    //First we're loading the word template there's used to create the export, it's quite a simple template.
    final data = await rootBundle.load('assets/docs/template.docx');
    final bytes = data.buffer.asUint8List();
    final docx = await DocxTemplate.fromBytes(bytes);

    //Creating the list for the speaker and word data.
    var contentList = <Content>[];

    //Going through all elements in the provided list and adding them to the contentList.
    for (var e in speakerWithWords) {
      String startTime = getMinSec(e.startTime);
      String endTime = getMinSec(e.endTime);

      final c = PlainContent("value")
        ..add(TextContent("spk",
            "${labels[getNumber(e.speakerLabel)]} (Time: $startTime to $endTime): "))
        ..add(TextContent("words", "${e.pronouncedWords}\n"));
      contentList.add(c);
    }

    //Creating the variable with the content.
    Content c = Content();

    //Adding the title and contentList together to get the combined content.
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
      /*String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Please select a folder for your transcription',
      );*/

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
