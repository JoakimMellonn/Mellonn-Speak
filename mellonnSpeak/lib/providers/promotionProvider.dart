import 'package:http/http.dart' as http;
import 'package:mellonnSpeak/pages/home/profile/promotion/getPromotionPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/addBenefitPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/createPromotionPage.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'dart:convert';

///
///Gets promotion and applies the discount.
///
Future<Promotion> getPromotion(
    Function() stateSetter, String code, String email, int freePeriods) async {
  final params = '{"code":"$code","email":"$email"}';

  final response = await http.put(
    Uri.parse(getPromotionEndPoint),
    headers: {
      "x-api-key": getPromotionKey,
    },
    body: params,
  );

  print(response.body);

  if (response.statusCode == 200) {
    gotPromotion = true;
    stateSetter();
    if (response.body == 'code no exist') {
      return Promotion(type: 'noExist', freePeriods: 0);
    } else if (response.body == 'code already used') {
      return Promotion(type: 'used', freePeriods: 0);
    } else {
      var jsonResponse = json.decode(response.body);
      Promotion promotion = Promotion(
          type: jsonResponse['type'],
          freePeriods: int.parse(jsonResponse['freePeriods']));
      await applyPromotion(stateSetter, promotion, email, freePeriods);
      return promotion;
    }
  } else {
    return Promotion(type: 'error', freePeriods: 0);
  }
}

///
///Applies the discount
///
Future<void> applyPromotion(Function() stateSetter, Promotion promotion,
    String email, int freePeriods) async {
  if (promotion.type == 'benefit') {
    await addEmail(email, stateSetter);
    if (promotion.freePeriods > 0) {
      await DataStoreAppProvider()
          .updateUserData(freePeriods + promotion.freePeriods, email);
    }
  } else {
    await DataStoreAppProvider()
        .updateUserData(freePeriods + promotion.freePeriods, email);
  }
}

///
///Adds an email to the list of benefit emails
///
Future<bool> addEmail(String email, Function() stateSetter) async {
  final params = '{"action": "add", "email": "$email"}';

  final response = await http.post(
    Uri.parse(addBenefitEndPoint),
    headers: {
      "x-api-key": addBenefitKey,
    },
    body: params,
  );

  print(response.body);

  if (response.statusCode == 200) {
    emailAdded = true;
    stateSetter();
    return true;
  } else {
    return false;
  }
}

///
///Removes an email from the list of benefit emails
///
Future<bool> removeEmail(String email, Function() stateSetter) async {
  final params = '{"action": "remove", "email": "$email"}';

  final response = await http.post(
    Uri.parse(addBenefitEndPoint),
    headers: {
      "x-api-key": addBenefitKey,
    },
    body: params,
  );

  print(response.body);

  if (response.statusCode == 200) {
    emailRemoved = true;
    stateSetter();
    return true;
  } else {
    return false;
  }
}

///
///Adds a promotion and creates a new one
///
Future<bool> addPromotion(Function() stateSetter, String type, String code,
    String uses, String freePeriods) async {
  final params =
      '{"action":"add","type":"$type","code":"$code","date":"","uses":$uses,"freePeriods":$freePeriods}';

  final response = await http.put(
    Uri.parse(addPromotionEndPoint),
    headers: {
      "x-api-key": addPromotionKey,
    },
    body: params,
  );

  print(response.body);

  if (response.statusCode == 200) {
    promotionAdded = true;
    responseBody = response.body;
    stateSetter();
    return true;
  } else {
    return false;
  }
}

///
///Removes a promotion
///
Future<bool> removePromotion(Function() stateSetter, String code) async {
  final params = '{"action":"remove","code":"$code"}';

  final response = await http.put(
    Uri.parse(addPromotionEndPoint),
    headers: {
      "x-api-key": addPromotionKey,
    },
    body: params,
  );

  print(response.body);

  if (response.statusCode == 200) {
    promotionRemoved = true;
    removeResponseBody = response.body;
    stateSetter();
    return true;
  } else {
    return false;
  }
}

class Promotion {
  String type;
  int freePeriods;

  Promotion({
    required this.type,
    required this.freePeriods,
  });
}
