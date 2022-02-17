import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/record/recordPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/src/provider.dart';

class RecordPageMobile extends StatefulWidget {
  const RecordPageMobile({Key? key}) : super(key: key);

  @override
  State<RecordPageMobile> createState() => _RecordPageMobileState();
}

class _RecordPageMobileState extends State<RecordPageMobile> {
  @override
  void initState() {
    Stripe.instance.isApplePaySupported.addListener(update);
    super.initState();
  }

  @override
  void dispose() {
    Stripe.instance.isApplePaySupported.removeListener(update);
    super.dispose();
  }

  void update() {
    setState(() {});
  }

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
          Container(
            padding: EdgeInsets.all(25),
            child: Center(
              child: Text(
                'Recording in app will come soon...',
                style: Theme.of(context).textTheme.headline2,
              ),
            ),
          ),
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
                      onTap: () async {
                        if (await checkUploadPermission()) {
                          uploadRecordingDialog();
                        } else {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => OkAlert(
                                title: 'Missing permission',
                                text:
                                    'You need to give permission to use local storage. Without this Speak won\'t be able to access the audio you want transcribed.'),
                          );
                        }
                      },
                      child: StandardButton(
                        text: 'Upload recording',
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 25,
                  ),
                  /*Center(
                    child: InkWell(
                      onTap: () async {
                        void paySuccess() {
                          print('Success!');
                        }

                        void payFailed() {
                          print('Failed!');
                        }

                        initPayment(
                          context,
                          email: context.read<AuthAppProvider>().email,
                          product: stProduct,
                          periods: Periods(
                              total: 1,
                              periods: 1,
                              freeLeft: 0,
                              freeUsed: false),
                          paySuccess: paySuccess,
                          payFailed: payFailed,
                        );
                      },
                      child: StandardButton(
                        text: 'Test payment',
                      ),
                    ),
                  ),*/
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<bool> checkUploadPermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      var askResult = await Permission.storage.request();
      if (askResult.isGranted) {
        return true;
      } else {
        return false;
      }
    } else if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  void uploadRecordingDialog() {
    Periods periods =
        Periods(total: 0, periods: 0, freeLeft: 0, freeUsed: false);
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
    bool isPayProcessing = false;

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
                                onTap: () async {
                                  periods = await pickFile(
                                      resetState,
                                      setSheetState,
                                      context
                                          .read<DataStoreAppProvider>()
                                          .userData,
                                      context);
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
                              TextFormField(
                                focusNode: titleFocusNode,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: (textValue) {
                                  if (textValue!.length > 16) {
                                    return 'Title can\'t be more than 16 characters';
                                  } else if (textValue.length == 0) {
                                    return 'This field is mandatory';
                                  } else {
                                    return null;
                                  }
                                },
                                decoration: InputDecoration(
                                  labelText: 'Title',
                                  labelStyle:
                                      Theme.of(context).textTheme.headline3,
                                ),
                                onChanged: (textValue) {
                                  var text = textValue;
                                  if (text.length > 16) {
                                    text = textValue.substring(0, 16);
                                  }
                                  setSheetState(() {
                                    title = text;
                                  });
                                },
                              ),
                              StandardFormField(
                                focusNode: descFocusNode,
                                label: 'Description',
                                onChanged: (textValue) {
                                  setState(() {
                                    description = textValue;
                                  });
                                },
                                changeColor: false,
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
                                            fileName != null ||
                                        formKey.currentState!.validate() &&
                                            filePicked) {
                                      pageController.animateToPage(1,
                                          duration: Duration(milliseconds: 200),
                                          curve: Curves.easeIn);
                                    } else if (fileName == null ||
                                        !filePicked) {
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
                    child: ListView(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      children: [
                        Text(
                          'Checkout',
                          style: Theme.of(context).textTheme.headline5,
                        ),
                        SizedBox(
                          height: 40,
                        ),
                        CheckoutPage(
                          product: stProduct,
                          periods: periods,
                        ),
                        SizedBox(
                          height: 25,
                        ),
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
                                onTap: () async {
                                  bool payed = false;
                                  void paySuccess() async {
                                    print('Payment successful');
                                    await DataStoreAppProvider().updateUserData(
                                        periods.freeLeft,
                                        context.read<AuthAppProvider>().email);
                                    uploadRecording(clearFilePicker);
                                    setSheetState(() {
                                      isPayProcessing = false;
                                    });
                                    Navigator.pop(context);
                                  }

                                  void payFailed() {
                                    setSheetState(() {
                                      isPayProcessing = false;
                                    });
                                  }

                                  if (context
                                          .read<AuthAppProvider>()
                                          .userGroup ==
                                      'dev') {
                                    setSheetState(() {
                                      isPayProcessing = true;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Payment completed!')),
                                    );
                                    paySuccess();
                                  } else {
                                    setSheetState(() {
                                      isPayProcessing = true;
                                    });
                                    await initPayment(
                                      context,
                                      email:
                                          context.read<AuthAppProvider>().email,
                                      product: stProduct,
                                      periods: periods,
                                      paySuccess: paySuccess,
                                      payFailed: payFailed,
                                    );
                                  }
                                },
                                child: LoadingButton(
                                  text: 'Pay',
                                  isLoading: isPayProcessing,
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
