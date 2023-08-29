import 'dart:io';
import 'dart:ui';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/main/mainPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/speakerLabels/speakerLabelsPage.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/versionHistory/versionHistoryPage.dart';
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

bool isLoading = true; //Creating the necessary variables
String json = '';
String audioPath = '';
late AudioManager audioManager;

class TranscriptionPage extends StatefulWidget {
  //Creating the necessary variables
  final Recording recording;

  //Making them required
  const TranscriptionPage({
    required this.recording,
    Key? key,
  }) : super(key: key);

  @override
  _TranscriptionPageState createState() => _TranscriptionPageState();
}

class _TranscriptionPageState extends State<TranscriptionPage> {
  //Temp variable
  DateFormat formatter = DateFormat('dd-MM-yyyy');

  @override
  void dispose() {
    json = '';
    isLoading = true;
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
      context.read<TranscriptionPageProvider>().recording = widget.recording;

      //If the recording doesn't have any labels, we'll send the user to the labels page
      if (context.read<TranscriptionPageProvider>().labelsEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SpeakerLabelsPage(),
          ),
        );
      }
      try {
        json = await context.read<StorageProvider>().downloadTranscript(context.read<TranscriptionPageProvider>().recording.id);

        audioPath = await context.read<StorageProvider>().getAudioUrl(context.read<TranscriptionPageProvider>().recording.fileKey!);
        audioManager = AudioManager(
          audioFilePath: audioPath,
        );

        context.read<TranscriptionPageProvider>().transcription = context.read<TranscriptionProcessing>().getTranscriptionFromString(json);
        context.read<TranscriptionPageProvider>().loadTranscription();

        await checkOriginalVersion(context.read<TranscriptionPageProvider>().recording.id, context.read<TranscriptionPageProvider>().transcription);

        isLoading = false;
      } catch (e) {
        context.read<AnalyticsProvider>().recordEventError('initialize-transcription', e.toString());
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
    context.read<TranscriptionPageProvider>().recording = newRecording;
  }

  ///
  ///This function handles when an item in the popup menu is clicked
  ///
  Future<void> handleClick(String choice) async {
    if (Platform.isIOS) Navigator.pop(context);
    if (choice == 'Edit labels') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SpeakerLabelsPage(),
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          content: Text(
            'Title: ${context.watch<TranscriptionPageProvider>().recording.name} \nDescription: ${context.watch<TranscriptionPageProvider>().recording.description} \nDate: ${formatter.format(context.watch<TranscriptionPageProvider>().recording.date?.getDateTimeInUtc() ?? DateTime.now())} \nFile: ${context.watch<TranscriptionPageProvider>().recording.fileName} \nParticipants: ${context.watch<TranscriptionPageProvider>().recording.speakerCount}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Exporting DOCX...'),
        content: Container(
          height: 70,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    String docxCreated = await TranscriptionToDocx().createDocxInCloud(
      context.read<TranscriptionPageProvider>().recording,
      context.read<TranscriptionPageProvider>().speakerWordsCombined,
    );
    Navigator.pop(context);

    if (docxCreated == 'true' && !Platform.isIOS) {
      print('Docx created!');
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Docx creation succeeded!',
          text: 'You can now find the generated docx file in the downloads folder of your phone.',
        ),
      );
    } else if (docxCreated == 'true' && Platform.isIOS) {
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Docx creation succeeded!',
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

  void showVersionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VersionHistoryPage(
          recording: context.read<TranscriptionPageProvider>().recording,
          transcriptionResetState: transcriptionResetState,
        ),
      ),
    );
  }

  Future<void> deleteRecording() async {
    final fileKey = context.read<TranscriptionPageProvider>().recording.fileKey!;
    final id = context.read<TranscriptionPageProvider>().recording.id;
    try {
      (await Amplify.DataStore.query(Recording.classType, where: Recording.ID.eq(context.read<TranscriptionPageProvider>().recording.id)))
          .forEach((element) async {
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
          context.read<AnalyticsProvider>().recordEventError('deleteRecording-DataStore', e.message);
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
      context.read<AnalyticsProvider>().recordEventError('deleteRecording-other', e.toString());
      print('ERROR: $e');
    }
  }

  ///
  ///Building the transcriptionPage widget
  ///
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialize(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (isLoading || context.watch<TranscriptionPageProvider>().labelsEmpty) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
              ),
            ),
          );
        } else {
          return Scaffold(
            body: Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      backgroundColor: Theme.of(context).colorScheme.background,
                      leading: appBarLeading(context, () {
                        if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MainPage(),
                            ),
                          );
                        }
                      }),
                      actions: [
                        menu(),
                        SizedBox(
                          width: 20,
                        ),
                      ],
                      pinned: true,
                      elevation: 0.5,
                      surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                      expandedHeight: 100,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Hero(
                          tag: context.watch<TranscriptionPageProvider>().recording.id,
                          child: Text(
                            context.watch<TranscriptionPageProvider>().recording.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildListDelegate([
                        SizedBox(
                          height: 25,
                        ),
                        ...context.watch<TranscriptionPageProvider>().speakerWordsCombined.map(
                          (element) {
                            return ChatBubble(
                              transcription: context.read<TranscriptionPageProvider>().transcription,
                              sww: element,
                              label: context.watch<TranscriptionPageProvider>().recording.labels![int.parse(element.speakerLabel.split('_')[1])],
                              isInterviewer: context.watch<TranscriptionPageProvider>().recording.interviewers!.contains(element.speakerLabel),
                              canFocus: true,
                            );
                          },
                        ),
                        SizedBox(
                          height: 105,
                        ),
                      ]),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 0,
                  child: Container(
                    height: 105,
                    padding: EdgeInsets.fromLTRB(25, 10, 25, 0),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.background,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(context).shadowColor,
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: mediaController(),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget menu() {
    final buttons = {'Edit labels', 'Export DOCX', 'Version history', 'Info', 'Delete this recording', 'Help', 'Give feedback'};
    if (Platform.isIOS) {
      return IconButton(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onPressed: () => showCupertinoActionSheet(
            context,
            context.read<TranscriptionPageProvider>().recording.name,
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
                            color: WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                          ),
                  ),
                );
              },
            ).toList()),
        icon: Icon(
          CupertinoIcons.ellipsis_circle,
          color: Theme.of(context).colorScheme.primary,
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
        }).toList();
      },
    );
  }

  Widget mediaController() {
    const double sizeMultiplier = 1.1;

    return Column(
      children: [
        ValueListenableBuilder<ProgressBarState>(
          valueListenable: audioManager.progressNotifier,
          builder: (_, value, __) {
            return ProgressBar(
              progress: value.current,
              buffered: value.buffered,
              total: value.total,
              onSeek: audioManager.seek,
              timeLabelTextStyle: Theme.of(context).textTheme.bodyMedium,
              thumbGlowRadius: 30,
            );
          },
        ),
        Transform.translate(
          offset: Offset(0, -15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder<ProgressBarState>(
                valueListenable: audioManager.progressNotifier,
                builder: (_, value, __) {
                  return IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () {
                      if (value.current < Duration(seconds: context.read<SettingsProvider>().jumpSeconds)) {
                        audioManager.seek(Duration.zero);
                      } else {
                        audioManager.seek(value.current - Duration(seconds: context.read<SettingsProvider>().jumpSeconds));
                      }
                    },
                    icon: Icon(FontAwesomeIcons.backwardStep),
                    iconSize: 22.0 * sizeMultiplier,
                    color: Theme.of(context).colorScheme.secondary,
                  );
                },
              ),
              ValueListenableBuilder(
                valueListenable: audioManager.buttonNotifier,
                builder: (_, value, __) {
                  switch (value) {
                    case ButtonState.loading:
                      return Container(
                        margin: const EdgeInsets.all(8.0),
                        width: 32.0 * sizeMultiplier,
                        height: 32.0 * sizeMultiplier,
                        child: const CircularProgressIndicator(),
                      );
                    case ButtonState.paused:
                      return IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: const Icon(FontAwesomeIcons.play),
                        iconSize: 22.0 * sizeMultiplier,
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: audioManager.play,
                      );
                    case ButtonState.playing:
                      return IconButton(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: const Icon(FontAwesomeIcons.pause),
                        iconSize: 22.0 * sizeMultiplier,
                        color: Theme.of(context).colorScheme.secondary,
                        onPressed: audioManager.pause,
                      );
                  }
                },
              ),
              ValueListenableBuilder<ProgressBarState>(
                valueListenable: audioManager.progressNotifier,
                builder: (_, value, __) {
                  return IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onPressed: () {
                      audioManager.seek(value.current + Duration(seconds: context.read<SettingsProvider>().jumpSeconds));
                    },
                    icon: Icon(FontAwesomeIcons.forwardStep),
                    iconSize: 22.0 * sizeMultiplier,
                    color: Theme.of(context).colorScheme.secondary,
                  );
                },
              ),
            ],
          ),
        ),
      ],
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
  final bool canFocus;

  const ChatBubble({
    Key? key,
    required this.transcription,
    required this.sww,
    required this.label,
    required this.isInterviewer,
    required this.canFocus,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  double boxScale = 1;
  double playerScale = 1;

  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.sww.startTime);
    String endTime = getMinSec(widget.sww.endTime);

    Color bgColor = Theme.of(context).colorScheme.surface;
    Color textColor = Theme.of(context).colorScheme.secondary;
    CrossAxisAlignment align = CrossAxisAlignment.start;
    EdgeInsets padding = EdgeInsets.fromLTRB(20, 5, 0, 10);

    if (widget.isInterviewer) {
      bgColor = Theme.of(context).colorScheme.onPrimary;
      textColor = Theme.of(context).colorScheme.onSecondary;
      align = CrossAxisAlignment.end;
      padding = EdgeInsets.fromLTRB(0, 5, 20, 10);
    }

    return ValueListenableBuilder<ProgressBarState>(
      valueListenable: audioManager.progressNotifier,
      builder: (context, value, _) {
        double currentSeconds = value.current.inMilliseconds / 1000;
        if (widget.sww.startTime <= currentSeconds && currentSeconds <= widget.sww.endTime) {
          playerScale = 1.07;
        } else {
          playerScale = 1.0;
        }
        return Container(
          padding: padding,
          child: Column(
            crossAxisAlignment: align,
            children: [
              GestureDetector(
                onTapDown: (details) {
                  if (widget.canFocus) {
                    setState(() {
                      boxScale = 0.95;
                    });
                  }
                },
                onTapUp: (details) {
                  if (widget.canFocus) {
                    setState(() {
                      boxScale = 1.0;
                    });
                  }
                },
                onLongPress: () async {
                  if (widget.canFocus) {
                    HapticFeedback.mediumImpact();
                    int speaker = int.parse(widget.sww.speakerLabel.split('_')[1]);
                    context.read<TranscriptionPageProvider>().resetState();
                    context.read<TranscriptionPageProvider>().originalSpeaker = speaker;
                    context.read<TranscriptionPageProvider>().speaker = speaker;
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
                  }
                },
                child: AnimatedScale(
                  scale: playerScale,
                  duration: Duration(milliseconds: 500),
                  curve: Curves.elasticOut,
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
                            color: Theme.of(context).shadowColor,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        '${widget.sww.pronouncedWords}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          fontSize: 11.5,
                        ),
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
      },
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
    context.read<TranscriptionPageProvider>().resetState();
    animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        Navigator.pop(context);
      }
    });
    animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    context.read<TranscriptionPageProvider>().initialWords = initialWords;

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
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * animation.value),
                child: Container(
                  height: MediaQuery.of(context).size.height + 200,
                  width: MediaQuery.of(context).size.width - 30,
                  child: ListView(
                    children: [
                      GestureDetector(
                        onTap: () => closePanel(),
                        child: Container(
                          color: Colors.transparent,
                          height: MediaQuery.of(context).size.height * 0.1,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(15),
                        margin: EdgeInsets.fromLTRB(15, 15, 15, 0),
                        width: MediaQuery.of(context).size.width - 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Theme.of(context).shadowColor,
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
                            context.read<TranscriptionPageProvider>().isTextSaved = value == initialText;
                            context.read<TranscriptionPageProvider>().textValue = textValue;
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
                              labels: context.read<TranscriptionPageProvider>().recording.labels!,
                            )
                          : Container(),
                      CupertinoActionSheet(
                        actions: [
                          !context.watch<TranscriptionPageProvider>().isSaved
                              ? CupertinoActionSheetAction(
                                  onPressed: () {
                                    context.read<TranscriptionPageProvider>().saveEdit(widget.sww);
                                    closePanel();
                                  },
                                  child: Text(
                                    'Save',
                                    style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 17),
                                  ),
                                )
                              : Container(),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => closePanel(),
                          isDestructiveAction: true,
                          child: Text(
                            'Cancel',
                            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 17),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => closePanel(),
                        child: Container(
                          color: Colors.transparent,
                          height: 200,
                          width: MediaQuery.of(context).size.width,
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
      margin: EdgeInsets.fromLTRB(15, 15, 15, 0),
      constraints: BoxConstraints(
        maxHeight: 200,
      ),
      width: MediaQuery.of(context).size.width - 15,
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
      onTap: () => context.read<TranscriptionPageProvider>().speaker = index,
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        height: 55,
        decoration: BoxDecoration(
          color: index == currentSpeaker ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(fontSize: 17),
          ),
        ),
      ),
    );
  }
}
