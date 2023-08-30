import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/models/Settings.dart';
import 'package:mellonnSpeak/pages/home/main/mainPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/login/loginPages/forgotPasswordPage.dart';
import 'package:mellonnSpeak/pages/login/loginPages/signInPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';
import 'confirmSignUpPage.dart';

class SignInPage extends StatefulWidget {
  final Function goToSignUp;

  const SignInPage({Key? key, required this.goToSignUp}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final formKey = GlobalKey<FormState>();

  FocusNode emailFocusNode = new FocusNode();
  FocusNode passwordFocusNode = new FocusNode();

  void signIn(String em, String pw) async {
    String tempEmail = em.replaceAll(new RegExp(r':, '), '');
    try {
      SignInResult res = await Amplify.Auth.signIn(username: tempEmail, password: pw);
      context.read<SignInPageProvider>().isSignedIn = res.isSignedIn;
      if (context.read<SignInPageProvider>().isSignedIn == true) {
        await setSettings();
        await context.read<AuthAppProvider>().getUserAttributes();
        await context.read<DataStoreAppProvider>().getUserData(context.read<AuthAppProvider>().email);
        context.read<AnalyticsProvider>().recordEventNewLogin(
              context.read<AuthAppProvider>().firstName,
              context.read<AuthAppProvider>().lastName,
              context.read<SignInPageProvider>().email,
            );
        context.read<SignInPageProvider>().isSignedInConfirmed = true;
      }
    } on AuthException catch (e) {
      context.read<SignInPageProvider>().isLoading = false;
      print(e.message);
      if (e.message == "User not found in the system.") {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("No user has been found for this email"),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              )
            ],
          ),
        );
        await Amplify.Auth.signOut();
      } else if (e.message == "Failed since user is not authorized.") {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("You've entered a wrong password"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  context.read<SignInPageProvider>().isLoading = false;
                  Navigator.pop(context, 'OK');
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
        await Amplify.Auth.signOut();
      } else if (e.message == "User not confirmed in the system." || e.message == "User is not confirmed.") {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
          return Scaffold(
            body: ConfirmSignUp(
              email: context.read<SignInPageProvider>().email,
              password: context.read<SignInPageProvider>().password,
            ),
          );
        }));
      } else if (e.message == "One or more parameters are incorrect.") {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("One or more of the entered parameters are incorrect or empty"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  context.read<SignInPageProvider>().isLoading = false;
                  Navigator.pop(context, 'OK');
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("${e.message}"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  context.read<SignInPageProvider>().isLoading = false;
                  Navigator.pop(context, 'OK');
                },
                child: const Text('OK'),
              )
            ],
          ),
        );
        await Amplify.Auth.signOut();
      }
    }

    if (context.read<SignInPageProvider>().isSignedInConfirmed == true) {
      await Amplify.DataStore.clear();
      try {
        await Amplify.Auth.getCurrentUser();
        context.read<AuthAppProvider>().getUserAttributes();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
          return MainPage();
        }));
      } on AuthException catch (e) {
        print('SignInPage Error: ${e.message}');
      }
    }
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
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: StandardBox(
          margin: EdgeInsets.all(25),
          child: Column(
            children: [
              TextFormField(
                focusNode: emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (textValue) {
                  context.read<SignInPageProvider>().email = textValue;
                },
                validator: (emailValue) {
                  if (emailValue!.isEmpty) {
                    return 'This field is mandatory';
                  }

                  RegExp regExp = new RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

                  if (regExp.hasMatch(emailValue)) {
                    return null;
                  }

                  return 'This is not a valid email';
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: emailFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              TextFormField(
                focusNode: passwordFocusNode,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (textValue) {
                  context.read<SignInPageProvider>().password = textValue;
                },
                onFieldSubmitted: (value) {
                  if (!context.read<SignInPageProvider>().isLoading && value == context.read<SignInPageProvider>().password) {
                    context.read<SignInPageProvider>().isLoading = true;
                    signIn(context.read<SignInPageProvider>().email, context.read<SignInPageProvider>().password);
                  }
                },
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color: passwordFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              SizedBox(
                height: 25.0,
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) {
                        return ForgotPassword();
                      },
                    ),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              SizedBox(
                height: 25,
              ),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  if (!context.read<SignInPageProvider>().isLoading && formKey.currentState!.validate()) {
                    context.read<SignInPageProvider>().isLoading = true;
                    signIn(context.read<SignInPageProvider>().email, context.read<SignInPageProvider>().password);
                  }
                },
                child: LoadingButton(
                  text: 'Log in',
                  isLoading: context.watch<SignInPageProvider>().isLoading,
                ),
              ),
              SizedBox(
                height: 25.0,
              ),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  widget.goToSignUp();
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 5.0),
                  height: 55.0,
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: FittedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "You don't already have an account? ",
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          "Create one!",
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            shadows: <Shadow>[
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
