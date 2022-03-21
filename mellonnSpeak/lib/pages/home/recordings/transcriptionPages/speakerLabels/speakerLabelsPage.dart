import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/speakerLabels/speakerLabelsProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPage.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

//Labels stuff
List<String> labels = ['', '', '', '', '', '', '', '', '', ''];
List<String> interviewers = ['', '', '', '', '', '', '', '', '', ''];

class SpeakerLabelsPage extends StatefulWidget {
  final Recording recording;
  final bool first;
  final Function()? stateSetter;

  const SpeakerLabelsPage({
    required this.recording,
    required this.first,
    this.stateSetter,
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
  String audioPath = '';
  final player = AudioPlayer();
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
      try {
        json = await context
            .read<StorageProvider>()
            .downloadTranscript(widget.recording.id);

        audioPath = await context
            .read<StorageProvider>()
            .getAudioPath(widget.recording.fileKey!);
        await player.setFilePath(audioPath);
        await player.load();

        isLoading = false;
      } catch (e) {
        recordEventError('initialize-labels', e.toString());
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
  }

  @override
  void dispose() {
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
          speakerWordsCombined =
              context.watch<TranscriptionProcessing>().speakerWordsCombined();

          if (isLoading) {
            return LoadingScreen();
          } else {
            List<SpeakerElement> elements = getElements(
              speakerWordsCombined,
              widget.recording.speakerCount,
              widget.recording.interviewers,
              widget.recording.labels,
            );
            return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.background,
                automaticallyImplyLeading: false,
                title: StandardAppBarTitle(),
                elevation: 0,
              ),
              body: Column(
                children: [
                  TitleBox(
                    title: 'Assign labels',
                    heroString: 'assignLabels',
                    extras: true,
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
                                  } else {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
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
            );
          }
        },
      ),
    );
  }
}

class Speaker extends StatefulWidget {
  final SpeakerElement element;

  const Speaker({
    required this.element,
    Key? key,
  }) : super(key: key);

  @override
  State<Speaker> createState() => _SpeakerState();
}

class _SpeakerState extends State<Speaker> {
  String currentType = '';

  @override
  void initState() {
    currentType = widget.element.type;
    super.initState();
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
                items: <String>['Interviewer', 'Interviewee']
                    .map<DropdownMenuItem<String>>((String value) {
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
            validator: (value) {
              if (value == '' || value == null) {
                return 'You need to give this speaker a label';
              }
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
