import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/versionHistory/versionPage/versionPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';

class VersionElement extends StatelessWidget {
  final TemporalDateTime date;
  final String recordingID;
  final String versionID;
  final String user;

  const VersionElement({
    required this.date,
    required this.recordingID,
    required this.versionID,
    required this.user,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat format = DateFormat('dd/MM/yyyy hh:mm');
    String dateString = format.format(date.getDateTimeInUtc());
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VersionPage(
              recordingID: recordingID,
              versionID: versionID,
              dateString: dateString,
              user: user,
            ),
          ),
        );
      },
      child: StandardBox(
        child: Column(
          children: [
            Text(
              dateString,
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
      ),
    );
  }
}
