import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/.env.dart';

class TranscriptionPageProvider with ChangeNotifier {
  late Transcription _transcription;
  List<Word> _initialWords = [];
  String _textValue = '';
  TextSelection _textSelection = TextSelection(baseOffset: 0, extentOffset: 0);

  List<String> _labels = [];
  int _originalSpeaker = 0;
  int _currentSpeaker = 0;
  bool _textSelected = false;
  bool _isTextSaved = true;
  bool _isSelectSaved = true;

  Transcription get transcription => _transcription;
  List<String> get labels => _labels;
  int get currentSpeaker => _currentSpeaker;
  bool get textSelected => _textSelected;
  bool get isSaved => _isTextSaved && _isSelectSaved;

  void setLabels(List<String> input) {
    _labels = input;
    notifyListeners();
  }

  void setOriginalSpeaker(int speaker) {
    _originalSpeaker = speaker;
    notifyListeners();
  }

  void setSpeaker(int speaker) {
    _currentSpeaker = speaker;
    setIsSelectSaved(speaker == _originalSpeaker);
    notifyListeners();
  }

  void setInitialWords(List<Word> initialWords) {
    _initialWords = initialWords;
  }

  void setTextValue(String textValue) {
    _textValue = textValue;
  }

  void setTextSelected(bool isSelected, TextSelection selection) {
    _textSelected = isSelected;
    _textSelection = selection;
    notifyListeners();
  }

  void setIsTextSaved(bool isSaved) {
    _isTextSaved = isSaved;
    notifyListeners();
  }

  void setIsSelectSaved(bool isSaved) {
    _isSelectSaved = isSaved;
    notifyListeners();
  }

  Future saveEdit(String id) async {
    if (!_isTextSaved) {
      await saveTextEdit(id);
    }

    if (!_isSelectSaved) {
      saveSpeakerEdit();
    }
  }

  Future saveTextEdit(String id) async {
    List<Word> newList = createWordListFromString(_initialWords, _textValue);
    _transcription = wordListToTranscription(_transcription, newList);
    bool hasUploaded = await StorageProvider().saveTranscription(_transcription, id);

    //Adding the version to the version history
    final json = transcriptionToJson(_transcription);
    await uploadVersion(json, id, 'Edited Text');

    if (hasUploaded) {
      //Update transcription
    } else {
      //Error
    }
  }

  Future saveSpeakerEdit() async {}

