import 'package:flutter/material.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class VersionPage extends StatefulWidget {
  final String recordingID;
  final String versionID;
  final String dateString;
  final String user;

  const VersionPage({
    required this.recordingID,
    required this.versionID,
    required this.dateString,
    required this.user,
    Key? key,
  }) : super(key: key);

  @override
  _VersionPageState createState() => _VersionPageState();
}

class _VersionPageState extends State<VersionPage> {
  bool isLoading = true;
  List<SpeakerWithWords> swCombined = [];

  Future<void> initialize() async {
    String json = await downloadVersion(widget.recordingID, widget.versionID);
    swCombined = await context
        .read<TranscriptionProcessing>()
        .processTranscriptionJSON(json);
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
            appBar: standardAppBar,
            body: Container(
              height: MediaQuery.of(context).size.height,
              child: Column(
                children: [
                  TitleBox(
                    title: widget.dateString,
                    extras: false,
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
                              startTime: element.startTime,
                              endTime: element.endTime,
                              speakerLabel: element.speakerLabel,
                              text: element.pronouncedWords,
                              isUser: element.speakerLabel == widget.user,
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
