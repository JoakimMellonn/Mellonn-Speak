import 'package:flutter/material.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';

class GetPromotionPageProvider with ChangeNotifier {
  String _code = '';
  String _discount = '';
  bool _gettingPromotion = false;
  late Promotion _promotion;

  String get code => _code;
  String get discount => _discount;
  bool get gettingPromotion => _gettingPromotion;
  Promotion get promotion => _promotion;

  set code(String code) {
    _code = code;
    notifyListeners();
  }

  set discount(String discount) {
    _discount = discount;
    notifyListeners();
  }

  set gettingPromotion(bool gettingPromotion) {
    _gettingPromotion = gettingPromotion;
    notifyListeners();
  }

  set promotion(Promotion promotion) {
    _promotion = promotion;
    notifyListeners();
  }
}
