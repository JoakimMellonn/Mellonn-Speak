import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'package:http/http.dart' as http;

Future<void> initPayment(
  context, {
  required String email,
  required double amountDouble,
  required String currency,
}) async {
  int amount = (amountDouble * 100).toInt();

  try {
    //Step 1: Getting information on the client (user and Stripe id)
    RestOptions options = RestOptions(
      apiName: 'stripeFunction',
      path: '/stripeFunction',
      body: Uint8List.fromList(
          '{\'email\':\'$email\', \'amount\':\'${amount.toString()}\', \'currency\':\'$currency\'}'
              .codeUnits),
    );
    RestOperation restOperation = Amplify.API.post(restOptions: options);
    RestResponse response = await restOperation.response;

    final jsonResponse = jsonDecode(response.body);

    //log(jsonResponse.toString());

    //Step 2: Using the recieved info to create the payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: jsonResponse['paymentIntent'],
        billingDetails: billingDetails,
        merchantDisplayName: 'Mellonn',
        customerId: jsonResponse['customer'],
        customerEphemeralKeySecret: jsonResponse['ephemeralKey'],
        style: themeMode,
        testEnv: true,
        merchantCountryCode: 'DK',
        googlePay: true,
        applePay: true,
        primaryButtonColor: Colors.deepPurple,
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
          content: Text('${e.error.localizedMessage}'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      log('Error: $e');
    }
  }
}

Future<void> sendReceipt() async {}

Future<void> getCreateContact() async {
  const contact = {
    'name': '',
  };

  var response = await http.get(
    Uri.https(billyEndPoint, '/v2/contacts'),
    headers: {
      'X-Access-Token': billyToken,
    },
  );

  final jsonResponse = json.decode(response.body);
  final List contacts = jsonResponse['contacts'];
  //print(jsonResponse);

  for (var contact in contacts) {
    if (contact['type'] == 'person') {
      print(contact);
    }
  }
}

Future<void> getProducts() async {
  //Getting product ID's
  var productsResponse = await http.get(
    Uri.https(billyEndPoint, '/v2/products'),
    headers: {
      'X-Access-Token': billyToken,
    },
  );

  final jsonProductsResponse = json.decode(productsResponse.body);
  final List products = jsonProductsResponse['products'];
  List idList = [];
  for (var product in products) {
    idList.add(product['id']);
    print(product);
  }

  //Getting prices for each product
  for (var id in idList) {}
  var idResponse = await http.get(
    Uri.https(billyEndPoint, '/v2/productPrices/${idList[0]}'),
    headers: {
      'X-Access-Token': billyToken,
    },
  );
  final jsonIdResponse = json.decode(idResponse.body);
  print(jsonIdResponse);
}

class Products {
  double standardDK = 50.0; //DKK
  double benefitDK = 40.0; //DKK
  double standardEU = 6.75; //EUR
  double benefitEU = 5.5; //EUR
  double standardINTL = 7.5; //USD
  double benefitINTL = 6.0; //USD
}
