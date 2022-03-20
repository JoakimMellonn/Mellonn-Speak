import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mellonnSpeak/pages/home/homePageMobile.dart';
import 'package:mellonnSpeak/pages/home/homePageTab.dart';
import 'package:mellonnSpeak/pages/home/record/recordPageProvider.dart' as rpp;
import 'package:mellonnSpeak/pages/home/record/shareIntent/shareIntentProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:mellonnSpeak/utilities/responsiveLayout.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

String languageCode = '';
String title = '';
String description = '';
int speakerCount = 2;
ProductDetails productDetails = ProductDetails(
  id: '',
  title: '',
  description: '',
  price: '',
  rawPrice: 0,
  currencyCode: '',
);
String discountText = '';
double seconds = 0;
String fileName = '';
File file = File('');

class ShareIntentPage extends StatefulWidget {
  final List<File> files;

  const ShareIntentPage({
    required this.files,
    Key? key,
  }) : super(key: key);

  @override
  State<ShareIntentPage> createState() => _ShareIntentPageState();
}

class _ShareIntentPageState extends State<ShareIntentPage> {
  bool isLoading = true;

  Future initialize() async {
    while (productsIAP.isEmpty) {
      productsIAP = await getAllProductsIAP();
    }
    file = widget.files.first;
    fileName = file.path.split('/').last;
    /*if (Platform.isIOS) {
      Directory docDir = await getLibraryDirectory();
      file = await file.copy('$docDir/$fileName');
    }*/
    seconds = await getSharedAudioDuration(file.path);
    isLoading = false;
  }

