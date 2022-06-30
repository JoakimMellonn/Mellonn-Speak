import 'package:flutter/material.dart';

class NewUpdatePage extends StatelessWidget {
  const NewUpdatePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        children: [
          Container(
            child: Center(
              child: Text(
                'Hello world!',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
