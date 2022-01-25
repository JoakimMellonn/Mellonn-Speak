import 'package:flutter/material.dart';

class RecordPageTab extends StatelessWidget {
  const RecordPageTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Record Tab',
        style: Theme.of(context).textTheme.headline4,
      ),
    );
  }
}
