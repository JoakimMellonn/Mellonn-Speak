import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/src/provider.dart';
import 'package:mellonnSpeak/providers/colorProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/providers/settingsProvider.dart';

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
            Container(
              padding: EdgeInsets.all(25),
              width: MediaQuery.of(context).size.width,
              constraints: BoxConstraints(
                minHeight: 100,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            //Back button
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: 40,
                                minWidth:
                                    MediaQuery.of(context).size.width * 0.4,
                              ),
                              child: FittedBox(
                                child: Row(
                                  children: [
                                    InkWell(
                                      splashColor: Colors.transparent,
                                      highlightColor: Colors.transparent,
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                      child: Icon(
                                        FontAwesomeIcons.arrowLeft,
                                        size: 15,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                      ),
                                    ),
                                    //Magic spacing...
                                    SizedBox(
                                      width: 10,
                                    ),
                                    //Getting the recording title
                                    Text(
                                      "Settings",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context
                                            .watch<ColorProvider>()
                                            .darkText,
                                        shadows: <Shadow>[
                                          Shadow(
                                            color: context
                                                .watch<ColorProvider>()
                                                .shadow,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
                      child: SettingButton(
                        text: 'Toggle darkmode',
                        icon: Icon(
                          FontAwesomeIcons.cog,
                          size: 20,
                          color: Theme.of(context).colorScheme.secondary,
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
                      child: SettingButton(
                        text: 'Reset default settings',
                        icon: Icon(
                          FontAwesomeIcons.undo,
                          size: 20,
                          color: Theme.of(context).colorScheme.secondary,
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

class SettingButton extends StatefulWidget {
  final String text;
  final Icon icon;

  const SettingButton({
    Key? key,
    required this.text,
    required this.icon,
  }) : super(key: key);

  @override
  _SettingButtonState createState() => _SettingButtonState();
}

class _SettingButtonState extends State<SettingButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        minHeight: 50,
      ),
      padding: EdgeInsets.fromLTRB(25, 25, 35, 25),
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
                widget.icon,
                SizedBox(
                  width: 15,
                ),
                Text(
                  '${widget.text}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 15,
                    shadows: <Shadow>[
                      Shadow(
                        color: Theme.of(context).colorScheme.secondaryVariant,
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

    ///
    ///Widget build
    ///
    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        minHeight: 50,
      ),
      padding: EdgeInsets.fromLTRB(25, 25, 35, 25),
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
                  FontAwesomeIcons.language,
                  size: 20,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                SizedBox(
                  width: 15,
                ),
                Text(
                  'Select default language:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 15,
                    shadows: <Shadow>[
                      Shadow(
                        color: Theme.of(context).colorScheme.secondaryVariant,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 10,
          ),
          Container(
            alignment: Alignment.center,
            child: DropdownButton(
              value: dropdownValue,
              items: languageList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 15,
                      shadows: <Shadow>[
                        Shadow(
                          color: Theme.of(context).colorScheme.secondaryVariant,
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
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
              icon: Icon(
                Icons.arrow_downward,
                color: Theme.of(context).colorScheme.secondary,
              ),
              elevation: 16,
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                shadows: <Shadow>[
                  Shadow(
                    color: Theme.of(context).colorScheme.secondaryVariant,
                    blurRadius: 1,
                  ),
                ],
              ),
              underline: Container(
                height: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
