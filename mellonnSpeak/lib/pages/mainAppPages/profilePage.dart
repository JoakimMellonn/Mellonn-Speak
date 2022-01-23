import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:transscriber/main.dart';
import 'package:transscriber/pages/mainAppPages/settingsPage.dart';
import 'package:transscriber/providers/amplifyAuthProvider.dart';
import 'package:transscriber/providers/amplifyDataStoreProvider.dart';
import 'package:transscriber/providers/colorProvider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    return Column(
      children: [
        /*
        * This is the title of the page, or the place with the main profile info
        * Like profile picture (which isn't implemented, but we don't talk about that)
        * Name and profile status (wether it's a normal user or a dev), is also displayed here
        */
        Container(
          margin: EdgeInsets.only(top: 8),
          padding: EdgeInsets.fromLTRB(25, 50, 25, 25),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Theme.of(context).colorScheme.primary,
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
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.55,
                  child: Column(
                    children: [
                      //Profile piccy
                      Container(
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: MediaQuery.of(context).size.width * 0.25,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondaryVariant,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      //Magic spacing...
                      SizedBox(
                        height: 15,
                      ),
                      //The name of the user
                      Container(
                        height: 75,
                        child: FittedBox(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              //I say Hi, cause I'm nice
                              Text(
                                "Hi ${context.watch<AuthAppProvider>().firstName} ${context.watch<AuthAppProvider>().lastName}!",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryVariant,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                              //Magic spacing...
                              SizedBox(
                                height: 5,
                              ),
                              //This is supposed to be wether the user is a normal peasant or a chad dev
                              Text(
                                'This is your info',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryVariant,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        /*
        * You wan't some more info and options? YOU GOTTEM!
        */
        Expanded(
          child: ListView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(25),
            children: [
              Container(
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
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text(
                                  '${context.watch<AuthAppProvider>().email}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 15, //TODO Fix this
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: context
                                            .watch<ColorProvider>()
                                            .shadow,
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
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text(
                                  'Your phone',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 15,
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: context
                                            .watch<ColorProvider>()
                                            .shadow,
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
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text(
                                  'Your something', //TODO: Probably remove this...
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.secondary,
                                    fontSize: 15,
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: context
                                            .watch<ColorProvider>()
                                            .shadow,
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
              //Magic spacing...
              SizedBox(
                height: 25,
              ),
              //Settings button!! It just changes from light to dark mode for now
              InkWell(
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
              //Magic spacing...
              SizedBox(
                height: 25,
              ),
              //If the user for some reason wanna sign out, I'm kind enough to have given them the option
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  signOut();
                },
                child: Container(
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
            ],
          ),
        ),
      ],
    );
  }
}
