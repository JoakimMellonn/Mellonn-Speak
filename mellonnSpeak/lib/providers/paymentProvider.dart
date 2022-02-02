import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/utilities/.env.dart';

Future<void> initPayment(context,
    {required String email,
    required double amountDouble,
    required String currency}) async {
  int amount = (amountDouble * 100).toInt();

  try {
    //Step 1: Getting information on the client (user and Stripe id)
    final response = await http.post(Uri.parse(paymentEndpoint), body: {
      'email': email,
      'amount': amount.toString(),
      'currency': currency,
    });

    final jsonResponse = jsonDecode(response.body);
    log(jsonResponse.toString());

    //Step 2: Using the recieved info to create the payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: jsonResponse['paymentIntent'],
        merchantDisplayName: 'Mellonn',
        customerId: jsonResponse['customer'],
        customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
        style: themeMode,
        testEnv: true,
        merchantCountryCode: 'DK',
      ),
    );

    //Step 3: Show the payment sheet
    await Stripe.instance.presentPaymentSheet();

    //Step 4: Profit
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment completed!')),
    );
  } catch (e) {
    if (e is StripeException) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error from Stripe: ${e.error.localizedMessage}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
