import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'transcriptionParsing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TranscriptionProcessing with ChangeNotifier {
  String jobName = '';
  String accountID = '';
  String status = 'INCOMPLETE';
  Transcription transcription = Transcription(
    accountId: '',
    jobName: '',
    status: '',
    results: Results(
      transcripts: [],
      speakerLabels: SpeakerLabels(speakers: 0, segments: []),
      items: [],
    ),
  );
  Results results = Results(
    transcripts: [],
    speakerLabels: SpeakerLabels(speakers: 0, segments: []),
    items: [],
  );
  SpeakerLabels speakerLabels = SpeakerLabels(speakers: 0, segments: []);
  String _fullTranscript = '';

  List<SpeakerSegment> _speakerInterval = [];
  List<PronouncedWord> _wordList = [];
  List<SpeakerWithWords> _speakerWordsCombined = [];

  String get fullTranscript => _fullTranscript;
  List<SpeakerSegment> speakerInterval() => _speakerInterval;
  List<PronouncedWord> wordList() => _wordList;
  List<SpeakerWithWords> speakerWordsCombined() => _speakerWordsCombined;

  Future<void> clear() async {
    _fullTranscript = '';
    _speakerInterval = [];
    _wordList = [];
    _speakerWordsCombined = [];
  }

  /*
  * In this function the given url will be loaded and made into a json string
  * After that the json string is sent to the json parsing function and will be returned as a Transcription class
  */
  static Future<Transcription> getTranscriptionFromURL(String url) async {
    Uri uri = Uri.parse(url);
    var response;
    try {
      response = await http.get(uri);
      if (response.statusCode == 200) {
        print('Did not fail!');
        final Transcription transcription = transcriptionFromJson(utf8.decode(response.bodyBytes));
        return transcription;
      } else {
        print('Failed but got response: ${response.statusCode}!');
        Transcription error = Transcription(
          accountId: '',
          jobName: '',
          status: '',
          results: Results(
            transcripts: [],
            speakerLabels: SpeakerLabels(speakers: 0, segments: []),
            items: [],
          ),
        );
        return error;
      }
    } catch (e) {
      recordEventError('getTranscriptionFromURL', e.toString());
      print('ERROR TranscriptionChat: $e');
      final Transcription transcription = transcriptionFromJson(response.body);
      return transcription;
    }
  }

  Transcription getTranscriptionFromString(String string) {
    Transcription transcription = transcriptionFromJson(string);
    return transcription;
  }

  /*
  * This function will split the received Transcription class into smaller chunks
  * These chunks are easier for me to work with
  */
  Future<void> getTranscript() async {
    jobName = transcription.jobName;
    accountID = transcription.accountId;
    status = transcription.status;
    results = transcription.results;
    speakerLabels = results.speakerLabels;
    _fullTranscript = results.transcripts.first.toString();
  }

  /*
  * This function will take all the speaker labels and get the time interval in which they speak
  * It will also group together the same speaker labels
  */
  List<SpeakerSegment> getSpeakerLabels(List<Segment> slSegments) {
    //Creating the necessary variables
    List<SpeakerSegment> sInterval = [];
    String currentSpeaker = '';
    double currentStartTime = 0.0;
    int currentIndex = 0;

    /*
    * Each segment in the slSegments contains a speaker label and the time frame in which they speak
    * It will then remember what the last speaker label was, if they're the same, it will put them together
    * If not, it will move on to a new group, and so on...
    */
    for (Segment segment in slSegments) {
      if (segment.speakerLabel == currentSpeaker) {
        sInterval[currentIndex] = SpeakerSegment(
          startTime: currentStartTime,
          speakerLabel: currentSpeaker,
          endTime: double.parse(segment.endTime),
        );
        currentSpeaker = segment.speakerLabel;
      } else if (segment.speakerLabel != currentSpeaker) {
        currentStartTime = double.parse(segment.startTime);
        currentIndex = sInterval.length;
        currentSpeaker = segment.speakerLabel;
        sInterval.add(
          SpeakerSegment(
            startTime: double.parse(segment.startTime),
            speakerLabel: segment.speakerLabel,
            endTime: double.parse(segment.endTime),
          ),
        );
      }
    }
    _speakerInterval = sInterval;
    return sInterval;
  }

  /*
  * This function gets the word and time frame in which it has been spoken
  * As a bonus, it also gets the confidence of the word
  */
  List<PronouncedWord> getWords(List<Item> items) {
    List<PronouncedWord> wList = [];
    /*
    * Each item in items (I know it sounds stupid) contains the type of item
    * In here we check it's a pronunciation, which means it's a word
    * It can also be a punctuation, which means it's autogenerated by the AI
    * 
    * Every pronunciation contains an alternative, which contains the word, time frame and confidence
    * This is used add every word to a word list, with the time frame and confidence
    * 
    * Every punctuation is put into the word list as well
    */
    for (Item item in items) {
      if (item.type == 'pronunciation') {
        String word = '';
        double confidence = 0.0;
        for (Alternative alternative in item.alternatives) {
          word = alternative.content;
          confidence = double.parse(alternative.confidence);
          wList.add(
            PronouncedWord(
              startTime: double.parse(item.startTime),
              word: word,
              endTime: double.parse(item.endTime),
              confidence: confidence,
            ),
          );
        }
      } else {
        double lastEndTime = wList.last.endTime;
        for (Alternative alternative in item.alternatives) {
          String punctuation = alternative.content;
          wList.add(
            PronouncedWord(
              startTime: lastEndTime,
              word: punctuation,
              endTime: lastEndTime + 0.01,
              confidence: 100,
            ),
          );
        }
      }
    }
    _wordList = wList;
    return wList;
  }

  /*
  * In this function the words are combined with the speaker labels
  * This is done by using the time frame from both parts and checking if it matches
  * It's like Tinder for words and speaker labels...
  */
  List<SpeakerWithWords> combineWordsWithSpeaker(List<SpeakerSegment> spInterval, List<PronouncedWord> wList) {
    List<SpeakerWithWords> swCombined = [];
    /*
    * It's done by first getting the SpeakerSegments which were created in the getSpeakerLabels function
    * For each segment in that list it's checking through the word list and getting the word with a time frame within the same as the SpeakerSegment
    */
    for (SpeakerSegment speakerSegment in spInterval) {
      List<String> _words = [];
      List<String> _joinableWords = [];
      for (PronouncedWord pronouncedWord in wList) {
        if (pronouncedWord.startTime >= speakerSegment.startTime && pronouncedWord.endTime <= speakerSegment.endTime) {
          _words.add(pronouncedWord.word);
        }
      }
      for (String word in _words) {
        if (word == ',' || word == '.' || word == '?' || word == '!' || _joinableWords.isEmpty) {
          _joinableWords.add('$word');
        } else {
          _joinableWords.add(' $word');
        }
      }
      swCombined.add(
        SpeakerWithWords(
          startTime: speakerSegment.startTime,
          speakerLabel: speakerSegment.speakerLabel,
          endTime: speakerSegment.endTime,
          pronouncedWords: _joinableWords.join(),
        ),
      );
    }
    _speakerWordsCombined = swCombined;
    return swCombined;
  }

  /*
  * This function is used to process the transcription when it has been loaded
  */
  List<SpeakerWithWords> assignWordsToSpeaker(Transcription _transcription) {
    List<SpeakerSegment> _spkSegments = getSpeakerLabels(_transcription.results.speakerLabels.segments);
    List<PronouncedWord> _wList = getWords(_transcription.results.items);
    List<SpeakerWithWords> _swCombined = combineWordsWithSpeaker(_spkSegments, _wList);
    return _swCombined;
  }

  Future processTranscription(String url) async {
    transcription = await getTranscriptionFromURL(url);
    getTranscript();
    assignWordsToSpeaker(transcription);
  }

  List<SpeakerWithWords> processTranscriptionJSON(String json) {
    transcription = getTranscriptionFromString(json);
    getTranscript();
    return assignWordsToSpeaker(transcription);
  }
}

class SpeakerSegment {
  SpeakerSegment({
    required this.startTime,
    required this.speakerLabel,
    required this.endTime,
  });

  double startTime;
  String speakerLabel;
  double endTime;
}

class PronouncedWord {
  PronouncedWord({
    required this.startTime,
    required this.word,
    required this.endTime,
    required this.confidence,
  });

  double startTime;
  String word;
  double endTime;
  double confidence;
}

class SpeakerWithWords {
  SpeakerWithWords({
    required this.startTime,
    required this.speakerLabel,
    required this.endTime,
    required this.pronouncedWords,
  });

  double startTime;
  String speakerLabel;
  double endTime;
  String pronouncedWords;
}
