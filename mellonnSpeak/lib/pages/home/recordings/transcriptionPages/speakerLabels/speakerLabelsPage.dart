import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/speakerLabels/speakerLabelsProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

//Labels stuff
List<String> labels = ['', '', '', '', '', '', '', '', '', ''];
List<String> interviewers = ['', '', '', '', '', '', '', '', '', ''];

//Player stuff
String audioPath = '';
final player = AudioPlayer();
int currentlyPlaying = 0;

class SpeakerLabelsPage extends StatefulWidget {
  final Recording recording;
  final bool first;
  final Function()? stateSetter;
  final Function(Recording) refreshRecording;

  const SpeakerLabelsPage({
    required this.recording,
    required this.first,
    this.stateSetter,
    required this.refreshRecording,
    Key? key,
  }) : super(key: key);

  @override
  State<SpeakerLabelsPage> createState() => _SpeakerLabelsPageState();
}

class _SpeakerLabelsPageState extends State<SpeakerLabelsPage> {
  //Page stuff
  bool isLoading = true;
  final formKey = GlobalKey<FormState>();
  bool applying = false;

  //Audio and transcription stuff
  late final PageManager speakerLabelPageManager;
  String json = '';
  List<SpeakerWithWords> speakerWordsCombined = [];
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

  Future<void> initialize() async {
    if (isLoading == true) {
      if (widget.recording.interviewers != null && widget.recording.interviewers != [] && widget.recording.interviewers!.isNotEmpty) {
        for (var interviewer in widget.recording.interviewers!) {
          interviewers[int.parse(interviewer.split('_').last)] = 'Interviewer';
        }
      } else {
        interviewers[0] = 'Interviewer';
      }
      if (widget.recording.labels != null && widget.recording.labels != [] && widget.recording.labels!.isNotEmpty) {
        int i = 0;
        for (var label in widget.recording.labels!) {
          labels[i] = label;
          i++;
        }
      }
      //print('Interviewers: $interviewers, labels: $labels');
      try {
        //print('json');
        json = await context.read<StorageProvider>().downloadTranscript(widget.recording.id);
        //print('audio');
        audioPath = await context.read<StorageProvider>().getAudioUrl(widget.recording.fileKey!);
        //print('pageManager');
        speakerLabelPageManager = PageManager(
          pageSetState: pageSetState,
          audioPlayer: player,
        );
        await player.setUrl(audioPath);
        await player.load();

        isLoading = false;
      } catch (e) {
        recordEventError('initialize-labels', e.toString());
        print('Something went wrong: $e');
      }
    }

    if (isLoading == false) {
      //print('transcription');
      transcription = context.read<TranscriptionProcessing>().getTranscriptionFromString(json);
      //print('process');
      context.read<TranscriptionProcessing>().processTranscriptionJSON(json);
    }
  }

  void pageSetState() {
    setState(() {});
  }

  Future<void> handleClick(String choice) async {
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
    labels = ['', '', '', '', '', '', '', '', '', ''];
    interviewers = ['', '', '', '', '', '', '', '', '', ''];
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
              widget.recording.speakerCount,
              widget.recording.interviewers,
              widget.recording.labels,
            );
            print('Done, elements length: ${elements.length}');
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
                child: Column(
                  children: [
                    TitleBox(
                      title: 'Assign labels',
                      heroString: 'assignLabels',
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
                            'Help',
                            'Give feedback',
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
                    Expanded(
                      child: Form(
                        key: formKey,
                        child: ListView(
                          physics: BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          children: [
                            ...elements.map(
                              (element) {
                                return Speaker(
                                  element: element,
                                  speakerWithWords: speakerWordsCombined,
                                  pageSetState: pageSetState,
                                  speakerLabelPageManager: speakerLabelPageManager,
                                );
                              },
                            ),
                            Container(
                              padding: EdgeInsets.all(25),
                              child: InkWell(
                                onTap: () async {
                                  if (formKey.currentState!.validate()) {
                                    setState(() {
                                      applying = true;
                                    });
                                    Recording newRecording = await applyLabels(
                                      widget.recording,
                                      labels,
                                      interviewers,
                                    );
                                    if (widget.first) {
                                      Navigator.pop(context);
                                      widget.refreshRecording(newRecording);
                                    } else {
                                      Navigator.pop(context);
                                      widget.refreshRecording(newRecording);
                                    }
                                  }
                                },
                                child: LoadingButton(
                                  text: 'Assign labels',
                                  isLoading: applying,
                                ),
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
        },
      ),
    );
  }
}

class Speaker extends StatefulWidget {
  final SpeakerElement element;
  final List<SpeakerWithWords> speakerWithWords;
  final Function() pageSetState;
  final PageManager speakerLabelPageManager;

  const Speaker({
    required this.element,
    required this.speakerWithWords,
    required this.pageSetState,
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
      if (currentlyPlaying != widget.element.getNumber() + 1) {
        await widget.speakerLabelPageManager.setClip(
          startTime,
          startTime + Duration(seconds: 5),
        );
        widget.speakerLabelPageManager.play();
        setState(() {
          currentlyPlaying = widget.element.getNumber() + 1;
        });
        print('Currently playing: $currentlyPlaying');
      } else {
        setState(() {
          currentlyPlaying = 0;
        });
        print('Currently playing: $currentlyPlaying');
      }
    } else {
      await widget.speakerLabelPageManager.setClip(
        startTime,
        startTime + Duration(seconds: 5),
      );
      widget.speakerLabelPageManager.play();
      setState(() {
        currentlyPlaying = widget.element.getNumber() + 1;
      });
      print('Currently playing: $currentlyPlaying');
    }
    widget.pageSetState();
  }

  Future shuffle() async {
    if (widget.speakerLabelPageManager.audioPlayer.playerState.playing) {
      widget.speakerLabelPageManager.pause();
      await widget.speakerLabelPageManager.setClip(
        startTime,
        startTime + Duration(seconds: 5),
      );
      widget.speakerLabelPageManager.play();
      setState(() {
        currentlyPlaying = widget.element.getNumber() + 1;
      });
      print('Currently playing: $currentlyPlaying');
    } else {
      await widget.speakerLabelPageManager.setClip(
        startTime,
        startTime + Duration(seconds: 5),
      );
      widget.speakerLabelPageManager.play();
      setState(() {
        currentlyPlaying = widget.element.getNumber() + 1;
      });
      print('Currently playing: $currentlyPlaying');
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
                style: Theme.of(context).textTheme.headline6,
              ),
              Spacer(),
              DropdownButton(
                value: currentType,
                items: <String>['Interviewer', 'Interviewee'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  );
                }).toList(),
                onChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      currentType = value;
                      interviewers[widget.element.getNumber()] = value;
                    });
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
              setState(() {
                labels[widget.element.getNumber()] = value;
              });
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
                    text: currentlyPlaying == widget.element.getNumber() + 1 ? 'Pause' : 'Play',
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
