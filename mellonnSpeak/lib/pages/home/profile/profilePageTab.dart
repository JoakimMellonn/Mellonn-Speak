import 'package:flutter/material.dart';

class ProfilePageTab extends StatelessWidget {
  const ProfilePageTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile Tab',
        style: Theme.of(context).textTheme.headline4,
      ),
    );
  }
}
