import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPage.dart';
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
  * This is the function called when a user wants to delete a recording
  * The 'are you sure' part is done in the widgets
  */
  void deleteRecording(String recID) async {
    try {
      (await Amplify.DataStore.query(Recording.classType,
              where: Recording.ID.eq(widget.id)))
          .forEach((element) async {
        //The tryception begins...
        try {
          await Amplify.DataStore.delete(element);
          print('Deleted a post');
        } on DataStoreException catch (e) {
          print('Delete failed: $e');
        }
      });
    } catch (e) {
      print('ERROR: $e');
    }
    //After the recording is deleted, it makes a new list of the recordings
    context.read<DataStoreAppProvider>().getRecordings();
  }

  /*
  * Building the widget
  */
  @override
  Widget build(BuildContext context) {
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
                  title: Text('${widget.fileName}'),
                  content: Container(
                    constraints: BoxConstraints(maxHeight: 75),
                    child: Column(
                      children: [
                        Text('File Key: ${widget.fileKey}'),
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () {
                            /*
                            * The user has tapped the delete button
                            * Because I'm a good person, and users can be dum dum I will ask if they are sure
                            */
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('Are you sure?'),
                                content: Text(
                                    'You are about to delete this recording, this can NOT be undone'),
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          //If they aren't, it will just close the dialog, and they can live happily everafter
                                          setState(() {
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: Text('No'),
                                      ),
                                      SizedBox(
                                        width: 75,
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          //If they are, it will delete the recording and close the dialog
                                          deleteRecording(widget.id);
                                          setState(() {
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: Text('Yes'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Text('Delete recording'),
                        ),
                        SizedBox(
                          width: 50,
                        ),
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
                      style: Theme.of(context).textTheme.headline5,
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
                  '${formatter.format(widget.recordingDate?.getDateTimeInUtc() ?? DateTime.now())}',
                  style: Theme.of(context).textTheme.headline6,
                ),
                //Magic spacing...
                SizedBox(
                  height: 10,
                ),
                //Showing the description given, when the recording was uploaded
                Text(
                  '${widget.recordingDescription}',
                  style: Theme.of(context).textTheme.bodyText2,
                ),
              ],
            ),
          ),
        ),
        //Magic spacing...
        SizedBox(
          height: 25,
        ),
      ],
    );
  }
}
