import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/transcription/transcriptionChatWidget.dart';
import 'mainAppPages/recordingsPage.dart';
import 'mainAppPages/recordPage.dart';
import 'mainAppPages/profilePage.dart';
import 'mainAppPages/newProfilePage.dart';
import 'package:provider/provider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';

class MainAppPage extends StatefulWidget {
  const MainAppPage({Key? key}) : super(key: key);

  @override
  _MainAppPageState createState() => _MainAppPageState();
}

class _MainAppPageState extends State<MainAppPage> {
  Color selectedBackground = Color(0xFFFAB228);
  //Navigation bar variables
  int _selectedIndex = 1;
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
    //await context.read<DataStoreAppProvider>().getRecordings();
    super.initState();
  }

  /*
  * This function updates the page, when the navigationbar has been tapped
  * The user taps something on the navigationbar, and the current index wil be updated to that
  * Then the shown page will be updated by the pageController (this needs an animation tho...)
  */
  void _onNavigationTapped(int index) {
    setState(() {
      _selectedIndex = index;
      pageController.jumpToPage(index);
      context
          .read<ColorProvider>()
          .setBGColor(index); //This shouldn't be necessary forever...
    });
    if (index == 1) {
      setState(() {
        selectedBackground = Color(0xFFFAB228);
      });
    } else {
      setState(() {
        selectedBackground = Theme.of(context).colorScheme.background;
      });
    }
  }

  /*
  * Building the mainAppPage widget
  */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: selectedBackground,
      //Creating the beautiful appbar, with the gorgeous logo
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Image.asset(
            context.watch<ColorProvider>().currentLogo,
            height: 25,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      //Creating the body, with PageView, for all the mainAppPages
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
        ),
        child: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: pageController,
          onPageChanged: (index) {
            _onNavigationTapped(index);
          },
          children: [
            Center(
              child: RecordingsPage(),
            ),
            Center(
              child: RecordPage(),
            ),
            Center(
              child: NewProfilePage(),
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
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Theme.of(context).colorScheme.secondary,
            onTap: (index) {
              _onNavigationTapped(index); //Changing the page when it's tapped
            },
          ),
        ),
      ),
    );
  }
}
