import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/superDevPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    context.read<SettingsProvider>().setCurrentSettings();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Stack(
          children: [
            BackGroundCircles(),
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  leading: appBarLeading(context),
                  pinned: true,
                  elevation: 0.5,
                  backgroundColor: Theme.of(context).colorScheme.background,
                  surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Hero(
                      tag: 'settings',
                      child: Text(
                        'Settings',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      ///
                      ///Theme selector... Pretty jank.
                      ///
                      StandardBox(
                        margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  FontAwesomeIcons.gear,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text(
                                  'Theme:',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                ThemeSelector(),
                              ],
                            ),
                          ],
                        ),
                      ),

                      ///
                      ///Language selector...
                      ///
                      LanguageSelector(),

                      ///
                      ///Option to select how much it should jump when listening.
                      ///
                      StandardBox(
                        margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                        child: Row(
                          children: [
                            Icon(
                              FontAwesomeIcons.stopwatch,
                              size: 20,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                            SizedBox(
                              width: 15,
                            ),
                            Text(
                              'Time to jump:',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            JumpSelector(),
                          ],
                        ),
                      ),

                      context.read<AuthAppProvider>().superDev
                          ? InkWell(
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SuperDevPage(),
                                  ),
                                );
                              },
                              child: StandardBox(
                                margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                                child: Row(
                                  children: [
                                    Icon(
                                      FontAwesomeIcons.dev,
                                      size: 20,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                    SizedBox(
                                      width: 15,
                                    ),
                                    Hero(
                                      tag: 'superDev',
                                      child: Text(
                                        'Super Dev Settings',
                                        style: Theme.of(context).textTheme.headlineSmall,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Container(),

                      ///
                      ///Reset settings to default...
                      ///
                      InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          await context.read<SettingsProvider>().setDefaultSettings();
                        },
                        child: StandardBox(
                          margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                          child: Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.arrowRotateLeft,
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              Text(
                                'Reset settings to default',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ),

                      ///
                      ///Deletes all the user data and the user
                      ///
                      InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () => removeUser(context),
                        child: StandardBox(
                          margin: EdgeInsets.fromLTRB(25, 25, 25, 25),
                          child: Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.trash,
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              Text(
                                'Delete my account',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> itemList = ['System', 'Light', 'Dark'];
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: () => showCupertinoDialogWidget(
          context,
          CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: itemList.indexOf(context.read<SettingsProvider>().themeMode),
            ),
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32,
            onSelectedItemChanged: (int selectedItem) {
              context.read<SettingsProvider>().themeMode = itemList[selectedItem];
            },
            children: List<Widget>.generate(itemList.length, (int index) {
              return Center(
                child: Text(
                  itemList[index],
                ),
              );
            }),
          ),
        ),
        child: Text(
          context.watch<SettingsProvider>().themeMode,
        ),
      );
    }
    return Container(
      child: DropdownButton(
        value: context.watch<SettingsProvider>().themeMode,
        items: itemList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            context.read<SettingsProvider>().themeMode = itemList[itemList.indexOf(value)];
          }
        },
        icon: Icon(
          Icons.arrow_downward,
          color: Theme.of(context).colorScheme.secondary,
        ),
        elevation: 16,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          shadows: <Shadow>[
            Shadow(
              color: Theme.of(context).colorScheme.secondaryContainer,
              blurRadius: 1,
            ),
          ],
        ),
        underline: Container(
          height: 0,
        ),
      ),
    );
  }
}

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ///
    ///Getting variables from provider
    ///
    List<String> languageList = context.read<LanguageProvider>().languageList;

    return StandardBox(
      margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                FontAwesomeIcons.language,
                size: 20,
                color: Theme.of(context).colorScheme.secondary,
              ),
              SizedBox(
                width: 15,
              ),
              Text(
                'Select default language:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            alignment: Alignment.center,
            child: LanguagePicker(
              onChanged: (String? newValue) {
                context.read<SettingsProvider>().languageCode = context.read<LanguageProvider>().getLanguageCode(newValue!);
                context.read<LanguageProvider>().setDefaultLanguage(context.read<SettingsProvider>().languageCode);
              },
              standardValue: context.read<LanguageProvider>().getLanguage(context.read<SettingsProvider>().languageCode),
              languageList: languageList,
            ),
          ),
        ],
      ),
    );
  }
}

class JumpSelector extends StatelessWidget {
  const JumpSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<int> valueList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: () => showCupertinoDialogWidget(
          context,
          CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: valueList.indexOf(context.read<SettingsProvider>().jumpSeconds),
            ),
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32,
            onSelectedItemChanged: (int selectedItem) {
              context.read<SettingsProvider>().jumpSeconds = valueList[selectedItem];
            },
            children: List<Widget>.generate(valueList.length, (int index) {
              return Center(
                child: Text(
                  valueList[index].toString(),
                ),
              );
            }),
          ),
        ),
        child: Text(
          context.watch<SettingsProvider>().jumpSeconds.toString(),
        ),
      );
    }
    return Container(
      child: DropdownButton(
        value: context.watch<SettingsProvider>().jumpSeconds,
        items: valueList.map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          );
        }).toList(),
        onChanged: (int? value) {
          if (value != null) {
            context.read<SettingsProvider>().jumpSeconds = value;
          }
        },
        icon: Icon(
          Icons.arrow_downward,
          color: Theme.of(context).colorScheme.secondary,
        ),
        elevation: 16,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          shadows: <Shadow>[
            Shadow(
              color: Theme.of(context).colorScheme.secondaryContainer,
              blurRadius: 1,
            ),
          ],
        ),
        underline: Container(
          height: 0,
        ),
      ),
    );
  }
}
