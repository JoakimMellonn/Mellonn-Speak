import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPage.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class VersionPage extends StatefulWidget {
  final Recording recording;
  final String versionID;
  final String dateString;
  final Function() transcriptionResetState;

  const VersionPage({
    required this.recording,
    required this.versionID,
    required this.dateString,
    required this.transcriptionResetState,
    Key? key,
  }) : super(key: key);

  @override
  _VersionPageState createState() => _VersionPageState();
}

class _VersionPageState extends State<VersionPage> {
  bool isLoading = true;
  List<SpeakerWithWords> swCombined = [];
  Transcription transcription = Transcription(
    jobName: '',
    accountId: '',
    results: Results(
      transcripts: <Transcript>[],
      speakerLabels: SpeakerLabels(speakers: 0, segments: <Segment>[]),
      items: <Item>[],
    ),
    status: '',
  );

  Future<void> initialize() async {
    String json = await downloadVersion(widget.recording.id, widget.versionID);
    transcription = transcriptionFromJson(json);
    swCombined = context.read<TranscriptionProcessing>().processTranscriptionJSON(json);
    if (swCombined.length > 0) {
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialize(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        //Assigning the values

        if (isLoading == true) {
          return LoadingScreen();
        } else {
          return Scaffold(
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: Theme.of(context).colorScheme.background,
                  surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                  leading: appBarLeading(context),
                  actions: [
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                            title: Text('Are you sure?'),
                            content: Text('Are you sure you want to recover the transcription to this state?'),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('No'),
                                  ),
                                  SizedBox(
                                    width: 75,
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      await context.read<StorageProvider>().saveTranscription(transcription, widget.recording.id);
                                      final json = transcriptionToJson(transcription);
                                      await uploadVersion(json, widget.recording.id, 'Recovered Version');

                                      final snackBar = SnackBar(
                                        content: const Text('Transcription recovered!'),
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      widget.transcriptionResetState();
                                    },
                                    child: Text('Yes'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(
                        FontAwesomeIcons.upload,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                    SizedBox(
                      width: 20,
                    ),
                  ],
                  pinned: true,
                  elevation: 0.5,
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Hero(
                      tag: 'pageTitle',
                      child: Text(
                        widget.dateString,
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
                          transcription: transcription,
                          sww: element,
                          label: widget.recording.labels![int.parse(element.speakerLabel.split('_')[1])],
                          isInterviewer: widget.recording.interviewers!.contains(element.speakerLabel),
                          canFocus: false,
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
}
