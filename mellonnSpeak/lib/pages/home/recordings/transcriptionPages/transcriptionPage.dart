import 'dart:io';
import 'dart:ui';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
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
    context.read<TranscriptionPageProvider>().setLabels(widget.recording.labels!);

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
    return FutureBuilder(
      future: initialize(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
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
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Theme.of(context).backgroundColor,
                  leading: appBarLeading(context),
                  actions: [
                    menu(),
                    SizedBox(
                      width: 20,
                    ),
                  ],
                  pinned: true,
                  elevation: 0.5,
                  surfaceTintColor: Theme.of(context).shadowColor,
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Hero(
                      tag: widget.recording.id,
                      child: Text(
                        widget.recording.name,
                        style: Theme.of(context).textTheme.headline5,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(
                      height: 25,
                    ),
                    ...speakerWordsCombined.map(
                      (element) {
                        return ChatBubble(
                          transcription: transcription,
                          sww: element,
                          label: widget.recording.labels![int.parse(element.speakerLabel.split('_')[1])],
                          isInterviewer: widget.recording.interviewers!.contains(element.speakerLabel),
                        );
                      },
                    ),
                  ]),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget menu() {
    final buttons = {'Edit labels', 'Edit speakers', 'Export DOCX', 'Version history', 'Info', 'Delete this recording', 'Help', 'Give feedback'};
    if (Platform.isIOS) {
      return IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onPressed: () => showCupertinoActionSheet(
            context,
            widget.recording.name,
            buttons.map(
              (String choice) {
                return CupertinoActionSheetAction(
                  onPressed: () => handleClick(choice),
                  isDestructiveAction: choice == 'Delete this recording',
                  child: Text(
                    choice,
                    style: choice == 'Delete this recording'
                        ? TextStyle()
                        : TextStyle(
                            color: SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                  ),
                );
              },
            ).toList()),
        icon: Icon(
          CupertinoIcons.ellipsis_circle,
        ),
      );
    }
    return PopupMenuButton<String>(
      icon: Icon(
        FontAwesomeIcons.ellipsisVertical,
        color: Theme.of(context).colorScheme.secondary,
      ),
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(25.0),
        ),
      ),
      onSelected: handleClick,
      itemBuilder: (BuildContext context) {
        return buttons.map((String choice) {
          return PopupMenuItem<String>(
            value: choice,
            child: Text(
              choice,
              style: Theme.of(context).textTheme.headline6,
            ),
          );
        }).toList();
      },
    );
  }
}

///
///Chat bubble stuff
///
class ChatBubble extends StatefulWidget {
  final Transcription transcription;
  final SpeakerWithWords sww;
  final String label;
  final bool isInterviewer;

