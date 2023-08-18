import 'dart:io';
import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:facebook_app_events/facebook_app_events.dart';

class AnalyticsProvider with ChangeNotifier {
  FacebookAppEvents _fb = FacebookAppEvents();
  AWSPinpointUserProfile _userProfile = AWSPinpointUserProfile();

  get fb => _fb;
  get userProfile => _userProfile;

  void registerToken(String token) async {
    final userId = (await Amplify.Auth.getCurrentUser()).userId;
    Amplify.Notifications.Push.identifyUser(userId: userId, userProfile: userProfile);
  }

  void recordEventError(String where, String error) async {
    AnalyticsEvent event = AnalyticsEvent('ERROR');
    event.customProperties
      ..addStringProperty('where', where)
      ..addStringProperty('ERROR', error);

    try {
      await Amplify.Analytics.enable();
      await Amplify.Analytics.recordEvent(event: event);
    } on AnalyticsException catch (e) {
      print('Analytics error: $where, $error');
      print(e.message);
    }
  }

  void recordEventNewLogin(String firstName, String lastName, String email) async {
    String fullName = '$firstName $lastName';
    UserProfile userProfile = UserProfile(name: fullName, email: email);

    try {
      await fb.setUserData(email: email, firstName: firstName, lastName: lastName);
      AuthUser result = await Amplify.Auth.getCurrentUser();
      await Amplify.Analytics.enable();
      await Amplify.Analytics.identifyUser(userId: result.userId, userProfile: userProfile);
    } on AnalyticsException catch (e) {
      print('Analytics new login error: $fullName, $email');
      print(e.message);
    } catch (e) {
      print('Analytics other error: $e');
    }
  }

  void recordPurchase(String type, String amount) async {
    AnalyticsEvent event = AnalyticsEvent('purchase');
    event.customProperties
      ..addStringProperty('type', type)
      ..addStringProperty('amount', amount);

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

  Future<void> sendFeedback(String email, String name, String where, String message, bool accepted) async {
    final params = '{"email":"$email","name":"$name","where":"$where","message":"$message","accepted":"$accepted"}';

    try {
      await Amplify.API.post("feedback/sendFeedback", body: HttpPayload.json(params)).response;
    } catch (e) {
      print('Feedback error: $e');
      recordEventError("SendFeedback: $where", e.toString());
    }
  }
}
