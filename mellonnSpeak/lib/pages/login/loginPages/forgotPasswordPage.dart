import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/pages/home/homePageMobile.dart';
import 'package:mellonnSpeak/pages/login/loginPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  ///
  ///Variables
  ///
  bool isPasswordReset = false;
  bool codeSent = false;
  bool isSendingLoading = false;
  bool isConfirmLoading = false;
  bool validMail = false;
  String em = ' ';
  String pw = ' ';
  String pwConf = ' ';
  String confirmCode = '';

  final formKey = GlobalKey<FormState>();
  FocusNode emailFocusNode = new FocusNode();
  FocusNode passwordFocusNode = new FocusNode();
  FocusNode passwordConfFocusNode = FocusNode();
  FocusNode confCodeFocusNode = new FocusNode();

  ///
  ///Init stuff...
  ///
  @override
  void initState() {
    isPasswordReset = false;
    codeSent = false;
    isSendingLoading = false;
    isConfirmLoading = false;
    super.initState();
  }

  ///
  ///Sends a reset code to the user's email.
  ///
  void sendConfirmCode() async {
    try {
      ResetPasswordResult res = await Amplify.Auth.resetPassword(
        username: em,
      );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Confirmation code sent!')));
      setState(() {
        isPasswordReset = res.isPasswordReset;
        codeSent = true;
      });
    } on AmplifyException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("${e.message}"),
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

  ///
  ///Sets the new password and uses it to log in.
  ///
  void setNewPW() async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: em,
        newPassword: pw,
        confirmationCode: confirmCode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password changed! Logging in...')));
      login();
    } on AmplifyException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("${e.message}"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                setState(() {
                  isConfirmLoading = false;
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

  ///
  ///Yeah...
  ///
  login() async {
    await Amplify.Auth.signIn(username: em, password: pw);

    context.read<AuthAppProvider>().getUserAttributes();

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
      return HomePageMobile();
    }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        title: StandardAppBarTitle(),
        elevation: 0,
      ),
      body: Column(
        children: [
          TitleBox(
            title: 'Forgot password',
            extras: !isPasswordReset,
            onBack: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) {
                return LoginPage();
              }));
            },
          ),
          SingleChildScrollView(
            child: StandardBox(
              margin: EdgeInsets.all(25),
              width: MediaQuery.of(context).size.width,
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    TextFormField(
                      focusNode: emailFocusNode,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (textValue) {
                        setState(() {
                          em = textValue;
                        });
                      },
                      validator: (emailValue) {
                        if (emailValue!.isEmpty) {
                          return 'This field is mandatory';
                        }

                        RegExp regExp = new RegExp(
                            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

                        if (regExp.hasMatch(emailValue)) {
                          validMail = true;
                          return null;
                        }

                        validMail = false;
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
                    !codeSent
                        ? SizedBox(
                            height: 25,
                          )
                        : SizedBox(
                            height: 10,
                          ),
                    !codeSent
                        ? Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  if (validMail) {
                                    setState(() {
                                      isSendingLoading = true;
                                    });
                                    sendConfirmCode();
                                  }
                                },
                                child: LoadingButton(
                                    text: 'Send verification code',
                                    isLoading: isSendingLoading),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                            ],
                          )
                        : Container(),
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
                      height: 10,
                    ),
                    TextFormField(
                      focusNode: passwordFocusNode,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (textValue) {
                        setState(() {
                          pw = textValue;
                        });
                      },
                      validator: (pwValue) {
                        if (pwValue!.isEmpty) {
                          return 'This field is mandatory';
                        }
                        if (pwValue.length < 8) {
                          return 'Password must be longer than 8 characters';
                        }
                        return null;
                      },
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(
                          color: passwordFocusNode.hasFocus
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    TextFormField(
                      focusNode: passwordConfFocusNode,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (textValue) {
                        setState(() {
                          pwConf = textValue;
                        });
                      },
                      validator: (pwcValue) {
                        if (pwcValue != pw) {
                          return 'Password must match';
                        }
                        return null;
                      },
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(
                          color: passwordConfFocusNode.hasFocus
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    InkWell(
                      onTap: () {
                        if (formKey.currentState!.validate()) {
                          setState(() {
                            isConfirmLoading = true;
                          });
                          setNewPW();
                        }
                      },
                      child: LoadingButton(
                        text: 'Change password',
                        isLoading: isConfirmLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
