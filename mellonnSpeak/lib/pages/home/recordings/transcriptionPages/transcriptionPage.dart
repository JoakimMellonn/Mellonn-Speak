import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/models/Version.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/editingPages/speakerEdit/transcriptionEditPage.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/versionHistory/versionHistoryPage.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
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
  final TemporalDateTime? recordingDate;
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
  DateFormat formatter = DateFormat('dd-MM-yyyy');

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

  void transcriptionResetState() {
    setState(() {
      isLoading = true;
    });
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
        recordEventError('initialize-transcription', e.toString());
        print('Something went wrong: $e');
      }
    }

    if (isLoading == false) {
      transcription = await context
          .read<TranscriptionProcessing>()
          .getTranscriptionFromString(json);

      bool originalExists =
          await checkOriginalVersion(widget.id, transcription);
      //print('Original: $originalExists');

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
    } else if (choice == 'Export DOCX') {
      await saveDOCX();
    } else if (choice == 'Version history') {
      showVersionHistory();
    } else if (choice == 'Info') {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(
            "Info",
            style: Theme.of(context).textTheme.headline5,
          ),
          content: Text(
            'Title: ${widget.recordingName} \nDescription: ${widget.recordingDescription} \nDate: ${formatter.format(widget.recordingDate?.getDateTimeInUtc() ?? DateTime.now())} \nFile: ${widget.fileName} \nParticipants: ${widget.speakerCount}',
            style: Theme.of(context).textTheme.headline6?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  isLoading = false;
                });
                Navigator.pop(context, 'OK');
              },
              child: Text(
                'OK',
                style: Theme.of(context).textTheme.headline6?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  shadows: <Shadow>[
                    Shadow(
                      color: Colors.amber,
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    } else if (choice == 'Delete this recording') {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Are you sure?'),
          content: Text(
              'You are about to delete this recording, this can NOT be undone'),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    //If they aren't, it will just close the dialog, and they can live happily everafter
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                  child: Text('No'),
                ),
                SizedBox(
                  width: 75,
                ),
                TextButton(
                  onPressed: () async {
                    //If they are, it will delete the recording and close the dialog
                    await deleteRecording();
                    setState(() {
                      Navigator.pop(context);
                    });
                  },
                  child: Text('Yes'),
                ),
              ],
            ),
          ],
        ),
      );
    } else if (choice == 'Help') {
      helpDialog(context, HelpPage.transcriptionPage);
    } else if (choice == 'Give feedback') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendFeedbackPage(
            where: 'Transcription page',
            type: FeedbackType.feedback,
          ),
        ),
      );
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

    if (docxCreated && !Platform.isIOS) {
      print('Docx created!');
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Docx creation succeeded :)',
          text:
              'You can now find the generated docx file in the location you chose',
        ),
      );
    } else if (docxCreated && Platform.isIOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Docx creation succeeded :)',
          text:
              'You can now find the generated docx file in the "Files"-app.\nIn the "Files"-app go to "Browse", "On My iPhone" and find the folder "Speak", the Word document will be in here.',
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
          transcriptionResetState: transcriptionResetState,
        ),
      ),
    );
  }

  void showVersionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VersionHistoryPage(
          recordingID: widget.id,
          user: user,
          transcriptionResetState: transcriptionResetState,
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
  ///Deletes the current recording...
  ///
  Future<void> deleteRecording() async {
    final fileKey = widget.fileKey;
    final id = widget.id;
    try {
      (await Amplify.DataStore.query(Recording.classType,
              where: Recording.ID.eq(widget.id)))
          .forEach((element) async {
        //The tryception begins...
        print('Deleting recording: ${element.id}');
        try {
          //Removing the DataStore element
          await Amplify.DataStore.delete(element);
          //Removing all files associated with the recording
          await removeRecording(id, fileKey);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Recording deleted'),
            backgroundColor: Colors.red,
          ));
          Navigator.pop(context);
        } on DataStoreException catch (e) {
          recordEventError('deleteRecording-DataStore', e.message);
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text(e.message),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, 'OK'),
                  child: const Text('OK'),
                )
              ],
            ),
          );
        }
      });
    } catch (e) {
      recordEventError('deleteRecording-other', e.toString());
      print('ERROR: $e');
    }
    //After the recording is deleted, it makes a new list of the recordings
    context.read<DataStoreAppProvider>().getRecordings();
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

        if (isLoading) {
          return LoadingScreen();
        } else {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              automaticallyImplyLeading: false,
              title: StandardAppBarTitle(),
              elevation: 0,
            ),
            body: Container(
              color: Theme.of(context).colorScheme.background,
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  TitleBox(
                    title: widget.recordingName,
                    heroString: 'pageTitle',
                    extras: true,
                    extra: PopupMenuButton<String>(
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
                        return {
                          'Edit',
                          'Export DOCX',
                          'Version history',
                          'Info',
                          'Delete this recording',
                          'Help',
                          'Give feedback'
                        }.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(choice,
                                style: Theme.of(context).textTheme.headline6),
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
                            height: 25,
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
                                transcriptionResetState:
                                    transcriptionResetState,
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
