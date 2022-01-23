import 'package:flutter/material.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify.dart';

class AuthAppProvider with ChangeNotifier {
  //Creating the necessary variables
  String _email = "Couldn't get your email";
  String _firstName = "First name";
  String _lastName = "Last name";
  String _userGroup = "none";

  //Making the variables ready for providing
  String get email => _email;
  String get firstName => _firstName;
  String get lastName => _lastName;
  String get userGroup => _userGroup;

  /*
  * Creating the function that gets the user attributes
  */
  Future<void> getUserAttributes() async {
    try {
      var res = await Amplify.Auth
          .fetchUserAttributes(); //Fetching them and putting them in a list (res)

      /*
      * Checking each element in the list
      * First checking what they key is
      * Then assigning the value to the corresponding variable
      */
      res.forEach((element) {
        if (element.userAttributeKey == 'email') {
          _email = element.value;
        } else if (element.userAttributeKey == 'name') {
          _firstName = element.value;
        } else if (element.userAttributeKey == 'family_name') {
          _lastName = element.value;
        } else if (element.userAttributeKey == 'custom:group') {
          _userGroup = element.value;
          print('User group: $_userGroup');
        } else {
          print(
              'fail: ${element.value}, attribute: ${element.userAttributeKey}');
        }
      });
    } on AuthException catch (e) {
      print(e.message); //Just in case...
    }
  }

  //Notifying that something has changed
  notifyListeners();
}
