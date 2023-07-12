@deprecated
import 'dart:io';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:mellonnSpeak/pages/home/profile/promotion/getPromotionPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/addBenefitPage.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/superDev/devPages/createPromotionPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

///
///Gets promotion from the given code.
///
Future<Promotion> getPromotion(Function() stateSetter, String code, String email, int freePeriods, bool applyPromo) async {
  final params = '{"code":"$code","email":"$email"}';
  Promotion failPromo = Promotion(
    code: code,
    type: 'error',
    freePeriods: 0,
    referrer: '',
    referGroup: '',
  );

  try {
    final response = await Amplify.API.post("getPromo/getPromotion", body: HttpPayload.json(params)).response;

    print(response.decodeBody());

    if (response.statusCode == 200) {
      gotPromotion = true;
      stateSetter();
      if (response.decodeBody() == 'code no exist') {
        failPromo.type = 'noExist';
        return failPromo;
      } else if (response.decodeBody() == 'code already used') {
        failPromo.type = 'used';
        return failPromo;
      } else {
        var jsonResponse = json.decode(response.decodeBody());
        Promotion promotion = Promotion(
          code: code,
          type: jsonResponse['type'],
          freePeriods: int.parse(jsonResponse['freePeriods'].toString()),
          referrer: jsonResponse['referrer'] ?? '',
          referGroup: jsonResponse['referGroup'] ?? '',
        );
        if (applyPromo) await applyPromotion(stateSetter, promotion, email, freePeriods);
        return promotion;
      }
    } else {
      return failPromo;
    }
  } on HttpStatusException catch (err) {
    print(err.message);
    return failPromo;
  }
}

///
///Applies the discount
///
Future<void> applyPromotion(Function() stateSetter, Promotion promotion, String email, int freePeriods) async {
  final params = '{"code":"${promotion.code}","email":"$email"}';
  try {
    await Amplify.API.post("getPromo/applyPromotion", body: HttpPayload.json(params)).response;
  } on HttpStatusException catch (err) {
    print(err.message);
  }

  if (promotion.type == 'benefit') {
    await addRemEmail(email, AddRemAction.add, stateSetter);
    if (promotion.freePeriods > 0) {
      await DataStoreAppProvider().updateUserData(freePeriods + promotion.freePeriods, email);
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
    } on AuthException catch (e) {
      recordEventError('applyPromotion', e.message);
      print(e.message);
    }
  } else if (promotion.type == 'referrer') {
    await addUserToReferrer(promotion.referrer, email, null);
    if (promotion.freePeriods > 0) {
      await DataStoreAppProvider().updateUserData(freePeriods + promotion.freePeriods, email);
    }
  } else if (promotion.type == 'referGroup') {
    await addUserToReferrer(promotion.referrer, email, promotion.referGroup);
    if (promotion.freePeriods > 0) {
      await DataStoreAppProvider().updateUserData(freePeriods + promotion.freePeriods, email);
    }
  } else {
    await DataStoreAppProvider().updateUserData(freePeriods + promotion.freePeriods, email);
  }
  await AuthAppProvider().getUserAttributes();
}

///
///Adds an email to the list of benefit emails
///
Future<bool> addRemEmail(String email, AddRemAction action, Function() stateSetter) async {
  String actionString = 'add';
  if (action == AddRemAction.remove) actionString = 'remove';
  final params = '{"action": "$actionString", "email": "$email"}';

  final response = await Amplify.API.post("getPromo/addRemBenefit", body: HttpPayload.json(params)).response;

  print(response.decodeBody());

  if (response.statusCode == 200) {
    emailAdded = true;
    stateSetter();
    return true;
  } else {
    return false;
  }
}

///
///Adds a promotion and creates a new one
///
Future<bool> addPromotion(Function() stateSetter, String type, String code, String uses, String freePeriods) async {
  final params = '{"action":"add","type":"$type","code":"$code","date":"","uses":$uses,"freePeriods":$freePeriods}';

  final response = await Amplify.API.post("getPromo/addPromo", body: HttpPayload.json(params)).response;

  print(response.decodeBody());

  if (response.statusCode == 200) {
    promotionAdded = true;
    responseBody = response.decodeBody();
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

  final response = await Amplify.API.post("getPromo/addPromo", body: HttpPayload.json(params)).response;

  print(response.decodeBody());

  if (response.statusCode == 200) {
    promotionRemoved = true;
    removeResponseBody = response.decodeBody();
    stateSetter();
    return true;
  } else {
    return false;
  }
}

Future<bool> addUserToReferrer(String referrer, String email, String? referGroup) async {
  final tempDir = await getTemporaryDirectory();
  final filePath = tempDir.path + '/referrerEmails.json';
  final file = File(filePath);
  final key = 'data/referrers/$referrer.json';

  try {
    List<String> emails = [];

    final urlResult = await Amplify.Storage.getUrl(key: key).result;
    final String response = (await http.get(Uri.parse(urlResult.url.toString()))).body;

    final result = json.decode(response);

    for (String referEmail in result['emails']) {
      emails.add(referEmail);
      if (referEmail == email) {
        return true;
      }
    }

    emails.add(email);
    var newReferrer = result;
    newReferrer['emails'] = emails;
    final newString =
        '{"referrer": "${result['referrer']}", "purchases": ${result['purchases']}, "periods": ${result['periods']}, "emails": [${emails.map((e) => '"$e"')}]}'
            .replaceAll('(', '')
            .replaceAll(')', '');
    await file.writeAsString(newString);
    await Amplify.Storage.uploadFile(localFile: AWSFile.fromPath(file.path), key: key).result;

    if (referGroup != null) {
      print('Refergroup api');
      return await addRemReferGroupAPI(AddRemAction.add, email, referGroup, referrer);
    }

    return true;
  } catch (err) {
    print('Error when adding user to group: $err');
    return false;
  }
}

Future<bool> addRemReferGroupAPI(AddRemAction action, String email, String referGroup, String referrer) async {
  String actionString = 'add';
  if (action == AddRemAction.remove) actionString = 'remove';
  final params = '{"action":"$actionString","email":"$email","referGroup":"$referGroup","referrer":"$referrer"}';

  try {
    await Amplify.API.post("getPromo/addRemReferGroup", body: HttpPayload.json(params)).response;
    await addRemEmail(email, action, () => null);
    return true;
  } on HttpStatusException catch (err) {
    print('Error while adding user to referGroup: ${err.message}');
    return false;
  }
}

class Promotion {
  String code;
  String type;
  int freePeriods;
  String referrer;
  String referGroup;

  Promotion({
    required this.code,
    required this.type,
    required this.freePeriods,
    required this.referrer,
    required this.referGroup,
  });

  String discountString() {
    if ((this.type == 'benefit' || this.type == 'referGroup') && this.freePeriods > 0) {
      return 'Benefit user \n(-40% on all purchases) \nand ${this.freePeriods} free credit(s)';
    } else if ((this.type == 'benefit' || this.type == 'referGroup') && this.freePeriods == 0) {
      return 'Benefit user \n(-40% on all purchases)';
    } else if (this.type == 'dev') {
      return 'Developer user \n(everything is free)';
    } else {
      return '${this.freePeriods} free credits';
    }
  }
}

enum AddRemAction { add, remove }
