import 'package:flutter/material.dart';
import 'package:mellonnSpeak/pages/home/onboarding/onboardingProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();

    List<Widget> pages = [
      Container(
        child: Center(
          child: OnboardContent(
            svgAsset: 'assets/svg/welcome.svg',
            title: "Welcome to Mellonn Speak!",
            text: "Let's go through some of the features of Mellonn Speak!",
          ),
        ),
      ),
      Container(
        child: Center(
          child: OnboardContent(
            svgAsset: 'assets/svg/upload.svg',
            title: "Uploading a recording",
            text:
                "When uploading a recording, you can choose up to 10 participants and 34 different languages/accents. Our AI will then do the transcribing for you!",
          ),
        ),
      ),
      Container(
        child: Center(
          child: OnboardContent(
            svgAsset: 'assets/svg/labelEdit.svg',
            title: "Edit speaker labels",
            text: "When the transcription is done, you can give the participants labels, so you know who said what!",
          ),
        ),
      ),
      Container(
        child: Center(
          child: OnboardContent(
            svgAsset: 'assets/svg/speakerEdit.svg',
            title: "Edit speakers",
            text: "If the AI didn't get it quite right, you can always change who's talking when, while listening.",
          ),
        ),
      ),
      Container(
        child: Center(
          child: OnboardContent(
            svgAsset: 'assets/svg/textEdit.svg',
            title: "Edit text",
            text: "Say what?! If it wasn't what was said in the recording, you can always change it!",
          ),
        ),
      ),
      Container(
        child: Center(
          child: OnboardContent(
            svgAsset: 'assets/svg/export.svg',
            title: "Export the transcription",
            text: "When you're all done, you can export the transcription as a Word-document (DOCX).",
          ),
        ),
      ),
      Container(
        child: Center(
          child: OnboardContent(
            svgAsset: 'assets/svg/help.svg',
            title: "Help",
            text:
                "If you need help using one of Mellonn Speak's many tools, you can always press one of the many Help buttons throughout the app! If this doesn't answer your question, you can also report an issue and we will get back to you ASAP.",
          ),
        ),
      ),
    ];

    double shape1Width = MediaQuery.of(context).size.width * 0.5;
    double shape2Width = MediaQuery.of(context).size.width * 0.45;

    return Scaffold(
      body: Column(
        children: [
          Transform.translate(
            offset: Offset(-(MediaQuery.of(context).size.width * 0.3), -(MediaQuery.of(context).size.height * 0.03)),
            child: CustomPaint(
              size: Size(shape1Width, (shape1Width * 0.5087876236581772).toDouble()),
              painter: CustomOrangeShape(),
            ),
          ),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: PageView(
              controller: controller,
              onPageChanged: (page) {
                context.read<OnboardingProvider>().changeButtonText(page.round(), pages.length);
              },
              children: pages,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned(
                  right: -(MediaQuery.of(context).size.width * 0.06),
                  bottom: -(MediaQuery.of(context).size.height * 0.02),
                  child: Transform.scale(
                    scale: -1,
                    child: Opacity(
                      opacity: 0.75,
                      child: CustomPaint(
                        size: Size(shape2Width, (shape2Width * 0.5087876236581772).toDouble()),
                        painter: CustomOrangeShape(),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 7),
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onTap: () async {
                            if (controller.positions.isNotEmpty) {
                              if (controller.page!.round() < pages.length - 1) {
                                controller.nextPage(duration: Duration(milliseconds: 250), curve: Curves.ease);
                              } else {
                                final preferences = await SharedPreferences.getInstance();
                                await preferences.setBool('onboarded', true);
                                context.read<OnboardingProvider>().setOnboardedState(true);
                              }
                            }
                          },
                          child: StandardButton(
                            text: context.watch<OnboardingProvider>().buttonText,
                          ),
                        ),
                      ),
                      Spacer(),
                      SmoothPageIndicator(
                        controller: controller,
                        count: pages.length,
                        effect: WormEffect(
                          activeDotColor: Theme.of(context).colorScheme.primary,
                          dotWidth: 6,
                          dotHeight: 6,
                          spacing: 7,
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.04,
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
