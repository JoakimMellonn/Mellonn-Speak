import 'dart:ui';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:transscriber/pages/mainAppPage.dart';
import 'package:provider/provider.dart';
import 'package:transscriber/providers/amplifyAuthProvider.dart';
import 'package:transscriber/providers/amplifyDataStoreProvider.dart';
import 'package:transscriber/providers/colorProvider.dart';

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

  FocusNode emailFocusNode = new FocusNode();
  FocusNode passwordFocusNode = new FocusNode();

  void signIn(String em, String pw) async {
    String tempEmail = em.replaceAll(new RegExp(r':, '), '');
    try {
      SignInResult res =
          await Amplify.Auth.signIn(username: tempEmail, password: pw);
      setState(() {
        isSignedIn = res.isSignedIn;
      });
      if (isSignedIn == true) {
        await context.read<DataStoreAppProvider>().getRecordings();
        await context.read<AuthAppProvider>().getUserAttributes();
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
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              )
            ],
          ),
        );
        await Amplify.Auth.signOut();
      } else if (e.message == "User not confirmed in the system.") {
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
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              )
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text(
                "You've catched an unknown error please send the following message to joakim@mellonn.com: ${e.message}"),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, 'OK'),
                child: const Text('OK'),
              )
            ],
          ),
        );
        await Amplify.Auth.signOut();
      }
    }

    if (isSignedInConfirmed == true) {
      final currentUser = await Amplify.Auth.getCurrentUser();
      context.read<AuthAppProvider>().getUserAttributes();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return MainAppPage();
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(minHeight: 100),
          padding: EdgeInsets.fromLTRB(35, 25, 35, 25),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(25),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Theme.of(context).colorScheme.secondaryVariant,
                blurRadius: 5,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            children: [
              TextFormField(
                focusNode: emailFocusNode,
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
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  signIn(email, password);
                },
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondaryVariant,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Log In',
                      style: const TextStyle(
                        fontSize: 20.0,
                      ),
                    ),
                  ),
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
                          style: const TextStyle(
                            fontSize: 13.0,
                          ),
                        ),
                        Text(
                          "Create one!",
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
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
