import 'package:flutter/material.dart';

class MainProvider with ChangeNotifier {
  bool _isLoading = true;
  bool _error = false;
  bool _isSharedData = false;

  bool get isLoading => _isLoading;
  bool get error => _error;
  bool get isSharedData => _isSharedData;

  set isLoading(bool value) {
    print("Setting isLoading to $value");
    _isLoading = value;
    notifyListeners();
  }

  set error(bool value) {
    _error = value;
    notifyListeners();
  }

  set isSharedData(bool value) {
    _isSharedData = value;
    notifyListeners();
  }
}
