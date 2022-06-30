import 'dart:io';
import 'dart:typed_data';
import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:intl/intl.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

final FacebookAppEvents fb = FacebookAppEvents();

void recordEventError(String where, String error) async {
  AnalyticsEvent event = AnalyticsEvent('ERROR');
  event.properties.addStringProperty('where', where);
  event.properties.addStringProperty('ERROR', error);

  try {
    await Amplify.Analytics.enable();
    await Amplify.Analytics.recordEvent(event: event);
  } on AnalyticsException catch (e) {
    print('Analytics error: $where, $error');
    print(e.message);
  }
}

void recordEventNewLogin(
    String firstName, String lastName, String email) async {
  String fullName = '$firstName $lastName';
  AnalyticsUserProfile userProfile =
      AnalyticsUserProfile(name: fullName, email: email);

  try {
    await fb.setUserData(
        email: email, firstName: firstName, lastName: lastName);
    AuthUser result = await Amplify.Auth.getCurrentUser();
    await Amplify.Analytics.enable();
    await Amplify.Analytics.identifyUser(
        userId: result.userId, userProfile: userProfile);
  } on AnalyticsException catch (e) {
    print('Analytics new login error: $fullName, $email');
    print(e.message);
  } catch (e) {
    print('Analytics other error: $e');
  }
}

void recordPurchase(String type, String amount) async {
  AnalyticsEvent event = AnalyticsEvent('purchase');
  event.properties.addStringProperty('type', type);
  event.properties.addStringProperty('amount', amount);

  List<String> amountList = amount.trim().split("");
  List<String> newList = [];
  for (var letter in amountList) {
    if (letter.contains(RegExp('[0-9,.]'))) {
      newList.add(letter);
    }
  }
  var format = NumberFormat.simpleCurrency(locale: Platform.localeName);
  double doubleAmount = double.parse(newList.join(''));

  try {
    fb.logPurchase(amount: doubleAmount, currency: format.currencyName!);
    await Amplify.Analytics.enable();
    await Amplify.Analytics.recordEvent(event: event);
  } on AnalyticsException catch (e) {
    print('Analytics purchase error: $type, $amount');
    print(e.message);
  }
}

Future<void> sendFeedback(String email, String name, String where,
    String message, bool accepted) async {
  final params =
      '{"email":"$email","name":"$name","where":"$where","message":"$message","accepted":"$accepted"}';

  RestOptions options = RestOptions(
    apiName: 'feedback',
    path: '/sendFeedback',
    body: Uint8List.fromList(params.codeUnits),
  );
  Amplify.API.post(restOptions: options);
}
