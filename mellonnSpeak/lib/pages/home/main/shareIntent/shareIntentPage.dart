import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mellonnSpeak/pages/home/main/mainPage.dart';
import 'package:mellonnSpeak/pages/home/main/mainPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
  final PageController controller = PageController();
  final titleFormKey = GlobalKey<FormState>();
  final descFormKey = GlobalKey<FormState>();
  bool initiated = false;

  //Navigation stuff
  String backText = 'Cancel';
  String nextText = 'Next';
  Duration animDuration = Duration(milliseconds: 250);
  Curve animCurve = Curves.easeInOut;

  bool isLoading = true;
  bool isCheckout = false;
  bool isPayProcessing = false;

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

  //Variables for creating a recording
  PickedFile? pickedFile;
  bool filePicked = false;
  double duration = 0; //Seconds
  String pickedPath = '', fileName = '', title = '', description = '', languageCode = '';
  int speakerCount = 2;
  String dropdownValue = '';
  File file = File('');

  Future initialize() async {
    while (productsIAP.isEmpty) {
      productsIAP = await getAllProductsIAP();
    }
    file = new File(await createTempFile(widget.files.first.path));
    fileName = file.path.split('/').last;

    seconds = await getAudioDuration(file.path);
    isLoading = false;
  }

  @override
  void dispose() {
    deleteTempFile(file.path);
    pickedFile = null;
    filePicked = false;
    duration = 0;
    pickedPath = '';
    fileName = '';
    title = '';
    description = '';
    languageCode = '';
    speakerCount = 2;
    super.dispose();
  }

  void nextClicked() async {
    int currentPage = controller.page!.round();
    if (currentPage == 0) {
      setState(() {
        backText = 'Back';
      });
      if (titleFormKey.currentState!.validate()) {
        controller.animateToPage(1, duration: animDuration, curve: animCurve);
      }
    } else if (currentPage == 1) {
      if (descFormKey.currentState!.validate()) {
        controller.animateToPage(2, duration: animDuration, curve: animCurve);
      }
    } else if (currentPage == 2) {
      controller.animateToPage(3, duration: animDuration, curve: animCurve);
    } else if (currentPage == 3) {
      setState(() {
        isCheckout = true;
        nextText = 'Pay';
      });
      controller.animateToPage(4, duration: animDuration, curve: animCurve);
    } else if (currentPage == 4) {
      if (!isPayProcessing) {
        void paySuccess() async {
          print('Payment successful');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Started upload!'),
            ),
          );
          await DataStoreAppProvider().updateUserData(
            pickedFile!.periods!.freeLeft,
            context.read<AuthAppProvider>().email,
          );
          await uploadRecording(title, description, languageCode, speakerCount, pickedFile!);
          await context.read<AuthAppProvider>().getUserAttributes();
          setState(() {
            isPayProcessing = false;
          });
          showDialog(
            context: context,
            builder: (BuildContext context) => OkAlert(
              title: 'Recording uploaded',
              text:
                  'Estimated time for completion: ${estimatedTime(pickedFile!.periods!.total)}.\nThis is only an estimate, it can take up to 2 hours. If it takes longer, please report an issue on the profile page.',
            ),
          );
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
            return MainPage();
          }));
        }

        void payFailed() {
          showDialog(
            context: context,
            builder: (BuildContext context) => OkAlert(
              title: 'Payment failed!',
              text: 'Something went wrong during payment, please try again.',
            ),
          );
          setState(() {
            isPayProcessing = false;
          });
        }

        if (context.read<AuthAppProvider>().userGroup == 'dev' || pickedFile!.periods!.periods == 0) {
          setState(() {
            isPayProcessing = true;
          });
          paySuccess();
        } else {
          setState(() {
            isPayProcessing = true;
          });

          await initializeIAP(
            context.read<AuthAppProvider>().userGroup == 'benefit' ? PurchaseType.benefit : PurchaseType.standard,
            pickedFile!.periods!.periods,
            paySuccess,
            payFailed,
          );

          late ProductDetails productIAP;

          if (context.read<AuthAppProvider>().userGroup == 'benefit') {
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
    }
  }

  void backClicked() {
    int currentPage = controller.page!.round();
    if (currentPage == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) => SureDialog(
          onYes: () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
              return MainPage();
            }));
          },
          text: 'Are you sure you want to cancel this upload?',
        ),
      );
    } else {
      if (currentPage == 1) {
        setState(() {
          backText = 'Cancel';
        });
      }
      if (currentPage == 5) {
        setState(() {
          nextText = 'Next';
          isCheckout = false;
        });
      }
      controller.animateToPage(currentPage - 1, duration: animDuration, curve: animCurve);
    }
  }

  void dialog(String title, text) {
    showDialog(
      context: context,
      builder: (BuildContext context) => OkAlert(
        title: title,
        text: text,
      ),
    );
  }

  Future<void> initializeIAP(PurchaseType type, int totalPeriods, Function() paySuccess, Function() payFailed) async {
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
              print('NEW PURCHASE, length: ${data.length}, status: ${data.last.status}');
            } else {
              print('No element');
            }
            purchasesIAP.addAll(data);
            String status = await verifyPurchase(type == PurchaseType.standard ? standardIAP : benefitIAP);

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
    String userGroup = context.read<AuthAppProvider>().userGroup;
    if (!initiated) {
      dropdownValue = context.read<LanguageProvider>().defaultLanguage;
      languageCode = context.read<LanguageProvider>().defaultLanguageCode;
      initiated = true;
    }

    return FutureBuilder(
        future: initialize(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (isLoading) {
            return LoadingScreen();
          } else {
            Periods periods = getPeriods(
              seconds,
              context.read<DataStoreAppProvider>().userData,
              userGroup,
            );
            pickedFile =
                PickedFile(file: PlatformFile(name: fileName, size: 0, path: file.path), duration: seconds, periods: periods, isError: false);

            return Scaffold(
              body: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    backgroundColor: Theme.of(context).colorScheme.background,
                    leading: appBarLeading(context),
                    pinned: true,
                    elevation: 0.5,
                    surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                    expandedHeight: 100,
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      title: Text(
                        'Upload recording',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildListDelegate([
                      StandardBox(
                        margin: EdgeInsets.all(25),
                        child: Column(
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: isCheckout ? 240 : 150,
                              ),
                              child: pages(context),
                            ),
                            SmoothPageIndicator(
                              controller: controller,
                              count: 5,
                              effect: WormEffect(
                                activeDotColor: Theme.of(context).colorScheme.primary,
                                dotWidth: 6,
                                dotHeight: 6,
                                spacing: 7,
                              ),
                            ),
                            SizedBox(
                              height: 15,
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                    onTap: backClicked,
                                    child: Container(
                                      height: 50,
                                      child: Center(
                                        child: Text(
                                          backText,
                                          style: Theme.of(context).textTheme.titleLarge,
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
                                    onTap: nextClicked,
                                    child: LoadingButton(
                                      maxWidth: 200,
                                      isLoading: isPayProcessing,
                                      text: nextText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            );
          }
        });
  }

  void clearFilePicker() {}

  ///
  ///Pages:
  ///0. Give a title.
  ///1. Give a description.
  ///2. Amount of participants.
  ///3. Language spoken.
  ///4. Payment.
  ///
  Widget pages(BuildContext context) {
    List<String> languageList = context.read<LanguageProvider>().languageList;
    List<String> languageCodeList = context.read<LanguageProvider>().languageCodeList;
    return PageView(
      physics: NeverScrollableScrollPhysics(),
      controller: controller,
      children: [
        //Title page
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Now we need a title',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Form(
              key: titleFormKey,
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
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
                  labelStyle: Theme.of(context).textTheme.titleLarge,
                ),
                maxLength: 16,
                onChanged: (textValue) {
                  var text = textValue;
                  if (text.length > 16) {
                    text = textValue.substring(0, 16);
                  }
                  setState(() {
                    title = text;
                  });
                },
              ),
            ),
          ],
        ),

        //Description page
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You'll also need a description",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Form(
              key: descFormKey,
              child: TextFormField(
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                validator: (textValue) {
                  if (textValue!.length == 0) {
                    return 'This field is mandatory';
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: Theme.of(context).textTheme.titleLarge,
                ),
                onChanged: (textValue) {
                  setState(() {
                    description = textValue;
                  });
                },
              ),
            ),
          ],
        ),

        //Speaker Count page
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many participants are there?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
              height: 20,
            ),
            NumberPicker(
              value: speakerCount,
              minValue: 1,
              maxValue: 10,
              axis: Axis.horizontal,
              textStyle: Theme.of(context).textTheme.titleLarge,
              selectedTextStyle: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
              onChanged: (value) => setState(() {
                speakerCount = value;
              }),
            ),
          ],
        ),

        //Language select page
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What language is spoken?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.topCenter,
              child: LanguagePicker(
                standardValue: dropdownValue,
                languageList: languageList,
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                    languageCode = languageCodeList[languageList.indexOf(dropdownValue)];
                  });
                },
              ),
            ),
          ],
        ),

        //Payment page
        Column(
          children: [
            CheckoutPage(
              periods: pickedFile!.periods!,
            ),
          ],
        ),
      ],
    );
  }
}
