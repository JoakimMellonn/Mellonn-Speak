import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mellonnSpeak/utilities/.env.dart';

void recordEventError(String where, String error) async {
  //print('Analytics: $where, $error');
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

void recordEventNewLogin(String name, String email) async {
  //print('Analytics new login: $name, $email');
  AnalyticsUserProfile userProfile =
      AnalyticsUserProfile(name: name, email: email);

  AuthUser result = await Amplify.Auth.getCurrentUser();

  try {
    await Amplify.Analytics.enable();
    await Amplify.Analytics.identifyUser(
        userId: result.userId, userProfile: userProfile);
  } on AnalyticsException catch (e) {
    print('Analytics new login error: $name, $email');
    print(e.message);
  }
}

void recordPurchase(String type, String amount) async {
  //print('Analytics purchase: $type, $amount');
  AnalyticsEvent event = AnalyticsEvent('purchase');
  event.properties.addStringProperty('type', type);
  event.properties.addStringProperty('amount', amount);

  try {
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

  final response = await http.put(
    Uri.parse(sendFeedbackEndPoint),
    headers: {
      "x-api-key": sendFeedbackKey,
    },
    body: params,
  );
}
