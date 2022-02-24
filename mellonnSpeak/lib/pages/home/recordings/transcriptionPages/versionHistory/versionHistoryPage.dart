import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/versionHistory/versionPage/versionPage.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/utilities/helpDialog.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: standardAppBar,
      body: Container(
        child: Column(
          children: [
            TitleBox(
              title: 'Version history',
              extras: true,
              extra: IconButton(
                onPressed: () {
                  helpDialog(context, HelpPage.versionHistoryPage);
                },
                icon: Icon(
                  FontAwesomeIcons.solidQuestionCircle,
                  color: context.read<ColorProvider>().darkText,
                  size: 30,
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: Amplify.DataStore.observeQuery(
                  Version.classType,
                  where: Version.RECORDINGID.eq(widget.recordingID),
                  sortBy: [Recording.DATE.ascending()],
                ).skipWhile((snapshot) => !snapshot.isSynced),
                builder:
                    (context, AsyncSnapshot<QuerySnapshot<Version>> snapshot) {
                  if (snapshot.data == null) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  QuerySnapshot<Version> querySnapshot = snapshot.data!;
                  var now = DateTime.now();
                  bool status = querySnapshot.isSynced;
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
                    itemCount: querySnapshot.items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => VersionPage(
                                  recordingID: widget.recordingID,
                                  versionID: 'original',
                                  dateString: 'Original',
                                  user: widget.user,
                                  transcriptionResetState:
                                      widget.transcriptionResetState,
                                ),
                              ),
                            );
                          },
                          child: StandardBox(
                            margin: EdgeInsets.only(bottom: 25),
                            child: Text(
                              'Original transcript',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ),
                        );
                      } else {
                        Version version = querySnapshot.items[index - 1];
                        return VersionElement(
                          date: version.date,
                          recordingID: version.recordingID,
                          versionID: version.id,
                          user: widget.user,
                          editType: version.editType,
                          transcriptionResetState:
                              widget.transcriptionResetState,
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
