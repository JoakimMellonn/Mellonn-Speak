import 'package:flutter/material.dart';

class CreatePromotionPageProvider with ChangeNotifier {
  bool _promotionAdded = false;
  bool _promotionRemoved = false;
  String _responseBody = '';
  String _removeResponseBody = '';

  String _typeValue = 'benefit';
  String _codeAdd = '';
  String _uses = '0';
  String _freePeriods = '0';
  String _referrer = '';
  bool _addLoading = false;

  String _codeRemove = '';
  bool _removeLoading = false;

  bool get promotionAdded => _promotionAdded;
  bool get promotionRemoved => _promotionRemoved;
  String get responseBody => _responseBody;
  String get removeResponseBody => _removeResponseBody;

  String get typeValue => _typeValue;
  bool get isReferrer => _typeValue == 'referrer' || _typeValue == 'referGroup';
  String get codeAdd => _codeAdd;
  String get uses => _uses;
  String get freePeriods => _freePeriods;
  String get referrer => _referrer;
  bool get addLoading => _addLoading;

  String get codeRemove => _codeRemove;
  bool get removeLoading => _removeLoading;

  set promotionAdded(bool value) {
    _promotionAdded = value;
    notifyListeners();
  }

  set promotionRemoved(bool value) {
    _promotionRemoved = value;
    notifyListeners();
  }

  set responseBody(String value) {
    _responseBody = value;
    notifyListeners();
  }

  set removeResponseBody(String value) {
    _removeResponseBody = value;
    notifyListeners();
  }

  set typeValue(String value) {
    _typeValue = value;
    notifyListeners();
  }

  set codeAdd(String value) {
    _codeAdd = value;
    notifyListeners();
  }

  set uses(String value) {
    _uses = value;
    notifyListeners();
  }

  set freePeriods(String value) {
    _freePeriods = value;
    notifyListeners();
  }

  set referrer(String value) {
    _referrer = value;
    notifyListeners();
  }

  set addLoading(bool value) {
    _addLoading = value;
    notifyListeners();
  }

  set codeRemove(String value) {
    _codeRemove = value;
    notifyListeners();
  }

  set removeLoading(bool value) {
    _removeLoading = value;
    notifyListeners();
  }

  void dispose() {
    _promotionAdded = false;
    _promotionRemoved = false;
    _responseBody = '';
    _removeResponseBody = '';
    _typeValue = 'benefit';
    _codeAdd = '';
    _uses = '0';
    _freePeriods = '0';
    _referrer = '';
    _addLoading = false;
    _codeRemove = '';
    _removeLoading = false;
    super.dispose();
  }
}
