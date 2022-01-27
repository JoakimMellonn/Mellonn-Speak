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
  bool lastPunctuation = false;

  for (var item in items) {
    if (item.type == 'pronunciation') {
      itemStart = double.parse(item.startTime);
      itemEnd = double.parse(item.endTime);
    } else {
      itemStart = lastEndTime;
      itemEnd = lastEndTime + 0.01;
    }

    if (itemStart >= startTime && itemStart <= endTime && itemEnd <= endTime) {
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
        lastPunctuation = false;
      } else if (item.type == 'punctuation' && !lastPunctuation) {
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
        lastPunctuation = true;
      }
    }
  }
  return wordList;
}

String getInitialValue(List<Word> words) {
  List<String> wordStrings = [];
  String initialValue = '';

  int i = 0;
  for (Word word in words) {
    if (word.pronounciation && i == 0) {
      wordStrings.add(word.word);
    } else if (word.pronounciation) {
      wordStrings.add(' ${word.word}');
    } else {
      wordStrings.add(word.word);
    }
    i++;
  }
  initialValue = wordStrings.join('');
  return initialValue;
}

List<Word> createWordListFromString(List<Word> wordList, String textValue) {
  List<String> newWords = convertStringToList(textValue);

  print('newWords:');
  newWords.forEach((element) {
    print(element);
  });

  print(
      'wordList, start ${wordList.first.startTime}, end: ${wordList.last.endTime}');
  wordList.forEach((element) {
    print(element.word);
  });

  List<Word> newWordList = [];
  int i = 0;
  bool lastFit = true;
  int firstNew = 0;
  List<String> newFits = [];

  ///
  ///Case 1: the length of both lists are the same.
  ///We replace just the words.
  ///
  if (wordList.length == newWords.length) {
    for (var word in wordList) {
      newWordList.add(Word(
        startTime: word.startTime,
        endTime: word.endTime,
        word: newWords[i],
        pronounciation: word.pronounciation,
        confidence: word.confidence,
      ));
      i++;
    }
  }

  ///
  ///Case 2: the length of newWords is not the same as wordList.
  ///We just calculate the average time for each word and place them in.
  ///Not scientific but it works.
  ///
  if (wordList.length != newWords.length) {
    double firstStart = wordList.first.startTime;
    double lastEnd = wordList.last.endTime;
    double previousStart = 0;
    int special = 0;

    ///Counting amount of special characters...
    for (var word in newWords) {
      if (word.contains(RegExp('[^A-Åa-å0-9]'))) {
        special++;
      }
    }
    double averageTime = double.parse(
        ((lastEnd - firstStart - (special * 0.01)) / newWords.length)
            .toStringAsFixed(2));

    for (var word in newWords) {
      if (i == 0 && word.contains(RegExp('[^A-Åa-å0-9]'))) {
        newWordList.add(Word(
          startTime: firstStart,
          endTime: double.parse((firstStart + 0.01).toStringAsFixed(2)),
          word: word,
          pronounciation: false,
          confidence: 100,
        ));
        previousStart = double.parse((firstStart + 0.01).toStringAsFixed(2));
      } else if (i == 0 && !word.contains(RegExp('[^A-Åa-å0-9]'))) {
        newWordList.add(Word(
          startTime: firstStart,
          endTime: double.parse((firstStart + averageTime).toStringAsFixed(2)),
          word: word,
          pronounciation: true,
          confidence: 100,
        ));
        previousStart =
            double.parse((firstStart + averageTime).toStringAsFixed(2));
      } else if (i != 0 && word.contains(RegExp('[^A-Åa-å0-9]'))) {
        newWordList.add(Word(
          startTime: previousStart,
          endTime: double.parse((previousStart + 0.01).toStringAsFixed(2)),
          word: word,
          pronounciation: false,
          confidence: 100,
        ));
        previousStart = double.parse((previousStart + 0.01).toStringAsFixed(2));
      } else {
        newWordList.add(Word(
          startTime: previousStart,
          endTime:
              double.parse((previousStart + averageTime).toStringAsFixed(2)),
          word: word,
          pronounciation: true,
          confidence: 100,
        ));
        previousStart =
            double.parse((previousStart + averageTime).toStringAsFixed(2));
      }
      i++;
    }
  }

  newWordList.last.endTime = wordList.last.endTime;

  print(
      'newWordList, start: ${newWordList.first.startTime}, end: ${newWordList.last.endTime}');
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

Transcription wordListToTranscription(
    Transcription transcription, List<Word> wordList) {
  Transcription newTranscription = transcription;
  List<Item> oldItems = transcription.results.items;
  List<Item> newItems = [];
  double firstStart = wordList.first.startTime;
  double lastEnd = wordList.last.endTime;
  bool itemsAdded = false;

  double itemStart = 0;
  double itemEnd = 0;
  double lastEndTime = 0;

  for (Item item in oldItems) {
    if (item.type == 'pronunciation') {
      itemStart = double.parse(item.startTime);
      itemEnd = double.parse(item.endTime);
    } else {
      itemStart = lastEndTime;
      itemEnd = lastEndTime + 0.01;
    }

    //
    if (itemEnd < firstStart && !itemsAdded) {
      newItems.add(item);
    } else if (firstStart <= itemStart && !itemsAdded) {
      for (var word in wordList) {
        List<Alternative> alternatives = [
          Alternative(
            confidence: word.confidence.toString(),
            content: word.word,
          ),
        ];
        String type = 'pronunciation';
        if (!word.pronounciation) type = 'punctuation';

        newItems.add(Item(
          startTime: word.startTime.toString(),
          endTime: word.endTime.toString(),
          alternatives: alternatives,
          type: type,
        ));
      }
      itemsAdded = true;
    } else if (itemStart >= firstStart && itemEnd <= lastEnd && itemsAdded) {
    } else if (itemStart > lastEnd && itemsAdded) {
      newItems.add(item);
    }
    lastEndTime = itemEnd;
  }
  newTranscription.results.items = newItems;

  return newTranscription;
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