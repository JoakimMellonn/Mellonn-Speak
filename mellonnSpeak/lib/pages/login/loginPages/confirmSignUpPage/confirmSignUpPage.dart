import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/main/mainPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/login/loginPages/confirmSignUpPage/confirmSignUpPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/promotionDbProvider.dart';
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
  final formKey = GlobalKey<FormState>();

  FocusNode firstNameFocusNode = new FocusNode();
  FocusNode lastNameFocusNode = new FocusNode();
  FocusNode confCodeFocusNode = new FocusNode();

  confirmSignUp() async {
    try {
      SignUpResult res = await Amplify.Auth.confirmSignUp(
        username: widget.email,
        confirmationCode: context.read<ConfirmSignUpPageProvider>().confirmCode,
      );
      if (res.isSignUpComplete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Confirmation complete!'),
          ),
        );
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
                context.read<ConfirmSignUpPageProvider>().isLoading = false;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Confirmation code sent!'),
        ),
      );
      context.read<ConfirmSignUpPageProvider>().isSendingLoading = false;
    } on AmplifyException catch (err) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("${err.message}"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                context.read<ConfirmSignUpPageProvider>().isSendingLoading = false;
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
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.name,
        value: context.read<ConfirmSignUpPageProvider>().firstName,
      ),
      AuthUserAttribute(
        userAttributeKey: CognitoUserAttributeKey.familyName,
        value: context.read<ConfirmSignUpPageProvider>().lastName,
      ),
    ];

    await Amplify.Auth.updateUserAttributes(attributes: attributes);
    await setSettings();
    Promotion? promotion = widget.promotion;
    if (widget.promotion == null && context.read<ConfirmSignUpPageProvider>().promoCode != '') {
      try {
        promotion = await getPromotion(context.read<ConfirmSignUpPageProvider>().promoCode, 0, false);
      } catch (e) {
        print(e);
        promotion = null;
      }
    }
    try {
      final signupPromo = await getPromotion('signup', 0, true);
      await applyPromotion(signupPromo, 0);
      await applyPromotion(promotion!, signupPromo.freePeriods);
    } catch (e) {
      print(e);
    }
    context.read<AuthAppProvider>().getUserAttributes();
    await context.read<DataStoreAppProvider>().createUserData(context.read<AuthAppProvider>().email);
    await context.read<DataStoreAppProvider>().getUserData(context.read<AuthAppProvider>().email);

    context.read<AnalyticsProvider>().recordEventNewLogin(
          context.read<ConfirmSignUpPageProvider>().firstName,
          context.read<ConfirmSignUpPageProvider>().lastName,
          widget.email,
        );

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
                backgroundColor: Theme.of(context).colorScheme.background,
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
                    style: Theme.of(context).textTheme.headlineSmall,
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          focusNode: firstNameFocusNode,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (textValue) {
                            context.read<ConfirmSignUpPageProvider>().firstName = textValue;
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
                            context.read<ConfirmSignUpPageProvider>().lastName = textValue;
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        TextFormField(
                          focusNode: confCodeFocusNode,
                          onChanged: (textValue) {
                            context.read<ConfirmSignUpPageProvider>().confirmCode = textValue;
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
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        InkWell(
                          onTap: () {
                            context.read<ConfirmSignUpPageProvider>().isSendingLoading = true;
                            resendConfirmCode();
                          },
                          child: LoadingButton(
                            text: 'Resend code',
                            isLoading: context.watch<ConfirmSignUpPageProvider>().isSendingLoading,
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
                              context.read<ConfirmSignUpPageProvider>().isLoading = true;
                              confirmSignUp();
                            }
                          },
                          child: LoadingButton(
                            text: 'Confirm',
                            isLoading: context.watch<ConfirmSignUpPageProvider>().isLoading,
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