  ///
  ///Text editing methods
  ///
  List<Word> createWordListFromString(List<Word> wordList, String textValue) {
    List<String> newWords = convertStringToList(textValue);

    List<Word> newWordList = [];
    int i = 0;

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
          pronunciation: word.pronunciation,
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

      for (var word in newWords) {
        if (word.contains(RegExp(allLetters))) {
          special++;
        }
      }
      double averageTime = double.parse(((lastEnd - firstStart - (special * 0.01)) / newWords.length).toStringAsFixed(2));

      for (var word in newWords) {
        if (i == 0 && word.contains(RegExp(allLetters))) {
          newWordList.add(Word(
            startTime: firstStart,
            endTime: double.parse((firstStart + 0.01).toStringAsFixed(2)),
            word: word,
            pronunciation: false,
            confidence: 100,
          ));
          previousStart = double.parse((firstStart + 0.01).toStringAsFixed(2));
        } else if (i == 0 && !word.contains(RegExp(allLetters))) {
          newWordList.add(Word(
            startTime: firstStart,
            endTime: double.parse((firstStart + averageTime).toStringAsFixed(2)),
            word: word,
            pronunciation: true,
            confidence: 100,
          ));
          previousStart = double.parse((firstStart + averageTime).toStringAsFixed(2));
        } else if (i != 0 && word.contains(RegExp(allLetters))) {
          newWordList.add(Word(
            startTime: previousStart,
            endTime: double.parse((previousStart + 0.01).toStringAsFixed(2)),
            word: word,
            pronunciation: false,
            confidence: 100,
          ));
          previousStart = double.parse((previousStart + 0.01).toStringAsFixed(2));
        } else {
          newWordList.add(Word(
            startTime: previousStart,
            endTime: double.parse((previousStart + averageTime).toStringAsFixed(2)),
            word: word,
            pronunciation: true,
            confidence: 100,
          ));
          previousStart = double.parse((previousStart + averageTime).toStringAsFixed(2));
        }
        i++;
      }
    }
    newWordList.last.endTime = wordList.last.endTime;
    return newWordList;
  }

  List<String> convertStringToList(String textValue) {
    List<String> list = textValue.split('');
    List<String> newList = [];
    List<String> returnList = [];

    for (var e in list) {
      if (e.contains(RegExp(allLettersAndSpace))) {
        newList.add(' $e');
      } else {
        newList.add(e);
      }
    }

    returnList = newList.join('').split(' ');

    return returnList;
  }

  Transcription wordListToTranscription(Transcription transcription, List<Word> wordList) {
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
          if (!word.pronunciation) type = 'punctuation';

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

  ///
  ///Speaker editing methods
  ///
  Transcription getNewSpeakerLabels(Transcription oldTranscription, double startTime, double endTime, int speaker) {
    //Creating the variables...
    Transcription newTranscription = oldTranscription;
    List<Segment> speakerLabels = newTranscription.results.speakerLabels.segments;

    newTranscription.results.speakerLabels.segments = getNewSLList(
      speakerLabels,
      startTime,
      endTime,
      speaker,
    );
    final sws = getSpeakerSwitches(newTranscription);
    return newTranscription;
  }

  List<Segment> getNewSLList(List<Segment> oldList, double startTime, double endTime, int speaker) {
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
    for (Segment segment in oldList) {
      double segmentStart = double.parse(segment.startTime);
      double segmentEnd = double.parse(segment.endTime);
      bool hasBeenThrough = false;
      bool beforeFirst = false;
      bool firstChanged = false;
      bool newChanged = false;
      bool lastChanged = false;

      if (index == 0 && startTime < segmentStart || multipleBeforeFirst && startTime <= segmentStart) beforeFirst = true;

      if (segmentStart <= startTime && startTime <= segmentEnd && endTime >= segmentEnd || beforeFirst && endTime > segmentStart) {
        ///
        ///Case 1:
        ///When the speaker assigning startTime is inside the current segment.
        ///Or if it's before the first one.
        ///
        List<SegmentItem> firstItems = goThroughSegmentItems(segment.speakerLabel, segmentStart, startTime, segment.items);
        if (firstItems.length > 0) {
          firstSegment = Segment(
            startTime: segment.startTime,
            speakerLabel: segment.speakerLabel,
            endTime: (startTime - 0.01).toString(),
            items: firstItems,
          );
          firstChanged = true;
        }

        if (multipleBeforeFirst) {
          multipleBeforeFirst = false;
        }

        ///Going through every item in the list and adds them to the new list.
        List<SegmentItem> newItemsList = goThroughSegmentItems(speakerLabel, startTime, endTime, segment.items);
        for (SegmentItem element in newItemsList) {
          newSegmentItems.add(element);
        }

        if (endTime <= segmentEnd) {
          newDone = true;
        }

        newChanged = true;
        newSegment.startTime = startTime.toString();
        newSegment.speakerLabel = speakerLabel;
        newSegment.endTime = endTime.toString();
        hasBeenThrough = true;
      } else if (segmentStart <= endTime && endTime <= segmentEnd && !hasBeenThrough) {
        ///
        ///Case 2:
        ///When the speaker assigning endTime is inside the current segment
        ///
        List<SegmentItem> lastItems = goThroughSegmentItems(segment.speakerLabel, endTime, segmentEnd, segment.items);
        if (lastItems.length > 0) {
          lastSegment = Segment(
            startTime: (endTime + 0.01).toString(),
            speakerLabel: segment.speakerLabel,
            endTime: segment.endTime,
            items: lastItems,
          );
          lastChanged = true;
        }

        ///Going through every item in the list and adds them to the new list
        List<SegmentItem> newItemsList = goThroughSegmentItems(speakerLabel, startTime, endTime, segment.items);

        newItemsList.forEach((element) => {newSegmentItems.add(element)});
        newChanged = true;
        newDone = true;

        newSegment.startTime = startTime.toString();
        newSegment.speakerLabel = speakerLabel;
        newSegment.endTime = endTime.toString();
        hasBeenThrough = true;
      } else if (segmentStart >= startTime && endTime >= segmentEnd && !hasBeenThrough) {
        ///
        ///Case 3:
        ///When the speaker assigning startTime is going through the current segment
        ///So when the startTime is before and endTime is after
        ///

        ///Changing all the speakerLabels and adding them to the list
        segment.items.forEach((item) => {item.speakerLabel = speakerLabel, newSegmentItems.add(item)});

        hasBeenThrough = true;
        newChanged = true;
      } else if (startTime >= segmentStart && endTime <= segmentEnd || beforeFirst && endTime <= segmentStart) {
        ///
        ///Case 4:
        ///When it's all in the segment
        ///
        List<SegmentItem> firstItems = goThroughSegmentItems(segment.speakerLabel, segmentStart, startTime, segment.items);
        if (firstItems.length > 0) {
          firstSegment = Segment(
            startTime: segment.startTime,
            speakerLabel: segment.speakerLabel,
            endTime: (startTime - 0.01).toString(),
            items: firstItems,
          );
          firstChanged = true;
        }

        List<SegmentItem> lastItems = goThroughSegmentItems(segment.speakerLabel, endTime, segmentEnd, segment.items);
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
        List<SegmentItem> newItemsList = goThroughSegmentItems(speakerLabel, startTime, endTime, segment.items);
        newItemsList.forEach((element) => {newSegmentItems.add(element)});

        if (beforeFirst) {
          multipleBeforeFirst = true;
        }

        newChanged = true;
        newDone = true;
        newSegment.startTime = startTime.toString();
        newSegment.speakerLabel = speakerLabel;
        newSegment.endTime = endTime.toString();
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

  List<SegmentItem> goThroughSegmentItems(String speakerLabel, double startTime, double endTime, List<SegmentItem> items) {
    List<SegmentItem> newList = [];

    for (SegmentItem item in items) {
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
      int currentSpeaker = int.parse(segment.speakerLabel.split('_')[1]);
      double startTimeMil = double.parse(segment.startTime) * 1000;
      double endTimeMil = double.parse(segment.endTime) * 1000;
      Duration startTime = Duration(milliseconds: startTimeMil.toInt());
      Duration endTime = Duration(milliseconds: endTimeMil.toInt());

      if (currentSpeaker == lastSpeaker) {
        lastSpeaker = currentSpeaker;
      } else {
        speakerSwitchList.add(speakerSwitch);
        speakerSwitch = SpeakerSwitch(
          duration: startTime,
          durationEnd: endTime,
          speaker: currentSpeaker,
        );
        lastSpeaker = currentSpeaker;
      }
    }
    return speakerSwitchList;
  }

  List<double> getStartEndFromSelection(SpeakerWithWords sww, Transcription transcription, int selectStart, int selectEnd) {
    final allItems = transcription.results.items;
    List<WordCharacters> wordCharList = [];
    bool startEntered = false;
    double lastEnd = 0;

    for (Item item in allItems) {
      if (double.parse(item.startTime) >= sww.startTime && double.parse(item.endTime) <= sww.endTime) {
        startEntered = true;
        wordCharList.add(WordCharacters(
            startTime: double.parse(item.startTime),
            endTime: double.parse(item.endTime),
            characters: item.alternatives[0].content.split(''),
            type: item.type));
        lastEnd = double.parse(item.endTime);
      } else if (startEntered) {
        wordCharList.add(
            WordCharacters(startTime: lastEnd + 0.01, endTime: lastEnd + 0.02, characters: item.alternatives[0].content.split(''), type: item.type));
      }
      if (double.parse(item.startTime) > sww.endTime) break;
    }

    double currentPlace = 0;
    bool startChosen = false;
    int startIndex = 0;
    int endIndex = 0;
    int i = 0;

    for (WordCharacters word in wordCharList) {
      if (word.type == 'pronunciation') {
        currentPlace += word.characters.length + 1;
      } else {
        currentPlace += word.characters.length;
      }
      if (!startChosen && selectStart + 1 <= currentPlace) {
        startIndex = i;
        startChosen = true;
      }
      if (startChosen && selectEnd <= currentPlace) {
        endIndex = i;
        break;
      }
      i++;
    }
    return [wordCharList[startIndex].startTime, wordCharList[endIndex].endTime];
  }
}

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

int getMil(double seconds) {
  double milliseconds = seconds * 1000;
  return milliseconds.toInt();
}

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

class WordCharacters {
  WordCharacters({
    required this.startTime,
    required this.endTime,
    required this.characters,
    required this.type,
  });
  final double startTime;
  final double endTime;
  final List<String> characters;
  final String type;
}

class Word {
  double startTime;
  double endTime;
  String word;
  bool pronunciation;
  double confidence;

  Word({
    required this.startTime,
    required this.endTime,
    required this.word,
    required this.pronunciation,
    required this.confidence,
  });
}
