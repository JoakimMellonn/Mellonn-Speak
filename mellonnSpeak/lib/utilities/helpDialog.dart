import 'package:flutter/material.dart';

void helpDialog(context, HelpPage page) {
  String title = '';
  Widget content = Container();

  if (page == HelpPage.transcriptionPage) {
    title = 'Help - Transcription Reader';
    content = TranscriptionPageHelp();
  } else if (page == HelpPage.speakerEditPage) {
    title = 'Help - Speaker Label Editor';
    content = SpeakerEditHelp();
  } else if (page == HelpPage.textEditPage) {
    title = 'Help - Text Bubble Editor';
    content = TextEditHelp();
  } else if (page == HelpPage.versionHistoryPage) {
    title = 'Help - Version History';
    content = VersionHistoryHelp();
  } else if (page == HelpPage.speakerLabelsPage) {
    title = 'Help - Speaker Labels';
    content = SpeakerLabelsHelp();
  }

  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      contentPadding: EdgeInsets.fromLTRB(10, 25, 10, 25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.headline5,
      ),
      content: content,
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'OK');
          },
          child: Text(
            'OK',
            style: Theme.of(context).textTheme.headline6?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              shadows: <Shadow>[
                Shadow(
                  color: Colors.amber,
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        )
      ],
    ),
  );
}

enum HelpPage {
  transcriptionPage,
  speakerEditPage,
  textEditPage,
  versionHistoryPage,
  speakerLabelsPage,
}

