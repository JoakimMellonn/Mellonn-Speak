import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/pages/home/homePageMobile.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class ConfirmSignUp extends StatefulWidget {
  final String email;
  final String password;

  const ConfirmSignUp({Key? key, required this.email, required this.password})
      : super(key: key);

  @override
  _ConfirmSignUpState createState() => _ConfirmSignUpState();
}

class _ConfirmSignUpState extends State<ConfirmSignUp> {
  String confirmCode = ' ';
  String firstName = ' ';
  String lastName = ' ';
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  FocusNode firstNameFocusNode = new FocusNode();
  FocusNode lastNameFocusNode = new FocusNode();
  FocusNode confCodeFocusNode = new FocusNode();

  @override
  void initState() {
    isLoading = false;
    super.initState();
  }

  _confirmSignUp() async {
    try {
      SignUpResult res = await Amplify.Auth.confirmSignUp(
        username: widget.email,
        confirmationCode: confirmCode,
      );
      if (res.isSignUpComplete) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Confirmation complete!')));
        _login();
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

  _login() async {
    await Amplify.Auth.signIn(
        username: widget.email, password: widget.password);

    var attributes = [
      AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.name, value: firstName),
      AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.familyName,
          value: lastName),
    ];

    await Amplify.Auth.updateUserAttributes(attributes: attributes);
    context.read<AuthAppProvider>().getUserAttributes();
    await context
        .read<DataStoreAppProvider>()
        .createUserData(context.read<AuthAppProvider>().email);
    await context
        .read<DataStoreAppProvider>()
        .getUserData(context.read<AuthAppProvider>().email);

    recordEventNewLogin('$firstName $lastName', widget.email);

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePageMobile();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        appBar: standardAppBar,
        body: Column(
          children: [
            TitleBox(title: 'Account confirmation', extras: false),
            SingleChildScrollView(
              child: StandardBox(
                margin: EdgeInsets.all(25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Please give us some more information",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF505050),
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 5,
                          ),
                        ],
                      ),
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
                          color: firstNameFocusNode.hasFocus
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
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
                          color: lastNameFocusNode.hasFocus
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 50,
                    ),
                    Text(
                      'Please enter confirmation code sent to your mail',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF505050),
                        shadows: <Shadow>[
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 5,
                          ),
                        ],
                      ),
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
                      },
                      decoration: InputDecoration(
                        labelText: 'Confirmation code',
                        labelStyle: TextStyle(
                          color: confCodeFocusNode.hasFocus
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
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
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            isLoading = true;
                          });
                          _confirmSignUp();
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
            ),
          ],
        ),
      ),
    );
  }
}
