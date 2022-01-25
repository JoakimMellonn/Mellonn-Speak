import 'package:mellonnSpeak/pages/home/homePageMobile.dart';
import 'package:mellonnSpeak/pages/home/profile/profilePage.dart';
import 'package:mellonnSpeak/pages/home/recordings/recordingsPage.dart';
import 'package:mellonnSpeak/pages/home/record/recordPage.dart';
import 'package:mellonnSpeak/pages/login/loginPage.dart';

var appRoutes = {
  '/': (context) => HomePageMobile(),
  '/home/profile': (context) => ProfilePageMobile(),
  '/home/record': (context) => RecordPageMobile(),
  '/home/recordings': (context) => RecordingsPageMobile(),
  '/login': (context) => LoginPage(),
};
