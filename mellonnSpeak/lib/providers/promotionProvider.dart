import 'dart:typed_data';

import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mellonnSpeak/pages/home/profile/promotion/getPromotionPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/addBenefitPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/createPromotionPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'dart:convert';

///
///Gets promotion and applies the discount.
///
Future<Promotion> getPromotion(
    Function() stateSetter, String code, String email, int freePeriods) async {
  final params = '{"code":"$code","email":"$email"}';

  try {
    RestOptions options = RestOptions(
      apiName: 'getPromo',
      path: '/getPromo',
      body: Uint8List.fromList(params.codeUnits),
    );
    RestOperation restOperation = Amplify.API.post(restOptions: options);
    RestResponse response = await restOperation.response;

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
  } on RestException catch (err) {
    print(err);
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
  } else if (promotion.type == 'dev') {
    try {
      var attributes = [
        AuthUserAttribute(
          userAttributeKey: CognitoUserAttributeKey.custom("group"),
          value: 'dev',
        ),
      ];

      await Amplify.Auth.updateUserAttributes(attributes: attributes);
      await AuthAppProvider().getUserAttributes();
    } on AuthException catch (e) {
      recordEventError('applyPromotion', e.message);
      print(e.message);
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

  RestOptions options = RestOptions(
    apiName: 'getPromo',
    path: '/addRemBenefit',
    body: Uint8List.fromList(params.codeUnits),
  );
  RestOperation restOperation = Amplify.API.post(restOptions: options);
  RestResponse response = await restOperation.response;

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

  RestOptions options = RestOptions(
    apiName: 'getPromo',
    path: '/addRemBenefit',
    body: Uint8List.fromList(params.codeUnits),
  );
  RestOperation restOperation = Amplify.API.post(restOptions: options);
  RestResponse response = await restOperation.response;

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

  RestOptions options = RestOptions(
    apiName: 'getPromo',
    path: '/addPromo',
    body: Uint8List.fromList(params.codeUnits),
  );
  RestOperation restOperation = Amplify.API.post(restOptions: options);
  RestResponse response = await restOperation.response;

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

  RestOptions options = RestOptions(
    apiName: 'getPromo',
    path: '/addPromo',
    body: Uint8List.fromList(params.codeUnits),
  );
  RestOperation restOperation = Amplify.API.post(restOptions: options);
  RestResponse response = await restOperation.response;

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
