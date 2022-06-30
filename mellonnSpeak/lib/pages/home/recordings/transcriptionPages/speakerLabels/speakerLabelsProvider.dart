import 'dart:math';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/speakerLabels/speakerLabelsPage.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';

List<SpeakerElement> getElements(List<SpeakerWithWords> speakerWithWords,
    int speakers, List<String>? interviewers, List<String>? labels) {
  List<SpeakerElement> elements = [];

  List<String> speakerList = [];
  for (var sww in speakerWithWords) {
    if (!speakerList.contains(sww.speakerLabel)) {
      speakerList.add(sww.speakerLabel);
    }
  }

  for (int i = speakerList.length - 1; i >= 0; i--) {
    String speakerLabel = 'spk_$i';
    SpeakerWithWords current = speakerWithWords.firstWhere((sww) =>
        sww.speakerLabel == speakerLabel && sww.endTime - sww.startTime > 5);
    Duration startTime = secsToDuration(current.startTime);
    Duration endTime = secsToDuration(current.endTime);
    String label = '';
    String type = '';

    if (labels == null || labels.isEmpty) {
      label = '';
    } else {
      label = labels[i];
    }
    if (interviewers == null || interviewers.isEmpty) {
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

Duration getShuffle(
    List<SpeakerWithWords> speakerWithWords, String speakerLabel) {
  Random rnd = Random(DateTime.now().millisecondsSinceEpoch);
  List<SpeakerWithWords> speakerList = [];

  for (var sww in speakerWithWords) {
    if (sww.speakerLabel == speakerLabel && sww.endTime - sww.startTime > 5) {
      speakerList.add(sww);
    }
  }
  int rndNumber = rnd.nextInt(speakerList.length);
  SpeakerWithWords shuffledSWW = speakerList[rndNumber == 0 ? 1 : rndNumber];

  return secsToDuration(shuffledSWW.startTime);
}

Duration secsToDuration(double seconds) {
  return Duration(milliseconds: (seconds * 1000).round());
}

class PageManager {
  PageManager({
    required this.pageSetState,
    required this.audioPlayer,
  }) {
    _init();
  }

  Function() pageSetState;
  final AudioPlayer audioPlayer;

  void _init() async {
    ///
    ///Getting and updating the state of the play/pause button
    ///
    audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
      } else if (!isPlaying) {
      } else if (processingState != ProcessingState.completed) {
      } else {
        // completed
        currentlyPlaying = 0;
        pageSetState();
        audioPlayer.seek(Duration.zero);
        audioPlayer.pause();
      }
    });
  }

  void dispose() {
    audioPlayer.dispose();
  }

  Future setClip(Duration start, Duration end) async {
    await audioPlayer.setClip(start: start, end: end);
  }

  void play() {
    audioPlayer.play();
  }

  void pause() {
    audioPlayer.pause();
  }
}
