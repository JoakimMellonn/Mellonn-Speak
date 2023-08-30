import 'package:flutter/material.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';

class CreateLoginProvider with ChangeNotifier {
  String _email = '', _password = '', _confirmPassword = '', _promoCode = '', _promoString = '';
  bool _termsAgreed = false;
  Promotion? _promotion;
  bool _isLoading = false, _isLoadingPromo = false;

  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;
  String get promoCode => _promoCode;
  String get promoString => _promoString;
  bool get termsAgreed => _termsAgreed;
  Promotion? get promotion => _promotion;
  bool get isLoading => _isLoading;
  bool get isLoadingPromo => _isLoadingPromo;

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

  set promoCode(String value) {
    _promoCode = value;
    notifyListeners();
  }

  set promoString(String value) {
    _promoString = value;
    notifyListeners();
  }

  set termsAgreed(bool value) {
    _termsAgreed = value;
    notifyListeners();
  }

  set promotion(Promotion? value) {
    _promotion = value;
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set isLoadingPromo(bool value) {
    _isLoadingPromo = value;
    notifyListeners();
  }
}
