import 'package:flutter/material.dart';

class ConfirmSignUpPageProvider with ChangeNotifier {
  String _promoCode = '';

  String get promoCode => _promoCode;

  set promoCode(String value) {
    _promoCode = value;
    notifyListeners();
  }

  String _confirmCode = '';
  String _firstName = '';
  String _lastName = '';
  bool _isLoading = false;
  bool _isSendingLoading = false;

  String get confirmCode => _confirmCode;
  String get firstName => _firstName;
  String get lastName => _lastName;
  bool get isLoading => _isLoading;
  bool get isSendingLoading => _isSendingLoading;

  set confirmCode(String value) {
    _confirmCode = value;
    notifyListeners();
  }

  set firstName(String value) {
    _firstName = value;
    notifyListeners();
  }

  set lastName(String value) {
    _lastName = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set isSendingLoading(bool value) {
    _isSendingLoading = value;
    notifyListeners();
  }
}
