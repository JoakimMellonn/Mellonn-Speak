import 'package:flutter/material.dart';

class ForgotPasswordPageProvider with ChangeNotifier {
  bool _isPasswordReset = false, _codeSent = false, _isSendingLoading = false, _isConfirmLoading = false;
  String _email = '', _password = '', _confirmPassword = '', _confirmCode = '';
  RegExp _regExp = new RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+\.[a-zA-Z]+");

  bool get isPasswordReset => _isPasswordReset;
  bool get codeSent => _codeSent;
  bool get isSendingLoading => _isSendingLoading;
  bool get isConfirmLoading => _isConfirmLoading;
  bool get validEmail => _regExp.hasMatch(_email);
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get confirmCode => _confirmCode;

  set isPasswordReset(bool value) {
    _isPasswordReset = value;
    notifyListeners();
  }

  set codeSent(bool value) {
    _codeSent = value;
    notifyListeners();
  }

  set isSendingLoading(bool value) {
    _isSendingLoading = value;
    notifyListeners();
  }

  set isConfirmLoading(bool value) {
    _isConfirmLoading = value;
    notifyListeners();
  }

  set email(String value) {
    _email = value;
    notifyListeners();
  }

  set password(String value) {
    _password = value;
    notifyListeners();
  }

  set confirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  set confirmCode(String value) {
    _confirmCode = value;
    notifyListeners();
  }

  void dispose() {
    _isPasswordReset = false;
    _codeSent = false;
    _isSendingLoading = false;
    _isConfirmLoading = false;
    super.dispose();
  }
}
