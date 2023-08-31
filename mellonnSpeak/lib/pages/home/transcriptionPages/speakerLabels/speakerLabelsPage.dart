import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/speakerLabels/speakerLabelsProvider.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class SpeakerLabelsPage extends StatefulWidget {
  const SpeakerLabelsPage({Key? key}) : super(key: key);

  @override
  State<SpeakerLabelsPage> createState() => _SpeakerLabelsPageState();
}

class _SpeakerLabelsPageState extends State<SpeakerLabelsPage> {
  //Page stuff
  bool isLoading = true;
  final formKey = GlobalKey<FormState>();

  //Audio and transcription stuff
  late final PageManager speakerLabelPageManager;
  String json = '';
  List<SpeakerWithWords> speakerWordsCombined = [];

  Future<void> initialize() async {
    final recording = context.read<TranscriptionPageProvider>().recording;
    if (isLoading == true) {
      if (recording.interviewers != null && recording.interviewers != [] && recording.interviewers!.isNotEmpty) {
        for (var interviewer in recording.interviewers!) {
          context.read<SpeakerLabelsProvider>().interviewers[int.parse(interviewer.split('_').last)] = 'Interviewer';
        }
      } else {
        context.read<SpeakerLabelsProvider>().interviewers[0] = 'Interviewer';
      }
      if (recording.labels != null && recording.labels != [] && recording.labels!.isNotEmpty) {
        int i = 0;
        for (var label in recording.labels!) {
          context.read<SpeakerLabelsProvider>().labels[i] = label;
          i++;
        }
      }
      //print('Interviewers: $interviewers, labels: $labels');
      try {
        //print('json');
        json = await context.read<StorageProvider>().downloadTranscript(recording.id);
        speakerWordsCombined = context.read<TranscriptionProcessing>().processTranscriptionJSON(json);
        //print('audio');
        context.read<SpeakerLabelsProvider>().audioPath = await context.read<StorageProvider>().getAudioUrl(recording.fileKey!);
        //print('pageManager');
        speakerLabelPageManager = PageManager(
          audioPlayer: context.read<SpeakerLabelsProvider>().player,
        );
        await context.read<SpeakerLabelsProvider>().player.setUrl(context.read<SpeakerLabelsProvider>().audioPath);
        await context.read<SpeakerLabelsProvider>().player.load();

        isLoading = false;
      } catch (e) {
        context.read<AnalyticsProvider>().recordEventError('initialize-labels', e.toString());
        print('Something went wrong: $e');
      }
    }
  }

