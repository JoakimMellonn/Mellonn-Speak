import 'package:flutter/material.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';
import 'loginPages/signInPage.dart';
import 'loginPages/createLogin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
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
            TitleBox(
              title: 'Welcome to\nMellonn Speak',
              extras: false,
            ),
            Expanded(
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                controller: pageController,
                children: [
                  SignInPage(goToSignUp: () {
                    pageController.animateToPage(
                      1,
                      duration: Duration(milliseconds: 200),
                      curve: Curves.easeIn,
                    );
                  }),
                  CreateLogin(
                    goToLogin: () {
                      pageController.animateToPage(
                        0,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeIn,
                      );
                    },
                    goToSecondPage: () {
                      pageController.animateToPage(
                        2,
                        duration: Duration(milliseconds: 200),
                        curve: Curves.easeIn,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
