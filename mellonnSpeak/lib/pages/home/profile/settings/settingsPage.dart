import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';
import 'package:url_launcher/url_launcher.dart';

Settings currentSettings = Settings(
  themeMode: 'System',
  languageCode: 'da-DK',
  jumpSeconds: 3,
);
String currentTheme = 'System';

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
    currentSettings = context.watch<SettingsProvider>().currentSettings;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).colorScheme.background,
      //Creating the same appbar that is used everywhere else
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        automaticallyImplyLeading: false,
        title: StandardAppBarTitle(),
        elevation: 0,
      ),
      //Creating the page
      body: Container(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            //Making that sweet title widget (with the sexy orange background and rounded corners)
            TitleBox(title: 'Settings', extras: true),
            //Getting the TranscriptionChatWidget with the given URL
            Expanded(
              child: Container(
                child: ListView(
                  physics: BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  children: [
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
                                initValue: currentSettings.themeMode,
                              ),
                            ],
                          ),
                          Text('If jank restart app'),
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
                            FontAwesomeIcons.cog,
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
                            initValue: currentSettings.jumpSeconds,
                          ),
                        ],
                      ),
                    ),

                    ///
                    ///Reset settings to default...
                    ///
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        bool saved = await context
                            .read<SettingsProvider>()
                            .setDefaultSettings(false);
                        print(saved);
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
                        margin: EdgeInsets.fromLTRB(25, 25, 25, 0),
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
    String currentValue = widget.initValue;
    return Container(
      child: DropdownButton(
        value: currentValue,
        items: <String>['System', 'Light', 'Dark']
            .map<DropdownMenuItem<String>>((String value) {
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
              currentSettings.themeMode = value;
              currentValue = value;
            });
            context.read<SettingsProvider>().saveSettings(currentSettings);
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
  String languageCode = '';
  @override
  Widget build(BuildContext context) {
    ///
    ///Getting variables from provider
    ///
    List<String> languageList = context.read<LanguageProvider>().languageList;
    List<String> languageCodeList =
        context.read<LanguageProvider>().languageCodeList;
    String dropdownValue = context
        .read<LanguageProvider>()
        .getLanguage(currentSettings.languageCode);
    languageCode = context.read<LanguageProvider>().defaultLanguageCode;

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
                  languageCode = context
                      .read<LanguageProvider>()
                      .getLanguageCode(dropdownValue);
                  currentSettings.languageCode = languageCode;
                });
                context.read<SettingsProvider>().saveSettings(currentSettings);
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
    int currentValue = widget.initValue;
    return Container(
      child: DropdownButton(
        value: currentValue,
        items: <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
            .map<DropdownMenuItem<int>>((int value) {
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
              currentSettings.jumpSeconds = value;
            });
            context.read<SettingsProvider>().saveSettings(currentSettings);
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
