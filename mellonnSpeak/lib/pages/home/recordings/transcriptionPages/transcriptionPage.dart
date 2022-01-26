import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/editingPages/speakerEdit/transcriptionEditPage.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/src/provider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionToDocx.dart';
import 'package:just_audio/just_audio.dart';

bool isLoading = true; //Creating the necessary variables
String fullTranscript = '';
List<SpeakerWithWords> speakerWordsCombined = [];
String user = '';
String json = '';
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
String audioPath = '';
bool nowPlaying = false;
int currentlyPlaying = 0;
final player = AudioPlayer();

class TranscriptionPage extends StatefulWidget {
  //Creating the necessary variables
  final String recordingName;
  final TemporalDate? recordingDate;
  final String recordingDescription;
  final String fileName;
  final String fileKey;
  final String id;
  final String fileUrl;
  final int speakerCount;

  //Making them required
  const TranscriptionPage({
    Key? key,
    required this.recordingName,
    required this.recordingDate,
    required this.recordingDescription,
    required this.fileName,
    required this.fileKey,
    required this.id,
    required this.fileUrl,
    required this.speakerCount,
  }) : super(key: key);

  @override
  _TranscriptionPageState createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  //Temp variable
  int userNumber = 1;

  ///
  ///Opposite of iniState this is called when the widget is closed...
  ///
  @protected
  @mustCallSuper
  void dispose() {
    fullTranscript = '';
    speakerWordsCombined = [];
    json = '';
    user = '';
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
    isLoading = true;
    player.dispose();
    //context.read<TranscriptionProcessing>().clear();
    super.dispose();
  }

  ///
  ///When initializing this widget, the transcription first needs to be loaded.. apparently
  ///First we're calling the json parsing code, which makes the recieved json-file into a list
  ///That list is then split into the different parts we need in order to create the chat bubbles
  ///
  Future initialize() async {
    final tempDir = await getTemporaryDirectory();
    final filePath = tempDir.path + '/${widget.id}.json';

    await context.read<TranscriptionProcessing>().clear();

    if (isLoading == true) {
      try {
        json =
            await context.read<StorageProvider>().downloadTranscript(widget.id);

        audioPath =
            await context.read<StorageProvider>().getAudioPath(widget.fileKey);
        await player.setFilePath(audioPath);
        await player.load();

        isLoading = false;
      } catch (e) {
        print('Something went wrong: $e');
      }
    }

    if (isLoading == false) {
      transcription = await context
          .read<TranscriptionProcessing>()
          .getTranscriptionFromString(json);

      await context
          .read<TranscriptionProcessing>()
          .processTranscriptionJSON(json);
    }

    user =
        'spk_${userNumber}'; //The user has to choose whose what speakernumber
  }

  ///
  ///This function handles when an item in the popup menu is clicked
  ///
  Future<void> handleClick(String choice) async {
    if (choice == 'Edit') {
      editTranscription();
    } else if (choice == 'Download DOCX') {
      await saveDOCX();
    } else if (choice == 'Info') {
      setState(() {
        print('Info');
      });
    }
  }

  ///
  ///This function creates a DOCX-file from the transcription
  ///
  Future<void> saveDOCX() async {
    bool docxCreated = await TranscriptionToDocx().createDocxFromTranscription(
      widget.recordingName,
      speakerWordsCombined,
    );

    if (docxCreated) {
      print('Docx created!');
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Docx creation succeded :)',
          text:
              'You can now find the generated docx file in the location you chose',
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Docx creation failed :(',
          text: 'You need to choose a location for the output file...',
        ),
      );
    }
  }

  ///
  ///This function starts the editing of the transcript
  ///
  Future<void> editTranscription() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranscriptionEditPage(
          id: widget.id,
          recordingName: widget.recordingName,
          user: user,
          transcription: transcription,
          speakerWordsCombined: speakerWordsCombined,
          speakerCount: widget.speakerCount,
          audioFileKey: audioPath,
        ),
      ),
    );
  }

  void playPause(double startTime, double endTime, int i) async {
    await player.setClip(
      start: Duration(milliseconds: getMil(startTime)),
      end: Duration(milliseconds: getMil(endTime)),
    );
    if (!nowPlaying) {
      setState(() {
        nowPlaying = true;
        currentlyPlaying = i;
      });
      player.play();
    } else if (nowPlaying && currentlyPlaying == i) {
      setState(() {
        nowPlaying = false;
      });
      await player.pause();
    } else {
      setState(() {
        nowPlaying = true;
        currentlyPlaying = i;
      });
      await player.pause();
      player.play();
    }
  }

  ///
  ///Building the transcriptionPage widget
  ///
  @override
  Widget build(BuildContext context) {
    int i = 0;
    return FutureBuilder(
      future: initialize(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        //Assigning the values
        fullTranscript =
            context.watch<TranscriptionProcessing>().fullTranscript;
        speakerWordsCombined =
            context.watch<TranscriptionProcessing>().speakerWordsCombined();

        if (isLoading == true) {
          return LoadingScreen();
        } else {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: standardAppBar,
            body: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  TitleBox(
                    title: widget.recordingName,
                    extras: true,
                    extra: PopupMenuButton<String>(
                      color: context.read<ColorProvider>().backGround,
                      icon: Icon(
                        FontAwesomeIcons.ellipsisV,
                        color: context.read<ColorProvider>().darkText,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(
                          Radius.circular(25.0),
                        ),
                      ),
                      onSelected: handleClick,
                      itemBuilder: (BuildContext context) {
                        return {'Edit', 'Download DOCX', 'Info'}
                            .map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(
                              choice,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: context.read<ColorProvider>().darkText,
                                shadows: <Shadow>[
                                  Shadow(
                                    color: context.read<ColorProvider>().shadow,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  //Getting the TranscriptionChatWidget with the given JSON
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: ListView(
                        physics: BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        children: [
                          SizedBox(
                            height: 15,
                          ),

                          ///
                          ///Mapping the list of words, which also contains info about who said it and when
                          ///
                          ...speakerWordsCombined.map(
                            (element) {
                              i++;
                              return AnimatedChatDrawer(
                                recordingName: widget.recordingName,
                                id: widget.id,
                                startTime: element.startTime,
                                endTime: element.endTime,
                                speakerLabel: element.speakerLabel,
                                pronouncedWords: element.pronouncedWords,
                                i: i,
                                transcription: transcription,
                                audioPath: audioPath,
                                playPause: playPause,
                                isUser: element.speakerLabel == user,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
