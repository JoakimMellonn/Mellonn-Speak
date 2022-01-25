import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:provider/src/provider.dart';
import '../transcriptionTextEditProvider.dart';

class TranscriptionTextEditPage extends StatefulWidget {
  final String recordingName;
  final double startTime;
  final double endTime;
  final String audioFileKey;
  final Transcription transcription;

  const TranscriptionTextEditPage({
    Key? key,
    required this.recordingName,
    required this.startTime,
    required this.endTime,
    required this.audioFileKey,
    required this.transcription,
  }) : super(key: key);

  @override
  _TranscriptionTextEditPageState createState() =>
      _TranscriptionTextEditPageState();
}

class _TranscriptionTextEditPageState extends State<TranscriptionTextEditPage> {
  late final PageManager _pageManager;

  @override
  void initState() {
    _pageManager = PageManager(
      startTime: widget.startTime,
      endTime: widget.endTime,
      audioFilePath: widget.audioFileKey,
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.primary,
      //Creating the same appbar that is used everywhere else
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Image.asset(
            context.watch<ColorProvider>().currentLogo,
            height: 25,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: Container(
        child: Column(
          children: [
            //Making that sweet title widget (with the sexy orange background and rounded corners)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: Container(
                padding: EdgeInsets.all(25),
                width: MediaQuery.of(context).size.width,
                constraints: BoxConstraints(
                  minHeight: 100,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                constraints: BoxConstraints(
                                  maxHeight: 40,
                                  minWidth:
                                      MediaQuery.of(context).size.width * 0.4,
                                ),
                                child: FittedBox(
                                  child: Row(
                                    children: [
                                      //Back button
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                        child: Icon(
                                          FontAwesomeIcons.arrowLeft,
                                          size: 15,
                                          color: context
                                              .watch<ColorProvider>()
                                              .darkText,
                                        ),
                                      ),
                                      //Magic spacing...
                                      SizedBox(
                                        width: 10,
                                      ),
                                      //Getting the recording title
                                      Text(
                                        "${widget.recordingName}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: context
                                              .watch<ColorProvider>()
                                              .darkText,
                                          shadows: <Shadow>[
                                            Shadow(
                                              color: context
                                                  .watch<ColorProvider>()
                                                  .shadow,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            ///
            ///Main page content
            ///
            Container(
              padding: EdgeInsets.all(25),
              child: Column(
                children: [
                  ///
                  ///Media controller
                  ///
                  Container(
                    padding: EdgeInsets.all(25),
                    constraints: BoxConstraints(
                      minHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ValueListenableBuilder<ProgressBarState>(
                          valueListenable: _pageManager.progressNotifier,
                          builder: (_, value, __) {
                            return ProgressBar(
                              progress: value.current,
                              buffered: value.buffered,
                              total: value.total,
                              onSeek: _pageManager.seek,
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ValueListenableBuilder(
                              valueListenable: _pageManager.buttonNotifier,
                              builder: (_, value, __) {
                                switch (value) {
                                  case ButtonState.loading:
                                    return Container(
                                      margin: const EdgeInsets.all(8.0),
                                      width: 32.0,
                                      height: 32.0,
                                      child: const CircularProgressIndicator(),
                                    );
                                  case ButtonState.paused:
                                    return IconButton(
                                      icon: const Icon(Icons.play_arrow),
                                      iconSize: 32.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      onPressed: _pageManager.play,
                                    );
                                  case ButtonState.playing:
                                    return IconButton(
                                      icon: const Icon(Icons.pause),
                                      iconSize: 32.0,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      onPressed: _pageManager.pause,
                                    );
                                }
                                return IconButton(
                                  onPressed: () {},
                                  icon: Icon(Icons.error),
                                  iconSize: 32,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    height: 25,
                  ),

                  ///
                  ///
                  ///
                  Container(
                    padding: EdgeInsets.all(25),
                    constraints: BoxConstraints(
                      minHeight: 100,
                    ),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).colorScheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
