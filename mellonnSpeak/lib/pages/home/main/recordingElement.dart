import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/models/Recording.dart';

/*
* Creating the class that makes the widgets for each recording in the list of recordings
* This is used on the recordingsPage
*/
class RecordingElement extends StatefulWidget {
  final Recording recording;
  final BuildContext recordingsContext;

  const RecordingElement({
    required this.recording,
    required this.recordingsContext,
    Key? key,
  }) : super(key: key);

  @override
  _RecordingElementState createState() => _RecordingElementState();
}

class _RecordingElementState extends State<RecordingElement> {
  GlobalKey key = GlobalKey();
  DateFormat formatter = DateFormat('dd-MM-yyyy');

  void refreshRecording(Recording newRecording) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (recordingsContext) => TranscriptionPage(
          recording: newRecording,
        ),
      ),
    );
  }

  /*
  * Building the widget
  */
  @override
  Widget build(BuildContext context) {
    DateTime date = widget.recording.date?.getDateTimeInUtc() ?? DateTime.now();
    Duration timeToNow = DateTime.now().difference(date);
    bool isOld = timeToNow.inDays > 180;
    DateTime deleteDate = DateTime(date.year, date.month, date.day + 180);
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
            if (widget.recording.fileUrl == null) {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: Text('${widget.recording.name}'),
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
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => TranscriptionPage(
                    recording: widget.recording,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    final width = MediaQuery.of(context).size.width;
                    final height = MediaQuery.of(context).size.height;
                    double top = 0;
                    final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.linear);
                    RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
                    Offset? position = box?.localToGlobal(Offset.zero);
                    Size? boxSize = box?.size;
                    if (position != null && boxSize != null) {
                      top = (-(height / 2) + position.dy + boxSize.height / 2) * (1 - animation.value);
                    }

                    return Stack(
                      children: [
                        Positioned(
                          top: top,
                          child: Container(
                            width: width,
                            height: height,
                            child: ScaleTransition(
                              scale: Tween(begin: 0.0, end: 1.0).animate(curvedAnimation),
                              child: child,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  transitionDuration: Duration(milliseconds: 250),
                  reverseTransitionDuration: Duration(milliseconds: 250),
                ),
              );
            }
          },
          /*
          * This is where the design magic begins, even Apple would call this magic
          */
          child: Container(
            key: key,
            child: StandardBox(
              width: MediaQuery.of(context).size.width,
              padding: EdgeInsets.fromLTRB(25, 20, 25, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Hero(
                        tag: widget.recording.id,
                        child: Text(
                          '${widget.recording.name}',
                          style: isOld
                              ? Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red)
                              : Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      /*
                      * Here i am once again asking if the fileURL is empty
                      * If it is, this means the recording hasn't been transcribed and it will show a loading circle besides the title
                      * If it's not, this means the recording has been transcribed and it will show a nice checkmark besides the title
                      */
                      if (widget.recording.fileUrl == 'null' || widget.recording.fileUrl == null) ...[
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
                          FontAwesomeIcons.circleCheck,
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
                    isOld ? 'Will be deleted: ${formatter.format(deleteDate)}' : '${formatter.format(date)}',
                    style: isOld
                        ? Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.error)
                        : Theme.of(context).textTheme.headlineSmall,
                  ),
                  //Magic spacing...
                  SizedBox(
                    height: 10,
                  ),
                  //Showing the description given, when the recording was uploaded
                  Text(
                    '${widget.recording.description}',
                    style: isOld
                        ? Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)
                        : Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
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
