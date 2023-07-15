import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';

class SendFeedbackPage extends StatefulWidget {
  final String where;
  final FeedbackType type;
  const SendFeedbackPage({
    required this.where,
    required this.type,
    Key? key,
  }) : super(key: key);

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
    String name = '${context.read<AuthAppProvider>().firstName} ${context.read<AuthAppProvider>().lastName}';
    String title = 'Give feedback';
    String confirmation = 'Feedback sent!';

    if (widget.type == FeedbackType.feedback) {
      title = 'Give feedback';
      confirmation = 'Feedback sent!';
    } else {
      title = 'Report issue';
      confirmation = 'Issue reported!';
    }

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Stack(
          children: [
            BackGroundCircles(),
            Column(
              children: [
                standardAppBar(
                  context,
                  title,
                  'sendFeedback',
                  true,
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
                                title,
                                style: Theme.of(context).textTheme.headlineSmall,
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
                                  style: Theme.of(context).textTheme.bodySmall,
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
                                        text: "You haven't written a message, please do so or we can't help you with the problem/feedback :(",
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
                                        title: confirmation,
                                        text: accepted
                                            ? 'Thank you for your feedback! If we have any further questions, we will send you an email.'
                                            : 'Thank you for your feedback!',
                                      ),
                                    );
                                    Navigator.pop(context);
                                  }
                                }
                              },
                              child: LoadingButton(
                                text: title,
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
          ],
        ),
      ),
    );
  }
}

enum FeedbackType {
  feedback,
  issue,
}
