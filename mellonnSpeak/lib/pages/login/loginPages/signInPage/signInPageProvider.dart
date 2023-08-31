import 'package:flutter/material.dart';

class SignInPageProvider with ChangeNotifier {
  String _email = '', _password = '';
  bool _isSignedIn = false, _isSignedInConfirmed = false, _isLoading = false;

  String get email => _email;
  String get password => _password;
  bool get isSignedIn => _isSignedIn;
  bool get isSignedInConfirmed => _isSignedInConfirmed;
  bool get isLoading => _isLoading;

  set email(String value) {
    _email = value;
    notifyListeners();
  }

  set password(String value) {
    _password = value;
    notifyListeners();
  }

  set isSignedIn(bool value) {
    _isSignedIn = value;
    notifyListeners();
  }

  set isSignedInConfirmed(bool value) {
    _isSignedInConfirmed = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void dispose() {
    _email = '';
    _password = '';
    _isSignedIn = false;
    _isSignedInConfirmed = false;
    _isLoading = false;
    super.dispose();
  }
}