class TranscriptionPageHelp extends StatelessWidget {
  const TranscriptionPageHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        physics: BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyText2,
              children: [
                TextSpan(
                  text:
                      "Congratulations you have received your transcription! Now you can either begin to work on it, but you can also export it as a Word document now.\n\n\n",
                ),
                TextSpan(
                  text: "Export transcription\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "To export the transcription, you should just choose 'Download DOCX' in the three dot menu, where you found this!\n\n\n",
                ),
                TextSpan(
                  text: "Play or edit text bubbles\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "When reading your transcription, you can always pull out a chat bubble. Giving you the option to either listen to the audio in the time frame, or edit the text inside the chat bubble.",
                ),
                WidgetSpan(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Image.asset(
                      "assets/gifs/chatBubblePull.gif",
                    ),
                  ),
                ),
                TextSpan(
                  text: "\n\n\nEdit speakers\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "To edit the speakers (who talks when), you can press 'Edit speakers' in the three dot menu. In there you can also just listen to the whole recording.",
                ),
                TextSpan(
                  text: "\n\n\nEdit speaker labels\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "To edit the speaker labels (names of the participants), you can press 'Edit labels' in the three dot menu. In there you can also change who's the interviewer and interviewee (Interviewer is shown with the green bubbles). The labels are shown underneath the chat bubbles, with first the label and then the speaker number in parenthesis, example: 'Adam (Speaker 1)', the speaker number is not shown in the exported Word-document.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpeakerEditHelp extends StatelessWidget {
  const SpeakerEditHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyText2,
              children: [
                TextSpan(
                  text:
                      "On this page you can listen to your recording, and if the AI didn't do the absolute perfect job, you can easily fix it!\n\n\n",
                ),
                TextSpan(
                  text: "Save the transcription\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "You can always save the changes you've made to the transcription, by pressing the save button in the top right of the page. When done saving it will send you back to the page with chat bubble and a green popup will confirm that it has been saved.\n\n\n",
                ),
                TextSpan(
                  text: "Listen to the recording\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "You can listen to your recording by using the media player box. You can of course play/pause the recording, but you can also use the fast forward/backward buttons to jump in the recording, you can change how much this will jump in the settings (default is 3 seconds). You can also use the progress bar to jump further in the recording. Last but not least, you can change the playback speed on the bottom of the page.",
                ),
                WidgetSpan(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Image.asset(
                      "assets/gifs/mediaController.gif",
                    ),
                  ),
                ),
                TextSpan(
                  text: "\n\n\nChange the speaker labels\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "While listening, if the label assignment isn't quite right, you can change this while listening to the recording. This is done by just clicking the box with the appropriate label. If you don't want the speaker labels to switch automatically, you can turn this off in the checkbox (be aware, this can be destructive, if you don't manually switch the labels while listening!).",
                ),
                WidgetSpan(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Image.asset(
                      "assets/gifs/labelEditor.gif",
                    ),
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

class TextEditHelp extends StatelessWidget {
  const TextEditHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyText2,
              children: [
                TextSpan(
                  text:
                      "On this page you can edit the text in your transcription, if the AI didn't do the absolute perfect job.\n\n\n",
                ),
                TextSpan(
                  text: "Save the transcription\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "You can always save the changes you've made to the transcription, by pressing the save button in the top right of the page. When done saving it will send you back to the page with chat bubble and a green popup will confirm that it has been saved.\n\n\n",
                ),
                TextSpan(
                  text: "Listen to the recording\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "You can listen to your recording by using the media player box. You can of course play/pause the recording, but you can also use the fast forward/backward buttons to jump in the recording, you can change how much this will jump in the settings (default is 3 seconds). You can also use the progress bar to jump further in the recording. Last but not least, you can change the playback speed on the bottom of the page.",
                ),
                WidgetSpan(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Image.asset(
                      "assets/gifs/mediaController.gif",
                    ),
                  ),
                ),
                TextSpan(
                  text: "\n\n\nEdit the text\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "If the AI didn't get it quite right, you can always edit the text! This you can easily do by pressing in the text box and changing what you want.",
                ),
                WidgetSpan(
                  child: Container(
                    padding: EdgeInsets.all(10),
                    child: Image.asset(
                      "assets/gifs/textEditor.gif",
                    ),
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

class VersionHistoryHelp extends StatelessWidget {
  const VersionHistoryHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyText2,
              children: [
                TextSpan(
                  text:
                      "On this page you can look through the history of changes made. Every time you save an edit, a new version will be saved. There's saved up to 10 versions and one original, which contains the result from the first transcription.\n\n\n",
                ),
                TextSpan(
                  text: "Open a transcription\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "You can open the version of transcription just by pressing it. The version are sorted by the oldest first and latest last. Maximum amount of versions is 10, if this is exceeded it will remove the oldest version.\n\n\n",
                ),
                TextSpan(
                  text: "Recover transcription\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "You can recover a transcription when you have opened a version, by pressing the upload icon in the top right of the page. When doing this, the last saved transcription will still be available to go back to.\n\n\n",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpeakerLabelsHelp extends StatelessWidget {
  const SpeakerLabelsHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      child: ListView(
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyText2,
              children: [
                TextSpan(
                  text:
                      "On this page you can change the labels on the participants in the recording. You can also change who's the interviewer and who's the interviewee. This screen is always shown the first time you open a transcription.\n\n\n",
                ),
                TextSpan(
                  text: "Change the speaker labels\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "For each speaker/participant, you can change the labels in the text boxes. The labels can be a maximum length of 16 characters. In the dropdown menu, you can change wether the participant is the interviewer or the interviewee. There can be multiple interviewers/interviewees.\n\n\n",
                ),
                TextSpan(
                  text: "Listen to clips of the participants\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "To be absolutely sure who's who, you can always listen to short clips of the interview. By pressing the 'Play' button, it will play the first clip of the participant that's five seconds. If you want to listen to another clip (this is recommended to be sure), you can press the 'Shuffle' button, this will play a random five second clip of the participant.\n\n\n",
                ),
                TextSpan(
                  text: "Save the changes\n\n",
                  style: Theme.of(context).textTheme.headline6,
                ),
                TextSpan(
                  text:
                      "To save the changes made, you can press the 'Assign labels' button. You will then be sent directly to the page with the full transcription.\n\n\n",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
