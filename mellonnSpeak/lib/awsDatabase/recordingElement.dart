import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPage.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';

/*
* Creating the class that makes the widgets for each recording in the list of recordings
* This is used on the recordingsPage
*/
class RecordingElement extends StatefulWidget {
  //Getting all the necessary info about the current recording
  final String recordingName;
  final TemporalDateTime? recordingDate;
  final String recordingDescription;
  final String fileName;
  final String fileKey;
  final String id;
  final String fileUrl;
  final int speakerCount;

  //Making everything required when calling the widget
  const RecordingElement({
    Key? key,
    required this.recordingName,
    required this.recordingDate,
    required this.recordingDescription,
    required this.fileName,
    required this.fileKey,
    required this.id,
    required this.fileUrl,
    required this.speakerCount,
  }) : super(key: key);

  @override
  _RecordingElementState createState() => _RecordingElementState();
}

class _RecordingElementState extends State<RecordingElement> {
  DateFormat formatter = DateFormat('dd-MM-yyyy');

  /*
  * Building the widget
  */
  @override
  Widget build(BuildContext context) {
    DateTime date = widget.recordingDate?.getDateTimeInUtc() ?? DateTime.now();
    Duration timeToNow = DateTime.now().difference(date);
    bool isOld = timeToNow.inDays > 90;
    DateTime deleteDate = DateTime(date.year, date.month, date.day + 90);
    return Column(
      children: [
        InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            /*
            * If the fileURL is empty when the user taps the recordingElement
            * It will just show an alert dialog containing info about the recording
            * 
            * If the fileURL isn't empty
            * It will show the TranscriptionPage, with the fileURL
            */
            if (widget.fileUrl == 'null') {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text('${widget.recordingName}'),
                  content: Container(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: Column(
                      children: [
                        Text(
                            'The selected recording is currently being transcribed, this can take some time depending on the length of the audio clip.\nIf this takes longer than 2 hours, please contact Mellonn by using Report issue on profile page.'),
                        //Text('The transcription job was started: ')
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            //This will just close the dialog, when the user is done looking at it
                            setState(() {
                              Navigator.pop(context);
                            });
                          },
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            } else {
              //If the fileURL isn't empty, it will push the TranscriptionPage, YAY!
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranscriptionPage(
                    recordingName: widget.recordingName,
                    recordingDate: widget.recordingDate,
                    recordingDescription: widget.recordingDescription,
                    fileName: widget.fileName,
                    fileKey: widget.fileKey,
                    id: widget.id,
                    fileUrl: widget.fileUrl,
                    speakerCount: widget.speakerCount,
                  ),
                ),
              );
            }
          },
          /*
          * This is where the design magic begins, even Apple would call this magic
          */
          child: StandardBox(
            width: MediaQuery.of(context).size.width,
            height: 130,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${widget.recordingName}',
                      style: isOld
                          ? Theme.of(context)
                              .textTheme
                              .headline5
                              ?.copyWith(color: Colors.red)
                          : Theme.of(context).textTheme.headline5,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    /*
                    * Here i am once again asking if the fileURL is empty
                    * If it is, this means the recording hasn't been transcribed and it will show a loading circle besides the title
                    * If it's not, this means the recording has been transcribed and it will show a nice checkmark besides the title
                    */
                    if (widget.fileUrl == 'null') ...[
                      SizedBox(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          strokeWidth: 2.5,
                        ),
                        width: 15,
                        height: 15,
                      ),
                    ] else ...[
                      Icon(
                        FontAwesomeIcons.checkCircle,
                        size: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ],
                ),
                //Magic spacing...
                SizedBox(
                  height: 10,
                ),
                //Showing the date of the recording being uploaded
                Text(
                  isOld
                      ? 'Will be deleted: ${formatter.format(deleteDate)}'
                      : '${formatter.format(date)}',
                  style: isOld
                      ? Theme.of(context)
                          .textTheme
                          .headline6
                          ?.copyWith(color: Colors.red)
                      : Theme.of(context).textTheme.headline6,
                ),
                //Magic spacing...
                SizedBox(
                  height: 10,
                ),
                //Showing the description given, when the recording was uploaded
                Text(
                  '${widget.recordingDescription}',
                  style: isOld
                      ? Theme.of(context)
                          .textTheme
                          .bodyText2
                          ?.copyWith(color: Colors.red)
                      : Theme.of(context).textTheme.bodyText2,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 25,
        ),
      ],
    );
  }
}
