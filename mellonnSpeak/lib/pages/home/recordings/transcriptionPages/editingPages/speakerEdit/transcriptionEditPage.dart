import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/editingPages/speakerEdit/transcriptionEditProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';
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
bool autoSwitchSpeaker = true;

class TranscriptionEditPage extends StatefulWidget {
  final String id;
  final String recordingName;
  final String user;
  final Transcription transcription;
  final List<SpeakerWithWords> speakerWordsCombined;
  final int speakerCount;
  final String audioFileKey;
  final Function() transcriptionResetState;

  const TranscriptionEditPage({
    Key? key,
    required this.id,
    required this.recordingName,
    required this.user,
    required this.transcription,
    required this.speakerWordsCombined,
    required this.speakerCount,
    required this.audioFileKey,
    required this.transcriptionResetState,
  }) : super(key: key);

  @override
  _TranscriptionEditPageState createState() => _TranscriptionEditPageState();
}

class _TranscriptionEditPageState extends State<TranscriptionEditPage> {
  late final PageManager _pageManager;
  List<SpeakerSwitch> speakerSwitches = [];
  bool isSaving = false;

  //This runs first, when the widget is called
  @override
  void initState() {
    if (!transcriptLoaded) {
      print('Setting transcriptions');
      widgetTranscription = widget.transcription;
      /*for (var e in widgetTranscription.results.speakerLabels.segments) {
        print(
            'startTime: ${e.startTime}, endTime: ${e.endTime}, spk: ${e.speakerLabel}');
      }*/
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

    //Adding the version to the version history
    final json = transcriptionToJson(transcription);
    await uploadVersion(json, widget.id, 'Edited Speaker Labels');

    context
        .read<TranscriptionEditProvider>()
        .setSavedTranscription(transcription);

    if (hasUploaded) {
      final snackBar = SnackBar(
        content: const Text('Transcription saved!'),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      isSaving = false;
      Navigator.pop(context);
      widget.transcriptionResetState();
    } else {
      final snackBar = SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: const Text('Something went wrong :('),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      setState(() {
        isSaving = false;
      });
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

  Future<void> handleClick(String choice) async {
    if (choice == 'Help') {
      helpDialog(context, HelpPage.labelEditPage);
    } else if (choice == 'Give feedback') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendFeedbackPage(
            where: 'Speaker edit page',
            type: FeedbackType.feedback,
          ),
        ),
      );
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

    TextStyle? titleStyle = Theme.of(context).textTheme.headline1;
    String titleText = 'Listen to your\nRecording';
    double spacing = 25;
    int jumpSeconds =
        context.read<SettingsProvider>().currentSettings.jumpSeconds;

    if (MediaQuery.of(context).size.height < 800) {
      titleStyle = Theme.of(context).textTheme.headline2;
      titleText = 'Listen to your Recording';
      spacing = 15;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      //Creating the same appbar that is used everywhere else
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        title: StandardAppBarTitle(),
        elevation: 0,
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
              ),
              child: TitleBox(
                title: widget.recordingName,
                heroString: 'pageTitle',
                extras: true,
                color: Theme.of(context).colorScheme.surface,
                textColor: Theme.of(context).colorScheme.secondary,
                onBack: () {
                  if (widgetTranscription ==
                      context
                          .read<TranscriptionEditProvider>()
                          .savedTranscription) {
                    Navigator.pop(context);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text('Do you want to save before exiting?'),
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
                              await saveEdit(widgetTranscription);
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
                extra: Row(
                  children: [
                    isSaving
                        ? CircularProgressIndicator()
                        : IconButton(
                            onPressed: () async {
                              setState(() {
                                isSaving = true;
                              });
                              await saveEdit(widgetTranscription);
                            },
                            icon: Icon(
                              FontAwesomeIcons.solidSave,
                              color: context.read<ColorProvider>().darkText,
                            ),
                          ),
                    PopupMenuButton<String>(
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
                          'Help',
                          'Give feedback',
                        }.map((String choice) {
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
                  ],
                ),
              ),
            ),

            ///
            ///Creating the page where you can edit the speakerlabel assignment.
            ///
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///
                  ///Title
                  ///
                  Container(
                    margin: EdgeInsets.fromLTRB(25, spacing, 25, 0),
                    child: Text(
                      titleText,
                      style: titleStyle,
                    ),
                  ),

                  ///
                  ///Progress bar and media controls
                  ///
                  StandardBox(
                    padding: EdgeInsets.fromLTRB(25, spacing, 25, 5),
                    margin: EdgeInsets.fromLTRB(25, spacing, 25, spacing),
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
                              timeLabelTextStyle:
                                  Theme.of(context).textTheme.bodyText2,
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder<SpeakerChooserState>(
                              valueListenable: _pageManager.speakerNotifier,
                              builder: (_, value, __) {
                                return IconButton(
                                  onPressed: () {
                                    switchSpeaker(
                                        value.position,
                                        _pageManager
                                            .getSpeakerLabel(value.position));
                                    if (value.position <
                                        Duration(seconds: jumpSeconds)) {
                                      _pageManager.seek(Duration.zero);
                                    } else {
                                      _pageManager.seek(value.position -
                                          Duration(seconds: jumpSeconds));
                                    }
                                  },
                                  icon: Icon(FontAwesomeIcons.stepBackward),
                                  iconSize: 22.0,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                );
                              },
                            ),
                            ValueListenableBuilder(
                              valueListenable: _pageManager.buttonNotifier,
                              builder: (_, value, __) {
                                switch (value) {
                                  case ButtonState.loading:
                                    return Container(
                                      margin: const EdgeInsets.all(8.0),
                                      width: 32.0,
                                      height: 32.0,
                                      child: const CircularProgressIndicator(),
                                    );
                                  case ButtonState.paused:
                                    return IconButton(
                                      icon: const Icon(FontAwesomeIcons.play),
                                      iconSize: 22.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      onPressed: _pageManager.play,
                                    );
                                  case ButtonState.playing:
                                    return IconButton(
                                      icon: const Icon(FontAwesomeIcons.pause),
                                      iconSize: 22.0,
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
                            ValueListenableBuilder<SpeakerChooserState>(
                              valueListenable: _pageManager.speakerNotifier,
                              builder: (_, value, __) {
                                return IconButton(
                                  onPressed: () {
                                    switchSpeaker(
                                        value.position,
                                        _pageManager
                                            .getSpeakerLabel(value.position));
                                    _pageManager.seek(value.position +
                                        Duration(seconds: jumpSeconds));
                                  },
                                  icon: Icon(FontAwesomeIcons.stepForward),
                                  iconSize: 22.0,
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

                  ///
                  ///Speaker editing box
                  ///
                  StandardBox(
                    margin: EdgeInsets.fromLTRB(25, 0, 25, 0),
                    padding: EdgeInsets.fromLTRB(25, spacing, 25, spacing),
                    child: Column(
                      children: [
                        ///Box Title
                        Container(
                          alignment: Alignment.topLeft,
                          margin: EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Change the speaker here',
                            style: Theme.of(context).textTheme.headline5,
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
                        ///Overwrite speaker checkbox
                        ///
                        Container(
                          alignment: Alignment.topLeft,
                          child: Row(
                            children: [
                              Text(
                                'Auto switch speakers?',
                                style: Theme.of(context).textTheme.headline6,
                              ),
                              Checkbox(
                                value: autoSwitchSpeaker,
                                onChanged: (value) {
                                  setState(() {
                                    autoSwitchSpeaker = value ?? false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),

                        ///
                        ///Creating the playback speed changer
                        ///
                        Container(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Change the playback speed here',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          child: Row(
                            children: [
                              PlaybackSpeedWidget(
                                speed: 0.5,
                                notifyParent: refresh,
                                pageManager: _pageManager,
                              ),
                              PlaybackSpeedWidget(
                                speed: 0.75,
                                notifyParent: refresh,
                                pageManager: _pageManager,
                              ),
                              PlaybackSpeedWidget(
                                speed: 1,
                                notifyParent: refresh,
                                pageManager: _pageManager,
                              ),
                              PlaybackSpeedWidget(
                                speed: 1.25,
                                notifyParent: refresh,
                                pageManager: _pageManager,
                              ),
                              PlaybackSpeedWidget(
                                speed: 1.5,
                                notifyParent: refresh,
                                pageManager: _pageManager,
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
              child: StandardBox(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.all(2),
                constraints: BoxConstraints(
                  minWidth: 50,
                  minHeight: 50,
                ),
                color: Theme.of(context).colorScheme.primary,
                child: Center(
                  child: Text(
                    '${widget.speakerNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                      shadows: <Shadow>[
                        Shadow(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
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
              child: StandardBox(
                padding: EdgeInsets.all(15),
                margin: EdgeInsets.all(2),
                constraints: BoxConstraints(
                  minWidth: 50,
                  minHeight: 50,
                ),
                color: Theme.of(context).colorScheme.secondary,
                child: Center(
                  child: Text(
                    '${widget.speakerNumber}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.surface,
                      shadows: <Shadow>[
                        Shadow(
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
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
  final PageManager pageManager;

  const PlaybackSpeedWidget({
    required this.speed,
    required this.notifyParent,
    required this.pageManager,
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
            widget.pageManager.setPlaybackSpeed(widget.speed);
            widget.notifyParent();
          },
          child: StandardBox(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.all(2),
            constraints: BoxConstraints(
              minWidth: 50,
              minHeight: 50,
            ),
            color: Theme.of(context).colorScheme.primary,
            child: Center(
              child: FittedBox(
                child: Text(
                  '${widget.speed}x',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 10,
                    shadows: <Shadow>[
                      Shadow(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
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
            widget.pageManager.setPlaybackSpeed(widget.speed);
            widget.notifyParent();
          },
          child: StandardBox(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.all(2),
            constraints: BoxConstraints(
              minWidth: 50,
              minHeight: 50,
            ),
            color: Theme.of(context).colorScheme.secondary,
            child: Center(
              child: FittedBox(
                child: Text(
                  '${widget.speed}x',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.surface,
                    fontSize: 10,
                    shadows: <Shadow>[
                      Shadow(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ),
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
