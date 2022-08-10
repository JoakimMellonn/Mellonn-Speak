import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/versionHistory/versionPage/versionPage.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

import 'versionHistoryProvider.dart';

class VersionHistoryPage extends StatefulWidget {
  final String recordingID;
  final String user;
  final Function() transcriptionResetState;

  const VersionHistoryPage({
    required this.recordingID,
    required this.user,
    required this.transcriptionResetState,
    Key? key,
  }) : super(key: key);

  @override
  _VersionHistoryPageState createState() => _VersionHistoryPageState();
}

class _VersionHistoryPageState extends State<VersionHistoryPage> {
  Future<void> handleClick(String choice) async {
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
              title: 'Version history',
              heroString: 'pageTitle',
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
              child: StreamBuilder(
                stream: Amplify.DataStore.observeQuery(
                  Version.classType,
                  where: Version.RECORDINGID.eq(widget.recordingID),
                  sortBy: [Recording.DATE.descending()],
                ).skipWhile((snapshot) => !snapshot.isSynced),
                builder: (context, AsyncSnapshot<QuerySnapshot<Version>> snapshot) {
                  if (snapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  QuerySnapshot<Version> querySnapshot = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
                    itemCount: querySnapshot.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VersionPage(
                                      recordingID: widget.recordingID,
                                      versionID: 'original',
                                      dateString: 'Original',
                                      user: widget.user,
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
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                              ),
                            ),
                            Divider(),
                            SizedBox(
                              height: 15,
                            ),
                          ],
                        );
                      } else {
                        Version version = querySnapshot.items[index - 1];
                        return VersionElement(
                          date: version.date,
                          recordingID: version.recordingID,
                          versionID: version.id,
                          user: widget.user,
                          editType: version.editType,
                          transcriptionResetState: widget.transcriptionResetState,
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
