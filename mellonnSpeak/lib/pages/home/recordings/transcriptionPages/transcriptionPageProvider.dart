import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/editingPages/textEdit/transcriptionTextEditProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';

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
  final Transcription transcription;
  final SpeakerWithWords sww;
  final String label;
  final bool isUser;

  const ChatBubble({
    Key? key,
    required this.transcription,
    required this.sww,
    required this.label,
    required this.isUser,
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble> {
  double boxScale = 1;

  @override
  Widget build(BuildContext context) {
    //Getting time variables ready...
    String startTime = getMinSec(widget.sww.startTime);
    String endTime = getMinSec(widget.sww.endTime);

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
          GestureDetector(
            onTapDown: (details) {
              print('tap down');
              setState(() {
                boxScale = 0.95;
              });
            },
            onTapUp: (details) {
              print('tap up');
              setState(() {
                boxScale = 1.0;
              });
            },
            onLongPress: () async {
              setState(() {
                boxScale = 1.0;
              });
              Navigator.push(
                context,
                PageRouteBuilder(
                  transitionDuration: Duration(milliseconds: 100),
                  reverseTransitionDuration: Duration(milliseconds: 100),
                  pageBuilder: (context, animation, secondaryAnimation) {
                    animation = Tween(begin: 0.0, end: 1.0).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: ChatBubbleFocused(
                        transcription: widget.transcription,
                        sww: widget.sww,
                      ),
                    );
                  },
                  fullscreenDialog: true,
                  opaque: false,
                ),
              );
            },
            child: AnimatedScale(
              scale: boxScale,
              duration: Duration(milliseconds: 500),
              curve: Curves.elasticOut,
              child: Container(
                padding: EdgeInsets.all(15),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      blurRadius: shadowRadius,
                    ),
                  ],
                ),
                child: Text(
                  '${widget.sww.pronouncedWords}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 5,
          ),
          Text(
            '${widget.label}: $startTime to $endTime',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatBubbleFocused extends StatefulWidget {
  final Transcription transcription;
  final SpeakerWithWords sww;

  const ChatBubbleFocused({
    required this.transcription,
    required this.sww,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatBubbleFocused> createState() => _ChatBubbleFocusedState();
}

class _ChatBubbleFocusedState extends State<ChatBubbleFocused> with SingleTickerProviderStateMixin {
  TextEditingController _controller = TextEditingController(text: 'Hello there!');
  List<Word> initialWords = [];
  String textValue = '';
  String initialText = '';
  bool isSaved = true;

  late AnimationController animController;
  late Animation<double> animation;

  @override
  void initState() {
    initialWords = getWords(widget.transcription, widget.sww.startTime, widget.sww.endTime);
    initialText = getInitialValue(initialWords);
    textValue = initialText;
    _controller = TextEditingController(text: initialText);

    super.initState();
    animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    animation = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: animController,
        curve: Curves.easeInOut,
      ),
    )..addListener(() {
        setState(() {});
      });
    animController.forward();
  }

  void closePanel() {
    animation.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        Navigator.pop(context);
      }
    });
    animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => closePanel(),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black38.withOpacity(0.7 * (1 - animation.value)),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.2,
              child: Transform.translate(
                offset: Offset(0, MediaQuery.of(context).size.height * animation.value),
                child: Container(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(15),
                        margin: EdgeInsets.all(15),
                        width: MediaQuery.of(context).size.width - 30,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondaryContainer,
                              blurRadius: shadowRadius,
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 10,
                          onChanged: (value) {
                            setState(() {
                              textValue = value;
                              isSaved = false;
                            });
                          },
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                width: 2,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      CupertinoActionSheet(
                        actions: [
                          CupertinoActionSheetAction(
                            onPressed: () {},
                            child: Text(
                              'Save',
                              style: TextStyle(
                                color: SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        ],
                        cancelButton: CupertinoActionSheetAction(
                          onPressed: () => closePanel(),
                          isDestructiveAction: true,
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
