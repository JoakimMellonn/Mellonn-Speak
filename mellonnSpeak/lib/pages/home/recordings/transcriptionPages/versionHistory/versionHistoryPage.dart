import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';

import 'versionHistoryProvider.dart';

class VersionHistoryPage extends StatefulWidget {
  final String recordingID;
  final List<Version> versionList;
  final String user;

  const VersionHistoryPage({
    required this.recordingID,
    required this.versionList,
    required this.user,
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
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
                itemCount: widget.versionList.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return StandardBox(
                      child: Text(
                        'Original transcript',
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    );
                  } else {
                    Version version = widget.versionList[index - 1];
                    return VersionElement(
                      date: version.date,
                      recordingID: widget.recordingID,
                      versionID: version.id,
                      user: widget.user,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
