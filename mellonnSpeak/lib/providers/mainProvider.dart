import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:mellonnSpeak/models/Recording.dart';

class MainProvider with ChangeNotifier {
  bool _isLoading = true;
  bool _error = false;
  bool _isSharedData = false;
  PushNotificationPermissionStatus? _pushNotificationPermissionStatus;

  bool get isLoading => _isLoading;
  bool get error => _error;
  bool get isSharedData => _isSharedData;
  PushNotificationPermissionStatus? get pushNotificationPermissionStatus => _pushNotificationPermissionStatus;

  set isLoading(bool value) {
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

  set pushNotificationPermissionStatus(PushNotificationPermissionStatus? value) {
    _pushNotificationPermissionStatus = value;
    notifyListeners();
  }
}
