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
  final String editType;
  final Function() transcriptionResetState;

  const VersionElement({
    required this.date,
    required this.recordingID,
    required this.versionID,
    required this.user,
    required this.editType,
    required this.transcriptionResetState,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateFormat format = DateFormat('dd/MM/yyyy HH:mm');
    String dateString = format.format(date.getDateTimeInUtc().toLocal());
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
              transcriptionResetState: transcriptionResetState,
            ),
          ),
        );
      },
      child: StandardBox(
        margin: EdgeInsets.only(bottom: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dateString,
              style: Theme.of(context).textTheme.headline6,
            ),
            SizedBox(
              height: 5,
            ),
            Text(
              'Type: ${editType}',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ],
        ),
      ),
    );
  }
}
