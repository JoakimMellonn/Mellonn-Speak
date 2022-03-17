import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mellonnSpeak/pages/home/homePageMobile.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/record/recordPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/src/provider.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

int payFailedInt = 0;
bool subscriptionStarted = false;
ProductDetails productDetails = ProductDetails(
  id: '',
  title: '',
  description: '',
  price: '',
  rawPrice: 0,
  currencyCode: '',
);
String discountText = '';

class RecordPageMobile extends StatefulWidget {
  final Function(int) homePageSetPage;
  final Function(bool) homePageSetState;
  const RecordPageMobile(
      {required this.homePageSetPage, required this.homePageSetState, Key? key})
      : super(key: key);

  @override
  State<RecordPageMobile> createState() => _RecordPageMobileState();
}

class _RecordPageMobileState extends State<RecordPageMobile> {
  void update() {
    setState(() {});
  }

  Future<void> initializeIAP(PurchaseType type, int totalPeriods,
      Function() paySuccess, Function() payFailed) async {
    bool _available = await iap.isAvailable();
    if (_available) {
      await getProductsIAP(
          totalPeriods, context.read<AuthAppProvider>().userGroup);

      subscriptionIAP = iap.purchaseStream.listen(
        (data) => setState(
          () async {
            if (data.length > 0) {
              print(
                  'NEW PURCHASE, length: ${data.length}, status: ${data.last.status}');
            } else {
              print('No element');
            }
            purchasesIAP.addAll(data);
            String status = await verifyPurchase(
                type == PurchaseType.standard ? standardIAP : benefitIAP);

            if (status == 'purchased') {
              purchasesIAP = [];
              subscriptionIAP.cancel();
              paySuccess();
            } else if (status == 'error' || status == 'canceled') {
              purchasesIAP = [];
              subscriptionIAP.cancel();
              payFailed();
            }
          },
        ),
      );
    }
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
            color: Theme.of(context).colorScheme.secondaryContainer,
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
                        if (productsIAP.isEmpty) {
                          productsIAP = await getAllProductsIAP();
                        }
                        if (await checkUploadPermission()) {
                          setState(() {
                            uploadActive = true;
                          });
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
    String userGroup = context.read<AuthAppProvider>().userGroup;
    Periods periods =
        Periods(total: 0, periods: 0, freeLeft: 0, freeUsed: false);
    PageController pageController = PageController(
      initialPage: 0,
      keepPage: true,
    );
    final formKey = GlobalKey<FormState>();
    widget.homePageSetState(true);
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
                                  UserData ud = context
                                      .read<DataStoreAppProvider>()
                                      .userData;
                                  ud.freePeriods = context
                                      .read<AuthAppProvider>()
                                      .freePeriods;
                                  periods = await pickFile(
                                    resetState,
                                    setSheetState,
                                    ud,
                                    context,
                                    userGroup,
                                  );
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
                                  fileName == null
                                      ? 'Chosen file: None'
                                      : 'Chosen file: $fileName',
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
                                      Theme.of(context).textTheme.headline6,
                                ),
                                maxLength: 16,
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
                                textStyle:
                                    Theme.of(context).textTheme.headline6,
                                selectedTextStyle: Theme.of(context)
                                    .textTheme
                                    .headline5!
                                    .copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
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
                                            widget.homePageSetState(false);
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
                                      widget.homePageSetState(false);
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
                                  onTap: () async {
                                    if (formKey.currentState!.validate() &&
                                            fileName != null ||
                                        formKey.currentState!.validate() &&
                                            filePicked) {
                                      pageController.animateToPage(
                                        1,
                                        duration: Duration(milliseconds: 200),
                                        curve: Curves.easeIn,
                                      );
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
                          periods: periods,
                          productDetails: productDetails,
                          discountText: discountText,
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
                                  if (isPayProcessing == false) {
                                    void paySuccess() async {
                                      print('Payment successful');
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Started upload!'),
                                        ),
                                      );
                                      await DataStoreAppProvider()
                                          .updateUserData(
                                        periods.freeLeft,
                                        context.read<AuthAppProvider>().email,
                                      );
                                      await uploadRecording(clearFilePicker);
                                      await context
                                          .read<AuthAppProvider>()
                                          .getUserAttributes();
                                      isPayProcessing = false;
                                      widget.homePageSetState(false);
                                      Navigator.pop(context);
                                      widget.homePageSetPage(0);
                                    }

                                    void payFailed() {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text('Payment failed!'),
                                        ),
                                      );
                                      setSheetState(() {
                                        isPayProcessing = false;
                                      });
                                    }

                                    if (userGroup == 'dev' ||
                                        periods.periods == 0) {
                                      setSheetState(() {
                                        isPayProcessing = true;
                                      });
                                      paySuccess();
                                    } else {
                                      setSheetState(() {
                                        isPayProcessing = true;
                                      });

                                      await initializeIAP(
                                        userGroup == 'benefit'
                                            ? PurchaseType.benefit
                                            : PurchaseType.standard,
                                        periods.periods,
                                        paySuccess,
                                        payFailed,
                                      );

                                      late ProductDetails productIAP;

                                      if (userGroup == 'benefit') {
                                        for (var prod in productsIAP) {
                                          if (prod.id == benefitIAP) {
                                            productIAP = prod;
                                          }
                                        }
                                      } else {
                                        for (var prod in productsIAP) {
                                          if (prod.id == standardIAP) {
                                            productIAP = prod;
                                          }
                                        }
                                      }

                                      buyProduct(productIAP);
                                    }
                                  }
                                },
                                child: LoadingButton(
                                  text:
                                      periods.periods == 0 || userGroup == 'dev'
                                          ? 'Upload'
                                          : 'Pay',
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
