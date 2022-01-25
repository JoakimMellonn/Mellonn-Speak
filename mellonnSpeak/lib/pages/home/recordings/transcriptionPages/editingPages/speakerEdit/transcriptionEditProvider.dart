import 'package:flutter/material.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:just_audio/just_audio.dart';

Duration lastStart = Duration.zero;
int lastSpeakerLabel = 0;
Duration clipLength = Duration.zero;

class TranscriptionEditProvider with ChangeNotifier {
  Transcription _unsavedTranscription = Transcription(
    jobName: '',
    accountId: '',
    results: Results(
      transcripts: <Transcript>[],
      speakerLabels: SpeakerLabels(
        speakers: 0,
        segments: <Segment>[],
      ),
      items: <Item>[],
    ),
    status: '',
  );
  Transcription _savedTranscription = Transcription(
    jobName: '',
    accountId: '',
    results: Results(
      transcripts: <Transcript>[],
      speakerLabels: SpeakerLabels(
        speakers: 0,
        segments: <Segment>[],
      ),
      items: <Item>[],
    ),
    status: '',
  );

  Transcription get unsavedTranscription => _unsavedTranscription;
  Transcription get savedTranscription => _savedTranscription;

  ///
  ///Setting the unsaved transcription to whatever you want
  ///
  void setTranscription(Transcription transcription) {
    _unsavedTranscription = transcription;
    notifyListeners();
  }

  void setSavedTranscription(Transcription transcription) {
    _savedTranscription = transcription;
    notifyListeners();
  }

  void setTranscriptionNoNo(Transcription transcription) {
    _unsavedTranscription = transcription;
  }

  void setSavedTranscriptionNoNo(Transcription transcription) {
    _savedTranscription = transcription;
  }

  ///
  ///This function will take a transcription and a time interval
  ///And change the speakerLabel in the given interval
  ///
  Transcription getNewSpeakerLabels(Transcription oldTranscription,
      double startTime, double endTime, int speaker) {
    //Creating the variables...
    Transcription newTranscription = oldTranscription;
    List<Segment> speakerLabels =
        newTranscription.results.speakerLabels.segments;

    newTranscription.results.speakerLabels.segments = getNewSLList(
      speakerLabels,
      startTime,
      endTime,
      speaker,
    );
    return newTranscription;
  }

