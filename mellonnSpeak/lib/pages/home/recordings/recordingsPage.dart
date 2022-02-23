import 'dart:math';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
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
  ///
  ///This function is used to refresh the list of recordings
  ///
  Future<void> _pullRefresh() async {
    await Amplify.DataStore.clear();
    await Future.delayed(Duration(milliseconds: 250));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          TitleBox(title: 'Here\'s your\nRecordings', extras: false),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await _pullRefresh();
              },
              child: StreamBuilder(
                stream: Amplify.DataStore.observeQuery(
                  Recording.classType,
                  sortBy: [Recording.DATE.descending()],
                ).skipWhile((snapshot) => !snapshot.isSynced),
                builder: (context,
                    AsyncSnapshot<QuerySnapshot<Recording>> snapshot) {
                  if (snapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  QuerySnapshot<Recording> querySnapshot = snapshot.data!;
                  var now = DateTime.now();
                  bool status = querySnapshot.isSynced;
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
                    itemCount: querySnapshot.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            /*Text(
                                'Current status isSynced: $status, last synced: $now'),
                            SizedBox(height: 25),*/
                          ],
                        );
                      } else {
                        Recording recording = querySnapshot.items[index - 1];
                        return RecordingElement(
                          recordingName: recording.name,
                          recordingDate: recording.date,
                          recordingDescription: recording.description!,
                          fileName: recording.fileName!,
                          fileKey: recording.fileKey!,
                          id: recording.id,
                          fileUrl: recording.fileUrl ?? 'null',
                          speakerCount: recording.speakerCount,
                          versionList: recording.versions ?? [],
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
