import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPage.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class VersionPage extends StatefulWidget {
  final String recordingID;
  final String versionID;
  final String dateString;
  final String user;
  final Function() transcriptionResetState;

  const VersionPage({
    required this.recordingID,
    required this.versionID,
    required this.dateString,
    required this.user,
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
    String json = await downloadVersion(widget.recordingID, widget.versionID);
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
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.background,
              automaticallyImplyLeading: false,
              title: StandardAppBarTitle(),
              elevation: 0,
            ),
            body: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  TitleBox(
                    title: widget.dateString,
                    heroString: 'pageTitle',
                    extras: true,
                    extra: IconButton(
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
                                      await context.read<StorageProvider>().saveTranscription(transcription, widget.recordingID);
                                      final json = transcriptionToJson(transcription);
                                      await uploadVersion(json, widget.recordingID, 'Recovered Version');

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
                        color: context.read<ColorProvider>().darkText,
                      ),
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
                          ...swCombined.map((element) {
                            return ChatBubble(
                              transcription: transcription,
                              sww: element,
                              label: element.speakerLabel,
                              isInterviewer: element.speakerLabel == widget.user,
                            );
                          }),
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