  const ChatBubble({
    Key? key,
    required this.transcription,
    required this.sww,
    required this.label,
    required this.isInterviewer,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  double boxScale = 1;

  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.sww.startTime);
    String endTime = getMinSec(widget.sww.endTime);

    Color bgColor = Theme.of(context).colorScheme.surface;
    CrossAxisAlignment align = CrossAxisAlignment.start;
    EdgeInsets padding = EdgeInsets.fromLTRB(20, 5, 0, 10);

    if (widget.isInterviewer) {
      bgColor = Theme.of(context).colorScheme.onSurface;
      align = CrossAxisAlignment.end;
      padding = EdgeInsets.fromLTRB(0, 5, 20, 10);
    }

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: align,
        children: [
          GestureDetector(
            onTapDown: (details) {
              setState(() {
                boxScale = 0.95;
              });
            },
            onTapUp: (details) {
              setState(() {
                boxScale = 1.0;
              });
            },
            onLongPress: () async {
              HapticFeedback.mediumImpact();
              int speaker = int.parse(widget.sww.speakerLabel.split('_')[1]);
              context.read<TranscriptionPageProvider>().setSpeaker(speaker);
              context.read<TranscriptionPageProvider>().setOriginalSpeaker(speaker);
              setState(() {
                boxScale = 1.0;
              });
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 100),
                  reverseTransitionDuration: Duration(milliseconds: 100),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    animation = Tween(begin: 0.0, end: 1.0).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: ChatBubbleFocused(
                        transcription: widget.transcription,
                        sww: widget.sww,
                      ),
                    );
                  },
                  fullscreenDialog: true,
                  opaque: false,
                ),
              );
            },
            child: AnimatedScale(
              scale: boxScale,
              duration: Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              child: Container(
                padding: EdgeInsets.all(15),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.sww.pronouncedWords}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            '${widget.label}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

///
///Focused chat bubble stuff
///
class ChatBubbleFocused extends StatefulWidget {
  final Transcription transcription;
  final SpeakerWithWords sww;

  const ChatBubbleFocused({
    required this.transcription,
    required this.sww,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatBubbleFocused> createState() => _ChatBubbleFocusedState();
}

class _ChatBubbleFocusedState extends State<ChatBubbleFocused> with SingleTickerProviderStateMixin {
  TextEditingController textFieldController =
      TextEditingController(text: 'This is an error, if you see this text please close the dialog and open it again.');
  late TextSelection selectedText;
  List<Word> initialWords = [];
  String textValue = '';
  String initialText = '';

  late AnimationController animController;
  late Animation<double> animation;

  @override
  void initState() {
    initialWords = getWords(widget.transcription, widget.sww.startTime, widget.sww.endTime);
    initialText = getInitialValue(initialWords);
    textValue = initialText;
    textFieldController = TextEditingController(text: initialText);
    textFieldController.addListener(() {
      selectedText = textFieldController.selection;
      context.read<TranscriptionPageProvider>().setTextSelected(selectedText.end - selectedText.start != 0, selectedText);
    });

    super.initState();
    animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    animation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: animController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {});
      });
    animController.forward();
  }

  void closePanel() {
    animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        Navigator.pop(context);
      }
    });
    animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    context.read<TranscriptionPageProvider>().setInitialWords(initialWords);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => closePanel(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black38.withOpacity(0.7 * (1 - animation.value)),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.1,
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * animation.value),
                child: Container(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(15),
                        margin: EdgeInsets.all(15),
                        width: MediaQuery.of(context).size.width - 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              blurRadius: shadowRadius,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: textFieldController,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 10,
                          onChanged: (value) {
                            setState(() {
                              textValue = value;
                            });
                            context.read<TranscriptionPageProvider>().setIsTextSaved(value == initialText);
                            context.read<TranscriptionPageProvider>().setTextValue(textValue);
                          },
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      context.watch<TranscriptionPageProvider>().textSelected
                          ? SpeakerSelector(
                              labels: context.read<TranscriptionPageProvider>().labels,
                            )
                          : Container(),
                      CupertinoActionSheet(
                        actions: [
                          !context.watch<TranscriptionPageProvider>().isSaved
                              ? CupertinoActionSheetAction(
                                  onPressed: () {},
                                  child: Text(
                                    'Save',
                                    style: TextStyle(
                                      color: SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                                    ),
                                  ),
                                )
                              : Container(),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => closePanel(),
                          isDestructiveAction: true,
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeakerSelector extends StatelessWidget {
  final List<String> labels;

  const SpeakerSelector({
    required this.labels,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: 200,
      ),
      width: MediaQuery.of(context).size.width - 30,
      child: SingleChildScrollView(
        child: Column(
          children: [
            ...labels.map((label) {
              return speaker(context, label, labels.indexOf(label));
            }),
          ],
        ),
      ),
    );
  }

  Widget speaker(BuildContext context, String label, int index) {
    int currentSpeaker = context.watch<TranscriptionPageProvider>().currentSpeaker;
    return InkWell(
      onTap: () => context.read<TranscriptionPageProvider>().setSpeaker(index),
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        height: 50,
        decoration: BoxDecoration(
          color: index == currentSpeaker ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.headline6,
          ),
        ),
      ),
    );
  }
}
