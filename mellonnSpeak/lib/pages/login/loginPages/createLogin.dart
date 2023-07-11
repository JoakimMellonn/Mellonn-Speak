import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/providers/promotionProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:url_launcher/url_launcher.dart';
import 'confirmSignUpPage.dart';

class CreateLogin extends StatefulWidget {
  final Function goToLogin;
  final Function goToSecondPage;

  const CreateLogin({Key? key, required this.goToLogin, required this.goToSecondPage}) : super(key: key);

  @override
  _CreateLoginState createState() => _CreateLoginState();
}

class _CreateLoginState extends State<CreateLogin> {
  String email = ' ', password = ' ', passwordConf = ' ', promoCode = '', promoString = '';
  bool termsAgreed = false;
  Promotion? promotion;
  final formKey = GlobalKey<FormState>();
  bool isLoading = false, isLoadingPromo = false;

  FocusNode emailFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode passwordConfFocusNode = FocusNode();
  FocusNode promoFocusNode = FocusNode();

  @override
  void initState() {
    isLoading = false;
    super.initState();
  }

  void _createUser(String em, String pw) async {
    await Amplify.Auth.signUp(
      username: em,
      password: pw,
      options: SignUpOptions(userAttributes: {
        CognitoUserAttributeKey.email: em,
        CognitoUserAttributeKey.custom("group"): "user",
      }),
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registration complete!')));
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) {
          return Scaffold(
            body: ConfirmSignUp(
              email: email,
              password: password,
              promotion: promotion,
            ),
          );
        },
      ),
    );
  }

  void getPromo(String code) async {
    setState(() {
      isLoadingPromo = true;
    });
    promotion = await getPromotion(() => {}, code, email, 0, false);
    setState(() {
      promoString = promotion!.discountString();
      isLoadingPromo = false;
    });
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
                  setState(() {
                    email = textValue;
                  });
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
                  setState(() {
                    password = textValue;
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
                  setState(() {
                    passwordConf = textValue;
                  });
                },
                validator: (pwcValue) {
                  if (pwcValue != password) {
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
                    value: termsAgreed,
                    onChanged: (bool? value) {
                      setState(() {
                        termsAgreed = value!;
                      });
                    },
                  ),
                  Text(
                    'Agree to ',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    onTap: () => launchUrl(
                      Uri.parse('https://mellonn.notion.site/Terms-and-Conditions-92e458a5b84849678115777b473259ec'),
                    ),
                    child: Text(
                      'Terms and conditions',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 14,
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
                  ),
                ],
              ),
              SizedBox(
                height: 5.0,
              ),
              promoString == ''
                  ? Column(
                      children: [
                        TextField(
                          focusNode: promoFocusNode,
                          onChanged: (textValue) {
                            setState(() {
                              promoCode = textValue;
                            });
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
                          onTap: () => getPromo(promoCode),
                          child: LoadingButton(
                            text: 'Check promo code',
                            isLoading: isLoadingPromo,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      promoString,
                      style: Theme.of(context).textTheme.bodySmall,
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
                          if (formKey.currentState!.validate() && termsAgreed == true) {
                            setState(() {
                              isLoading = true;
                            });
                            formKey.currentState!.save();
                            _createUser(email, password);
                          } else if (termsAgreed == false) {
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
                          isLoading: isLoading,
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
