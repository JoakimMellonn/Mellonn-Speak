import 'package:flutter/material.dart';

class TranscriptionPageProvider with ChangeNotifier {
  List<String> _labels = [];
  int _originalSpeaker = 0;
  int _currentSpeaker = 0;
  bool _textSelected = false;
  bool _isTextSaved = true;
  bool _isSelectSaved = true;

  List<String> get labels => _labels;
  int get currentSpeaker => _currentSpeaker;
  bool get textSelected => _textSelected;
  bool get isSaved => _isTextSaved && _isSelectSaved;

  void setLabels(List<String> input) {
    _labels = input;
    notifyListeners();
  }

  void setOriginalSpeaker(int speaker) {
    _originalSpeaker = speaker;
    notifyListeners();
  }

  void setSpeaker(int speaker) {
    _currentSpeaker = speaker;
    setIsSelectSaved(speaker == _originalSpeaker);
    notifyListeners();
  }

  void setTextSelected(bool isSelected) {
    _textSelected = isSelected;
    notifyListeners();
  }

  void setIsTextSaved(bool isSaved) {
    _isTextSaved = isSaved;
    notifyListeners();
  }

  void setIsSelectSaved(bool isSaved) {
    _isSelectSaved = isSaved;
    notifyListeners();
  }
}

String getMinSec(double seconds) {
  double minDouble = seconds / 60;
  int minInt = minDouble.floor();
  double secDouble = seconds - (minInt * 60);
  int secInt = secDouble.floor();

  String minSec = '${minInt}m ${secInt}s';
  String sec = '${secInt}s';

  if (minInt == 0) {
    return sec;
  } else {
    return minSec;
  }
}

int getMil(double seconds) {
  double milliseconds = seconds * 1000;
  return milliseconds.toInt();
}
