import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/models/Settings.dart';
import 'package:mellonnSpeak/pages/home/main/mainPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/promotionProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';

class ConfirmSignUp extends StatefulWidget {
  final String email;
  final String password;
  final Promotion? promotion;

  const ConfirmSignUp({
    Key? key,
    required this.email,
    required this.password,
    this.promotion,
  }) : super(key: key);

  @override
  _ConfirmSignUpState createState() => _ConfirmSignUpState();
}

class _ConfirmSignUpState extends State<ConfirmSignUp> {
  String confirmCode = ' ';
  String firstName = ' ';
  String lastName = ' ';
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isSendingLoading = false;

  FocusNode firstNameFocusNode = new FocusNode();
  FocusNode lastNameFocusNode = new FocusNode();
  FocusNode confCodeFocusNode = new FocusNode();

  @override
  void initState() {
    isLoading = false;
    super.initState();
  }

  confirmSignUp() async {
    try {
      SignUpResult res = await Amplify.Auth.confirmSignUp(
        username: widget.email,
        confirmationCode: confirmCode,
      );
      if (res.isSignUpComplete) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Confirmation complete!')));
        login();
      }
    } on AuthException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text(e.message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  isLoading = false;
                });
                Navigator.pop(context, 'OK');
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  resendConfirmCode() async {
    try {
      await Amplify.Auth.resendSignUpCode(username: widget.email);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Confirmation code sent!')));
      setState(() {
        isSendingLoading = false;
      });
    } on AmplifyException catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("${err.message}"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  isSendingLoading = false;
                });
                Navigator.pop(context, 'OK');
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  login() async {
    await Amplify.Auth.signIn(username: widget.email, password: widget.password);

    var attributes = [
      AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.name, value: firstName),
      AuthUserAttribute(userAttributeKey: CognitoUserAttributeKey.familyName, value: lastName),
    ];

    await Amplify.Auth.updateUserAttributes(attributes: attributes);
    await setSettings();
    final signupPromo = await getPromotion(() {}, 'signup', widget.email, 0, true);
    await applyPromotion(() {}, signupPromo, widget.email, 0);
    await applyPromotion(() {}, widget.promotion!, widget.email, signupPromo.freePeriods);
    context.read<AuthAppProvider>().getUserAttributes();
    await context.read<DataStoreAppProvider>().createUserData(context.read<AuthAppProvider>().email);
    await context.read<DataStoreAppProvider>().getUserData(context.read<AuthAppProvider>().email);

    recordEventNewLogin(firstName, lastName, widget.email);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return MainPage();
    }));
  }

  Future<void> setSettings() async {
    await context.read<SettingsProvider>().setCurrentSettings();
    Settings cSettings = context.read<SettingsProvider>().currentSettings;
    if (cSettings.themeMode == 'Dark') {
      themeMode = ThemeMode.dark;
      currentLogo = darkModeLogo;
    } else if (cSettings.themeMode == 'Light') {
      currentLogo = lightModeLogo;
    }
    context.read<LanguageProvider>().setDefaultLanguage(cSettings.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Form(
        key: formKey,
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Theme.of(context).backgroundColor,
                leading: appBarLeading(context),
                automaticallyImplyLeading: false,
                pinned: true,
                elevation: 0.5,
                surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                expandedHeight: 100,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    'Account confirmation',
                    style: Theme.of(context).textTheme.headline5,
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  StandardBox(
                    margin: EdgeInsets.all(25),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Please give us some more information",
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          focusNode: firstNameFocusNode,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (textValue) {
                            setState(() {
                              firstName = textValue;
                            });
                          },
                          validator: (textValue) {
                            if (textValue!.length <= 0) {
                              return 'You must fill in your first name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'First name',
                            labelStyle: TextStyle(
                              color: firstNameFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        TextFormField(
                          focusNode: lastNameFocusNode,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (textValue) {
                            setState(() {
                              lastName = textValue;
                            });
                          },
                          validator: (textValue) {
                            if (textValue!.length <= 0) {
                              return 'You must fill in your last name';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Last name',
                            labelStyle: TextStyle(
                              color: lastNameFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                        ),
                        Text(
                          'Please enter confirmation code sent to your mail',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          focusNode: confCodeFocusNode,
                          onChanged: (textValue) {
                            setState(() {
                              confirmCode = textValue;
                            });
                          },
                          validator: (textValue) {
                            if (textValue!.isEmpty) {
                              return 'You need to fill in the confirmation code';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            labelText: 'Confirmation code',
                            labelStyle: TextStyle(
                              color: confCodeFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Text(
                          "Didn't receive a code?",
                          style: Theme.of(context).textTheme.headline6,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              isSendingLoading = true;
                            });
                            resendConfirmCode();
                          },
                          child: StandardButton(
                            text: 'Resend code',
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              setState(() {
                                isLoading = true;
                              });
                              confirmSignUp();
                            }
                          },
                          child: LoadingButton(
                            text: 'Confirm',
                            isLoading: isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
