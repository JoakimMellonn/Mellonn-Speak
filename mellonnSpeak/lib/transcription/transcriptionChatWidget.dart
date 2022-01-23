import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transcriptionProvider.dart';
import 'package:transscriber/providers/colorProvider.dart';

class TranscriptionChatWidget extends StatefulWidget {
  const TranscriptionChatWidget(
      {Key? key, required this.url, required this.userNumber})
      : super(key: key);

  final String url;
  final int userNumber;

  @override
  _TranscriptionChatWidgetState createState() =>
      _TranscriptionChatWidgetState();
}

class _TranscriptionChatWidgetState extends State<TranscriptionChatWidget> {
  //Creating the necessary variables
  String fullTranscript = '';
  List<SpeakerWithWords> speakerWordsCombined = [];
  bool isLoading = true;
  String user = '';
  bool hasInitialized = false;

  /*
  * Calling the initialize function when initializing the widget, what... a... coincidence...
  */
  void initState() async {
    isLoading = true; //Yes it's loading, until it's not
    await initialize();
    super.initState();
  }

  /*
  * When initializing this widget, the transcription first needs to be loaded apparently
  * First we're calling the json parsing code, which makes the recieved json-file into a list
  * That list is then split into the different parts we need in order to create the chat bubbles
  */
  Future initialize() async {
    if (!hasInitialized) {
      //print('Calling ProcessTranscription...');
      hasInitialized = true;
      await context
          .read<TranscriptionProcessing>()
          .processTranscription(widget.url); //It's all done in the provider
    }

    if (fullTranscript != '') {
      isLoading =
          false; //If nothing is recieved the page will never load, some would say this is a problem, I think it's a feature
    } else {
      isLoading =
          true; //And of course, the page will load when the json has been processed
    }
    user =
        'spk_${widget.userNumber}'; //The user has to choose whose what speakernumber
  }

  /*
  * Building the main part of the chat bubbles
  * This will check whether it's the user or someone else who's speaking
  * And then place the chat bubble on the right side and give the right color
  */
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialize(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        //Assigning the values
        fullTranscript =
            context.watch<TranscriptionProcessing>().fullTranscript;
        speakerWordsCombined =
            context.watch<TranscriptionProcessing>().speakerWordsCombined();
        return Container(
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: [
              SizedBox(
                height: 15,
              ),
              /*
              * Mapping the list of words, which also contains info about who said it and when
              */
              ...speakerWordsCombined.map(
                (element) {
                  if (element.speakerLabel == user) {
                    //Checks if it's the user speaking, and return the right widget
                    return ChatBubbleUser(
                        startTime: element.startTime,
                        endTime: element.endTime,
                        speakerLabel: element.speakerLabel,
                        text: element.pronouncedWords);
                  } else {
                    //Everything else will be a normal chat bubble
                    return ChatBubble(
                        startTime: element.startTime,
                        endTime: element.endTime,
                        speakerLabel: element.speakerLabel,
                        text: element.pronouncedWords);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChatBubble extends StatefulWidget {
  //Assigning values and making them required
  const ChatBubble(
      {Key? key,
      required this.startTime,
      required this.endTime,
      required this.speakerLabel,
      required this.text})
      : super(key: key);

  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String text;

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

/*
* Creating a widget for the normal chat bubble
* This means I can make however many of them I want
* Don't tell me... I know I'm smart
*/
class _ChatBubbleState extends State<ChatBubble> {
  /*
  * Send this function an amount of seconds and it will return it in format: *m *s
  */
  String getMinSec(double seconds) {
    double minDouble = seconds / 60;
    int minInt = minDouble.floor();
    double secDouble = seconds - (minInt * 60);
    int secInt = secDouble.floor();

    String minSec = '${minInt}m ${secInt}s';
    String sec = '${secInt}s';

    if (minInt == 0) {
      return sec;
    } else {
      return minSec;
    }
  }

  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.startTime);
    String endTime = getMinSec(widget.endTime);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 5, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //Making the container, which looks sexy af
          Container(
            padding: EdgeInsets.all(15),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  0.7, //The chat bubble will fill 70% of the screen's width
              minHeight: 50,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
            //The bubble will just have the text inside of it
            child: Text(
              '${widget.text}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 13,
                shadows: <Shadow>[
                  Shadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          //Magic spacing...
          SizedBox(
            height: 5,
          ),
          //For now we'll show the speakerlabel and timeframe the words have been spoken
          Text(
            '${widget.speakerLabel}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubbleUser extends StatefulWidget {
  //Assigning values and making them required
  const ChatBubbleUser(
      {Key? key,
      required this.startTime,
      required this.endTime,
      required this.speakerLabel,
      required this.text})
      : super(key: key);

  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String text;

  @override
  _ChatBubbleUserState createState() => _ChatBubbleUserState();
}

/*
* Creating a widget for the user's chat bubble
* This means I can make however many of them I want
* Don't tell me... I know I'm smart
*/
class _ChatBubbleUserState extends State<ChatBubbleUser> {
  /*
  * Send this function an amount of seconds and it will return it in format: *m *s
  */
  String getMinSec(double seconds) {
    double minDouble = seconds / 60;
    int minInt = minDouble.floor();
    double secDouble = seconds - (minInt * 60);
    int secInt = secDouble.floor();

    String minSec = '${minInt}m ${secInt}s';
    String sec = '${secInt}s';

    if (minInt == 0) {
      return sec;
    } else {
      return minSec;
    }
  }

  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.startTime);
    String endTime = getMinSec(widget.endTime);

    return Container(
      padding: EdgeInsets.fromLTRB(0, 5, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment
            .end, //Aligning the bubble to the right of the screen instead
        children: [
          //Making the container, which looks sexy af
          Container(
            padding: EdgeInsets.all(15),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width *
                  0.7, //The chat bubble will fill 70% of the screen's width
              minHeight: 50,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface, //This bubble is green
              borderRadius: BorderRadius.circular(25),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
            //The bubble will just have the text inside of it
            child: Text(
              '${widget.text}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 13,
                shadows: <Shadow>[
                  Shadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          //Magic spacing...
          SizedBox(
            height: 5,
          ),
          //For now we'll show the speakerlabel and timeframe the words have been spoken
          Text(
            '${widget.speakerLabel}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
