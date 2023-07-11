import 'package:flutter/material.dart';

void helpDialog(context, HelpPage page) {
  String title = '';
  List<Widget> content = [];

  List<Widget> transcriptionPage = [
    RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text:
                "Congratulations you have received your transcription! Now you can either begin to work on it, but you can also export it as a Word document.\n\n\n",
          ),
          TextSpan(
            text: "Export transcription\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text: "To export the transcription, you should just choose 'Export DOCX' in the menu, where you found this!\n\n\n",
          ),
          TextSpan(
            text: "Edit text bubbles\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text:
                "When reading your transcription, you can hold your finger on a chat bubble. Giving you the option to edit the text inside the chat bubble, or select a text span to change who said it.",
          ),
          TextSpan(
            text: "\n\n\nEdit speaker labels\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text:
                "To edit the speaker labels (names of the participants), you can press 'Edit labels' in the three dot menu. In there you can also change who's the interviewer and interviewee (Interviewer is shown with the green bubbles). The labels are shown underneath the chat bubbles, with first the label and then the speaker number in parenthesis, example: 'Adam (Speaker 1)', the speaker number is not shown in the exported Word-document.",
          ),
        ],
      ),
    ),
  ];

  List<Widget> versionHistory = [
    RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text:
                "On this page you can look through the history of changes made. Every time you save an edit, a new version will be saved. There's saved up to 10 versions and one original, which contains the result from the first transcription.\n\n\n",
          ),
          TextSpan(
            text: "Open a transcription\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text:
                "You can open the version of transcription just by pressing it. The version are sorted by the oldest first and latest last. Maximum amount of versions is 10, if this is exceeded it will remove the oldest version.\n\n\n",
          ),
          TextSpan(
            text: "Recover transcription\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text:
                "You can recover a transcription when you have opened a version, by pressing the upload icon in the top right of the page. When doing this, the last saved transcription will still be available to go back to.\n\n\n",
          ),
        ],
      ),
    ),
  ];

  List<Widget> speakerLabel = [
    RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text:
                "On this page you can change the labels on the participants in the recording. You can also change who's the interviewer and who's the interviewee. This screen is always shown the first time you open a transcription.\n\n\n",
          ),
          TextSpan(
            text: "Change the speaker labels\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text:
                "For each speaker/participant, you can change the labels in the text boxes. The labels can be a maximum length of 16 characters. In the dropdown menu, you can change wether the participant is the interviewer or the interviewee. There can be multiple interviewers/interviewees.\n\n\n",
          ),
          TextSpan(
            text: "Listen to clips of the participants\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text:
                "To be absolutely sure who's who, you can always listen to short clips of the interview. By pressing the 'Play' button, it will play the first clip of the participant that's five seconds. If you want to listen to another clip (this is recommended to be sure), you can press the 'Shuffle' button, this will play a random five second clip of the participant.\n\n\n",
          ),
          TextSpan(
            text: "Save the changes\n\n",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          TextSpan(
            text:
                "To save the changes made, you can press the 'Assign labels' button. You will then be sent directly to the page with the full transcription.\n\n\n",
          ),
        ],
      ),
    ),
  ];

  if (page == HelpPage.transcriptionPage) {
    title = 'Help - Transcription Reader';
    content = transcriptionPage;
  } else if (page == HelpPage.versionHistoryPage) {
    title = 'Help - Version History';
    content = versionHistory;
  } else if (page == HelpPage.speakerLabelsPage) {
    title = 'Help - Speaker Labels';
    content = speakerLabel;
  }
  Size size = MediaQuery.of(context).size;

  showModalBottomSheet(
    isScrollControlled: true,
    context: context,
    builder: (context) => Container(
      color: Theme.of(context).colorScheme.background,
      height: size.height * 0.8,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: Theme.of(context).colorScheme.background,
            automaticallyImplyLeading: false,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
            pinned: true,
            elevation: 0.5,
            surfaceTintColor: Color.fromARGB(38, 118, 118, 118),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              SizedBox(
                height: 5,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Column(
                  children: content,
                ),
              ),
              SizedBox(
                height: 50,
              ),
            ]),
          ),
        ],
      ),
    ),
  );
}

enum HelpPage {
  transcriptionPage,
  versionHistoryPage,
  speakerLabelsPage,
}
