import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mellonnSpeak/awsDatabase/recordingElement.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';

class RecordingsPage extends StatefulWidget {
  const RecordingsPage({Key? key}) : super(key: key);

  @override
  _RecordingsPageState createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  //Creating the necessary variables
  List<Recording> recordings = [];
  List<Recording> recordingsReversed = [];

  /*
  * This function is used to refresh the list of recordings
  * It does need a little work, to get smoother and more reliable
  */
  Future<void> _pullRefresh() async {
    try {
      //await context.read<DataStoreAppProvider>().clearRecordings();
      await context.read<DataStoreAppProvider>().getRecordings();
      //await Future.delayed(Duration(milliseconds: 1000));
    } catch (e) {
      print('Pull refresh error: $e');
    }
  }

  /*
  * Building the recordingsPage
  */
  @override
  Widget build(BuildContext context) {
    recordings = context.watch<DataStoreAppProvider>().recordings;
    recordingsReversed = List.from(recordings.reversed);
    return Container(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          //Creating that beautiful title, with orange background and rounded corners, oh my!
          Container(
            padding: EdgeInsets.all(25),
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(
              minHeight: 150,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              children: [
                Container(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.55,
                    child: FittedBox(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Here's your",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondary,
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
                          SizedBox(
                            height: 1,
                          ),
                          Text(
                            'Recordings',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSecondary,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          //The place for all them recordings
          Expanded(
            child: RefreshIndicator(
              color: context.read<ColorProvider>().orange,
              onRefresh:
                  _pullRefresh, //When pulling down, the page will refresh...
              child: ListView(
                physics: BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ), //Make the pullRefresh work, even though the page is empty
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