  ///
  ///Call this function with a List of speakerLabel segments, start- and endTime and a speakerLabel
  ///And then it will return a new List of speakerLabel segments where the given interval has been changed
  ///
  List<Segment> getNewSLList(
      List<Segment> oldList, double startTime, double endTime, int speaker) {
    //Creating the variables
    String speakerLabel = 'spk_$speaker';
    List<Segment> newList = <Segment>[];
    int index = 0;
    List<SegmentItem> newSegmentItems = [];
    Segment newSegment = Segment(
      startTime: '',
      speakerLabel: '',
      endTime: '',
      items: <SegmentItem>[],
    );
    Segment firstSegment = Segment(
      startTime: '',
      speakerLabel: '',
      endTime: '',
      items: <SegmentItem>[],
    );
    Segment lastSegment = Segment(
      startTime: '',
      speakerLabel: '',
      endTime: '',
      items: <SegmentItem>[],
    );
    bool newDone = false;
    bool multipleBeforeFirst = false;

    Segment lastInList = oldList.last;
    Segment firstInList = oldList.first;

    if (double.parse(lastInList.endTime) < endTime) {
      endTime = double.parse(lastInList.endTime);
    }

    if (double.parse(firstInList.startTime) > startTime) {
      startTime = double.parse(firstInList.startTime);
      if (double.parse(firstInList.startTime) > endTime) {
        startTime -= 0.01;
        endTime = double.parse(firstInList.startTime);
      }
    }

    ///
    ///Going through all segments to check where the new speaker assigning takes place.
    ///
    for (var segment in oldList) {
      double segmentStart = double.parse(segment.startTime);
      double segmentEnd = double.parse(segment.endTime);
      bool hasBeenThrough = false;
      bool beforeFirst = false;
      bool firstChanged = false;
      bool newChanged = false;
      bool lastChanged = false;

      if (index == 0 && startTime < segmentStart ||
          multipleBeforeFirst && startTime <= segmentStart) beforeFirst = true;

      if (segmentStart <= startTime &&
              startTime <= segmentEnd &&
              endTime >= segmentEnd ||
          beforeFirst && endTime > segmentStart) {
        ///
        ///Case 1:
        ///When the speaker assigning startTime is inside the current segment.
        ///Or if it's before the first one.
        ///
        List<SegmentItem> firstItems = goThroughSegmentItems(
          segment.speakerLabel,
          segmentStart,
          startTime,
          segment.items,
        );
        if (firstItems.length > 0) {
          firstSegment = Segment(
            startTime: segment.startTime,
            speakerLabel: segment.speakerLabel,
            endTime: startTime.toString(),
            items: firstItems,
          );
          firstChanged = true;
        }

        if (multipleBeforeFirst) {
          multipleBeforeFirst = false;
        }

        ///Going through every item in the list and adds them to the new list.
        List<SegmentItem> newItemsList = goThroughSegmentItems(
            speakerLabel, startTime, endTime, segment.items);
        newItemsList.forEach((element) {
          newSegmentItems.add(element);
        });

        if (endTime <= segmentEnd) {
          newDone = true;
        }

        newChanged = true;
        newSegment.startTime = '$startTime';
        newSegment.speakerLabel = speakerLabel;
        newSegment.endTime = '$endTime';
        hasBeenThrough = true;
      } else if (segmentStart <= endTime &&
          endTime <= segmentEnd &&
          !hasBeenThrough) {
        ///
        ///Case 2:
        ///When the speaker assigning endTime is inside the current segment
        ///
        List<SegmentItem> lastItems = goThroughSegmentItems(
          segment.speakerLabel,
          endTime,
          segmentEnd,
          segment.items,
        );
        if (lastItems.length > 0) {
          lastSegment = Segment(
            startTime: endTime.toString(),
            speakerLabel: segment.speakerLabel,
            endTime: segment.endTime,
            items: lastItems,
          );
          lastChanged = true;
        }

        ///Going through every item in the list and adds them to the new list
        List<SegmentItem> newItemsList = goThroughSegmentItems(
            speakerLabel, startTime, endTime, segment.items);

        newItemsList.forEach((element) {
          newSegmentItems.add(element);
        });
        newChanged = true;
        newDone = true;

        newSegment.startTime = '$startTime';
        newSegment.speakerLabel = speakerLabel;
        newSegment.endTime = '$endTime';
        hasBeenThrough = true;
      } else if (segmentStart >= startTime &&
          endTime >= segmentEnd &&
          !hasBeenThrough) {
        ///
        ///Case 3:
        ///When the speaker assigning startTime is going through the current segment
        ///So when the startTime is before and endTime is after
        ///

        ///Changing all the speakerLabels and adding them to the list
        segment.items.forEach((item) {
          item.speakerLabel = speakerLabel;
          newSegmentItems.add(item);
        });

        hasBeenThrough = true;
        newChanged = true;
      } else if (startTime >= segmentStart && endTime <= segmentEnd ||
          beforeFirst && endTime <= segmentStart) {
        ///
        ///Case 4:
        ///When it's all in the segment
        ///
        List<SegmentItem> firstItems = goThroughSegmentItems(
          segment.speakerLabel,
          segmentStart,
          startTime,
          segment.items,
        );
        if (firstItems.length > 0) {
          firstSegment = Segment(
            startTime: segment.startTime,
            speakerLabel: segment.speakerLabel,
            endTime: startTime.toString(),
            items: firstItems,
          );
          firstChanged = true;
        }

        List<SegmentItem> lastItems = goThroughSegmentItems(
          segment.speakerLabel,
          endTime,
          segmentEnd,
          segment.items,
        );
        if (lastItems.length > 0) {
          lastSegment = Segment(
            startTime: endTime.toString(),
            speakerLabel: segment.speakerLabel,
            endTime: segment.endTime,
            items: lastItems,
          );
          lastChanged = true;
        }

        ///Going through every item in the list and adds them to the new list.
        List<SegmentItem> newItemsList = goThroughSegmentItems(
            speakerLabel, startTime, endTime, segment.items);
        newItemsList.forEach((element) {
          newSegmentItems.add(element);
        });

        if (beforeFirst) {
          multipleBeforeFirst = true;
        }

        newChanged = true;
        newDone = true;
        newSegment.startTime = '$startTime';
        newSegment.speakerLabel = speakerLabel;
        newSegment.endTime = '$endTime';
        hasBeenThrough = true;
      } else {
        ///
        ///Case 5:
        ///When it's not in the segment
        ///
      }

      if (firstChanged) {
        newList.add(firstSegment);
      }
      if (newChanged && newDone) {
        newSegment.items = newSegmentItems;
        newList.add(newSegment);
      }
      if (lastChanged) {
        newList.add(lastSegment);
      }
      if (newChanged && !newDone) {}
      if (!firstChanged && !newChanged && !lastChanged) {
        newList.add(segment);
      }
      index++;
    }
    return newList;
  }

