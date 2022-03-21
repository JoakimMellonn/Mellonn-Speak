import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/speakerLabels/speakerLabelsPage.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';

List<SpeakerElement> getElements(List<SpeakerWithWords> speakerWithWords,
    int speakers, List<String>? interviewers, List<String>? labels) {
  List<SpeakerElement> elements = [];

  for (int i = speakers - 1; i >= 0; i--) {
    String speakerLabel = 'spk_$i';
    SpeakerWithWords current = speakerWithWords.firstWhere((sww) =>
        sww.speakerLabel == speakerLabel && sww.endTime - sww.startTime > 5);
    Duration startTime = secsToDuration(current.startTime);
    Duration endTime = secsToDuration(current.endTime);
    String label = '';
    String type = '';

    if (labels == null) {
      label = '';
    } else {
      label = labels[i];
    }

    if (interviewers == null) {
      type = i == 0 ? 'Interviewer' : 'Interviewee';
    } else {
      type =
          interviewers.contains(speakerLabel) ? 'Interviewer' : 'Interviewee';
    }

    SpeakerElement element = SpeakerElement(
      speakerLabel: speakerLabel,
      startTime: startTime,
      endTime: endTime,
      label: label,
      type: type,
    );
    //print(
    //    'Element for speaker $i, first clip: start ${startTime.inSeconds}, end ${endTime.inSeconds}');
    elements.add(element);
  }
  return List.from(elements.reversed);
}

Future<Recording> applyLabels(
    Recording recording, List<String> labels, List<String> interviewers) async {
  List<String> newLabels = [];
  for (String label in labels) {
    if (label != '') {
      newLabels.add(label);
    }
  }

  List<String> newInterviewers = [];
  for (int i = 0; i <= 9; i++) {
    if (interviewers[i] == 'Interviewer') {
      newInterviewers.add('spk_$i');
    }
  }

  Recording newRecording = recording.copyWith(
    labels: newLabels,
    interviewers: newInterviewers,
  );

  try {
    await Amplify.DataStore.save(newRecording);
  } on DataStoreException catch (e) {
    recordEventError('applyLabel', e.message);
    print('Query failed: $e');
  }

  print(
      'New recording labels: ${newRecording.labels}, interviewers: ${newRecording.interviewers}');
  return newRecording;
}

Duration secsToDuration(double seconds) {
  return Duration(milliseconds: (seconds * 1000).round());
}
