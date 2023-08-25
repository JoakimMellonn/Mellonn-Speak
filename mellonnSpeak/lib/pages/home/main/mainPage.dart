import 'dart:io';
import 'dart:ui';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mellonnSpeak/pages/home/main/recordingElement.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/main/mainPageProvider.dart';
import 'package:mellonnSpeak/pages/home/onboarding/onboardingPage.dart';
import 'package:mellonnSpeak/pages/home/onboarding/onboardingProvider.dart';
import 'package:mellonnSpeak/pages/home/profile/profilePage.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:pro_animated_blur/pro_animated_blur.dart';
import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  PanelController panelController = PanelController();
  Size bodySize = Size.zero;
  Size titleSize = Size.zero;
  Size expSize = Size.zero;
  double titleBlur = 0;
  StackSequence currentStackSequence = StackSequence.standard;
  List<Widget> mainStackChildren = [];
  List<Widget> bodyStackChildren = [];

  bool isRecordingsLoading = false;

  //Panel blur animation
  void panelOpen(double amount) {
    setState(() {
      titleBlur = amount * 10;
    });
  }

  void closeUpload() async {
    setState(() {
      isUploadActive = false;
    });
    await Future.delayed(Duration(milliseconds: uploadAnimLength + 100));
    setState(() {
      currentStackSequence = StackSequence.standard;
    });
  }

  //Upload button blur animation
  int uploadAnimLength = 200; //Milliseconds
  bool isUploadActive = false;

  List<Widget> changeMainStack(StackSequence type) {
    double heightOffset = 0;
    if (Platform.isIOS) {
      heightOffset = 0.07;
    } else {
      heightOffset = 0.03;
    }

    if (type == StackSequence.standard) {
      return [
        Hero(
          tag: 'background',
          child: BackGroundCircles(),
        ),
        Stack(
          children: bodyStackChildren,
        ),
        SlidingUpPanel(
          minHeight: MediaQuery.of(context).size.height * (1 + heightOffset) - bodySize.height,
          maxHeight: MediaQuery.of(context).size.height,
          onPanelSlide: panelOpen,
          panelBuilder: recordingList,
          renderPanelSheet: false,
          controller: panelController,
        ),
      ];
    } else if (type == StackSequence.upload) {
      return [
        BackGroundCircles(),
        Positioned(
          top: bodySize.height - MediaQuery.of(context).size.height * heightOffset,
          child: Container(
            height: MediaQuery.of(context).size.height - bodySize.height + MediaQuery.of(context).size.height * heightOffset,
            width: MediaQuery.of(context).size.width,
            child: recordingList(null),
          ),
        ),
        Stack(
          children: bodyStackChildren,
        ),
      ];
    }
    return [];
  }

  List<Widget> changeBodyStack(StackSequence type) {
    if (type == StackSequence.standard) {
      return [
        title(),
        upload(),
        blur(titleBlur, true),
      ];
    } else if (type == StackSequence.upload) {
      return [
        title(),
        blur(titleBlur, false),
        upload(),
      ];
    }
    return [];
  }

  state() {}

  void initialize() async {
    await context.read<OnboardingProvider>().getOnboardedState();
    context.read<MainPageProvider>().isLoading = false;
  }

  Future<void> _pullRefresh() async {
    //await StorageProvider().testFileConverter();
    setState(() {
      isRecordingsLoading = true;
    });
    await Amplify.DataStore.clear();
    await Future.delayed(Duration(milliseconds: 250));
    setState(() {
      isRecordingsLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    bodyStackChildren = changeBodyStack(currentStackSequence);
    mainStackChildren = changeMainStack(currentStackSequence);
    if (context.watch<MainPageProvider>().isLoading) {
      initialize();
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }
    if (!context.read<OnboardingProvider>().overrideOnboarded && context.watch<OnboardingProvider>().onboarded) {
      return Scaffold(
        body: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Stack(
            children: mainStackChildren,
          ),
        ),
      );
    } else {
      return OnboardPage();
    }
  }

  //Widget with profile picture and titles, doesn't contain the upload button (because of blurry reasons)
  Widget title() {
    return Wrap(
      children: [
        MeasureSize(
          onChange: (size) {
            setState(() {
              bodySize = size;
            });
          },
          child: Container(
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top, 20, MediaQuery.of(context).padding.bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MeasureSize(
                  onChange: (size) {
                    setState(() {
                      titleSize = size;
                    });
                  },
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(
                                  homePageSetState: state,
                                ),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  final width = MediaQuery.of(context).size.width;
                                  final height = MediaQuery.of(context).size.height;
                                  double top =
                                      -((height / 2) * (1 - animation.value)) + ((MediaQuery.of(context).padding.top + 20) * (1 - animation.value));
                                  double left = -((width / 2) * (1 - animation.value)) + (20 * (1 - animation.value));
                                  final curvedAnimation = CurvedAnimation(parent: animation, curve: Curves.linear);

                                  return Stack(
                                    children: [
                                      Opacity(
                                        opacity: animation.value,
                                        child: Container(
                                          width: width,
                                          height: height,
                                          color: Theme.of(context).colorScheme.background,
                                        ),
                                      ),
                                      Positioned(
                                        top: top,
                                        left: left,
                                        child: Container(
                                          width: width,
                                          height: height,
                                          child: ScaleTransition(
                                            scale: Tween(begin: 0.0, end: 1.0).animate(curvedAnimation),
                                            child: child,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                                transitionDuration: Duration(milliseconds: 250),
                                reverseTransitionDuration: Duration(milliseconds: 250),
                              ),
                            );
                          },
                          child: Hero(
                            tag: 'profilePic',
                            child: Container(
                              width: MediaQuery.of(context).size.height * 0.06,
                              height: MediaQuery.of(context).size.height * 0.06,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                  image: NetworkImage(context.read<AuthAppProvider>().avatarURI),
                                  fit: BoxFit.fill,
                                ),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Theme.of(context).shadowColor,
                                    blurRadius: shadowRadius,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Opacity(
                          opacity: 0.75,
                          child: Text(
                            '${greetingsString()}, ${context.read<AuthAppProvider>().firstName} ${context.read<AuthAppProvider>().lastName}!',
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 14,
                                ),
                          ),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Upload new recording?...',
                          style: GoogleFonts.raleway(
                            textStyle: Theme.of(context).textTheme.headlineMedium,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 90 + 25,
                ),
                Text(
                  '...Or edit a recording?',
                  style: GoogleFonts.raleway(
                    textStyle: Theme.of(context).textTheme.headlineMedium,
                    fontSize: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  //Widget with the upload button, doesn't contain the upload experience itself
  Widget upload() {
    return Positioned(
      top: titleSize.height + MediaQuery.of(context).padding.top,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          if (currentStackSequence == StackSequence.standard) {
            setState(() {
              currentStackSequence = StackSequence.upload;
            });
            await Future.delayed(Duration(milliseconds: 10));
            setState(() {
              isUploadActive = true;
            });
          } else {}
        },
        child: AnimatedContainer(
          padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          margin: EdgeInsets.fromLTRB(20, 20, 20, 0),
          width: MediaQuery.of(context).size.width - 40,
          height: isUploadActive ? expSize.height + 85 : 70,
          duration: Duration(milliseconds: uploadAnimLength),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Theme.of(context).shadowColor,
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Upload a new recording',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Spacer(),
                  AnimatedOpacity(
                    opacity: isUploadActive ? 0 : 1,
                    duration: Duration(milliseconds: uploadAnimLength),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Theme.of(context).shadowColor,
                            blurRadius: 1,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          FontAwesomeIcons.arrowUpFromBracket,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              MeasureSize(
                onChange: (size) {
                  setState(() {
                    expSize = size;
                  });
                },
                child: isUploadActive
                    ? Column(
                        children: [
                          SizedBox(
                            height: 15,
                          ),
                          AnimatedOpacity(
                            opacity: isUploadActive ? 1 : 0,
                            duration: Duration(milliseconds: uploadAnimLength),
                            child: UploadExperience(
                              closeDialog: closeUpload,
                            ),
                          ),
                        ],
                      )
                    : Container(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  //I programmed this in a blur, don't remember what happened
  Widget blur(double blurAmount, bool ignoreClick) {
    if (ignoreClick) {
      return IgnorePointer(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurAmount,
            sigmaY: blurAmount,
          ),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Theme.of(context).colorScheme.surface.withOpacity(blurAmount / 20),
          ),
        ),
      );
    } else {
      return ProAnimatedBlur(
        blur: isUploadActive ? 10 : 0,
        duration: Duration(milliseconds: uploadAnimLength),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Theme.of(context).colorScheme.surface.withOpacity(blurAmount / 20),
        ),
      );
    }
  }

  //List of recordings, using the recording elements
  Widget recordingList(ScrollController? scrollController) {
    return StreamBuilder(
      stream: Amplify.DataStore.observeQuery(
        Recording.classType,
        sortBy: [
          Recording.DATE.descending(),
        ],
      ).skipWhile((snapshot) => !snapshot.isSynced),
      builder: (context, AsyncSnapshot<QuerySnapshot<Recording>> snapshot) {
        if (snapshot.data == null) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
        QuerySnapshot<Recording> querySnapshot = snapshot.data!;
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(25, 25, 25, 0),
          itemCount: querySnapshot.items.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: _pullRefresh,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 25, 0, 25),
                  child: LoadingButton(
                    text: "Reload",
                    isLoading: isRecordingsLoading,
                  ),
                ),
              );
            } else {
              Recording recording = querySnapshot.items[index - 1];
              return RecordingElement(
                recording: recording,
                recordingsContext: context,
              );
            }
          },
        );
      },
    );
  }
}

//Upload experience
class UploadExperience extends StatefulWidget {
  final Function() closeDialog;

  const UploadExperience({
    Key? key,
    required this.closeDialog,
  }) : super(key: key);

  @override
  State<UploadExperience> createState() => _UploadExperienceState();
}

class _UploadExperienceState extends State<UploadExperience> {
  final PageController controller = PageController();
  final titleFormKey = GlobalKey<FormState>();
  final descFormKey = GlobalKey<FormState>();
  bool initiated = false;

  //Navigation stuff
  String backText = 'Cancel';
  String nextText = 'Next';
  Duration animDuration = Duration(milliseconds: 250);
  Curve animCurve = Curves.easeInOut;

  //Variables for creating a recording
  PickedFile? pickedFile;
  bool filePicked = false;
  String title = '', description = '', languageCode = '';
  int speakerCount = 2;
  String dropdownValue = '';

  //Variables for payment
  bool isCheckout = false;
  bool isPayProcessing = false;

  void backClicked() {
    int currentPage = controller.page!.round();
    FocusManager.instance.primaryFocus?.unfocus();
    if (currentPage == 0) {
      if (filePicked) {
        showDialog(
          context: context,
          builder: (BuildContext context) => SureDialog(
            onYes: () {
              widget.closeDialog();
              Navigator.pop(context);
            },
            text: 'Are you sure you want to cancel this upload?',
          ),
        );
      } else {
        widget.closeDialog();
      }
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

  void nextClicked() async {
    int currentPage = controller.page!.round();
    FocusManager.instance.primaryFocus?.unfocus();
    if (currentPage == 0) {
      setState(() {
        backText = 'Back';
      });
      if (filePicked) {
        controller.animateToPage(1, duration: animDuration, curve: animCurve);
      } else {
        dialog('No file', 'You need to select an audio file.');
      }
    } else if (currentPage == 1) {
      if (titleFormKey.currentState!.validate()) {
        controller.animateToPage(2, duration: animDuration, curve: animCurve);
      }
    } else if (currentPage == 2) {
      if (descFormKey.currentState!.validate()) {
        controller.animateToPage(3, duration: animDuration, curve: animCurve);
      }
    } else if (currentPage == 3) {
      controller.animateToPage(4, duration: animDuration, curve: animCurve);
    } else if (currentPage == 4) {
      setState(() {
        isCheckout = true;
        nextText = 'Pay';
      });
      controller.animateToPage(5, duration: animDuration, curve: animCurve);
    } else if (currentPage == 5) {
      if (!isPayProcessing) {
        void paySuccess() async {
          print('Payment successful');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
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
          widget.closeDialog();
          showDialog(
            context: context,
            builder: (BuildContext context) => OkAlert(
              title: 'Recording uploaded',
              text:
                  'Estimated time for completion: ${estimatedTime(pickedFile!.periods!.total)}.\nThis is only an estimate, it can take up to 2 hours. If it takes longer, please report an issue on the profile page.',
            ),
          );
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

  Future<void> initializeIAP(PurchaseType type, int totalPeriods, Function() paySuccess, Function() payFailed) async {
    bool _available = await iap.isAvailable();
    if (_available) {
      getProductsIAP(totalPeriods, context.read<AuthAppProvider>().userGroup);

      subscriptionIAP = iap.purchaseStream.listen(
        (data) async {
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
      );
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

  @override
  void dispose() {
    if (pickedFile != null) deleteTempFile(pickedFile!.file.path!);
    pickedFile = null;
    filePicked = false;
    title = '';
    description = '';
    languageCode = '';
    speakerCount = 2;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!initiated) {
      dropdownValue = context.read<LanguageProvider>().defaultLanguage;
      languageCode = context.read<LanguageProvider>().defaultLanguageCode;
      initiated = true;
    }

    return Column(
      children: [
        Container(
          constraints: BoxConstraints(
            maxHeight: isCheckout ? 240 : 150,
          ),
          child: pages(context),
        ),
        SmoothPageIndicator(
          controller: controller,
          count: 6,
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
                      style: Theme.of(context).textTheme.headlineSmall,
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
    );
  }

  ///
  ///Pages:
  ///0. Choose file to upload.
  ///1. Give a title.
  ///2. Give a description.
  ///3. Amount of participants.
  ///4. Language spoken.
  ///5. Payment.
  ///
  Widget pages(BuildContext context) {
    List<String> languageList = context.read<LanguageProvider>().languageList;
    List<String> languageCodeList = context.read<LanguageProvider>().languageCodeList;
    return PageView(
      physics: NeverScrollableScrollPhysics(),
      controller: controller,
      children: [
        //Pick file page
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'First we need a recording!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(
              height: 10,
            ),
            InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () async {
                final result = await pickFile(
                  context.read<DataStoreAppProvider>().userData,
                  context.read<AuthAppProvider>().userGroup,
                );
                if (result.isError) {
                  filePicked = false;
                  dialog('Something went wrong.', result.file.name.split('ERROR:')[1]);
                } else {
                  setState(() {
                    pickedFile = result;
                    filePicked = true;
                  });
                }
              },
              child: Center(
                child: StandardButton(
                  maxWidth: 200,
                  text: 'Select audio file',
                ),
              ),
            ),
            SizedBox(
              height: 10,
            ),
            filePicked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('File name: ${pickedFile!.file.name}'),
                      Text('Recording length: ${getMinSec(pickedFile!.duration!)}'),
                    ],
                  )
                : Container(),
          ],
        ),

        //Title page
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Now we need a title',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Form(
              key: titleFormKey,
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                onFieldSubmitted: (_) => nextClicked(),
                autofocus: true,
                initialValue: title,
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
                  labelStyle: Theme.of(context).textTheme.headlineSmall,
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Form(
              key: descFormKey,
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                onFieldSubmitted: (_) => nextClicked(),
                autofocus: true,
                initialValue: description,
                validator: (textValue) {
                  if (textValue!.length == 0) {
                    return 'This field is mandatory';
                  } else {
                    return null;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: Theme.of(context).textTheme.headlineSmall,
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(
              height: 20,
            ),
            NumberPicker(
              value: speakerCount,
              minValue: 1,
              maxValue: 10,
              axis: Axis.horizontal,
              textStyle: Theme.of(context).textTheme.headlineSmall,
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
              style: Theme.of(context).textTheme.headlineSmall,
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
                  print('Current language and code: $dropdownValue, $languageCode');
                },
              ),
            ),
          ],
        ),

        //Payment page
        Column(
          children: [
            filePicked
                ? CheckoutPage(
                    periods: pickedFile!.periods!,
                  )
                : Container(),
          ],
        ),
      ],
    );
  }
}
