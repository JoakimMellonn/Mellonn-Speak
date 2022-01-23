import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:mellonnSpeak/pages/mainAppPage.dart';
import 'package:provider/provider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';

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

  FocusNode firstNameFocusNode = new FocusNode();
  FocusNode lastNameFocusNode = new FocusNode();
  FocusNode confCodeFocusNode = new FocusNode();

  _confirmSignUp() async {
    SignUpResult res = await Amplify.Auth.confirmSignUp(
      username: widget.email,
      confirmationCode: confirmCode,
    );
    if (res.isSignUpComplete) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Confirmation complete!')));
      _login();
    }
  }

  _login() async {
    await Amplify.Auth.signIn(
        username: widget.email, password: widget.password);

    //final currentUser = await Amplify.Auth.getCurrentUser();

    var attributes = [
      AuthUserAttribute(userAttributeKey: 'name', value: firstName),
      AuthUserAttribute(userAttributeKey: 'family_name', value: lastName)
    ];

    await Amplify.Auth.updateUserAttributes(attributes: attributes);
    context.read<AuthAppProvider>().getUserAttributes();

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return MainAppPage();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
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
                        _confirmSignUp();
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color:
                                Theme.of(context).colorScheme.secondaryVariant,
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      margin: EdgeInsets.symmetric(horizontal: 5.0),
                      height: 55.0,
                      width: 250.0,
                      alignment: Alignment.center,
                      child: Text(
                        'Confirm code',
                        style: const TextStyle(
                          fontSize: 20.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
