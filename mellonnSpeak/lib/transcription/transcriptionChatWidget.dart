import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'transcriptionProvider.dart';

class TranscriptionChatWidget extends StatefulWidget {
  const TranscriptionChatWidget({Key? key, required this.url, required this.userNumber}) : super(key: key);

  final String url;
  final int userNumber;

  @override
  _TranscriptionChatWidgetState createState() => _TranscriptionChatWidgetState();
}

class _TranscriptionChatWidgetState extends State<TranscriptionChatWidget> {
  String fullTranscript = '';
  List<SpeakerWithWords> speakerWordsCombined = [];
  bool isLoading = true;
  String user = '';
  bool hasInitialized = false;

  void initState() async {
    isLoading = true;
    await initialize();
    super.initState();
  }

  Future initialize() async {
    if (!hasInitialized) {
      hasInitialized = true;
      await context.read<TranscriptionProcessing>().processTranscription(widget.url);
    }

    if (fullTranscript != '') {
      isLoading = false;
    } else {
      isLoading = true;
    }
    user = 'spk_${widget.userNumber}';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initialize(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        fullTranscript = context.watch<TranscriptionProcessing>().fullTranscript;
        speakerWordsCombined = context.watch<TranscriptionProcessing>().speakerWordsCombined();
        return Container(
          child: ListView(
            physics: BouncingScrollPhysics(),
            children: [
              SizedBox(
                height: 15,
              ),
              ...speakerWordsCombined.map(
                (element) {
                  if (element.speakerLabel == user) {
                    return ChatBubbleUser(
                      startTime: element.startTime,
                      endTime: element.endTime,
                      speakerLabel: element.speakerLabel,
                      text: element.pronouncedWords,
                    );
                  } else {
                    return ChatBubble(
                      startTime: element.startTime,
                      endTime: element.endTime,
                      speakerLabel: element.speakerLabel,
                      text: element.pronouncedWords,
                    );
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
  const ChatBubble({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.speakerLabel,
    required this.text,
  }) : super(key: key);

  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String text;

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
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
    String startTime = getMinSec(widget.startTime);
    String endTime = getMinSec(widget.endTime);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 5, 0, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(15),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              minHeight: 50,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Text(
              '${widget.text}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 13,
                shadows: <Shadow>[
                  Shadow(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            '${widget.speakerLabel}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryContainer,
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
  const ChatBubbleUser({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.speakerLabel,
    required this.text,
  }) : super(key: key);

  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String text;

  @override
  _ChatBubbleUserState createState() => _ChatBubbleUserState();
}

class _ChatBubbleUserState extends State<ChatBubbleUser> {
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
    String startTime = getMinSec(widget.startTime);
    String endTime = getMinSec(widget.endTime);

    return Container(
      padding: EdgeInsets.fromLTRB(0, 5, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: EdgeInsets.all(15),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              minHeight: 50,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).shadowColor,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Text(
              '${widget.text}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 13,
                shadows: <Shadow>[
                  Shadow(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            '${widget.speakerLabel}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryContainer,
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
