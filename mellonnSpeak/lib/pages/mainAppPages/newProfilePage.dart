import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/pages/mainAppPages/settingsPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';

class NewProfilePage extends StatefulWidget {
  const NewProfilePage({Key? key}) : super(key: key);

  @override
  _NewProfilePageState createState() => _NewProfilePageState();
}

class _NewProfilePageState extends State<NewProfilePage> {
  /*
  * This function signs the user out and clears every from the device we've got on em
  * But only the stuff on the device muhahaha
  * Can I be a ZUCC now?
  */
  void signOut() async {
    // ignore: unnecessary_statements
    context.read<DataStoreAppProvider>().clearRecordings;
    await Amplify.Auth.signOut();
    await Amplify.DataStore.clear();
    //Sends the user back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MyApp()),
    );
  }

  /*
  * Building the whole goddam page
  */
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        ///
        ///Sliver header go brrrr
        ///
        SliverAppBar(
          pinned: true,
          shadowColor: Theme.of(context).colorScheme.secondaryVariant,
          //collapsedHeight: 75,
          expandedHeight: MediaQuery.of(context).size.height * 0.4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25)),
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            title: Column(
              children: [
                Spacer(),
                //This is supposed to be wether the user is a normal peasant or a chad dev
                Text(
                  'This is your info',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSecondary,
                    shadows: <Shadow>[
                      Shadow(
                        color: Theme.of(context).colorScheme.secondaryVariant,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            background: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.25,
                    height: MediaQuery.of(context).size.width * 0.25,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    "Hi ${context.watch<AuthAppProvider>().firstName} ${context.watch<AuthAppProvider>().lastName}!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                      shadows: <Shadow>[
                        Shadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
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
        //The main info box
        SliverToBoxAdapter(
          child: Container(
            margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(minHeight: 100),
            padding: EdgeInsets.fromLTRB(35, 25, 35, 25),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(25),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Theme.of(context).colorScheme.secondaryVariant,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width,
                  alignment: Alignment.topLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //This shows the user's email and a nice icon
                      FittedBox(
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.solidEnvelope,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              '${context.watch<AuthAppProvider>().email}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 15, //TODO Fix this
                                shadows: <Shadow>[
                                  Shadow(
                                    color:
                                        context.watch<ColorProvider>().shadow,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      //Magic divider...
                      Divider(),
                      //This shows the user's phone number, if they've defined it
                      FittedBox(
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.phone,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              'Your phone',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 15,
                                shadows: <Shadow>[
                                  Shadow(
                                    color:
                                        context.watch<ColorProvider>().shadow,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      //Magic divider...
                      Divider(),
                      //This shows the user's something... Idek
                      FittedBox(
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.question,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              'Your something', //TODO: Probably remove this...
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 15,
                                shadows: <Shadow>[
                                  Shadow(
                                    color:
                                        context.watch<ColorProvider>().shadow,
                                    blurRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        //Settings button!! It actually works now
        SliverToBoxAdapter(
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsPage(),
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                minHeight: 50,
              ),
              padding: EdgeInsets.fromLTRB(35, 25, 35, 25),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.cog,
                          size: 20,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Text(
                          'Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 15,
                            shadows: <Shadow>[
                              Shadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryVariant,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        //If the user for some reason wanna sign out, I'm kind enough to have given them the option
        SliverToBoxAdapter(
          child: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onTap: () {
              signOut();
            },
            child: Container(
              margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                minHeight: 50,
              ),
              padding: EdgeInsets.fromLTRB(35, 25, 35, 25),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.signOutAlt,
                          size: 20,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 15,
                            shadows: <Shadow>[
                              Shadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryVariant,
                                blurRadius: 3,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 25,
          ),
        ),
      ],
    );
  }
}
