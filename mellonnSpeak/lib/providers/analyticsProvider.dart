import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

void recordEventError(String where, String error) async {
  AnalyticsEvent event = AnalyticsEvent('ERROR');
  event.properties.addStringProperty('where', where);
  event.properties.addStringProperty('ERROR', error);

  await Amplify.Analytics.enable();
  await Amplify.Analytics.recordEvent(event: event);
}

void recordEventNewLogin(String name, String email) async {
  AnalyticsUserProfile userProfile =
      AnalyticsUserProfile(name: name, email: email);

  AuthUser result = await Amplify.Auth.getCurrentUser();

  await Amplify.Analytics.enable();
  await Amplify.Analytics.identifyUser(
      userId: result.userId, userProfile: userProfile);
}

void recordPurchase(String type, String amount) async {
  AnalyticsEvent event = AnalyticsEvent('purchase');
  event.properties.addStringProperty('type', type);
  event.properties.addStringProperty('amount', amount);

  await Amplify.Analytics.enable();
  await Amplify.Analytics.recordEvent(event: event);
}
