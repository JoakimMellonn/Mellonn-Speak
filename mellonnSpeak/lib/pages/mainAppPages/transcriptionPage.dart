import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/src/provider.dart';
import 'package:transscriber/pages/mainAppPages/edit/transcriptionEditPage.dart';
import 'package:transscriber/providers/amplifyStorageProvider.dart';
import 'package:transscriber/providers/colorProvider.dart';
import 'package:transscriber/transcription/transcriptionParsing.dart';
import 'package:transscriber/transcription/transcriptionProvider.dart';
import 'package:transscriber/transcription/transcriptionToDocx.dart';
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
        builder: (BuildContext context) => AlertDialog(
          title: Text('Docx creation succeded :)'),
          content: Text(
              'You can now find the generated docx file in the location you chose'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text('Docx creation failed :('),
          content: Text('You need to choose a location for the output file...'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  ///
  ///This function starts the editing of the transcript
  ///
  ///Currently it's just a test to see if I can edit, save and load a transcription
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
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary),
              ),
            ),
          );
        } else {
          return Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Theme.of(context).colorScheme.background,
            //Creating the same appbar that is used everywhere else
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Center(
                child: Image.asset(
                  context.watch<ColorProvider>().currentLogo,
                  height: 25,
                ),
              ),
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.background,
            ),
            //Creating the page
            body: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  //Making that sweet title widget (with the sexy orange background and rounded corners)
                  Container(
                    padding: EdgeInsets.all(25),
                    width: MediaQuery.of(context).size.width,
                    constraints: BoxConstraints(
                      minHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  //Back button
                                  Container(
                                    constraints: BoxConstraints(
                                      maxHeight: 40,
                                      minWidth:
                                          MediaQuery.of(context).size.width *
                                              0.4,
                                    ),
                                    child: FittedBox(
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              Navigator.pop(context);
                                            },
                                            child: Icon(
                                              FontAwesomeIcons.arrowLeft,
                                              size: 15,
                                              color: context
                                                  .watch<ColorProvider>()
                                                  .darkText,
                                            ),
                                          ),
                                          //Magic spacing...
                                          SizedBox(
                                            width: 10,
                                          ),
                                          //Getting the recording title
                                          Text(
                                            "${widget.recordingName}",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: context
                                                  .watch<ColorProvider>()
                                                  .darkText,
                                              shadows: <Shadow>[
                                                Shadow(
                                                  color: context
                                                      .watch<ColorProvider>()
                                                      .shadow,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Spacer(),
                                  PopupMenuButton<String>(
                                    color: context
                                        .read<ColorProvider>()
                                        .backGround,
                                    icon: Icon(
                                      FontAwesomeIcons.ellipsisV,
                                      color: context
                                          .read<ColorProvider>()
                                          .darkText,
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
                                              color: context
                                                  .read<ColorProvider>()
                                                  .darkText,
                                              shadows: <Shadow>[
                                                Shadow(
                                                  color: context
                                                      .read<ColorProvider>()
                                                      .shadow,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  //Getting the TranscriptionChatWidget with the given JSON
                  Expanded(
                    child: Container(
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
                              if (element.speakerLabel == user) {
                                //Checks if it's the user speaking, and return the right widget
                                return ChatBubbleUser(
                                  startTime: element.startTime,
                                  endTime: element.endTime,
                                  speakerLabel: element.speakerLabel,
                                  text: element.pronouncedWords,
                                  i: i,
                                );
                              } else {
                                //Everything else will be a normal chat bubble
                                return ChatBubble(
                                  startTime: element.startTime,
                                  endTime: element.endTime,
                                  speakerLabel: element.speakerLabel,
                                  text: element.pronouncedWords,
                                  i: i,
                                );
                              }
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

/*
* Send this function an amount of seconds and it will return it in format: *m *s
*/
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

class ChatBubble extends StatefulWidget {
  //Assigning values and making them required
  const ChatBubble({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.speakerLabel,
    required this.text,
    required this.i,
  }) : super(key: key);

  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String text;
  final int i;

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

/*
* Creating a widget for the normal chat bubble
* This means I can make however many of them I want
* Don't tell me... I know I'm smart
*/
class _ChatBubbleState extends State<ChatBubble> {
  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.startTime);
    String endTime = getMinSec(widget.endTime);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 5, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Making the container, which looks sexy af
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await player.setClip(
                start: Duration(milliseconds: getMil(widget.startTime)),
                end: Duration(milliseconds: getMil(widget.endTime)),
              );
              if (!nowPlaying) {
                setState(() {
                  nowPlaying = true;
                  currentlyPlaying = widget.i;
                });
                player.play();
              } else if (nowPlaying && currentlyPlaying == widget.i) {
                setState(() {
                  nowPlaying = false;
                });
                await player.pause();
              } else {
                setState(() {
                  nowPlaying = true;
                  currentlyPlaying = widget.i;
                });
                await player.pause();
                player.play();
              }
            },
            child: Container(
              padding: EdgeInsets.all(15),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.7, //The chat bubble will fill 70% of the screen's width
                minHeight: 50,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 5,
                  ),
                ],
              ),
              //The bubble will just have the text inside of it
              child: Text(
                '${widget.text}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 13,
                  shadows: <Shadow>[
                    Shadow(
                      color: Theme.of(context).colorScheme.secondaryVariant,
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
          //Magic spacing...
          SizedBox(
            height: 5,
          ),
          //For now we'll show the speakerlabel and timeframe the words have been spoken
          Text(
            '${widget.speakerLabel}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubbleUser extends StatefulWidget {
  //Assigning values and making them required
  const ChatBubbleUser({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.speakerLabel,
    required this.text,
    required this.i,
  }) : super(key: key);

  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String text;
  final int i;

  @override
  _ChatBubbleUserState createState() => _ChatBubbleUserState();
}

/*
* Creating a widget for the user's chat bubble
* This means I can make however many of them I want
* Don't tell me... I know I'm smart
*/
class _ChatBubbleUserState extends State<ChatBubbleUser> {
  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.startTime);
    String endTime = getMinSec(widget.endTime);

    return Container(
      padding: EdgeInsets.fromLTRB(0, 5, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment
            .end, //Aligning the bubble to the right of the screen instead
        children: [
          //Making the container, which looks sexy af
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () async {
              await player.setClip(
                start: Duration(milliseconds: getMil(widget.startTime)),
                end: Duration(milliseconds: getMil(widget.endTime)),
              );
              if (!nowPlaying) {
                setState(() {
                  nowPlaying = true;
                  currentlyPlaying = widget.i;
                });
                player.play();
              } else if (nowPlaying && currentlyPlaying == widget.i) {
                setState(() {
                  nowPlaying = false;
                });
                await player.pause();
              } else {
                setState(() {
                  nowPlaying = true;
                  currentlyPlaying = widget.i;
                });
                await player.pause();
                player.play();
              }
            },
            child: Container(
              padding: EdgeInsets.all(15),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.7, //The chat bubble will fill 70% of the screen's width
                minHeight: 50,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface, //This bubble is green
                borderRadius: BorderRadius.circular(25),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 5,
                  ),
                ],
              ),
              //The bubble will just have the text inside of it
              child: Text(
                '${widget.text}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 13,
                  shadows: <Shadow>[
                    Shadow(
                      color: Theme.of(context).colorScheme.secondaryVariant,
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ),
          ),
          //Magic spacing...
          SizedBox(
            height: 5,
          ),
          //For now we'll show the speakerlabel and timeframe the words have been spoken
          Text(
            '${widget.speakerLabel}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