  Future<void> handleClick(String choice) async {
    if (Platform.isIOS) Navigator.pop(context);
    if (choice == 'Help') {
      helpDialog(context, HelpPage.speakerLabelsPage);
    } else if (choice == 'Give feedback') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendFeedbackPage(
            where: 'Speaker labels page',
            type: FeedbackType.feedback,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    speakerLabelPageManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: FutureBuilder(
        future: initialize(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          //print('swc');
          speakerWordsCombined = context.watch<TranscriptionProcessing>().speakerWordsCombined();

          if (isLoading) {
            return LoadingScreen();
          } else {
            //print('getElements');
            List<SpeakerElement> elements = getElements(
              speakerWordsCombined,
              context.read<TranscriptionPageProvider>().recording.speakerCount,
              context.read<TranscriptionPageProvider>().recording.interviewers,
              context.read<TranscriptionPageProvider>().recording.labels,
            );
            print('Done, elements length: ${elements.length}');
            return Scaffold(
              body: Stack(
                children: [
                  BackGroundCircles(),
                  Form(
                    key: formKey,
                    child: CustomScrollView(
                      slivers: [
                        SliverAppBar(
                          backgroundColor: Theme.of(context).colorScheme.background,
                          leading: appBarLeading(context, () {
                            if (context.read<TranscriptionPageProvider>().labelsEmpty) {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            } else {
                              Navigator.pop(context);
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
                              tag: context.read<TranscriptionPageProvider>().recording.id,
                              child: Text(
                                context.read<TranscriptionPageProvider>().recording.name,
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildListDelegate([
                            ...elements.map(
                              (element) {
                                return Speaker(
                                  element: element,
                                  speakerWithWords: speakerWordsCombined,
                                  speakerLabelPageManager: speakerLabelPageManager,
                                );
                              },
                            ),
                            Container(
                              padding: EdgeInsets.all(25),
                              child: InkWell(
                                onTap: () async {
                                  if (formKey.currentState!.validate()) {
                                    context.read<SpeakerLabelsProvider>().applying = true;
                                    Recording newRecording = await applyLabels(
                                      context.read<TranscriptionPageProvider>().recording,
                                      context.read<SpeakerLabelsProvider>().labels,
                                      context.read<SpeakerLabelsProvider>().interviewers,
                                    );
                                    context.read<TranscriptionPageProvider>().recording = newRecording;
                                    Navigator.pop(context);
                                  }
                                },
                                child: LoadingButton(
                                  text: 'Assign labels',
                                  isLoading: context.watch<SpeakerLabelsProvider>().applying,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget menu() {
    final buttons = {'Help', 'Give feedback'};
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
}

class Speaker extends StatefulWidget {
  final SpeakerElement element;
  final List<SpeakerWithWords> speakerWithWords;
  final PageManager speakerLabelPageManager;

  const Speaker({
    required this.element,
    required this.speakerWithWords,
    required this.speakerLabelPageManager,
    Key? key,
  }) : super(key: key);

  @override
  State<Speaker> createState() => _SpeakerState();
}

class _SpeakerState extends State<Speaker> {
  String currentType = '';
  Duration startTime = Duration.zero;

  @override
  void initState() {
    currentType = widget.element.type;
    startTime = widget.element.startTime;
    super.initState();
  }

  Future playPause() async {
    if (widget.speakerLabelPageManager.audioPlayer.playerState.playing) {
      widget.speakerLabelPageManager.pause();
      if (context.read<SpeakerLabelsProvider>().currentlyPlaying != widget.element.getNumber() + 1) {
        await widget.speakerLabelPageManager.setClip(
          startTime,
          startTime + Duration(seconds: 5),
        );
        widget.speakerLabelPageManager.play();
        context.read<SpeakerLabelsProvider>().currentlyPlaying = widget.element.getNumber() + 1;
        print('Currently playing: ${context.read<SpeakerLabelsProvider>().currentlyPlaying}');
      } else {
        context.read<SpeakerLabelsProvider>().currentlyPlaying = 0;
        print('Currently playing: ${context.read<SpeakerLabelsProvider>().currentlyPlaying}');
      }
    } else {
      await widget.speakerLabelPageManager.setClip(
        startTime,
        startTime + Duration(seconds: 5),
      );
      widget.speakerLabelPageManager.play();
      context.read<SpeakerLabelsProvider>().currentlyPlaying = widget.element.getNumber() + 1;
      print('Currently playing: ${context.read<SpeakerLabelsProvider>().currentlyPlaying}');
    }
  }

  Future shuffle() async {
    if (widget.speakerLabelPageManager.audioPlayer.playerState.playing) {
      widget.speakerLabelPageManager.pause();
      await widget.speakerLabelPageManager.setClip(
        startTime,
        startTime + Duration(seconds: 5),
      );
      widget.speakerLabelPageManager.play();
      context.read<SpeakerLabelsProvider>().currentlyPlaying = widget.element.getNumber() + 1;
      print('Currently playing: ${context.read<SpeakerLabelsProvider>().currentlyPlaying}');
    } else {
      await widget.speakerLabelPageManager.setClip(
        startTime,
        startTime + Duration(seconds: 5),
      );
      widget.speakerLabelPageManager.play();
      context.read<SpeakerLabelsProvider>().currentlyPlaying = widget.element.getNumber() + 1;
      print('Currently playing: ${context.read<SpeakerLabelsProvider>().currentlyPlaying}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StandardBox(
      margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Speaker ${widget.element.getNumber() + 1}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Spacer(),
              DropdownButton(
                value: currentType,
                items: <String>['Interviewer', 'Interviewee'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      //This will not be removed, it is needed to update the UI
                      currentType = value;
                    });
                    context.read<SpeakerLabelsProvider>().interviewers[widget.element.getNumber()] = value;
                  }
                },
                icon: Icon(
                  Icons.arrow_downward,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                elevation: 16,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  shadows: <Shadow>[
                    Shadow(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      blurRadius: 1,
                    ),
                  ],
                ),
                underline: Container(
                  height: 0,
                ),
              ),
            ],
          ),
          TextFormField(
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == '' || value == null) {
                return 'You need to give this speaker a label';
              }
              return null;
            },
            decoration: InputDecoration(
              label: Text('Label'),
            ),
            onChanged: (value) {
              context.read<SpeakerLabelsProvider>().labels[widget.element.getNumber()] = value;
            },
            maxLength: 16,
            initialValue: widget.element.label,
          ),
          SizedBox(
            height: 15,
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    await playPause();
                  },
                  child: StandardButton(
                    text: context.read<SpeakerLabelsProvider>().currentlyPlaying == widget.element.getNumber() + 1 ? 'Pause' : 'Play',
                  ),
                ),
              ),
              SizedBox(
                width: 15,
              ),
              Expanded(
                child: InkWell(
                  onTap: () async {
                    startTime = getShuffle(widget.speakerWithWords, widget.element.speakerLabel);
                    await shuffle();
                  },
                  child: StandardButton(
                    text: 'Shuffle',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SpeakerElement {
  String speakerLabel;
  Duration startTime;
  Duration endTime;
  String label;
  String type;

  SpeakerElement({
    required this.speakerLabel,
    required this.startTime,
    required this.endTime,
    required this.label,
    required this.type,
  });

  int getNumber() {
    return int.parse(speakerLabel.split('_').last);
  }
}
