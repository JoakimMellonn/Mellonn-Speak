import 'package:flutter/material.dart';

class ProfilePageMobile extends StatelessWidget {
  const ProfilePageMobile({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Profile',
        style: Theme.of(context).textTheme.headline4,
      ),
    );
  }
}
