import 'package:flutter/material.dart';

class SendFeedbackPageProvider with ChangeNotifier {
  String _message = '';
  bool _accepted = true, _isSending = false;

  String get message => _message;
  bool get accepted => _accepted;
  bool get isSending => _isSending;

  set message(String value) {
    _message = value;
    notifyListeners();
  }

  set accepted(bool value) {
    _accepted = value;
    notifyListeners();
  }

  set isSending(bool value) {
    _isSending = value;
    notifyListeners();
  }
}
