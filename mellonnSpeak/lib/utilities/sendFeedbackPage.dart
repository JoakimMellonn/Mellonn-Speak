import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class SendFeedbackPage extends StatefulWidget {
  final String where;
  const SendFeedbackPage({required this.where, Key? key}) : super(key: key);

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  String message = '';
  bool accepted = true;
  bool isSending = false;

  void checkBox(bool? value) {
    setState(() {
      accepted = value!;
    });
  }

  @override
  Widget build(BuildContext context) {
    String email = context.read<AuthAppProvider>().email;
    String name =
        '${context.read<AuthAppProvider>().firstName} ${context.read<AuthAppProvider>().lastName}';

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        //Creating the same appbar that is used everywhere else
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          automaticallyImplyLeading: false,
          title: StandardAppBarTitle(),
          elevation: 0,
        ),
        body: Column(
          children: [
            TitleBox(
              title: 'Send feedback',
              heroString: 'sendFeedback',
              extras: true,
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(25),
                children: [
                  StandardBox(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Text(
                            'Send feedback',
                            style: Theme.of(context).textTheme.headline5,
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Divider(),
                        TextField(
                          onChanged: (textValue) {
                            setState(() {
                              message = textValue;
                            });
                          },
                          maxLines: null,
                          maxLength: 500,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          decoration: InputDecoration(
                            labelText: 'Message',
                          ),
                        ),
                        SizedBox(
                          height: 15,
                        ),
                        Row(
                          children: [
                            Checkbox(
                              value: accepted,
                              onChanged: checkBox,
                            ),
                            Text(
                              'Mellonn can email me\nwith further questions',
                              style: Theme.of(context).textTheme.bodyText2,
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 25,
                        ),
                        InkWell(
                          onTap: () async {
                            if (!isSending) {
                              if (message == '') {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) => OkAlert(
                                    title: "You need to write a message",
                                    text:
                                        "You haven't written a message, please do so or we can't help you with the problem :(",
                                  ),
                                );
                              } else {
                                setState(() {
                                  isSending = true;
                                });
                                await sendFeedback(
                                  email,
                                  name,
                                  widget.where,
                                  message,
                                  accepted,
                                );
                                isSending = false;
                                await showDialog(
                                  context: context,
                                  builder: (BuildContext context) => OkAlert(
                                    title: "Feedback sent!",
                                    text: accepted
                                        ? 'Thank you for your feedback! If we have any further messages, we will send you an email.'
                                        : 'Thank you for your feedback!',
                                  ),
                                );
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: LoadingButton(
                            text: 'Send feedback',
                            isLoading: isSending,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
