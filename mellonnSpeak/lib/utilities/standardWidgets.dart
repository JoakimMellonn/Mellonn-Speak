import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/recordings/transcriptionPages/transcriptionPage.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';

///
///Standard stateless widgets
///
class StandardAppBarTitle extends StatelessWidget {
  const StandardAppBarTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String logoPath = '';
    String currentTheme =
        context.read<SettingsProvider>().currentSettings.themeMode;
    if (currentTheme == 'System') {
      var brightness = SchedulerBinding.instance!.window.platformBrightness;
      bool isDarkMode = brightness == Brightness.dark;
      if (isDarkMode) {
        logoPath = darkModeLogo;
      } else {
        logoPath = lightModeLogo;
      }
    } else if (currentTheme == 'Light') {
      logoPath = lightModeLogo;
    } else {
      logoPath = darkModeLogo;
    }
    return Center(
      child: Image.asset(
        logoPath,
        height: 25,
      ),
    );
  }
}

class StandardBox extends StatelessWidget {
  final BoxConstraints? constraints;
  final double? width;
  final double? height;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Widget child;

  const StandardBox({
    Key? key,
    this.constraints,
    this.width,
    this.height,
    this.color,
    this.padding,
    this.margin,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.all(25),
      margin: margin ?? EdgeInsets.all(0),
      width: width,
      height: height,
      constraints: constraints,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).colorScheme.secondaryContainer,
            blurRadius: 5,
          ),
        ],
      ),
      child: child,
    );
  }
}

class StandardButton extends StatelessWidget {
  final double? maxWidth;
  final String text;
  final Color? color;
  final bool shadow;

  const StandardButton({
    Key? key,
    this.maxWidth,
    required this.text,
    this.color,
    this.shadow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<BoxShadow> boxShadows = [
      BoxShadow(
        color: Theme.of(context).colorScheme.secondaryContainer,
        blurRadius: 3,
      ),
    ];
    if (!shadow) {
      boxShadows = [];
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 50,
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? MediaQuery.of(context).size.width,
      ),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(25),
        boxShadow: boxShadows,
      ),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.headline6,
        ),
      ),
    );
  }
}

class TitleBox extends StatelessWidget {
  final String title;
  final String heroString;
  final bool extras;
  final Color? color;
  final Color? textColor;
  final Widget? extra;
  final Function()? onBack;

  const TitleBox({
    Key? key,
    required this.title,
    required this.heroString,
    required this.extras,
    this.color,
    this.textColor,
    this.extra,
    this.onBack,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (extras) {
      return Container(
        margin: EdgeInsets.only(top: 5),
        padding: EdgeInsets.all(25),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: color ?? Theme.of(context).colorScheme.primary,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(context).colorScheme.secondaryContainer,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              constraints: BoxConstraints(
                maxHeight: 60,
                minWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: onBack ??
                        () {
                          Navigator.pop(context);
                        },
                    child: Icon(
                      FontAwesomeIcons.arrowLeft,
                      size: 30,
                      color: textColor ??
                          Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Hero(
                    tag: heroString,
                    child: Text(
                      title,
                      style: title.length < 12
                          ? Theme.of(context)
                              .textTheme
                              .headline1
                              ?.copyWith(color: textColor ?? Color(0xFF505050))
                          : Theme.of(context).textTheme.headline2?.copyWith(
                              fontSize: 26,
                              color: textColor ?? Color(0xFF505050)),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),
            extra ?? Container(),
          ],
        ),
      );
    } else {
      return Container(
        margin: EdgeInsets.only(top: 5),
        padding: EdgeInsets.all(25),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).colorScheme.primary,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color:
                  textColor ?? Theme.of(context).colorScheme.secondaryContainer,
              blurRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headline1
                      ?.copyWith(color: textColor ?? Color(0xFF505050)),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class OkAlert extends StatelessWidget {
  final String title;
  final String text;
  const OkAlert({
    Key? key,
    required this.title,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
      ),
      content: Text(
        text,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}

class SureDialog extends StatelessWidget {
  final String? text;
  final Function() onYes;
  const SureDialog({
    Key? key,
    this.text,
    required this.onYes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Are you sure?!'),
      content: Text(
        text ?? '',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('No'),
        ),
        TextButton(
          onPressed: onYes,
          child: const Text('Yes'),
        ),
      ],
    );
  }
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

///
///Standard stateful widgets
///
class StandardFormField extends StatefulWidget {
  final FocusNode focusNode;
  final String label;
  final Function(String textValue) onChanged;
  final String? validate;
  final bool changeColor;

  const StandardFormField({
    Key? key,
    required this.focusNode,
    required this.label,
    required this.onChanged,
    this.validate,
    this.changeColor = true,
  }) : super(key: key);

  @override
  _StandardFormFieldState createState() => _StandardFormFieldState();
}

class _StandardFormFieldState extends State<StandardFormField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: widget.focusNode,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (textValue) {
        String validateText = widget.validate ?? '';
        if (textValue == validateText) {
          return 'This field is mandatory';
        }
      },
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.label,
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: widget.changeColor
              ? (widget.focusNode.hasFocus
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary)
              : Theme.of(context).colorScheme.secondary,
          fontSize: 15,
          shadows: <Shadow>[
            Shadow(
              color: Theme.of(context).colorScheme.secondaryContainer,
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}

class LanguagePicker extends StatefulWidget {
  final Function(String?) onChanged;
  final String standardValue;
  final List<String> languageList;

  const LanguagePicker({
    Key? key,
    required this.onChanged,
    required this.standardValue,
    required this.languageList,
  }) : super(key: key);

  @override
  _LanguagePickerState createState() => _LanguagePickerState();
}

class _LanguagePickerState extends State<LanguagePicker> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: widget.standardValue,
      items: widget.languageList.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: Theme.of(context).textTheme.headline6,
          ),
        );
      }).toList(),
      onChanged: widget.onChanged,
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
    );
  }
}

class LoadingButton extends StatefulWidget {
  final String text;
  final bool isLoading;
  final Color? color;

  const LoadingButton({
    Key? key,
    required this.text,
    required this.isLoading,
    this.color,
  }) : super(key: key);

  @override
  _LoadingButtonState createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 250),
      curve: Curves.easeIn,
      height: 60,
      width: widget.isLoading ? 60 : MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.color ??
                Theme.of(context).colorScheme.secondaryContainer,
            blurRadius: 3,
          ),
        ],
      ),
      child: widget.isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: Text(
                widget.text,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
    );
  }
}
