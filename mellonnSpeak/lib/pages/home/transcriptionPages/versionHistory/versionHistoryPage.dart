import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/versionHistory/versionPage/versionPage.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';

import 'versionHistoryProvider.dart';

class VersionHistoryPage extends StatefulWidget {
  final Recording recording;
  final Function() transcriptionResetState;

  const VersionHistoryPage({
    required this.recording,
    required this.transcriptionResetState,
    Key? key,
  }) : super(key: key);

  @override
  _VersionHistoryPageState createState() => _VersionHistoryPageState();
}

class _VersionHistoryPageState extends State<VersionHistoryPage> {
  Future<void> handleClick(String choice) async {
    if (Platform.isIOS) Navigator.pop(context);
    if (choice == 'Help') {
      helpDialog(context, HelpPage.versionHistoryPage);
    } else if (choice == 'Give feedback') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SendFeedbackPage(
            where: 'Text edit page',
            type: FeedbackType.feedback,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: Amplify.DataStore.observeQuery(
          Version.classType,
          where: Version.RECORDINGID.eq(widget.recording.id),
          sortBy: [Recording.DATE.descending()],
        ).skipWhile((snapshot) => !snapshot.isSynced),
        builder: (context, AsyncSnapshot<QuerySnapshot<Version>> snapshot) {
          if (snapshot.data == null) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          QuerySnapshot<Version> querySnapshot = snapshot.data!;
          return Stack(
            children: [
              BackGroundCircles(),
              CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(context).colorScheme.background,
                    leading: appBarLeading(context),
                    pinned: true,
                    elevation: 0.5,
                    surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                    expandedHeight: 100,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        "Version history",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VersionPage(
                                        recording: widget.recording,
                                        versionID: 'original',
                                        dateString: 'Original',
                                        transcriptionResetState: widget.transcriptionResetState,
                                      ),
                                    ),
                                  );
                                },
                                child: StandardBox(
                                  margin: EdgeInsets.only(bottom: 15),
                                  width: MediaQuery.of(context).size.width,
                                  child: Text(
                                    'Original transcript',
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                ),
                              ),
                              Divider(),
                              SizedBox(
                                height: 15,
                              ),
                            ],
                          ),
                        ),
                        ...querySnapshot.items.map(
                          (version) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
                              child: VersionElement(
                                date: version.date,
                                recording: widget.recording,
                                versionID: version.id,
                                editType: version.editType,
                                transcriptionResetState: widget.transcriptionResetState,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
