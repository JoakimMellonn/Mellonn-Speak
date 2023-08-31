import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/pages/login/loginPages/confirmSignUpPage/confirmSignUpPageProvider.dart';
import 'package:mellonnSpeak/pages/login/loginPages/createLogin/createLoginProvider.dart';
import 'package:mellonnSpeak/providers/promotionDbProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../confirmSignUpPage/confirmSignUpPage.dart';

class CreateLogin extends StatefulWidget {
  final Function goToLogin;
  final Function goToSecondPage;

  const CreateLogin({Key? key, required this.goToLogin, required this.goToSecondPage}) : super(key: key);

  @override
  _CreateLoginState createState() => _CreateLoginState();
}

class _CreateLoginState extends State<CreateLogin> {
  final formKey = GlobalKey<FormState>();
  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode passwordConfFocusNode = FocusNode();
  FocusNode promoFocusNode = FocusNode();

  void _createUser(String em, String pw) async {
    await Amplify.Auth.signUp(
      username: em,
      password: pw,
      options: SignUpOptions(userAttributes: {
        CognitoUserAttributeKey.email: em,
        CognitoUserAttributeKey.custom("group"): "user",
      }),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registration complete!'),
      ),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            body: ConfirmSignUp(
              email: context.read<CreateLoginProvider>().email,
              password: context.read<CreateLoginProvider>().password,
              promotion: context.read<CreateLoginProvider>().promotion,
            ),
          );
        },
      ),
    );
  }

  void getPromo(String code) async {
    context.read<CreateLoginProvider>().isLoadingPromo = true;
    try {
      context.read<CreateLoginProvider>().promotion = await getPromotion(code, 0, false);
      context.read<CreateLoginProvider>().promoString = discountString(context.read<CreateLoginProvider>().promotion!);
    } catch (e) {
      context.read<ConfirmSignUpPageProvider>().promoCode = code;
      context.read<CreateLoginProvider>().promoString = 'Proceed to confirm signup';
      print(e);
    }
    context.read<CreateLoginProvider>().isLoadingPromo = false;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: StandardBox(
          margin: EdgeInsets.all(25),
          child: Column(
            children: [
              TextFormField(
                focusNode: emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (textValue) {
                  context.read<CreateLoginProvider>().email = textValue;
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
                  context.read<CreateLoginProvider>().password = textValue;
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
                  labelText: 'Password',
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
                  context.read<CreateLoginProvider>().confirmPassword = textValue;
                },
                validator: (pwcValue) {
                  if (pwcValue != context.read<CreateLoginProvider>().password) {
                    return 'Password must match';
                  }
                  return null;
                },
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  labelStyle: TextStyle(
                    color: passwordConfFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
              SizedBox(
                height: 15.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    activeColor: Theme.of(context).colorScheme.primary,
                    value: context.watch<CreateLoginProvider>().termsAgreed,
                    onChanged: (bool? value) {
                      context.read<CreateLoginProvider>().termsAgreed = value!;
                    },
                  ),
                  Text(
                    'Agree to ',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => launchUrl(
                      Uri.parse('https://mellonn.notion.site/Terms-and-Conditions-92e458a5b84849678115777b473259ec'),
                    ),
                    child: Text(
                      'Terms and conditions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 5.0,
              ),
              context.watch<CreateLoginProvider>().promoString == ''
                  ? Column(
                      children: [
                        TextField(
                          focusNode: promoFocusNode,
                          onChanged: (textValue) {
                            context.read<CreateLoginProvider>().promoCode = textValue;
                          },
                          decoration: InputDecoration(
                            labelText: 'Promo code',
                            labelStyle: TextStyle(
                              color: promoFocusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        InkWell(
                          onTap: () => getPromo(context.read<CreateLoginProvider>().promoCode),
                          child: LoadingButton(
                            text: 'Check promo code',
                            isLoading: context.watch<CreateLoginProvider>().isLoadingPromo,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      context.read<CreateLoginProvider>().promoString,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
              SizedBox(
                height: 15.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        widget.goToLogin();
                      },
                      child: StandardButton(
                        text: 'Cancel',
                        color: Theme.of(context).colorScheme.surface,
                        textColor: Theme.of(context).colorScheme.secondary,
                        shadow: false,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Container(
                      child: InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () {
                          if (formKey.currentState!.validate() && context.read<CreateLoginProvider>().termsAgreed == true) {
                            context.read<CreateLoginProvider>().isLoading = true;
                            formKey.currentState!.save();
                            _createUser(context.read<CreateLoginProvider>().email, context.read<CreateLoginProvider>().password);
                          } else if (context.read<CreateLoginProvider>().termsAgreed == false) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => AlertDialog(
                                title: Text('You must agree to terms of service'),
                                actions: <Widget>[TextButton(onPressed: () => Navigator.pop(context, 'OK'), child: const Text('OK'))],
                              ),
                            );
                          }
                        },
                        child: LoadingButton(
                          text: 'Confirm',
                          isLoading: context.watch<CreateLoginProvider>().isLoading,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
