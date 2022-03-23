import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'transcriptionParsing.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class TranscriptionProcessing with ChangeNotifier {
  /*
  * Creating all the necessary variables
  * All the variables needs to be empty, an error occurs if they are null
  */
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

  /*
  * Providing the necessary variables and creating the lists
  */
  List<SpeakerSegment> _speakerInterval = [];
  List<PronouncedWord> _wordList = [];
  List<SpeakerWithWords> _speakerWordsCombined = [];

  String get fullTranscript => _fullTranscript;
  List<SpeakerSegment> speakerInterval() => _speakerInterval;
  List<PronouncedWord> wordList() => _wordList;
  List<SpeakerWithWords> speakerWordsCombined() => _speakerWordsCombined;

  /*
  * Clearing all the variables, so it's ready for another round...
  */
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
    Uri uri = Uri.parse(url); //Getting the uri from the url
    var response;
    try {
      response = await http.get(uri); //Trying to reach the uri
      //print(response.body);
      if (response.statusCode == 200) {
        print('Did not fail!'); //If the statuscode is 200, then it didn't fail
        final Transcription transription = transcriptionFromJson(utf8.decode(
            response
                .bodyBytes)); //Decoding the recieved http string and parsing the json
        return transription; //Returning the Transcription class
      } else {
        print('Failed but got response: ${response.statusCode}!'); //It failed
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
        return error; //Returning an empty Transcription class
      }
    } catch (e) {
      recordEventError('getTranscriptionFromURL', e.toString());
      print('ERROR TranscriptionChat: $e');
      final Transcription transription = transcriptionFromJson(response.body);
      return transription;
    }
  }

  Transcription getTranscriptionFromString(String string) {
    Transcription transcription = transcriptionFromJson(string);
    return transcription;
  }

  /*
  * This function will split the recieved Transcription class into smaller chunks
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
  * This function will take all the speakerlabels and get the time interval in which they speak
  * It will also group together the same speakerlabels
  */
  List<SpeakerSegment> getSpeakerLabels(List<Segment> slSegments) {
    //Creating the necessary variables
    List<SpeakerSegment> sInterval = [];
    String currentSpeaker = '';
    double currentStartTime = 0.0;
    int currentIndex = 0;
    int index = 0;

    /*
    * Each segment in the slSegments contains a speakerlabel and the timeframe in which they speak
    * It will then remember what the last speakerlabel was, if they're the same, it will put them together
    * If not, it will move on to a new group, and so on...
    */
    for (Segment segment in slSegments) {
      if (segment.speakerLabel == currentSpeaker) {
        //Checks if it's the same speakerlabel as the last one
        sInterval[currentIndex] = SpeakerSegment(
          //If it is, it will update the current index
          startTime: currentStartTime, //The start time will stay the same
          speakerLabel:
              currentSpeaker, //The speakerlabel of course stays the same
          endTime: double.parse(
              segment.endTime), //The end time is set as the current segment's
        );
        currentSpeaker = segment.speakerLabel;
      } else if (segment.speakerLabel != currentSpeaker) {
        //Checks if the speakerlabel aren't the same as the last one
        currentStartTime = double.parse(segment
            .startTime); //Updates the start time to be the current segment's
        currentIndex = sInterval
            .length; //The new index will be checked from the length of the list
        currentSpeaker = segment
            .speakerLabel; //The current speakerlabel is updated to the new one
        sInterval.add(
          //A new SpeakerSegment is added to the list
          SpeakerSegment(
            startTime: double.parse(segment.startTime),
            speakerLabel: segment.speakerLabel,
            endTime: double.parse(segment.endTime),
          ),
        );
      } //Repeat...
      index++;
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
    * In here we check it's a pronounciation, which means it's a word
    * It can also be a punctuation, which means it's autogenerated by the AI
    * 
    * Every pronounciation contains an alternative, which contains the word, timeframe and confidence
    * This is used add every word to a word list, with the timeframe and confidence
    * 
    * Every punctuation is put into the word list as well
    */
    for (Item item in items) {
      if (item.type == 'pronunciation') {
        //Checking if it's a pronounciation
        //Creating temporary variables
        String word = '';
        double confidence = 0.0;
        //Running through every "alternative"
        for (Alternative alternative in item.alternatives) {
          word = alternative
              .content; //The word is assigned to a temporary variable
          confidence =
              double.parse(alternative.confidence); //Getting the confidence
          wList.add(
            //Adding the word, timeframe and confidence to the word list
            PronouncedWord(
              startTime: double.parse(item.startTime),
              word: word,
              endTime: double.parse(item.endTime),
              confidence: confidence,
            ),
          );
        }
      } else {
        //Everything that isn't a pronounciation
        //Creating temporary variables
        double lastStartTime = wList.last.startTime;
        double lastEndTime = wList.last.endTime;
        //Running through every "alternative"
        for (Alternative alternative in item.alternatives) {
          String punctuation = alternative
              .content; //The type of punctuation is assigned to a temporary variable
          wList.add(
            //Adding the punctuation, timeframe (ish) and confidence (ish) to the word list
            PronouncedWord(
              startTime:
                  lastEndTime, //Using the last end time to make an estimate
              word: punctuation,
              endTime: lastEndTime + 0.01, //Again but plus a little bit
              confidence: 100,
            ), //Definitely 100%
          );
        }
      }
      //Repeat...
    }
    _wordList = wList;
    return wList;
  }

  /*
  * In this function the words are combined with the speakerlabels
  * This is done by using the timeframe from both parts and checking if it matches
  * It's like Tinder for words and speakerlabels...
  */
  List<SpeakerWithWords> combineWordsWithSpeaker(
      List<SpeakerSegment> spInterval, List<PronouncedWord> wList) {
    List<SpeakerWithWords> swCombined = [];
    /*
    * It's done by first getting the SpeakerSegments which were created in the getSpeakerLabels function
    * For each segment in that list it's checking through the word list and getting the word with a timeframe within the same as the SpeakerSegment
    */
    for (SpeakerSegment speakerSegment in spInterval) {
      //Creating temporary variables
      List<String> _words = [];
      List<String> _joinableWords = [];
      //Checking through the word list if the timeframe is matching
      for (PronouncedWord pronouncedWord in wList) {
        if (pronouncedWord.startTime >= speakerSegment.startTime &&
            pronouncedWord.endTime <= speakerSegment.endTime) {
          _words.add(pronouncedWord
              .word); //If the timeframe matches, the word will be added to a list of words matching the current speakerlabel
        }
      }
      //Checking for punctuations and adding a space between words and punctuations
      for (String word in _words) {
        if (word == ',' || word == '.' || word == '?' || word == '!') {
          _joinableWords.add('$word');
        } else {
          _joinableWords.add(' $word');
        }
      }
      //When every is fine and dandy, the speakerlabel and words will be combined as a single element in a list
      swCombined.add(
        SpeakerWithWords(
          startTime: speakerSegment.startTime,
          speakerLabel: speakerSegment.speakerLabel,
          endTime: speakerSegment.endTime,
          pronouncedWords: _joinableWords.join(),
        ),
      );
      //Repeat...
    }
    _speakerWordsCombined = swCombined;
    return swCombined;
  }

  /*
  * This function is used to process the transcription when it has been loaded
  */
  List<SpeakerWithWords> assignWordsToSpeaker(Transcription _transcription) {
    List<SpeakerSegment> _spkSegments =
        getSpeakerLabels(_transcription.results.speakerLabels.segments);
    List<PronouncedWord> _wList = getWords(_transcription.results.items);
    List<SpeakerWithWords> _swCombined =
        combineWordsWithSpeaker(_spkSegments, _wList);
    return _swCombined;
  }

  /*
  * This function is the one being called when the user want's to get the transcription
  */
  Future processTranscription(String url) async {
    //clear();
    transcription = await getTranscriptionFromURL(url);
    getTranscript();
    assignWordsToSpeaker(transcription);
  }

  List<SpeakerWithWords> processTranscriptionJSON(String json) {
    //clear();
    transcription = getTranscriptionFromString(json);
    getTranscript();
    return assignWordsToSpeaker(transcription);
  }
}

/*
* This class creates an element containing the speakerlabel and the timeframe in which they speak
*/
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

/*
* This class creates an element containing the word, timefram and confidence
*/
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

/*
* This class creates an element containing the speakerlabel, timeframe and the words spoken
*/
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
