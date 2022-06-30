import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:meta/meta.dart';

class OnboardPage extends StatelessWidget {
  const OnboardPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();

    List<Widget> pages = [
      Container(
        child: Center(
          child: Text(
            'Welcome to Mellonn Speak!',
          ),
        ),
      ),
      Container(
        child: Center(
          child: Text(
            'Upload recording',
          ),
        ),
      ),
      Container(
        child: Center(
          child: Text(
            'Edit speaker labels',
          ),
        ),
      ),
      Container(
        child: Center(
          child: Text(
            'Edit speakers',
          ),
        ),
      ),
      Container(
        child: Center(
          child: Text(
            'Edit text',
          ),
        ),
      ),
      Container(
        child: Center(
          child: Text(
            'Export',
          ),
        ),
      ),
      Container(
        child: Center(
          child: Text(
            'Get help inside the app',
          ),
        ),
      ),
    ];

    return Scaffold(
      body: PageView(
        controller: controller,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (controller.page != pages.length - 1) {
            controller.nextPage(duration: Duration(milliseconds: 200), curve: Curves.easeIn);
          } else {
            print('Last page');
          }
        },
        child: Icon(
          FontAwesomeIcons.arrowRight,
          color: Theme.of(context).colorScheme.secondary,
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class OnboardContent extends StatelessWidget {
  final String text;

  const OnboardContent({
    required this.text,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodyText2,
        ),
      ],
    );
  }
}
