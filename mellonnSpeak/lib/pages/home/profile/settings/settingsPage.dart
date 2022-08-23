import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/models/Settings.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/superDevPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

String currentTheme = 'System';

String themeMode = 'System';
String languageCode = 'en-US';
int jumpSeconds = 3;

class SettingsPage extends StatefulWidget {
  final Function() profileSetState;
  const SettingsPage({
    required this.profileSetState,
    Key? key,
  }) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    context.read<SettingsProvider>().setCurrentSettings();
    setValues(context.read<SettingsProvider>().currentSettings);
    super.initState();
  }

  Future initialize() async {
    await context.read<SettingsProvider>().setCurrentSettings();
    setValues(context.read<SettingsProvider>().currentSettings);
  }

  void setValues(Settings settings) {
    themeMode = settings.themeMode;
    languageCode = settings.languageCode;
    jumpSeconds = settings.jumpSeconds;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Theme.of(context).backgroundColor,
        child: Stack(
          children: [
            BackGroundCircles(
              colorBig: Color.fromARGB(163, 250, 176, 40),
              colorSmall: Color.fromARGB(112, 250, 176, 40),
            ),
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  leading: appBarLeading(context),
                  pinned: true,
                  elevation: 0.5,
                  surfaceTintColor: Theme.of(context).shadowColor,
                  expandedHeight: 100,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Hero(
                      tag: 'settings',
                      child: Text(
                        'Settings',
                        style: Theme.of(context).textTheme.headline2,
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
                                  FontAwesomeIcons.cog,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                                SizedBox(
                                  width: 15,
                                ),
                                Text(
                                  'Theme:',
                                  style: Theme.of(context).textTheme.headline6,
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                ThemeSelector(
                                  initValue: themeMode,
                                ),
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
                              style: Theme.of(context).textTheme.headline6,
                            ),
                            SizedBox(
                              width: 20,
                            ),
                            JumpSelector(
                              initValue: jumpSeconds,
                            ),
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
                                        style: Theme.of(context).textTheme.headline6,
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
                          setState(() {
                            initialize();
                          });
                        },
                        child: StandardBox(
                          margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
                          child: Row(
                            children: [
                              Icon(
                                FontAwesomeIcons.undo,
                                size: 20,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              SizedBox(
                                width: 15,
                              ),
                              Text(
                                'Reset settings to default',
                                style: Theme.of(context).textTheme.headline6,
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
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeSelector extends StatefulWidget {
  final String initValue;
  const ThemeSelector({Key? key, required this.initValue}) : super(key: key);

  @override
  _ThemeSelectorState createState() => _ThemeSelectorState();
}

class _ThemeSelectorState extends State<ThemeSelector> {
  @override
  Widget build(BuildContext context) {
    List<String> itemList = ['System', 'Light', 'Dark'];
    String currentValue = widget.initValue;
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: () => showCupertinoDialogWidget(
          context,
          CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: itemList.indexOf(currentValue),
            ),
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32,
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                currentValue = itemList[selectedItem];
                themeMode = itemList[selectedItem];
              });
              Settings saveSettings = context.read<SettingsProvider>().currentSettings.copyWith(
                    themeMode: themeMode,
                  );
              context.read<SettingsProvider>().saveSettings(saveSettings);
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
          currentValue,
        ),
      );
    }
    return Container(
      child: DropdownButton(
        value: currentValue,
        items: itemList.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: Theme.of(context).textTheme.headline6,
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            setState(() {
              currentValue = value;
              themeMode = value;
            });
            Settings saveSettings = context.read<SettingsProvider>().currentSettings.copyWith(
                  themeMode: themeMode,
                );
            context.read<SettingsProvider>().saveSettings(saveSettings);
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

class LanguageSelector extends StatefulWidget {
  const LanguageSelector({Key? key}) : super(key: key);

  @override
  _LanguageSelectorState createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  @override
  Widget build(BuildContext context) {
    ///
    ///Getting variables from provider
    ///
    List<String> languageList = context.read<LanguageProvider>().languageList;
    String dropdownValue = context.read<LanguageProvider>().getLanguage(languageCode);

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
                style: Theme.of(context).textTheme.headline6,
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
                setState(() {
                  dropdownValue = newValue!;
                  languageCode = context.read<LanguageProvider>().getLanguageCode(newValue);
                });
                Settings saveSettings = context.read<SettingsProvider>().currentSettings.copyWith(
                      languageCode: languageCode,
                    );
                context.read<LanguageProvider>().setDefaultLanguage(languageCode);
                context.read<SettingsProvider>().saveSettings(saveSettings);
              },
              standardValue: dropdownValue,
              languageList: languageList,
            ),
          ),
        ],
      ),
    );
  }
}

class JumpSelector extends StatefulWidget {
  final int initValue;
  const JumpSelector({Key? key, required this.initValue}) : super(key: key);

  @override
  _JumpSelectorState createState() => _JumpSelectorState();
}

class _JumpSelectorState extends State<JumpSelector> {
  @override
  Widget build(BuildContext context) {
    List<int> valueList = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    int currentValue = widget.initValue;
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: () => showCupertinoDialogWidget(
          context,
          CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: valueList.indexOf(currentValue),
            ),
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32,
            onSelectedItemChanged: (int selectedItem) {
              setState(() {
                currentValue = valueList[selectedItem];
                jumpSeconds = valueList[selectedItem];
              });
              Settings saveSettings = context.read<SettingsProvider>().currentSettings.copyWith(
                    themeMode: themeMode,
                  );
              context.read<SettingsProvider>().saveSettings(saveSettings);
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
          currentValue.toString(),
        ),
      );
    }
    return Container(
      child: DropdownButton(
        value: currentValue,
        items: valueList.map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text(
              value.toString(),
              style: Theme.of(context).textTheme.headline6,
            ),
          );
        }).toList(),
        onChanged: (int? value) {
          if (value != null) {
            setState(() {
              jumpSeconds = value;
            });
            Settings saveSettings = context.read<SettingsProvider>().currentSettings.copyWith(
                  jumpSeconds: jumpSeconds,
                );
            context.read<SettingsProvider>().saveSettings(saveSettings);
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
