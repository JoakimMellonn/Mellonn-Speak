import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/profilePage.dart';
import 'package:mellonnSpeak/pages/home/record/recordPage.dart';
import 'package:mellonnSpeak/pages/home/record/recordPageProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/recordingsPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:mellonnSpeak/utilities/theme.dart';

class HomePageMobile extends StatefulWidget {
  const HomePageMobile({Key? key}) : super(key: key);

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  //Navigation bar variables
  Color backGroundColor = colorSchemeLight.primary;
  int _selectedIndex = 1;
  bool isUploading = false;
  PageController pageController = PageController(
    initialPage: 1,
    keepPage: true,
  );

  /*
  * Function that runs when initializing the widget
  * This will get the recordings from the user's database, so they will be ready when the page has been loaded, how convenient!
  */
  @override
  void initState() {
    super.initState();
  }

  void stateSetter(int i) {
    setState(() {
      _selectedIndex = i;
      _onNavigationTapped(i);
    });
  }

  void homePageSetState(bool upload) {
    setState(() {
      isUploading = upload;
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
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      currentLogo = darkModeLogo;
    } else {
      currentLogo = lightModeLogo;
    }
    return Scaffold(
      backgroundColor: backGroundColor,
      resizeToAvoidBottomInset: false,
      //Creating the beautiful appbar, with the gorgeous logo
      appBar: standardAppBar,
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
                  homePageSetPage: stateSetter,
                  homePageSetState: homePageSetState,
                ),
              ),
            ),
            Center(
              child: ProfilePageMobile(),
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
              color: Theme.of(context).colorScheme.secondaryVariant,
              blurRadius: 5,
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
  }
}