  Future<void> initializeIAP(PurchaseType type, int totalPeriods,
      Function() paySuccess, Function() payFailed) async {
    bool _available = await iap.isAvailable();
    if (_available) {
      if (productsIAP.isEmpty) {
        productsIAP = await getAllProductsIAP();
      }

      getProductsIAP(totalPeriods, context.read<AuthAppProvider>().userGroup);

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

  void resetState() {
    languageCode = '';
    title = '';
    description = '';
    speakerCount = 2;
    productDetails = ProductDetails(
      id: '',
      title: '',
      description: '',
      price: '',
      rawPrice: 0,
      currencyCode: '',
    );
    discountText = '';
    seconds = 0;
    fileName = '';
    file = File('');
  }

  @override
  Widget build(BuildContext context) {
    PageController pageController = PageController(
      initialPage: 0,
      keepPage: true,
    );
    final formKey = GlobalKey<FormState>();
    List<String> languageList = context.read<LanguageProvider>().languageList;
    List<String> languageCodeList =
        context.read<LanguageProvider>().languageCodeList;
    String dropdownValue = context.read<LanguageProvider>().defaultLanguage;
    languageCode = context.read<LanguageProvider>().defaultLanguageCode;
    bool isPayProcessing = false;
    String userGroup = context.read<AuthAppProvider>().userGroup;

    FocusNode titleFocusNode = FocusNode();
    FocusNode descFocusNode = FocusNode();

    return FutureBuilder(
        future: initialize(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (isLoading) {
            return LoadingScreen();
          } else {
            rpp.Periods periods = getSharedPeriods(
              seconds,
              context.read<DataStoreAppProvider>().userData,
              userGroup,
            );

            return Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.background,
                automaticallyImplyLeading: false,
                title: StandardAppBarTitle(),
                elevation: 0,
              ),
              body: Column(
                children: [
                  TitleBox(
                    title: 'Upload Recording',
                    heroString: 'shareIntent',
                    extras: true,
                    onBack: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) => SureDialog(
                          text: 'Are you sure you want to cancel this upload?',
                          onYes: () {
                            if (Platform.isIOS) {
                              ReceiveSharingIntent.reset();
                              Navigator.pop(context);
                              Navigator.pop(context);
                            } else {
                              ReceiveSharingIntent.reset();
                              exit(0);
                            }
                          },
                        ),
                      );
                    },
                  ),
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setSheetState) {
                      return Container(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                                        Align(
                                          alignment: Alignment.topCenter,
                                          child: Text(
                                            'Chosen file: $fileName',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText2,
                                          ),
                                        ),
                                        TextFormField(
                                          focusNode: titleFocusNode,
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
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
                                            labelStyle: Theme.of(context)
                                                .textTheme
                                                .headline6,
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
                                            setSheetState(() {
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
                                          textStyle: Theme.of(context)
                                              .textTheme
                                              .headline6,
                                          selectedTextStyle: Theme.of(context)
                                              .textTheme
                                              .headline5!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          onChanged: (value) =>
                                              setSheetState(() {
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
                                              setSheetState(() {
                                                int currentIndex = languageList
                                                    .indexOf(dropdownValue);
                                                languageCode = languageCodeList[
                                                    currentIndex];
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
                                            child: StandardButton(
                                              text: 'Next',
                                            ),
                                            onTap: () async {
                                              if (formKey.currentState!
                                                      .validate() ||
                                                  formKey.currentState!
                                                      .validate()) {
                                                pageController.animateToPage(
                                                  1,
                                                  duration: Duration(
                                                      milliseconds: 200),
                                                  curve: Curves.easeIn,
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
                                    style:
                                        Theme.of(context).textTheme.headline5,
                                  ),
                                  SizedBox(
                                    height: 40,
                                  ),
                                  rpp.CheckoutPage(
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
                                              duration:
                                                  Duration(milliseconds: 200),
                                              curve: Curves.easeIn,
                                            );
                                          },
                                          child: Container(
                                            height: 50,
                                            child: Center(
                                              child: Text(
                                                'Back',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText2,
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
                                                    content:
                                                        Text('Started upload!'),
                                                  ),
                                                );
                                                await DataStoreAppProvider()
                                                    .updateUserData(
                                                  periods.freeLeft,
                                                  context
                                                      .read<AuthAppProvider>()
                                                      .email,
                                                );
                                                await uploadSharedRecording(
                                                  file,
                                                  title,
                                                  description,
                                                  fileName,
                                                  speakerCount,
                                                  languageCode,
                                                );
                                                await context
                                                    .read<AuthAppProvider>()
                                                    .getUserAttributes();
                                                isPayProcessing = false;
                                                if (Platform.isIOS) {
                                                  ReceiveSharingIntent.reset();
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) {
                                                        return HomePageMobile(
                                                          initialPage: 0,
                                                        );
                                                      },
                                                    ),
                                                  );
                                                } else {
                                                  showDialog(
                                                    context: context,
                                                    builder: (BuildContext
                                                            context) =>
                                                        AlertDialog(
                                                      title: Text(
                                                        "Your recording has been uploaded",
                                                      ),
                                                      content: Text(
                                                        'You will be returned to where you came from.',
                                                      ),
                                                      actions: <Widget>[
                                                        TextButton(
                                                          onPressed: () {
                                                            ReceiveSharingIntent
                                                                .reset();
                                                            setState(() {
                                                              isLoading = false;
                                                            });
                                                            exit(0);
                                                          },
                                                          child:
                                                              const Text('OK'),
                                                        )
                                                      ],
                                                    ),
                                                  );
                                                }
                                              }

                                              void payFailed() {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    backgroundColor: Colors.red,
                                                    content:
                                                        Text('Payment failed!'),
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
                                                  for (var prod
                                                      in productsIAP) {
                                                    if (prod.id == benefitIAP) {
                                                      productIAP = prod;
                                                    }
                                                  }
                                                } else {
                                                  for (var prod
                                                      in productsIAP) {
                                                    if (prod.id ==
                                                        standardIAP) {
                                                      productIAP = prod;
                                                    }
                                                  }
                                                }

                                                buyProduct(productIAP);
                                              }
                                            }
                                          },
                                          child: LoadingButton(
                                            text: periods.periods == 0 ||
                                                    userGroup == 'dev'
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
                  ),
                ],
              ),
            );
          }
        });
  }

  void clearFilePicker() {}
}
