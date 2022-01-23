import 'package:mellonnSpeak/pages/home/homePage.dart';
import 'package:mellonnSpeak/pages/home/profile/profilePage.dart';
import 'package:mellonnSpeak/pages/home/recordings/recordingsPage.dart';
import 'package:mellonnSpeak/pages/login/loginPage.dart';
import 'package:mellonnSpeak/pages/oldPages/mainAppPages/recordPage.dart';

var appRoutes = {
  '/': (context) => HomePage(),
  '/home/profile': (context) => ProfilePage(),
  '/home/record': (context) => RecordPage(),
  '/home/recordings': (context) => RecordingsPage(),
  '/login': (context) => LoginPage(),
};
