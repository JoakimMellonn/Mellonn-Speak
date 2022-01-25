import 'package:flutter/material.dart';

class RecordingsPageTab extends StatelessWidget {
  const RecordingsPageTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Recordings Tab',
        style: Theme.of(context).textTheme.headline4,
      ),
    );
  }
}
