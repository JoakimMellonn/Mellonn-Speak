import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/sendFeedbackPageProvider.dart';
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
                                context.read<SendFeedbackPageProvider>().message = textValue;
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
                                  value: context.watch<SendFeedbackPageProvider>().accepted,
                                  onChanged: (value) {
                                    context.read<SendFeedbackPageProvider>().accepted = value!;
                                  },
                                ),
                                Text(
                                  'Mellonn can email me\nwith further questions',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                            SizedBox(
                              height: 25,
                            ),
                            InkWell(
                              onTap: () async {
                                if (!context.read<SendFeedbackPageProvider>().isSending) {
                                  if (context.read<SendFeedbackPageProvider>().message == '') {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) => OkAlert(
                                        title: "You need to write a message",
                                        text: "You haven't written a message, please do so or we can't help you with the problem/feedback :(",
                                      ),
                                    );
                                  } else {
                                    context.read<SendFeedbackPageProvider>().isSending = true;
                                    await context.read<AnalyticsProvider>().sendFeedback(
                                          email,
                                          name,
                                          widget.where,
                                          context.read<SendFeedbackPageProvider>().message,
                                          context.read<SendFeedbackPageProvider>().accepted,
                                        );
                                    context.read<SendFeedbackPageProvider>().isSending = false;
                                    await showDialog(
                                      context: context,
                                      builder: (BuildContext context) => OkAlert(
                                        title: confirmation,
                                        text: context.read<SendFeedbackPageProvider>().accepted
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
                                isLoading: context.watch<SendFeedbackPageProvider>().isSending,
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
