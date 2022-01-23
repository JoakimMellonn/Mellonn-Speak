import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';
import 'package:transscriber/pages/awsLoginPages/loginPages/confirmSignUpPage.dart';
import 'package:transscriber/providers/colorProvider.dart';
import 'loginPages/signInPage.dart';
import 'loginPages/createLogin.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(initialPage: 0);

    return Scaffold(
      //Creating the beautiful appbar, with the gorgeous logo
      appBar: AppBar(
        title: Center(
          child: Image.asset(
            context.watch<ColorProvider>().currentLogo,
            height: 25,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.center,
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(25),
                    width: MediaQuery.of(context).size.width,
                    constraints: BoxConstraints(
                      minHeight: 100,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    child: Column(
                      children: [
                        Container(
                          alignment: Alignment.topLeft,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.65,
                            child: FittedBox(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome to",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context
                                          .watch<ColorProvider>()
                                          .darkText,
                                      shadows: <Shadow>[
                                        Shadow(
                                          color: context
                                              .watch<ColorProvider>()
                                              .shadow,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(
                                    height: 1,
                                  ),
                                  Text(
                                    "Mellonn Speak",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context
                                          .watch<ColorProvider>()
                                          .darkText,
                                      shadows: <Shadow>[
                                        Shadow(
                                          color: context
                                              .watch<ColorProvider>()
                                              .shadow,
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
                ],
              ),
            ),
            Expanded(
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: pageController,
                children: [
                  SignInPage(goToSignUp: () {
                    pageController.animateToPage(1,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeIn);
                  }),
                  CreateLogin(
                    goToLogin: () {
                      pageController.animateToPage(0,
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeIn);
                    },
                    goToSecondPage: () {
                      pageController.animateToPage(2,
                          duration: Duration(milliseconds: 200),
                          curve: Curves.easeIn);
                    },
                  ),
                  //ConfirmSignUp(email: 'email', password: 'password'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
