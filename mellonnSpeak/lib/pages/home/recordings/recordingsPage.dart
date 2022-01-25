import 'package:flutter/material.dart';
import 'package:mellonnSpeak/awsDatabase/recordingElement.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';

class RecordingsPageMobile extends StatefulWidget {
  const RecordingsPageMobile({Key? key}) : super(key: key);

  @override
  State<RecordingsPageMobile> createState() => _RecordingsPageMobileState();
}

class _RecordingsPageMobileState extends State<RecordingsPageMobile> {
  //Creating the necessary variables
  List<Recording> recordings = [];
  List<Recording> recordingsReversed = [];

  ///
  ///This function is used to refresh the list of recordings
  ///It does need a little work, to get smoother and more reliable
  ///
  Future<void> _pullRefresh() async {
    try {
      await context.read<DataStoreAppProvider>().getRecordings();
    } catch (e) {
      print('Pull refresh error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    recordings = context.watch<DataStoreAppProvider>().recordings;
    recordingsReversed = List.from(recordings.reversed);
    return Container(
      child: Column(
        children: [
          TitleBox(title: 'Here\'s your\nRecordings', extras: false),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _pullRefresh,
              child: ListView(
                physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.all(25),
                children: [
                  /*
                  * Reversing the list of recordings, so the latest recordings will be first
                  * Mapping the reversed list and creating a RecordingElement widget for each of the elements in the list
                  */
                  ...recordingsReversed.map(
                    (rec) {
                      return RecordingElement(
                        recordingName: '${rec.name}',
                        recordingDate: rec.date,
                        recordingDescription: '${rec.description}',
                        fileName: '${rec.fileName}',
                        fileKey: '${rec.fileKey}',
                        fileUrl: '${rec.fileUrl}',
                        id: '${rec.id}',
                        speakerCount: rec.speakerCount,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
