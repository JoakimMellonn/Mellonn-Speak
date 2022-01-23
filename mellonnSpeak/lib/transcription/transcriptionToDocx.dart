import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:docx_template/src/template.dart';
import 'package:docx_template/src/model.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';

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
  Future<bool> createDocxFromTranscription(
      String recordingName, List<SpeakerWithWords> speakerWithWords) async {
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
        ..add(TextContent(
            "spk", "${e.speakerLabel} (Time: $startTime to $endTime): "))
        ..add(TextContent("words", "${e.pronouncedWords}\n"));
      contentList.add(c);
    }

    //Creating the variable with the content.
    Content c = Content();

    //Adding the title and contentList together to get the combined content.
    c..add(TextContent("title", "$recordingName"));
    c..add(ListContent("listnested", contentList));

    //Getting the user to choose the output directory.
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Please select a folder for your transcription',
    );

    /*
    * Checking if the user has chosen a directory.
    * If true it will generate the docx-file and place it in the selected directory, and return the function true.
    * If false it will return the function false.
    */
    if (selectedDirectory != null) {
      final d = await docx.generate(c);
      final of = File('$selectedDirectory/$recordingName.docx');
      if (d != null) await of.writeAsBytes(d);
      return true;
    } else {
      return false;
    }
  }
}
