import 'dart:ui';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/pages/home/homePageMobile.dart';
import 'package:mellonnSpeak/pages/login/loginPages/forgotPasswordPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

import 'confirmSignUpPage.dart';

class SignInPage extends StatefulWidget {
  final Function goToSignUp;

  const SignInPage({Key? key, required this.goToSignUp}) : super(key: key);

  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  String email = ' ', password = ' ';
  final formKey = GlobalKey<FormState>();
  bool isSignedIn = false;
  bool isSignedInConfirmed = false;
  bool isLoading = false;

  FocusNode emailFocusNode = new FocusNode();
  FocusNode passwordFocusNode = new FocusNode();

  @override
  void initState() {
    isLoading = false;
    super.initState();
  }

  void signIn(String em, String pw) async {
    String tempEmail = em.replaceAll(new RegExp(r':, '), '');
    try {
      SignInResult res =
          await Amplify.Auth.signIn(username: tempEmail, password: pw);
      setState(() {
        isSignedIn = res.isSignedIn;
      });
      if (isSignedIn == true) {
        await context.read<AuthAppProvider>().getUserAttributes();
        await context
            .read<DataStoreAppProvider>()
            .getUserData(context.read<AuthAppProvider>().email);
        recordEventNewLogin(
            '${context.read<AuthAppProvider>().firstName} ${context.read<AuthAppProvider>().lastName}',
            email);
        isSignedInConfirmed = true;
      }
    } on AuthException catch (e) {
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
        await Amplify.Auth.signOut();
      } else if (e.message == "User not confirmed in the system." ||
          e.message == "User is not confirmed.") {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) {
          return Scaffold(
            body: ConfirmSignUp(
              email: email,
              password: password,
            ),
          );
        }));
      } else if (e.message == "One or more parameters are incorrect.") {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
                "One or more of the entered parameters are incorrect or empty"),
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
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text("${e.message}"),
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
        await Amplify.Auth.signOut();
      }
    }

    if (isSignedInConfirmed == true) {
      await Amplify.DataStore.clear();
      final currentUser = await Amplify.Auth.getCurrentUser();
      context.read<AuthAppProvider>().getUserAttributes();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return HomePageMobile();
      }));
    }
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
                  setState(() {
                    email = textValue;
                  });
                },
                validator: (emailValue) {
                  if (emailValue!.isEmpty) {
                    return 'This field is mandatory';
                  }

                  RegExp regExp = new RegExp(
                      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

                  if (regExp.hasMatch(emailValue)) {
                    return null;
                  }

                  return 'This is not a valid email';
                },
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(
                    color: emailFocusNode.hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
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
                  setState(() {
                    password = textValue;
                  });
                },
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(
                    color: passwordFocusNode.hasFocus
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              SizedBox(
                height: 25.0,
              ),
              InkWell(
                onTap: () {
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return ForgotPassword();
                  }));
                },
                child: Hero(
                  tag: 'pageTitle',
                  child: Text(
                    'Forgot password?',
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ),
              ),
              SizedBox(
                height: 25,
              ),
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    isLoading = !isLoading;
                  });
                  signIn(email, password);
                },
                child: LoadingButton(
                  text: 'Log in',
                  isLoading: isLoading,
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
                          style: Theme.of(context).textTheme.bodyText2,
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
