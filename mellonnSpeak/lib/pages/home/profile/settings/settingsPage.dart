import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/src/provider.dart';

Settings currentSettings = Settings(
  darkMode: false,
  languageCode: 'da-DK',
);

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
                padding: EdgeInsets.all(25),
                child: ListView(
                  physics: BouncingScrollPhysics(),
                  children: [
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () {
                        context.read<ColorProvider>().toggleDarkMode();
                        context.read<ColorProvider>().setBGColor(2);
                        currentSettings.darkMode =
                            context.read<ColorProvider>().isDarkMode;
                        context
                            .read<SettingsProvider>()
                            .saveSettings(currentSettings);
                      },
                      child: StandardBox(
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
                              'Toggle darkmode',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 25,
                    ),
                    LanguageSelecter(),
                    SizedBox(
                      height: 25,
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

class LanguageSelecter extends StatefulWidget {
  const LanguageSelecter({Key? key}) : super(key: key);

  @override
  _LanguageSelecterState createState() => _LanguageSelecterState();
}

class _LanguageSelecterState extends State<LanguageSelecter> {
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
