import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionParsing.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';
import 'transcriptionTextEditProvider.dart';

Transcription widgetTranscription = Transcription(
  jobName: '',
  accountId: '',
  results: Results(
    transcripts: <Transcript>[],
    speakerLabels: SpeakerLabels(
      speakers: 0,
      segments: <Segment>[],
    ),
    items: <Item>[],
  ),
  status: '',
);
String textValue = '';
bool isSaved = true;
bool initialized = false;

class TranscriptionTextEditPage extends StatefulWidget {
  final String recordingName;
  final String id;
  final double startTime;
  final double endTime;
  final String audioFileKey;
  final Transcription transcription;

  const TranscriptionTextEditPage({
    Key? key,
    required this.recordingName,
    required this.id,
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
  TextEditingController _controller =
      TextEditingController(text: 'Hello there!');
  List<Word> initialWords = [];
  String initialText = '';

  @override
  void initState() {
    _pageManager = PageManager(
      startTime: widget.startTime,
      endTime: widget.endTime,
      audioFilePath: widget.audioFileKey,
    );
    if (!initialized) {
      widgetTranscription = widget.transcription;
    }

    initialWords =
        getWords(widget.transcription, widget.startTime, widget.endTime);
    initialText = getInitialValue(initialWords);
    textValue = initialText;
    _controller = TextEditingController(text: initialText);
    super.initState();
  }

  ///
  ///This function takes a transcription element and calls the backend to save it to the cloud
  ///It should return true or false, if it succeeds or not, but i havent implemented that yet.
  ///It creates a snackbar saying wheter it succeeded or not.
  ///
  Future<void> saveEdit(Transcription transcription) async {
    List<Word> newList = createWordListFromString(initialWords, textValue);
    Transcription widgetTranscription =
        wordListToTranscription(transcription, newList);

    bool hasUploaded = await context
        .read<StorageProvider>()
        .saveTranscription(widgetTranscription, widget.id);

    if (hasUploaded) {
      final snackBar = SnackBar(
        content: const Text('Transcription saved!'),
      );
      isSaved = true;
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      final snackBar = SnackBar(
        backgroundColor: Theme.of(context).colorScheme.error,
        content: const Text('Something went wrong :('),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  void testSave() {
    List<Word> newList = createWordListFromString(initialWords, textValue);

    print('Saved list: ');
    newList.forEach((element) {
      print(
          'Word: ${element.word}, start: ${element.startTime}, end: ${element.endTime}, type: ${element.pronounciation}');
    });
  }

  @override
  Widget build(BuildContext context) {
    int maxLines = 10;
    if (MediaQuery.of(context).size.height < 800) maxLines = 6;
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
              ),
              child: TitleBox(
                title: widget.recordingName,
                extras: true,
                color: Theme.of(context).colorScheme.surface,
                onBack: () {
                  if (isSaved) {
                    Navigator.pop(context);
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => AlertDialog(
                        title: Text('Do you want to save before exiting?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () async {
                              await saveEdit(widgetTranscription);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('Yes'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                extra: IconButton(
                  onPressed: () async {
                    await saveEdit(widget.transcription);
                    //testSave();
                  },
                  icon: Icon(
                    FontAwesomeIcons.solidSave,
                    color: context.read<ColorProvider>().darkText,
                  ),
                ),
              ),
            ),

            ///
            ///Main page content
            ///
            SingleChildScrollView(
              child: Column(
                children: [
                  ///
                  ///Media controller
                  ///
                  StandardBox(
                    margin: EdgeInsets.all(25),
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

                  ///
                  ///Editing box
                  ///
                  StandardBox(
                    margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                    width: MediaQuery.of(context).size.width,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Edit the text here',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        TextField(
                          controller: _controller,
                          maxLines: maxLines,
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
                      ],
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
