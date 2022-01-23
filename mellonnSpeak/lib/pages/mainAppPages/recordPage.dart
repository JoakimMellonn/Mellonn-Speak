import 'package:amplify_datastore/amplify_datastore.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({Key? key}) : super(key: key);

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  //Variables
  String title = '';
  String description = '';
  int speakerCount = 2;
  TemporalDate? date = TemporalDate.now();
  bool uploadActive = false;
  String languageCode = '';

  //File Picker Variables
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  String? _fileName;
  String? _saveAsFileName;
  List<PlatformFile>? _paths;
  FilePickerResult? result;
  String? _directoryPath;
  bool _isLoading = false;
  bool _userAborted = false;
  bool _hasPicked = false;
  FileType _pickingType = FileType.any;
  String _filePath = '';
  //Variables to AWS Storage
  File? file;
  String key = '';
  String fileType = '';

  //Price variables (EXTREMELY IMPORTANT)
  double pricePerQ = 50.0; //DKK

  @override
  void initState() {
    super.initState();
  }

  /*
  * This function first creates a new element in datastore
  * Then it gets the ID of that element
  * After that it uploads the selected file with the ID as the key (fancy word for filename)
  */
  void uploadRecording() async {
    print(
        'Uploading recording with title: $title, path: $_filePath, description: $description and date: $date...');
    Recording newRecording = Recording(
      name: title,
      description: description,
      date: date,
      fileKey: key,
      fileName: _fileName,
      speakerCount: speakerCount,
      languageCode: languageCode,
    );
    //Creates a new element in DataStore
    await Amplify.DataStore.save(newRecording);
    String recordingID = await dataID(title); //Gets the ID
    fileType =
        key.split('.').last.toString(); //Gets the filetype of the selected file
    String newFileKey =
        '$recordingID.$fileType'; //Creates the filekey from ID and filetype
    //Updates the element with the filekey
    Recording updatedRecording = newRecording.copyWith(
      id: recordingID,
      fileKey: newFileKey,
    );
    try {
      await Amplify.DataStore.save(updatedRecording); //saves it
      print('Saved the new filekey with: ${updatedRecording.fileKey}');
    } catch (e) {
      print(e);
    }
    clearFilePicker(); //clears the filepicker, doesn't work tho...

    //Saves the audio file in the app directory, so it doesn't have to be downloaded every time.
    final docDir = await getApplicationDocumentsDirectory();
    final localFilePath = docDir.path + '/$key';
    await File(_filePath).copy(localFilePath);

    //Uploads the selected file with the filekey
    context.read<StorageProvider>().uploadFile(
        File(localFilePath), result, newFileKey, title, description);
  }

  Future<void> getAudioDuration(String path) async {
    final player = AudioPlayer();
    var duration = await player.setFilePath(path);
    List<String> durationSplit = duration.toString().split(':');
    double hours = double.parse(durationSplit[0]);
    double minutes = double.parse(durationSplit[1]);
    double seconds = double.parse(durationSplit[2]);
    double totalSeconds = 3600 * hours + 60 * minutes + seconds;
    print(
        'Hours: $hours, minutes: $minutes, seconds: $seconds, totalSeconds: $totalSeconds');
    print('Price: ${getPrice(totalSeconds)}DKK');
  }

  double getPrice(double seconds) {
    double minutes = seconds / 60;
    double qPeriods = minutes.round() / 15;
    int periods = qPeriods.ceil();
    if (context.read<AuthAppProvider>().userGroup == "benefit") {
      pricePerQ = 40.0;
    } else if (context.read<AuthAppProvider>().userGroup == "dev") {
      pricePerQ = 0.0;
    }
    double price = pricePerQ * periods;
    return price;
  }

  /*
  * This function gets the ID of the element in DataStore and returns it as a String
  */
  Future<String> dataID(String name) async {
    List<Recording> _recordings = [];

    //Gets a list of recordings
    try {
      _recordings = await Amplify.DataStore.query(Recording.classType);
    } on DataStoreException catch (e) {
      print('Query failed: $e');
    }

    //Checks if the recording name is equal to the given name and returns the ID if true
    for (Recording recording in _recordings) {
      if (recording.name == name) {
        return recording.id;
      }
    }
    //Returns nothing if nothing
    return '';
  }

  /*
  * Yeah this doesn't work...
  */
  void clearFilePicker() {
    _resetState();
    _fileName = 'None';
    context.read<StorageProvider>().setFileName('$_fileName');
  }

  /*
  * This function opens the filepicker and let's the user pick an audio file (not audiophile, that would be human trafficing)
  */
  void _pickFile() async {
    _resetState(); //Resets all variables to ZERO (not actually but it sounds cool)
    try {
      _directoryPath = null;
      result = await FilePicker.platform.pickFiles(
          type:
              _pickingType); //Opens the file picker, and only shows audio files

      /*
      * Checks if the result isn't null, which means the user actually picked something, HURRAY!
      */
      if (result != null) {
        //Defines all the necessary variables, and some that isn't but f**k that
        final platformFile = result!.files.single;
        final path = platformFile.path!;
        _filePath = path;
        _fileName = platformFile.name;
        key = '${platformFile.name}';
        key = key.replaceAll(' ', '');
        file = File(path);
        await getAudioDuration(path);
        context.read<StorageProvider>().setFileName('$_fileName');
      }
    } on PlatformException catch (e) {
      //If error return error message
      _logException('Unsupported operation' + e.toString());
      _hasPicked = false;
    } catch (e) {
      _logException(e.toString());
      _hasPicked = false;
    }

    /*
    * This does something, i know that...
    * But i snatched the code from somewhere :|
    */
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _userAborted = _paths == null;
      _hasPicked = true;
      print('File name: $_fileName');
    });
  }

  /*
  * I snatched this too... But I don't think this has to do with wood logs
  */
  void _logException(String message) {
    print(message);
    _scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        //I like snacks tho
        content: Text(message),
      ),
    );
  }

  /*
  * Resets all variables to ZERO (still sounds cool)
  */
  void _resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = true;
      _directoryPath = null;
      _fileName = null;
      _paths = null;
      _saveAsFileName = null;
      _userAborted = false;
      _hasPicked = false;
    });
  }

  void uploadRecordingDialog() {
    PageController pageController = PageController(
      initialPage: 0,
      keepPage: true,
    );
    final formKey = GlobalKey<FormState>();
    setState(() {
      uploadActive = true;
    });
    List<String> languageList = context.read<LanguageProvider>().languageList;
    List<String> languageCodeList =
        context.read<LanguageProvider>().languageCodeList;
    String dropdownValue = context.read<LanguageProvider>().defaultLanguage;
    languageCode = context.read<LanguageProvider>().defaultLanguageCode;

    FocusNode titleFocusNode = FocusNode();
    FocusNode descFocusNode = FocusNode();

    showBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white.withOpacity(0),
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.62,
              minHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: pageController,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  margin: EdgeInsets.all(25),
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
                  padding: EdgeInsets.all(25),
                  child: Form(
                    key: formKey,
                    child: ListView(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      children: [
                        Column(
                          children: [
                            InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () {
                                _pickFile();
                              },
                              child: Expanded(
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryVariant,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Select Audio File',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                        fontSize: 21,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: context
                                                .watch<ColorProvider>()
                                                .shadow,
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            //Shows the name of the chosen file
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                'Chosen file: $_fileName',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 15,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryVariant,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            //This is where the user can give the recording a title and description below
                            TextFormField(
                              focusNode: titleFocusNode,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (textValue) {
                                if (textValue == '') {
                                  return 'This field is mandatory';
                                }
                              },
                              onChanged: (textValue) {
                                setSheetState(() {
                                  title = textValue;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Title',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: titleFocusNode.hasFocus
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                                  fontSize: 15,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryVariant,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextFormField(
                              focusNode: descFocusNode,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              validator: (textValue) {
                                if (textValue == '') {
                                  return 'This field is mandatory';
                                }
                              },
                              onChanged: (textValue) {
                                setState(() {
                                  description = textValue;
                                });
                              },
                              decoration: InputDecoration(
                                labelText: 'Description',
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: descFocusNode.hasFocus
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                                  fontSize: 15,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryVariant,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: Text(
                                "Please choose number of participants and language",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  fontSize: 12,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryVariant,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            NumberPicker(
                              value: speakerCount,
                              minValue: 1,
                              maxValue: 10,
                              axis: Axis.horizontal,
                              onChanged: (value) => setSheetState(() {
                                speakerCount = value;
                              }),
                            ),
                            Align(
                              alignment: Alignment.topCenter,
                              child: DropdownButton(
                                value: dropdownValue,
                                items: languageList
                                    .map<DropdownMenuItem<String>>(
                                        (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 15,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryVariant,
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setSheetState(() {
                                    dropdownValue = newValue!;
                                  });
                                  setState(() {
                                    int currentIndex =
                                        languageList.indexOf(dropdownValue);
                                    languageCode =
                                        languageCodeList[currentIndex];
                                  });
                                  print(
                                      'Current language and code: $dropdownValue, $languageCode');
                                },
                                icon: Icon(
                                  Icons.arrow_downward,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                elevation: 16,
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryVariant,
                                      blurRadius: 1,
                                    ),
                                  ],
                                ),
                                underline: Container(
                                  height: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  if (_fileName == 'None' ||
                                      _fileName == 'null') {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                        title: Text('Are you sure?!'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, 'No'),
                                            child: const Text('No'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              title = '';
                                              description = '';
                                              clearFilePicker();
                                              setState(() {
                                                uploadActive = false;
                                              });
                                              Navigator.pop(context);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      uploadActive = false;
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  child: Center(
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 21,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: context
                                                .watch<ColorProvider>()
                                                .shadow,
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () {
                                  if (formKey.currentState!.validate() &&
                                      _fileName != null) {
                                    pageController.animateToPage(1,
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeIn);
                                  } else if (_fileName == null) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) =>
                                          AlertDialog(
                                        title: Text(
                                            'You need to upload an audio file'),
                                        actions: <Widget>[
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, 'OK'),
                                              child: const Text('OK'))
                                        ],
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: context
                                            .watch<ColorProvider>()
                                            .shadow,
                                        blurRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Next',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context
                                            .watch<ColorProvider>()
                                            .darkText,
                                        fontSize: 21,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: context
                                                .watch<ColorProvider>()
                                                .shadow,
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                PaymentDialog(context, pageController),
              ],
            ),
          );
        });
      },
    );
  }

  Container PaymentDialog(BuildContext context, PageController pageController) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.all(25),
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
      padding: EdgeInsets.all(25),
      child: Column(
        children: [
          Text('Page 2'), //TODO: Create price/payment page
          Spacer(),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    pageController.animateToPage(
                      0,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeIn,
                    );
                  },
                  child: Container(
                    height: 50,
                    child: Center(
                      child: Text(
                        'Back',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 21,
                          shadows: <Shadow>[
                            Shadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryVariant,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              Expanded(
                child: InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    uploadRecording();
                    Navigator.pop(context);
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onSurface,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Pay',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondary,
                          fontSize: 21,
                          shadows: <Shadow>[
                            Shadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryVariant,
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double titleWidth() {
    if (uploadActive) {
      return MediaQuery.of(context).size.width * 0.41;
    } else {
      return MediaQuery.of(context).size.width * 0.55;
    }
  }

  /*
  * Building the recordPage
  */
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        //This is the whole page, because it all is an orange box (good design)
        Expanded(
          child: Container(
            padding: EdgeInsets.all(25),
            constraints: BoxConstraints(
              //minHeight: MediaQuery.of(context).size.height,
              maxHeight: double.infinity,
              minWidth: MediaQuery.of(context).size.width,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              color: Color(0xFFFAB228),
            ),
            child: Column(
              children: [
                //Creating the title of the page
                Container(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: titleWidth(),
                    child: FittedBox(
                      child: RecordTitle(
                        uploadActive: uploadActive,
                      ),
                    ),
                  ),
                ),
                //Magic spacing...
                Spacer(),
                //The box in which the user can choose to record or upload audio (only upload for now...)
                Container(
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.fromLTRB(25, 50, 25, 25),
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.305,
                    maxHeight: double.infinity,
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
                  child: Column(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        alignment: Alignment.topLeft,
                        child: FittedBox(
                          child: Text(
                            'Already have a recording?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 21,
                              shadows: <Shadow>[
                                Shadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryVariant,
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      //Magic spacing...
                      SizedBox(
                        height: 20,
                      ),
                      //Button for uploading the audio, if the user already have recorded it
                      InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          uploadRecordingDialog();
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryVariant,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Upload Audio',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                fontSize: 21,
                                shadows: <Shadow>[
                                  Shadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryVariant,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class RecordTitle extends StatefulWidget {
  final bool uploadActive;

  const RecordTitle({Key? key, required this.uploadActive}) : super(key: key);

  @override
  _RecordTitleState createState() => _RecordTitleState();
}

class _RecordTitleState extends State<RecordTitle> {
  @override
  Widget build(BuildContext context) {
    if (!widget.uploadActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Record or',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          Text(
            'Upload',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          Text(
            'Audio',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
          Text(
            'Audio',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSecondary,
              shadows: <Shadow>[
                Shadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
          ),
        ],
      );
    }
  }
}
