import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/pages/home/record/recordPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/src/provider.dart';

//Variables
String title = '';
String description = '';
int speakerCount = 2;
TemporalDateTime? date = TemporalDateTime.now();
bool uploadActive = false;
String languageCode = '';

//File Picker Variables
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
String? fileName = 'None';
FilePickerResult? result;
FileType pickingType = FileType.any;
String filePath = '';
//Variables to AWS Storage
File? file;
String key = '';
String fileType = '';
bool filePicked = false;

//Price variables (EXTREMELY IMPORTANT)
double pricePerQ = 50.0; //DKK

class RecordPageMobile extends StatefulWidget {
  const RecordPageMobile({Key? key}) : super(key: key);

  @override
  State<RecordPageMobile> createState() => _RecordPageMobileState();
}

class _RecordPageMobileState extends State<RecordPageMobile> {
  @override
  Widget build(BuildContext context) {
    String pageTitle = 'Record or\nUpload\nYour Recording';
    if (uploadActive) {
      pageTitle = 'Upload\nYour Recording';
    }
    return Container(
      margin: EdgeInsets.only(top: 5),
      padding: EdgeInsets.all(25),
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: colorSchemeLight.primary,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.secondaryVariant,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            pageTitle,
            style: Theme.of(context).textTheme.headline1,
          ),
          Spacer(),
          Center(
            child: StandardBox(
              width: MediaQuery.of(context).size.width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Already have a recording?',
                    style: Theme.of(context).textTheme.headline6,
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Center(
                    child: InkWell(
                      onTap: () {
                        uploadRecordingDialog();
                      },
                      child: StandardButton(
                        text: 'Upload recording',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
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

    showBottomSheet(
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
                  StandardBox(
                    margin: EdgeInsets.all(25),
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
                                  pickFile(resetState, setSheetState);
                                },
                                child: StandardButton(
                                  text: 'Select Audio File',
                                ),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Align(
                                alignment: Alignment.topCenter,
                                child: Text(
                                  'Chosen file: $fileName',
                                  style: Theme.of(context).textTheme.bodyText2,
                                ),
                              ),
                              StandardFormField(
                                focusNode: titleFocusNode,
                                onChanged: (textValue) {
                                  setSheetState(() {
                                    title = textValue;
                                  });
                                },
                              ),
                              StandardFormField(
                                focusNode: descFocusNode,
                                onChanged: (textValue) {
                                  setState(() {
                                    description = textValue;
                                  });
                                },
                              ),
                              SizedBox(
                                height: 10,
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
                                child: LanguagePicker(
                                  standardValue: dropdownValue,
                                  languageList: languageList,
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
                                  child: Container(
                                    height: 50,
                                    child: Center(
                                      child: Text(
                                        'Cancel',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline6,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    if (filePicked) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            SureDialog(
                                          text:
                                              'Are you sure you want to cancel this upload?',
                                          onYes: () {
                                            title = '';
                                            description = '';
                                            clearFilePicker();
                                            setState(() {
                                              uploadActive = false;
                                            });
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                          },
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        uploadActive = false;
                                      });
                                      Navigator.pop(context);
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: InkWell(
                                  child: StandardButton(
                                    text: 'Next',
                                  ),
                                  onTap: () {
                                    if (formKey.currentState!.validate() &&
                                        fileName != null) {
                                      pageController.animateToPage(1,
                                          duration: Duration(milliseconds: 200),
                                          curve: Curves.easeIn);
                                    } else if (fileName == null) {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) =>
                                            OkAlert(
                                          title:
                                              'You need to upload an audio file',
                                          text:
                                              'You need to upload an audio file',
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  StandardBox(
                    margin: EdgeInsets.all(25),
                    child: Column(
                      children: [
                        Text(
                          'Payment page, coming soon',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        Spacer(),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
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
                                      style:
                                          Theme.of(context).textTheme.bodyText2,
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
                                onTap: () {
                                  uploadRecording(clearFilePicker);
                                  Navigator.pop(context);
                                },
                                child: StandardButton(
                                  text: 'Pay',
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
            );
          },
        );
      },
    );
  }

  void clearFilePicker() {
    resetState();
    fileName = 'None';
    context.read<StorageProvider>().setFileName('$fileName');
  }

  void resetState() {
    if (!mounted) {
      return;
    }
    setState(() {
      fileName = null;
      filePicked = false;
    });
  }
}
