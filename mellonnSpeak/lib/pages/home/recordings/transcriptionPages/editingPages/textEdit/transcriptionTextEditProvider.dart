import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';

class TranscriptionTextEditProvider with ChangeNotifier {}

List<Word> getWords(
    Transcription transcription, double startTime, double endTime) {
  List<Item> items = transcription.results.items;
  List<Word> wordList = [];

  double itemStart = 0;
  double itemEnd = 0;
  double lastEndTime = 0;

  for (var item in items) {
    if (item.type == 'pronunciation') {
      itemStart = double.parse(item.startTime);
      itemEnd = double.parse(item.endTime);
    } else {
      itemStart = lastEndTime;
      itemEnd = lastEndTime + 0.01;
    }

    if (itemStart > startTime && itemStart < endTime) {
      if (item.type == 'pronunciation') {
        lastEndTime = itemEnd;
        for (var alt in item.alternatives) {
          wordList.add(
            Word(
              startTime: itemStart,
              endTime: itemEnd,
              word: alt.content,
              pronounciation: true,
              confidence: double.parse(alt.confidence),
            ),
          );
        }
      } else {
        for (var alt in item.alternatives) {
          wordList.add(
            Word(
              startTime: itemStart,
              endTime: itemEnd,
              word: alt.content,
              pronounciation: false,
              confidence: double.parse(alt.confidence),
            ),
          );
        }
      }
    }
  }
  return wordList;
}

String getInitialValue(List<Word> words) {
  List<String> wordStrings = [];
  String initialValue = '';

  for (Word word in words) {
    if (word.pronounciation) {
      wordStrings.add(' ${word.word}');
    } else {
      wordStrings.add(word.word);
    }
  }
  initialValue = wordStrings.join('');
  return initialValue;
}

List<Word> createWordListFromString(List<Word> wordList, String textValue) {
  List<String> newWords = convertStringToList(textValue);

  newWords.forEach((element) {
    print(element);
  });

  List<Word> newWordList = [];
  int i = 0;
  bool lastFit = true;
  int firstNew = 0;
  List<String> newFits = [];

  for (String word in newWords) {
    if (word == wordList[i].word) {
      if (lastFit) {
        newWordList.add(
          Word(
            startTime: wordList[i].startTime,
            endTime: wordList[i].endTime,
            word: word,
            pronounciation: wordList[i].pronounciation,
            confidence: wordList[i].confidence,
          ),
        );
      } else {
        if (newFits.length == i - firstNew) {
          int count = firstNew;
          for (String newFit in newFits) {
            newWordList.add(
              Word(
                startTime: wordList[count].startTime,
                endTime: wordList[count].endTime,
                word: newFit,
                pronounciation: wordList[count].pronounciation,
                confidence: wordList[count].confidence,
              ),
            );
            count++;
          }
        } else {
          double averageTime =
              (newWordList[i - 1].endTime - newWordList[firstNew].startTime) /
                      newFits.length -
                  (0.01 * newFits.length);
          int count = firstNew;
          double currentStart = newWordList[count].startTime;
          for (String newFit in newFits) {
            newWordList.add(
              Word(
                startTime: currentStart,
                endTime: currentStart + averageTime,
                word: newFit,
                pronounciation: wordList[count].pronounciation,
                confidence: wordList[count].confidence,
              ),
            );
            currentStart += averageTime + 0.01;
            count++;
          }
        }
        lastFit = true;
      }
    } else {
      if (lastFit) {
        newFits.add(word);
        lastFit = false;
        firstNew = i;
      } else {
        newFits.add(word);
      }
    }
    i++;
  }
  return newWordList;
}

List<String> convertStringToList(String textValue) {
  List<String> list = textValue.split('');
  List<String> newList = [];
  List<String> returnList = [];

  for (var e in list) {
    if (e.contains(RegExp('[^ A-Åa-å0-9]'))) {
      newList.add(' $e');
    } else {
      newList.add(e);
    }
  }

  returnList = newList.join('').split(' ');

  return returnList;
}

class Word {
  double startTime;
  double endTime;
  String word;
  bool pronounciation;
  double confidence;

  Word({
    required this.startTime,
    required this.endTime,
    required this.word,
    required this.pronounciation,
    required this.confidence,
  });
}

///
///Media controls
///
class PageManager {
  PageManager({
    required this.audioFilePath,
    required this.startTime,
    required this.endTime,
  }) {
    _init();
  }
  final String audioFilePath;
  final double startTime;
  final double endTime;

  late AudioPlayer _audioPlayer;

  void _init() async {
    _audioPlayer = AudioPlayer();
    await _audioPlayer.setFilePath(audioFilePath);
    Duration start = Duration(milliseconds: (startTime * 1000).toInt());
    Duration end = Duration(milliseconds: (endTime * 1000).toInt());
    _audioPlayer.setClip(start: start, end: end);

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
        _audioPlayer.seek(Duration.zero);
        _audioPlayer.pause();
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
  }

  final progressNotifier = ValueNotifier<ProgressBarState>(
    ProgressBarState(
      current: Duration.zero,
      buffered: Duration.zero,
      total: Duration.zero,
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

enum ButtonState { paused, playing, loading }
