import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/src/provider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/providers/transcriptionEditProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';

int currentSpeaker = 0;
double playbackSpeed = 1.0;
bool transcriptLoaded = false;
final player = AudioPlayer();
Transcription widgetTranscription = Transcription(
  jobName: '',
  accountId: '',
  results: Results(
    transcripts: <Transcript>[],
    speakerLabels: SpeakerLabels(
      speakers: 0,
      segments: <Segment>[],
    ),
    items: <Item>[],
  ),
  status: '',
);
Duration lastPosition = Duration.zero;
int lastSpeaker = 0;

class TranscriptionEditPage extends StatefulWidget {
  final String id;
  final String recordingName;
  final String user;
  final Transcription transcription;
  final List<SpeakerWithWords> speakerWordsCombined;
  final int speakerCount;
  final String audioFileKey;

  const TranscriptionEditPage({
    Key? key,
    required this.id,
    required this.recordingName,
    required this.user,
    required this.transcription,
    required this.speakerWordsCombined,
    required this.speakerCount,
    required this.audioFileKey,
  }) : super(key: key);

  @override
  _TranscriptionEditPageState createState() => _TranscriptionEditPageState();
}

class _TranscriptionEditPageState extends State<TranscriptionEditPage> {
  late final PageManager _pageManager;
  List<SpeakerSwitch> speakerSwitches = [];

  //This runs first, when the widget is called
  @override
  void initState() {
    if (!transcriptLoaded) {
      print('Setting transcriptions');
      widgetTranscription = widget.transcription;
      for (var e in widgetTranscription.results.speakerLabels.segments) {
        print(
            'startTime: ${e.startTime}, endTime: ${e.endTime}, spk: ${e.speakerLabel}');
      }
      context
          .read<TranscriptionEditProvider>()
          .setTranscriptionNoNo(widget.transcription);
      context
          .read<TranscriptionEditProvider>()
          .setSavedTranscriptionNoNo(widget.transcription);
      transcriptLoaded = true;
    }

    speakerSwitches = context
        .read<TranscriptionEditProvider>()
        .getSpeakerSwitches(widgetTranscription);

    _pageManager = PageManager(
      audioFilePath: widget.audioFileKey,
      speakerSwitches: speakerSwitches,
      switchSpeaker: switchSpeaker,
    );
    super.initState();
  }

  @override
  void dispose() {
    _pageManager.dispose();
    transcriptLoaded = false;
    lastPosition = Duration.zero;
    lastSpeaker = 0;
    super.dispose();
  }

  ///
  ///This is for the child widgets to call, when setState is needed.
  ///
  void refresh() {
    setState(() {});
  }

