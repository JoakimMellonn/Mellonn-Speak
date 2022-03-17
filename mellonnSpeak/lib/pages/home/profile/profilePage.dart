import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/promotion/getPromotionPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsPage.dart';
import 'package:mellonnSpeak/pages/login/loginPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPage.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePageMobile extends StatefulWidget {
  final Function() homePageSetState;
  const ProfilePageMobile({
    required this.homePageSetState,
    Key? key,
  }) : super(key: key);

  @override
  State<ProfilePageMobile> createState() => _ProfilePageMobileState();
}

class _ProfilePageMobileState extends State<ProfilePageMobile> {
  ///
  ///The function for signing out, if the name didn't tell you...
  ///
  void signOut() async {
    // ignore: unnecessary_statements
    context.read<DataStoreAppProvider>().clearRecordings(true);
    await Amplify.Auth.signOut();
    await Amplify.DataStore.clear();
    //Sends the user back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(),
      ),
    );
  }

  void profileSetState() {
    widget.homePageSetState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    String userGroup = context.read<AuthAppProvider>().userGroup;
    String userType = 'Standard account';
    if (userGroup == 'benefit') {
      userType = 'Benefit account (-40%)';
    } else if (userGroup == 'dev') {
      userType = 'Developer account';
    } else {
      userType = 'Standard account';
    }
    return Column(
      children: [
        StandardBox(
          margin: EdgeInsets.only(top: 5),
          color: Theme.of(context).colorScheme.primary,
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height < 800
              ? MediaQuery.of(context).size.height * 0.28
              : MediaQuery.of(context).size.height * 0.23,
          child: Column(
            children: [
              ///Profile pic circle
              Container(
                width: MediaQuery.of(context).size.height * 0.12,
                height: MediaQuery.of(context).size.height * 0.12,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 12,
              ),
              Text(
                'Hi ${context.watch<AuthAppProvider>().firstName} ${context.watch<AuthAppProvider>().lastName}!',
                style: Theme.of(context).textTheme.headline2,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            physics: BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: [
              ///
              ///Account info
              ///
              StandardBox(
                margin: EdgeInsets.all(25),
                child: Column(
                  children: [
                    Row(
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
                          context.watch<AuthAppProvider>().email,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ],
                    ),
                    Divider(
                      height: 35,
                    ),
                    Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.solidUser,
                          size: 20,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        SizedBox(
                          width: 15,
                        ),
                        Text(
                          userType,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ],
                    ),
                    Divider(
                      height: 35,
                    ),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) => OkAlert(
                            title: 'Free Credits',
                            text:
                                'A free credit gives up to 15 minutes of free transcription. The credits will be used automatically when uploading a recording.',
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.coins,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          SizedBox(
                            width: 15,
                          ),
                          Text(
                            'Free credits: ${context.read<AuthAppProvider>().freePeriods}',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              ///
              ///Get Promotion
              ///
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GetPromotionPage(),
                    ),
                  );
                },
                child: StandardBox(
                  margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                  child: Row(
                    children: [
                      Icon(
                        FontAwesomeIcons.percent,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Hero(
                        tag: 'getPromotion',
                        child: Text(
                          'Redeem promotional code',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              ///
              ///Settings
              ///
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsPage(
                        profileSetState: profileSetState,
                      ),
                    ),
                  );
                },
                child: StandardBox(
                  margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
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
                      Hero(
                        tag: 'settings',
                        child: Text(
                          'Settings',
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              ///
              ///HELP!
              ///
              StandardBox(
                margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
                child: Column(
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () => launch('https://www.mellonn.com/speak-help'),
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
                            'Help',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 40,
                    ),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SendFeedbackPage(
                              where: 'Report issue',
                              type: FeedbackType.issue,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: 30,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.bug,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              'Report issue',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              ///
              ///Sign out
              ///
              InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () => signOut(),
                child: StandardBox(
                  margin: EdgeInsets.fromLTRB(25, 0, 25, 25),
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
                        style: Theme.of(context).textTheme.headline6,
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