  ///
  ///This function will go through a List of segmentItems
  ///And return the items in the given interval, with the speakerLabels changed
  ///
  List<SegmentItem> goThroughSegmentItems(String speakerLabel, double startTime,
      double endTime, List<SegmentItem> items) {
    List<SegmentItem> newList = [];

    for (var item in items) {
      double itemStart = double.parse(item.startTime);
      double itemEnd = double.parse(item.endTime);

      if (itemStart >= startTime && itemEnd <= endTime) {
        SegmentItem newItem = SegmentItem(
          startTime: item.startTime,
          speakerLabel: speakerLabel,
          endTime: item.endTime,
        );
        newList.add(newItem);
      }
    }
    return newList;
  }

  ///
  ///When called with a transcription, it will return a list of all the times it switches the speaker.
  ///
  List<SpeakerSwitch> getSpeakerSwitches(Transcription transcription) {
    List<Segment> speakerLabels = transcription.results.speakerLabels.segments;
    List<SpeakerSwitch> speakerSwitchList = [];
    int lastSpeaker = 0;
    SpeakerSwitch speakerSwitch = SpeakerSwitch(
      duration: Duration.zero,
      durationEnd: Duration.zero,
      speaker: 0,
    );

    for (Segment segment in speakerLabels) {
      int currentSpeaker =
          int.parse(segment.speakerLabel.replaceAll('spk_', ''));
      double startTimeMil = double.parse(segment.startTime) * 1000;
      double endTimeMil = double.parse(segment.endTime) * 1000;
      Duration start = Duration(milliseconds: startTimeMil.toInt());
      Duration end = Duration(milliseconds: endTimeMil.toInt());

      if (currentSpeaker == lastSpeaker) {
        lastSpeaker = currentSpeaker;
      } else {
        speakerSwitchList.add(speakerSwitch);
        speakerSwitch = SpeakerSwitch(
          duration: start,
          durationEnd: end,
          speaker: currentSpeaker,
        );
        lastSpeaker = currentSpeaker;
      }
    }
    return speakerSwitchList;
  }
}

class PageManager {
  PageManager({
    required this.audioFilePath,
    required this.speakerSwitches,
    required this.switchSpeaker,
  }) {
    _init();
  }
  final String audioFilePath;
  final List<SpeakerSwitch> speakerSwitches;
  final Function(Duration position, int speaker) switchSpeaker;

  late AudioPlayer _audioPlayer;

  void _init() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setFilePath(audioFilePath);
    Duration duration = _audioPlayer.duration ?? Duration.zero;
    clipLength = duration;

