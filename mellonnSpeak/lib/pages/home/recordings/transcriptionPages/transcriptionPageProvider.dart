import 'package:flutter/material.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';

import 'editingPages/textEdit/transcriptionTextEditPage.dart';

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

int getMil(double seconds) {
  double milliseconds = seconds * 1000;
  return milliseconds.toInt();
}

class ChatBubble extends StatefulWidget {
  //Assigning values and making them required
  const ChatBubble({
    Key? key,
    required this.startTime,
    required this.endTime,
    required this.speakerLabel,
    required this.text,
    required this.i,
    required this.isUser,
  }) : super(key: key);

  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String text;
  final int i;
  final bool isUser;

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

/*
* Creating a widget for the normal chat bubble
* This means I can make however many of them I want
* Don't tell me... I know I'm smart
*/
class _ChatBubbleState extends State<ChatBubble> {
  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.startTime);
    String endTime = getMinSec(widget.endTime);

    Color bgColor = Theme.of(context).colorScheme.surface;
    CrossAxisAlignment align = CrossAxisAlignment.start;
    EdgeInsets padding = EdgeInsets.fromLTRB(20, 5, 0, 10);

    if (widget.isUser) {
      bgColor = Theme.of(context).colorScheme.onSurface;
      align = CrossAxisAlignment.end;
      padding = EdgeInsets.fromLTRB(0, 5, 20, 10);
    }

    return Container(
      padding: padding,
      child: Column(
        crossAxisAlignment: align,
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
              color: bgColor,
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

class AnimatedChatDrawer extends StatefulWidget {
  final String recordingName;
  final String id;
  final double startTime;
  final double endTime;
  final String speakerLabel;
  final String pronouncedWords;
  final int i;
  final Transcription transcription;
  final String audioPath;
  final Function(double startTime, double endTime, int i) playPause;
  final bool isUser;

  const AnimatedChatDrawer({
    Key? key,
    required this.recordingName,
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.speakerLabel,
    required this.pronouncedWords,
    required this.i,
    required this.transcription,
    required this.audioPath,
    required this.playPause,
    required this.isUser,
  }) : super(key: key);

  @override
  _AnimatedChatDrawerState createState() => _AnimatedChatDrawerState();
}

class _AnimatedChatDrawerState extends State<AnimatedChatDrawer>
    with SingleTickerProviderStateMixin {
  //Animation stuff
  static const Duration toggleDuration = Duration(milliseconds: 250);
  double maxSlide = 90;
  double maxDragStartEdge = 90 - 16;
  late AnimationController _animationController;
  bool _canBeDragged = false;

  void initState() {
    _animationController = AnimationController(
      vsync: this,
      duration: toggleDuration,
    );
    super.initState();
  }

  void close() => _animationController.reverse();

  void open() => _animationController.forward();

  void toggleDrawer() => _animationController.isCompleted ? close() : open();

  void _onDragStart(DragStartDetails details) {
    _canBeDragged = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_canBeDragged) {
      double delta = details.primaryDelta! / maxSlide;
      if (widget.isUser) {
        _animationController.value += -delta;
      } else {
        _animationController.value += delta;
      }
    }
  }

  void _onDragEnd(DragEndDetails details) {
    //I have no idea what it means, copied from Drawer
    double _kMinFlingVelocity = 365.0;

    if (_animationController.isDismissed || _animationController.isCompleted) {
      return;
    }
    if (details.velocity.pixelsPerSecond.dx.abs() >= _kMinFlingVelocity) {
      double visualVelocity = details.velocity.pixelsPerSecond.dx /
          MediaQuery.of(context).size.width;

      _animationController.fling(velocity: visualVelocity);
    } else if (_animationController.value < 0.5) {
      close();
    } else {
      open();
    }
  }

  @override
  Widget build(BuildContext context) {
    Alignment alignment = Alignment.bottomLeft;
    if (widget.isUser) alignment = Alignment.bottomRight;
    return GestureDetector(
      onTap: toggleDrawer,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _animationController,
        child: ChatBubble(
          startTime: widget.startTime,
          endTime: widget.endTime,
          speakerLabel: widget.speakerLabel,
          text: widget.pronouncedWords,
          i: widget.i,
          isUser: widget.isUser,
        ),
        builder: (context, child) {
          double slide = 0;
          double offset = 0;
          if (widget.isUser) {
            slide = -maxSlide * _animationController.value;
            offset = slide + maxSlide;
          } else {
            slide = maxSlide * _animationController.value;
            offset = slide - maxSlide;
          }
          return Stack(
            children: [
              Transform.translate(
                offset: Offset(offset, -25),
                child: ChatDrawer(
                  recordingName: widget.recordingName,
                  id: widget.id,
                  startTime: widget.startTime,
                  endTime: widget.endTime,
                  maxSlide: maxSlide,
                  i: widget.i,
                  transcription: widget.transcription,
                  audioPath: widget.audioPath,
                  playPause: widget.playPause,
                ),
              ),
              Transform.translate(
                offset: Offset(slide, 0),
                child: child,
              ),
            ],
            alignment: alignment,
          );
        },
      ),
    );
  }
}

class ChatDrawer extends StatefulWidget {
  final String recordingName;
  final String id;
  final double startTime;
  final double endTime;
  final double maxSlide;
  final int i;
  final Transcription transcription;
  final String audioPath;
  final Function(double startTime, double endTime, int i) playPause;

  const ChatDrawer({
    Key? key,
    required this.recordingName,
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.maxSlide,
    required this.i,
    required this.transcription,
    required this.audioPath,
    required this.playPause,
  }) : super(key: key);

  @override
  State<ChatDrawer> createState() => _ChatDrawerState();
}

class _ChatDrawerState extends State<ChatDrawer> {
  String playPause = 'Play';
  @override
  Widget build(BuildContext context) {
    return StandardBox(
      padding: EdgeInsets.all(15),
      margin: EdgeInsets.fromLTRB(10, 5, 10, 0),
      width: widget.maxSlide - 10,
      child: Column(
        children: [
          InkWell(
            onTap: () async {},
            child: Text(
              playPause,
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
          Divider(),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TranscriptionTextEditPage(
                    recordingName: widget.recordingName,
                    id: widget.id,
                    startTime: widget.startTime,
                    endTime: widget.endTime,
                    audioFileKey: widget.audioPath,
                    transcription: widget.transcription,
                  ),
                ),
              );
            },
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.bodyText2,
            ),
          ),
        ],
      ),
    );
  }
}
