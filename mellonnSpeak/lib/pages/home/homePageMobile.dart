import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/onboarding/onboardingPage.dart';
import 'package:mellonnSpeak/pages/home/onboarding/onboardingProvider.dart';
import 'package:mellonnSpeak/pages/home/profile/profilePage.dart';
import 'package:mellonnSpeak/pages/home/record/recordPage.dart';
import 'package:mellonnSpeak/pages/home/recordings/recordingsPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePageMobile extends StatefulWidget {
  final int initialPage;
  const HomePageMobile({
    required this.initialPage,
    Key? key,
  }) : super(key: key);

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  //Navigation bar variables
  late PageController pageController;
  bool isLoading = true;
  Color backGroundColor = colorSchemeLight.primary;
  int _selectedIndex = 1;
  bool isUploading = false;
  bool initCalled = false;

  @override
  void initState() {
    if (!initCalled) {
      print('init called');
      pageController = PageController(
        initialPage: widget.initialPage,
        keepPage: true,
      );
      _selectedIndex = widget.initialPage;
    }
    super.initState();
  }

  void pageSetter(int i) {
    setState(() {
      _selectedIndex = i;
      _onNavigationTapped(i);
    });
  }

  void homePageUploadState(bool upload) {
    setState(() {
      isUploading = upload;
    });
  }

  void homePageSetState() {
    setState(() {
      backGroundColor = Theme.of(context).colorScheme.background;
    });
  }

  Future checkOnboard(BuildContext context) async {
    final preferences = await SharedPreferences.getInstance();
    bool temp = preferences.getBool('onboarded') ?? false;

    //await preferences.setBool('onboarded', false);

    if (temp) {
      context.read<OnboardingProvider>().setOnboardedState(true);
    } else {
      context.read<OnboardingProvider>().setOnboardedState(false);
    }
    setState(() {
      isLoading = false;
    });
  }

  setOrangeBG() {
    setState(() {
      backGroundColor = colorSchemeLight.primary;
    });
  }

  /*
  * This function updates the page, when the navigationbar has been tapped
  * The user taps something on the navigationbar, and the current index wil be updated to that
  * Then the shown page will be updated by the pageController (this needs an animation tho...)
  */
  void _onNavigationTapped(int index) {
    if (!isUploading) {
      setState(() {
        _selectedIndex = index;
        if (index == 1) {
          backGroundColor = colorSchemeLight.primary;
        } else {
          backGroundColor = Theme.of(context).colorScheme.background;
        }
        pageController.jumpToPage(index);
      });
    }
  }

  /*
  * Building the mainAppPage widget
  */
  @override
  Widget build(BuildContext context) {
    if (!initCalled) {
      if (widget.initialPage == 1) {
        backGroundColor = colorSchemeLight.primary;
      } else {
        backGroundColor = Theme.of(context).colorScheme.background;
      }
      initCalled = true;
    }
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      currentLogo = darkModeLogo;
    } else {
      currentLogo = lightModeLogo;
    }

    return FutureBuilder(
      future: checkOnboard(context),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (isLoading) return LoadingScreen();

        if (!context.watch<OnboardingProvider>().onboarded) return OnboardPage();

        return Scaffold(
          backgroundColor: backGroundColor,
          resizeToAvoidBottomInset: false,
          //Creating the beautiful app bar, with the gorgeous logo
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            automaticallyImplyLeading: false,
            title: StandardAppBarTitle(),
            elevation: 0,
          ),
          //Creating the body, with PageView, for all the mainAppPages
          body: Container(
            child: PageView(
              physics: NeverScrollableScrollPhysics(),
              controller: pageController,
              onPageChanged: (index) {
                _onNavigationTapped(index);
              },
              children: [
                Center(
                  child: RecordingsPageMobile(),
                ),
                Container(
                  color: Theme.of(context).colorScheme.background,
                  child: Center(
                    child: RecordPageMobile(
                      homePageSetPage: pageSetter,
                      homePageSetState: homePageUploadState,
                    ),
                  ),
                ),
                Center(
                  child: ProfilePageMobile(
                    homePageSetState: homePageSetState,
                  ),
                ),
              ],
            ),
          ),
          //Creating the navigationbar, this need some work, but it's working (that's what's most important :D)
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  blurRadius: shadowRadius,
                ),
              ],
            ),
            constraints: BoxConstraints(
              minHeight: 85,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(25),
                topRight: Radius.circular(25),
              ),
              child: BottomNavigationBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(context).colorScheme.secondary,
                items: [
                  BottomNavigationBarItem(
                    icon: Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Icon(
                        FontAwesomeIcons.thList,
                        size: 24.0,
                      ),
                    ),
                    label: 'Recordings',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Icon(
                        FontAwesomeIcons.microphone,
                        size: 24.0,
                      ),
                    ),
                    label: 'Record',
                  ),
                  BottomNavigationBarItem(
                    icon: Container(
                      margin: EdgeInsets.only(top: 15),
                      child: Icon(
                        FontAwesomeIcons.userAlt,
                        size: 24.0,
                      ),
                    ),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: (index) {
                  _onNavigationTapped(index); //Changing the page when it's tapped
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