  ///
  ///This function takes a transcription element and calls the backend to save it to the cloud
  ///It should return true or false, if it succeeds or not, but i havent implemented that yet.
  ///It creates a snackbar saying wheter it succeeded or not.
  ///
  Future<void> saveEdit(Transcription transcription) async {
    bool hasUploaded = await context
        .read<StorageProvider>()
        .saveTranscription(transcription, widget.id);

    for (var e in transcription.results.speakerLabels.segments) {
      print(
          'startTime: ${e.startTime}, endTime: ${e.endTime}, spk: ${e.speakerLabel}');
    }

    context
        .read<TranscriptionEditProvider>()
        .setSavedTranscription(transcription);

    if (hasUploaded) {
      final snackBar = SnackBar(
        content: const Text('Transcription saved!'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      final snackBar = SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: const Text('Something went wrong :('),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  ///
  ///This function is called when the user switches the speaker.
  ///It then saves the last speaker and applies it to the transcript.
  ///
  void switchSpeaker(Duration position, int speaker) {
    double startTime = lastPosition.inMilliseconds / 1000;
    double endTime = position.inMilliseconds / 1000;
    Transcription oldTranscription = widgetTranscription;

    if (endTime != 0.0) {
      if (startTime == 0.0) {
        endTime = double.parse((endTime - 0.01).toStringAsFixed(2));
        startTime = double.parse((startTime + 0.01).toStringAsFixed(2));
      } else {
        endTime = double.parse((endTime - 0.01).toStringAsFixed(2));
        startTime = double.parse(startTime.toStringAsFixed(2));
      }
    }

    if (startTime < endTime) {
      print(
          'Switching speaker with start: $startTime, end: $endTime, speaker: $speaker');
      Transcription newTranscription = context
          .read<TranscriptionEditProvider>()
          .getNewSpeakerLabels(
              oldTranscription, startTime, endTime, lastSpeaker);

      widgetTranscription = newTranscription;
      context
          .read<TranscriptionEditProvider>()
          .setTranscription(newTranscription);

      speakerSwitches = context
          .read<TranscriptionEditProvider>()
          .getSpeakerSwitches(widgetTranscription);

      lastPosition = position;
      lastSpeaker = speaker;
    }
  }

  @override
  Widget build(BuildContext context) {
    ///
    ///This checks whether there will be one or two rows of speakerChoosers
    ///And sets the appropriate size for it.
    ///
    double speakerChooserSize = 0.5;
    if (widget.speakerCount <= 3) {
      speakerChooserSize = 0.33;
    } else {
      speakerChooserSize = 0.4;
    }
    widgetTranscription =
        context.watch<TranscriptionEditProvider>().unsavedTranscription;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
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
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(25),
                width: MediaQuery.of(context).size.width,
                constraints: BoxConstraints(
                  minHeight: 100,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).colorScheme.surface,
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
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: 40,
                                  minWidth:
                                      MediaQuery.of(context).size.width * 0.4,
                                ),
                                child: FittedBox(
                                  child: Row(
                                    children: [
                                      //Back button
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          if (context
                                                  .read<
                                                      TranscriptionEditProvider>()
                                                  .unsavedTranscription ==
                                              context
                                                  .read<
                                                      TranscriptionEditProvider>()
                                                  .savedTranscription) {
                                            Navigator.pop(context);
                                          } else {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) =>
                                                  AlertDialog(
                                                title: Text(
                                                    'Do you want to save before exiting?'),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('No'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () async {
                                                      await saveEdit(
                                                          widgetTranscription);
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    },
                                                    child: const Text('Yes'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }
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
                              IconButton(
                                onPressed: () async {
                                  await saveEdit(widgetTranscription);
                                },
                                icon: Icon(
                                  FontAwesomeIcons.solidSave,
                                  color: context.read<ColorProvider>().darkText,
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ///
            ///Creating the page where you can edit the speakerlabel assignment.
            ///
            Expanded(
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///
                    ///Title
                    ///
                    Container(
                      margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                      width: MediaQuery.of(context).size.width * 0.6,
                      constraints: BoxConstraints(maxHeight: 100),
                      child: FittedBox(
                        child: Text(
                          'Listen to your\nRecording',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: context.watch<ColorProvider>().darkText,
                            shadows: <Shadow>[
                              Shadow(
                                color: context.watch<ColorProvider>().shadow,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Spacer(),

                    ///
                    ///Progress bar and media controls
                    ///
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.175,
                      margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                      padding: EdgeInsets.all(25),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color:
                                Theme.of(context).colorScheme.secondaryVariant,
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ValueListenableBuilder<ProgressBarState>(
                            valueListenable: _pageManager.progressNotifier,
                            builder: (_, value, __) {
                              return ProgressBar(
                                progress: value.current,
                                buffered: value.buffered,
                                total: value.total,
                                onSeek: _pageManager.seek,
                              );
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ValueListenableBuilder(
                                valueListenable: _pageManager.buttonNotifier,
                                builder: (_, value, __) {
                                  switch (value) {
                                    case ButtonState.loading:
                                      return Container(
                                        margin: const EdgeInsets.all(8.0),
                                        width: 32.0,
                                        height: 32.0,
                                        child:
                                            const CircularProgressIndicator(),
                                      );
                                    case ButtonState.paused:
                                      return IconButton(
                                        icon: const Icon(Icons.play_arrow),
                                        iconSize: 32.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        onPressed: _pageManager.play,
                                      );
                                    case ButtonState.playing:
                                      return IconButton(
                                        icon: const Icon(Icons.pause),
                                        iconSize: 32.0,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        onPressed: _pageManager.pause,
                                      );
                                  }
                                  return IconButton(
                                    onPressed: () {},
                                    icon: Icon(Icons.error),
                                    iconSize: 32,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SingleChildScrollView(
                      child: Column(
                        children: [
                          ///
                          ///Speakerselecter
                          ///
                          Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height *
                                speakerChooserSize,
                            margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryVariant,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                ///Box Title
                                Container(
                                  margin: EdgeInsets.fromLTRB(25, 25, 25, 10),
                                  width: double.infinity,
                                  child: FittedBox(
                                    child: Text(
                                      'Change the speaker here',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryVariant,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                ///
                                ///Creating all the speakerLabel options
                                ///
                                ValueListenableBuilder<SpeakerChooserState>(
                                  valueListenable: _pageManager.speakerNotifier,
                                  builder: (_, value, __) {
                                    return SpeakerBuilder(
                                      speakerCount: widget.speakerCount,
                                      current: value.currentSpeaker,
                                      pageManager: _pageManager,
                                      notifyParent: refresh,
                                      switchSpeaker: switchSpeaker,
                                    );
                                  },
                                ),

                                ///
                                ///Creating the playback speed changer
                                ///
                                Spacer(),
                                Container(
                                  margin: EdgeInsets.fromLTRB(25, 0, 25, 0),
                                  width: double.infinity,
                                  child: FittedBox(
                                    child: Text(
                                      'Change the playback speed here',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryVariant,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.fromLTRB(25, 10, 25, 25),
                                  child: Row(
                                    children: [
                                      PlaybackSpeedWidget(
                                        speed: 0.5,
                                        notifyParent: refresh,
                                      ),
                                      PlaybackSpeedWidget(
                                        speed: 0.75,
                                        notifyParent: refresh,
                                      ),
                                      PlaybackSpeedWidget(
                                        speed: 1,
                                        notifyParent: refresh,
                                      ),
                                      PlaybackSpeedWidget(
                                        speed: 1.25,
                                        notifyParent: refresh,
                                      ),
                                      PlaybackSpeedWidget(
                                        speed: 1.5,
                                        notifyParent: refresh,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}

///
///These classes creates the box in where the buttons for choosing the current speaker is.
///
class SpeakerBuilder extends StatefulWidget {
  final int speakerCount;
  final int current;
  final PageManager pageManager;
  final Function() notifyParent;
  final Function(Duration position, int speaker) switchSpeaker;

  const SpeakerBuilder({
    required this.speakerCount,
    required this.current,
    required this.pageManager,
    required this.notifyParent,
    required this.switchSpeaker,
    Key? key,
  }) : super(key: key);

  @override
  _SpeakerBuilderState createState() => _SpeakerBuilderState();
}

class _SpeakerBuilderState extends State<SpeakerBuilder> {
  List<LabelElement> speakerLabels1 = [];
  List<LabelElement> speakerLabels2 = [];

  void createSpeakerLabels() {
    ///Getting the variables ready, list1 is for the first row and list2 second.
    speakerLabels1 = [];
    speakerLabels2 = [];
    int speaker = widget.speakerCount;

    ///
    ///This is creating the lists needed, so they can be plottet into the widget.
    ///
    if (speaker <= 3) {
      for (var i = widget.speakerCount; i >= 1; i--) {
        LabelElement labelElement = LabelElement(
          speakerLabel: 'spk_${i - 1}',
          speakerNumber: i - 1,
          current: widget.current,
        );
        speakerLabels1.add(labelElement);
      }
    } else if (speaker == 4 || speaker == 6 || speaker == 8 || speaker == 10) {
      for (var i = speaker ~/ 2; i >= 1; i--) {
        LabelElement labelElement = LabelElement(
          speakerLabel: 'spk_${i - 1}',
          speakerNumber: i - 1,
          current: widget.current,
        );
        speakerLabels1.add(labelElement);
      }
      for (var i = speaker ~/ 2; i >= 1; i--) {
        LabelElement labelElement = LabelElement(
          speakerLabel: 'spk_${i + speaker ~/ 2}',
          speakerNumber: i + speaker ~/ 2 - 1,
          current: widget.current,
        );
        speakerLabels2.add(labelElement);
      }
    } else if (speaker == 5 || speaker == 7 || speaker == 9) {
      for (var i = speaker ~/ 2; i >= 0; i--) {
        LabelElement labelElement = LabelElement(
          speakerLabel: 'spk_$i',
          speakerNumber: i,
          current: widget.current,
        );
        speakerLabels1.add(labelElement);
      }
      for (var i = speaker ~/ 2 - 1; i >= 1; i--) {
        LabelElement labelElement = LabelElement(
          speakerLabel: 'spk_${i + speaker ~/ 2}',
          speakerNumber: i + speaker ~/ 2,
          current: widget.current,
        );
        speakerLabels2.add(labelElement);
      }
    }
  }

  ///
  ///This is for the child widgets to call, when setState is needed.
  ///
  void refresh() {
    setState(() {});
    widget.notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    ///Calls the function to create the lists.
    createSpeakerLabels();

    ///
    ///It checks whether there will be one or two rows and creates the right amount.
    ///It plots the lists into the appropriate rows.
    ///
    if (widget.speakerCount <= 3) {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(25, 0, 25, 0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...speakerLabels1.reversed.map(
              (element) => SpeakerChooser(
                speakerLabel: element.speakerLabel,
                speakerNumber: element.speakerNumber,
                current: widget.current,
                pageManager: widget.pageManager,
                notifyParent: refresh,
                switchSpeaker: widget.switchSpeaker,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        margin: EdgeInsets.fromLTRB(25, 0, 25, 0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...speakerLabels1.reversed.map(
                  (element) => SpeakerChooser(
                    speakerLabel: element.speakerLabel,
                    speakerNumber: element.speakerNumber,
                    current: widget.current,
                    pageManager: widget.pageManager,
                    notifyParent: refresh,
                    switchSpeaker: widget.switchSpeaker,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...speakerLabels2.reversed.map(
                  (element) => SpeakerChooser(
                    speakerLabel: element.speakerLabel,
                    speakerNumber: element.speakerNumber,
                    current: widget.current,
                    pageManager: widget.pageManager,
                    notifyParent: refresh,
                    switchSpeaker: widget.switchSpeaker,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}

///
///These classes creates the widget for the bubbles in which you can choose a speaker.
///
class SpeakerChooser extends StatefulWidget {
  final String speakerLabel;
  final int speakerNumber;
  final int current;
  final PageManager pageManager;
  final Function() notifyParent;
  final Function(Duration position, int speaker) switchSpeaker;

  const SpeakerChooser({
    required this.speakerLabel,
    required this.speakerNumber,
    required this.current,
    required this.pageManager,
    required this.notifyParent,
    required this.switchSpeaker,
    Key? key,
  }) : super(key: key);

  @override
  _SpeakerChooserState createState() => _SpeakerChooserState();
}

class _SpeakerChooserState extends State<SpeakerChooser> {
  @override
  Widget build(BuildContext context) {
    ///
    ///It checks whether the bubble is the one for the current speaker.
    ///Then it gives the right color, orange if it's the one and grey for everything else.
    ///
    if (widget.speakerNumber == widget.current) {
      return Expanded(
        child: ValueListenableBuilder<SpeakerChooserState>(
          valueListenable: widget.pageManager.speakerNotifier,
          builder: (_, value, __) {
            return InkWell(
              onTap: () {
                widget.pageManager.setSpeakerChooser(
                  widget.speakerNumber,
                  value.position,
                );
                widget.switchSpeaker(value.position, widget.speakerNumber);
                widget.notifyParent();
              },
              child: Container(
                child: Center(
                  child: Text(
                    '${widget.speakerNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                      shadows: <Shadow>[
                        Shadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.all(2),
                constraints: BoxConstraints(
                  minWidth: 50,
                  minHeight: 55,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).colorScheme.secondaryVariant,
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Expanded(
        child: ValueListenableBuilder<SpeakerChooserState>(
          valueListenable: widget.pageManager.speakerNotifier,
          builder: (_, value, __) {
            return InkWell(
              onTap: () {
                widget.pageManager.setSpeakerChooser(
                  widget.speakerNumber,
                  value.position,
                );
                widget.switchSpeaker(value.position, widget.speakerNumber);
                widget.notifyParent();
              },
              child: Container(
                child: Center(
                  child: Text(
                    '${widget.speakerNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                      shadows: <Shadow>[
                        Shadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.all(2),
                constraints: BoxConstraints(
                  minWidth: 50,
                  minHeight: 55,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).colorScheme.secondaryVariant,
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }
  }
}

///
///These classes create the bubbles for the playback speed chooser.
///
class PlaybackSpeedWidget extends StatefulWidget {
  final double speed;
  final Function notifyParent;

  const PlaybackSpeedWidget({
    required this.speed,
    required this.notifyParent,
    Key? key,
  }) : super(key: key);

  @override
  _PlaybackSpeedWidgetState createState() => _PlaybackSpeedWidgetState();
}

class _PlaybackSpeedWidgetState extends State<PlaybackSpeedWidget> {
  @override
  Widget build(BuildContext context) {
    ///
    ///It checks (like with the speakerChooser), wether it's the current chosen speed.
    ///
    if (widget.speed == playbackSpeed) {
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              playbackSpeed = widget.speed;
            });
            widget.notifyParent();
          },
          child: Container(
            child: Center(
              child: Text(
                '${widget.speed}x',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondary,
                  fontSize: 10,
                  shadows: <Shadow>[
                    Shadow(
                      color: Theme.of(context).colorScheme.secondaryVariant,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.all(2),
            constraints: BoxConstraints(
              minWidth: 50,
              minHeight: 50,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(25),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              playbackSpeed = widget.speed;
            });
            widget.notifyParent();
          },
          child: Container(
            child: Center(
              child: Text(
                '${widget.speed}x',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.surface,
                  fontSize: 10,
                  shadows: <Shadow>[
                    Shadow(
                      color: Theme.of(context).colorScheme.secondaryVariant,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
            ),
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.all(2),
            constraints: BoxConstraints(
              minWidth: 50,
              minHeight: 50,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(25),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

///
///Creates the element for the labels, nothing more to say here.
///
class LabelElement {
  LabelElement({
    required this.speakerLabel,
    required this.speakerNumber,
    required this.current,
  });

  String speakerLabel;
  int speakerNumber;
  int current;
}