    ///
    ///Getting and updating the state of the play/pause button
    ///
    _audioPlayer.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      if (processingState == ProcessingState.loading ||
          processingState == ProcessingState.buffering) {
        buttonNotifier.value = ButtonState.loading;
      } else if (!isPlaying) {
        buttonNotifier.value = ButtonState.paused;
      } else if (processingState != ProcessingState.completed) {
        buttonNotifier.value = ButtonState.playing;
      } else {
        // completed
        switchSpeaker(duration, 0);
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
      }
    });

    ///
    ///Getting and updating the state of the speakerChoosers
    ///
    _audioPlayer
        .createPositionStream(
            minPeriod: const Duration(milliseconds: 10),
            maxPeriod: const Duration(milliseconds: 10))
        .listen((position) {
      Duration minDuration = position - Duration(milliseconds: 5);
      Duration maxDuration = position + Duration(milliseconds: 5);
      final oldState = speakerNotifier.value;
      speakerNotifier.value = SpeakerChooserState(
        currentSpeaker: oldState.currentSpeaker,
        position: position,
      );
      for (var speakerSwitch in speakerSwitches) {
        if (speakerSwitch.duration >= minDuration &&
            speakerSwitch.duration <= maxDuration) {
          setSpeakerChooser(speakerSwitch.speaker, position);
          switchSpeaker(position, speakerSwitch.speaker);
        }
      }
    });

    ///
    ///Getting and updating the state of the progress bar
    ///
    _audioPlayer.positionStream.listen((position) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: position,
        buffered: oldState.buffered,
        total: oldState.total,
      );
    });

    ///
    ///Getting and updating the state of the buffering bar
    ///
    _audioPlayer.bufferedPositionStream.listen((bufferedPosition) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: bufferedPosition,
        total: oldState.total,
      );
    });

    ///
    ///Getting and updating the state of the total duration
    ///
    _audioPlayer.durationStream.listen((totalDuration) {
      final oldState = progressNotifier.value;
      progressNotifier.value = ProgressBarState(
        current: oldState.current,
        buffered: oldState.buffered,
        total: totalDuration ?? Duration.zero,
      );
    });
  }

  void dispose() {
    _audioPlayer.dispose();
  }

  void play() {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
    speakerNotifier.value = SpeakerChooserState(
      currentSpeaker: getSpeakerLabel(position),
      position: position,
    );
  }

  void setPlaybackSpeed(double speed) {
    _audioPlayer.setSpeed(speed);
  }

  int getSpeakerLabel(Duration position) {
    int speakerLabel = 0;
    for (var element in speakerSwitches) {
      if (position >= element.duration && position <= element.durationEnd) {
        speakerLabel = element.speaker;
      }
    }
    return speakerLabel;
  }

  void setSpeakerChooser(int speakerLabel, Duration position) {
    speakerNotifier.value = SpeakerChooserState(
      currentSpeaker: speakerLabel,
      position: position,
    );
  }

  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
    ),
  );
  final speakerNotifier = ValueNotifier<SpeakerChooserState>(
    SpeakerChooserState(
      currentSpeaker: 0,
      position: Duration.zero,
    ),
  );
  final buttonNotifier = ValueNotifier<ButtonState>(ButtonState.paused);
}

class ProgressBarState {
  ProgressBarState({
    required this.current,
    required this.buffered,
    required this.total,
  });
  final Duration current;
  final Duration buffered;
  final Duration total;
}

class SpeakerChooserState {
  SpeakerChooserState({
    required this.currentSpeaker,
    required this.position,
  });
  final int currentSpeaker;
  final Duration position;
}

enum ButtonState { paused, playing, loading }

class SpeakerSwitch {
  SpeakerSwitch({
    required this.duration,
    required this.durationEnd,
    required this.speaker,
  });
  final Duration duration;
  final Duration durationEnd;
  final int speaker;
}
