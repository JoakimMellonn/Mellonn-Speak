import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/pages/home/main/mainPage.dart';
import 'package:mellonnSpeak/pages/login/loginPages/forgotPasswordPage/forgotPasswordPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({Key? key}) : super(key: key);

  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final formKey = GlobalKey<FormState>();
  FocusNode emailFocusNode = new FocusNode();
  FocusNode passwordFocusNode = new FocusNode();
  FocusNode passwordConfFocusNode = FocusNode();
  FocusNode confCodeFocusNode = new FocusNode();

  void sendConfirmCode() async {
    try {
      ResetPasswordResult res = await Amplify.Auth.resetPassword(
        username: context.read<ForgotPasswordPageProvider>().email,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Confirmation code sent!'),
        ),
      );
      context.read<ForgotPasswordPageProvider>().isPasswordReset = res.isPasswordReset;
      context.read<ForgotPasswordPageProvider>().codeSent = true;
    } on AmplifyException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("${e.message}"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                context.read<ForgotPasswordPageProvider>().isSendingLoading = false;
                Navigator.pop(context, 'OK');
              },
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  void setNewPW() async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: context.read<ForgotPasswordPageProvider>().email,
        newPassword: context.read<ForgotPasswordPageProvider>().password,
        confirmationCode: context.read<ForgotPasswordPageProvider>().confirmCode,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password changed! Logging in...'),
        ),
      );
      login();
    } on AmplifyException catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: Text("${e.message}"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                context.read<ForgotPasswordPageProvider>().isConfirmLoading = false;
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
    await Amplify.Auth.signIn(
      username: context.read<ForgotPasswordPageProvider>().email,
      password: context.read<ForgotPasswordPageProvider>().password,
    );

    context.read<AuthAppProvider>().getUserAttributes();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) {
        return MainPage();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
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
                  'Forgot password',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                StandardBox(
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
                            context.read<ForgotPasswordPageProvider>().email = textValue;
                          },
                          validator: (emailValue) {
                            if (emailValue!.isEmpty) {
                              return 'This field is mandatory';
                            }

                            RegExp regExp =
                                new RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

                            if (regExp.hasMatch(emailValue)) {
                              context.read<ForgotPasswordPageProvider>().validEmail = true;
                              return null;
                            }

                            context.read<ForgotPasswordPageProvider>().validEmail = false;
                            return 'This is not a valid email';
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                              color: emailFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        !context.read<ForgotPasswordPageProvider>().codeSent
                            ? SizedBox(
                                height: 25,
                              )
                            : SizedBox(
                                height: 10,
                              ),
                        !context.read<ForgotPasswordPageProvider>().codeSent
                            ? Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      if (context.read<ForgotPasswordPageProvider>().validEmail) {
                                        context.read<ForgotPasswordPageProvider>().isSendingLoading = true;
                                        sendConfirmCode();
                                      }
                                    },
                                    child: LoadingButton(
                                      text: 'Send verification code',
                                      isLoading: context.watch<ForgotPasswordPageProvider>().isSendingLoading,
                                    ),
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
                            context.read<ForgotPasswordPageProvider>().confirmCode = textValue;
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
                          height: 10,
                        ),
                        TextFormField(
                          focusNode: passwordFocusNode,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          onChanged: (textValue) {
                            context.read<ForgotPasswordPageProvider>().password = textValue;
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
                              color: passwordFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
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
                            context.read<ForgotPasswordPageProvider>().confirmPassword = textValue;
                          },
                          validator: (pwcValue) {
                            if (pwcValue != context.read<ForgotPasswordPageProvider>().password) {
                              return 'Password must match';
                            }
                            return null;
                          },
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            labelStyle: TextStyle(
                              color: passwordConfFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          onTap: () {
                            if (formKey.currentState!.validate()) {
                              context.read<ForgotPasswordPageProvider>().isConfirmLoading = true;
                              setNewPW();
                            }
                          },
                          child: LoadingButton(
                            text: 'Change password',
                            isLoading: context.watch<ForgotPasswordPageProvider>().isConfirmLoading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
