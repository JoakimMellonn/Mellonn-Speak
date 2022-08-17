import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/editingPages/speakerEdit/transcriptionEditPage.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/speakerLabels/speakerLabelsPage.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/versionHistory/versionHistoryPage.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';
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
  final Recording recording;
  final Function(Recording) refreshRecording;

  //Making them required
  const TranscriptionPage({
    required this.recording,
    required this.refreshRecording,
    Key? key,
  }) : super(key: key);

  @override
  _TranscriptionPageState createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  //Temp variable
  DateFormat formatter = DateFormat('dd-MM-yyyy');

  ///
  ///Opposite of iniState this is called when the widget is closed...
  ///
  @override
  void dispose() {
    fullTranscript = '';
    speakerWordsCombined = [];
    json = '';
    user = '';
    transcription = Transcription(
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
  ///First we're calling the json parsing code, which makes the received json-file into a list
  ///That list is then split into the different parts we need in order to create the chat bubbles
  ///
  Future initialize() async {
    await context.read<TranscriptionProcessing>().clear();

    if (isLoading == true) {
      try {
        json = await context.read<StorageProvider>().downloadTranscript(widget.recording.id);

        audioPath = await context.read<StorageProvider>().getAudioUrl(widget.recording.fileKey!);
        await player.setUrl(audioPath);
        await player.load();

        transcription = context.read<TranscriptionProcessing>().getTranscriptionFromString(json);

        await checkOriginalVersion(widget.recording.id, transcription);

        isLoading = false;
      } catch (e) {
        recordEventError('initialize-transcription', e.toString());
        print('Something went wrong: $e');
      }
    }

    if (isLoading == false) {
      if (json != '') {
        context.read<TranscriptionProcessing>().processTranscriptionJSON(json);
      } else {
        setState(() {
          isLoading = true;
        });
      }
    }
  }

  void refreshRecording(Recording newRecording) {
    //print('Transcription page 1');
    Navigator.pop(context);
    widget.refreshRecording(newRecording);
  }

  ///
  ///This function handles when an item in the popup menu is clicked
  ///
  Future<void> handleClick(String choice) async {
    if (choice == 'Edit speakers') {
      editTranscription();
    } else if (choice == 'Edit labels') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpeakerLabelsPage(
            recording: widget.recording,
            first: false,
            stateSetter: transcriptionResetState,
            refreshRecording: refreshRecording,
          ),
        ),
      );
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
            'Title: ${widget.recording.name} \nDescription: ${widget.recording.description} \nDate: ${formatter.format(widget.recording.date?.getDateTimeInUtc() ?? DateTime.now())} \nFile: ${widget.recording.fileName} \nParticipants: ${widget.recording.speakerCount}',
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
          content: Text('You are about to delete this recording, this can NOT be undone'),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    //If they aren't, it will just close the dialog, and they can live happily ever after
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
                    Navigator.pop(context);
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

  Future<void> saveDOCX() async {
    String docxCreated = await TranscriptionToDocx().createDocxFromTranscription(
      widget.recording.name,
      speakerWordsCombined,
      widget.recording.labels!,
    );

    if (docxCreated == 'true' && !Platform.isIOS) {
      print('Docx created!');
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Docx creation succeeded :)',
          text: 'You can now find the generated docx file in the downloads folder of your phone.',
        ),
      );
    } else if (docxCreated == 'true' && Platform.isIOS) {
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
          text: docxCreated,
        ),
      );
    }
  }

  Future<void> editTranscription() async {
    final url = await context.read<StorageProvider>().getAudioUrl(widget.recording.fileKey!);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TranscriptionEditPage(
          id: widget.recording.id,
          recordingName: widget.recording.name,
          user: user,
          transcription: transcription,
          speakerWordsCombined: speakerWordsCombined,
          speakerCount: widget.recording.speakerCount,
          audioFileKey: url,
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
          recordingID: widget.recording.id,
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

  Future<void> deleteRecording() async {
    final fileKey = widget.recording.fileKey!;
    final id = widget.recording.id;
    try {
      (await Amplify.DataStore.query(Recording.classType, where: Recording.ID.eq(widget.recording.id))).forEach((element) async {
        //The tryception begins...
        //print('Deleting recording: ${element.id}');
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
  }

  int getNumber(String speakerLabel) {
    return int.parse(speakerLabel.split('_').last);
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
        fullTranscript = context.watch<TranscriptionProcessing>().fullTranscript;
        speakerWordsCombined = context.watch<TranscriptionProcessing>().speakerWordsCombined();

        if (isLoading) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
          );
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
                    title: widget.recording.name,
                    heroString: widget.recording.id,
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
                          'Edit labels',
                          'Edit speakers',
                          'Export DOCX',
                          'Version history',
                          'Info',
                          'Delete this recording',
                          'Help',
                          'Give feedback'
                        }.map((String choice) {
                          return PopupMenuItem<String>(
                            value: choice,
                            child: Text(
                              choice,
                              style: Theme.of(context).textTheme.headline6,
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
                            height: 25,
                          ),

                          ///
                          ///Mapping the list of words, which also contains info about who said it and when
                          ///
                          ...speakerWordsCombined.map(
                            (element) {
                              i++;
                              return AnimatedChatDrawer(
                                recordingName: widget.recording.name,
                                id: widget.recording.id,
                                startTime: element.startTime,
                                endTime: element.endTime,
                                speakerLabel:
                                    '${widget.recording.labels![getNumber(element.speakerLabel)]} (Speaker ${getNumber(element.speakerLabel) + 1})',
                                pronouncedWords: element.pronouncedWords,
                                i: i,
                                transcription: transcription,
                                audioPath: audioPath,
                                playPause: playPause,
                                isUser: widget.recording.interviewers!.contains(element.speakerLabel),
                                transcriptionResetState: transcriptionResetState,
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
