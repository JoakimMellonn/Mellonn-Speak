import 'package:flutter/material.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'loginPages/signInPage.dart';
import 'loginPages/createLogin.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    Key? key,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final PageController pageController = PageController(initialPage: 0);

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          automaticallyImplyLeading: false,
          title: StandardAppBarTitle(),
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
          ),
          child: Column(
            children: [
              TitleBox(
                title: 'Welcome to\nMellonn Speak',
                heroString: 'pageTitle',
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
      ),
    );
  }
}
