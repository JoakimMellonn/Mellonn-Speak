import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:provider/provider.dart';

///
///AppBar stuff
///
AppBar standardAppBar(BuildContext context, String title, String tag, bool backButton) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.background,
    surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
    elevation: 0.5,
    leading: backButton ? appBarLeading(context) : null,
    automaticallyImplyLeading: backButton,
    title: Hero(
      tag: tag,
      child: backButton
          ? Text(
              title,
              style: Theme.of(context).textTheme.headline5,
            )
          : Center(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headline5,
              ),
            ),
    ),
  );
}

Widget appBarLeading(BuildContext context) {
  return IconButton(
    color: Theme.of(context).colorScheme.primary,
    padding: EdgeInsets.only(left: 30),
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    onPressed: () => Navigator.pop(context),
    icon: Icon(
      FontAwesomeIcons.angleLeft,
      size: 28,
    ),
  );
}

///
///Standard stateless widgets
///
class StandardAppBarTitle extends StatelessWidget {
  const StandardAppBarTitle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String logoPath = '';
    String currentTheme = context.read<SettingsProvider>().currentSettings.themeMode;
    if (currentTheme == 'System') {
      var brightness = SchedulerBinding.instance.window.platformBrightness;
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
  final double? blurRadius;
  final Widget child;

  const StandardBox({
    Key? key,
    this.constraints,
    this.width,
    this.height,
    this.color,
    this.padding,
    this.margin,
    this.blurRadius,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.fromLTRB(20, 15, 20, 15),
      margin: margin ?? EdgeInsets.all(0),
      width: width,
      height: height,
      constraints: constraints,
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: blurRadius ?? 10,
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
        color: Theme.of(context).shadowColor,
        blurRadius: shadowRadius,
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
        color: color ?? Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(15),
        boxShadow: boxShadows,
      ),
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.headline3,
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
        margin: EdgeInsets.only(top: shadowRadius),
        padding: EdgeInsets.fromLTRB(25, 15, 25, 15),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: color ?? Theme.of(context).colorScheme.primary,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: shadowRadius,
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
                      color: textColor ?? Theme.of(context).colorScheme.onSecondary,
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
                          ? Theme.of(context).textTheme.headline1?.copyWith(color: textColor ?? Color(0xFF505050))
                          : Theme.of(context).textTheme.headline2?.copyWith(fontSize: 26, color: textColor ?? Color(0xFF505050)),
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
        margin: EdgeInsets.only(top: shadowRadius),
        padding: EdgeInsets.fromLTRB(25, 15, 25, 15),
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).colorScheme.primary,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Theme.of(context).shadowColor,
              blurRadius: shadowRadius,
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
                  style: Theme.of(context).textTheme.headline1?.copyWith(color: textColor ?? Color(0xFF505050)),
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
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text(
          title,
        ),
        content: Text(
          text,
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      );
    } else {
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
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        title: Text('Are you sure?!'),
        content: Text(
          text ?? '',
        ),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: true,
            child: const Text('No'),
          ),
          CupertinoDialogAction(
            onPressed: onYes,
            isDestructiveAction: true,
            child: const Text('Yes'),
          ),
        ],
      );
    } else {
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
}

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class BackGroundCircles extends StatelessWidget {
  final Color colorBig;
  final Color colorSmall;

  const BackGroundCircles({
    Key? key,
    required this.colorBig,
    required this.colorSmall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: [
          Positioned(
            left: MediaQuery.of(context).size.width * 0.36,
            top: MediaQuery.of(context).size.height * 0.48,
            child: Container(
              width: MediaQuery.of(context).size.width * 1.55,
              height: MediaQuery.of(context).size.width * 1.55,
              decoration: BoxDecoration(
                color: colorBig,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * -0.24,
            top: MediaQuery.of(context).size.height * 0.66,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.84,
              height: MediaQuery.of(context).size.width * 0.84,
              decoration: BoxDecoration(
                color: colorSmall,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
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
        return null;
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
              ? (widget.focusNode.hasFocus ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary)
              : Theme.of(context).colorScheme.secondary,
          fontSize: 15,
          shadows: <Shadow>[
            Shadow(
              color: Theme.of(context).colorScheme.secondaryContainer,
              blurRadius: shadowRadius,
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
    if (Platform.isIOS) {
      return CupertinoButton(
        onPressed: () => showCupertinoDialogWidget(
          context,
          CupertinoPicker(
            scrollController: FixedExtentScrollController(
              initialItem: widget.languageList.indexOf(widget.standardValue),
            ),
            magnification: 1.22,
            squeeze: 1.2,
            useMagnifier: true,
            itemExtent: 32,
            onSelectedItemChanged: (int selectedItem) {
              widget.onChanged(widget.languageList[selectedItem]);
            },
            children: List<Widget>.generate(widget.languageList.length, (int index) {
              return Center(
                child: Text(
                  widget.languageList[index],
                ),
              );
            }),
          ),
        ),
        child: Text(
          widget.standardValue,
        ),
      );
    }
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
            blurRadius: shadowRadius,
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
  final double? maxWidth;
  final String text;
  final bool isLoading;
  final Color? color;

  const LoadingButton({
    Key? key,
    this.maxWidth,
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
      height: 50,
      constraints: BoxConstraints(
        maxWidth: widget.isLoading ? 50 : widget.maxWidth ?? MediaQuery.of(context).size.width,
      ),
      width: widget.isLoading ? 50 : MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: widget.color ?? Theme.of(context).colorScheme.primary,
        borderRadius: widget.isLoading ? BorderRadius.circular(25) : BorderRadius.circular(15),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: shadowRadius,
          ),
        ],
      ),
      child: widget.isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.surface,
              ),
            )
          : Center(
              child: Text(
                widget.text,
                style: Theme.of(context).textTheme.headline3,
              ),
            ),
    );
  }
}

class ShowOnceDialog extends StatefulWidget {
  final String title;
  final String content;
  final Function(bool?) onChanged;
  final Function() onOk;
  const ShowOnceDialog({
    required this.title,
    required this.content,
    required this.onChanged,
    required this.onOk,
    Key? key,
  }) : super(key: key);

  @override
  State<ShowOnceDialog> createState() => _ShowOnceDialogState();
}

class _ShowOnceDialogState extends State<ShowOnceDialog> {
  bool dontShowAgain = false;
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: Theme.of(context).textTheme.headline6,
      ),
      content: Container(
        height: 250,
        child: Column(
          children: [
            Text(
              widget.content,
              style: Theme.of(context).textTheme.bodyText2?.copyWith(
                    fontSize: 14,
                  ),
            ),
            Spacer(),
            Row(
              children: [
                Text(
                  "Don't show this again",
                  style: Theme.of(context).textTheme.bodyText2?.copyWith(
                        fontSize: 16,
                      ),
                ),
                Checkbox(
                  value: dontShowAgain,
                  onChanged: (value) {
                    widget.onChanged(value);
                    setState(() {
                      dontShowAgain = value ?? false;
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        Container(
          padding: EdgeInsets.fromLTRB(15, 0, 15, 5),
          child: Row(
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: widget.onOk,
                child: Text(
                  "OK",
                  style: Theme.of(context).textTheme.headline6?.copyWith(color: Theme.of(context).colorScheme.primary, shadows: <Shadow>[
                    Shadow(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

///
///Cupertino stuff
///
void showCupertinoDialogWidget(BuildContext context, Widget child) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => Container(
      height: 216,
      padding: const EdgeInsets.only(top: 6.0),
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      color: CupertinoColors.systemBackground.resolveFrom(context),
      child: SafeArea(
        top: false,
        child: child,
      ),
    ),
  );
}

void showCupertinoActionSheet(BuildContext context, String title, List<CupertinoActionSheetAction> actions) {
  showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext context) => CupertinoActionSheet(
      title: Text(title),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: SchedulerBinding.instance.window.platformBrightness == Brightness.dark ? Colors.white : Colors.black,
          ),
        ),
      ),
    ),
  );
}
