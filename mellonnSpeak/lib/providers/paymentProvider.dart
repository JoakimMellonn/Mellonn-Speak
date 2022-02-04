import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:intl/intl.dart';
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

Future<void> sendInvoice(String email, String name, String countryId,
    Product product, double quantity) async {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String date = formatter.format(now);
  final String contactId = await getContactId(email, name, countryId);
  final invoice = {
    'entryDate': date,
    'contactId': contactId,
    'taxMode': 'incl',
    'lines': [
      {
        'productId': product.productId,
        'unitPrice': product.unitPrice,
        'quantity': quantity,
      }
    ],
  };

  try {
    var response = await http.post(
      Uri.parse(billyEndPoint + '/invoices'),
      headers: {
        'X-Access-Token': billyToken,
        'Content-Type': 'application/json'
      },
      body: json.encode({
        'invoice': invoice,
      }),
    );
    final jsonResponse = json.decode(response.body);

    print('Invoice response: $jsonResponse');
  } catch (e) {
    print('Send invoice error: $e');
  }
}

Future<String> getContactId(String email, String name, String countryId) async {
  var response = await http.get(
    Uri.parse(billyEndPoint + '/contacts?contactNo=$email'),
    headers: {
      'X-Access-Token': billyToken,
    },
  );

  final jsonResponse = json.decode(response.body);
  List contacts = jsonResponse['contacts'];
  //print(jsonResponse);

  if (contacts.length > 0) {
    print('Contact exists returning id: ${contacts.first['id']}');
    return contacts.first['id'];
  } else {
    print('Contact doesnt exist, creating a new one...');
    final contact = {
      'name': '$name',
      'countryId': '$countryId',
      'contactNo': '$email',
      'isCustomer': true,
      'isSupplier': false,
    };

    var response = await http.post(
      Uri.parse(billyEndPoint + '/contacts'),
      headers: {
        'X-Access-Token': billyToken,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'contact': contact,
      }),
    );

    final newJsonResponse = json.decode(response.body);
    List contacts = newJsonResponse['contacts'];
    print('New user id: ${contacts.first['id']}');
    return contacts.first['id'];
  }
}

Future<Products> getProducts() async {
  late Product standardDK;
  late Product benefitDK;
  late Product standardEU;
  late Product benefitEU;
  late Product standardINTL;
  late Product benefitINTL;
  //Getting product ID's
  var productsResponse = await http.get(
    Uri.parse(billyEndPoint + '/products'),
    headers: {
      'X-Access-Token': billyToken,
    },
  );

  final jsonProductsResponse = json.decode(productsResponse.body);
  final List products = jsonProductsResponse['products'];
  List<IdName> idList = [];
  for (var product in products) {
    idList.add(
        IdName(id: product['id'], productNo: int.parse(product['productNo'])));
  }

  //Getting prices for each product
  for (var idName in idList) {
    var idResponse = await http.get(
      Uri.parse(billyEndPoint + '/productPrices?productId=${idName.id}'),
      headers: {
        'X-Access-Token': billyToken,
      },
    );
    final jsonIdResponse = json.decode(idResponse.body);
    final List productPrices = jsonIdResponse['productPrices'];
    //print(jsonIdResponse);

    for (var price in productPrices) {
      if (idName.productNo == 0) {
        standardDK = Product(
          productId: idName.id,
          unitPrice: double.parse(price['unitPrice'].toString()),
          currency: price['currencyId'],
        );
      } else if (idName.productNo == 1) {
        benefitDK = Product(
          productId: idName.id,
          unitPrice: double.parse(price['unitPrice'].toString()),
          currency: price['currencyId'],
        );
      } else if (idName.productNo == 2) {
        standardEU = Product(
          productId: idName.id,
          unitPrice: double.parse(price['unitPrice'].toString()),
          currency: price['currencyId'],
        );
      } else if (idName.productNo == 3) {
        benefitEU = Product(
          productId: idName.id,
          unitPrice: double.parse(price['unitPrice'].toString()),
          currency: price['currencyId'],
        );
      } else if (idName.productNo == 4) {
        standardINTL = Product(
          productId: idName.id,
          unitPrice: double.parse(price['unitPrice'].toString()),
          currency: price['currencyId'],
        );
      } else if (idName.productNo == 5) {
        benefitINTL = Product(
          productId: idName.id,
          unitPrice: double.parse(price['unitPrice'].toString()),
          currency: price['currencyId'],
        );
      }
    }
  }
  return Products(
    standardDK: standardDK,
    standardEU: standardEU,
    standardINTL: standardINTL,
    benefitDK: benefitDK,
    benefitEU: benefitEU,
    benefitINTL: benefitINTL,
  );
}

class Products {
  Product standardDK;
  Product benefitDK;
  Product standardEU;
  Product benefitEU;
  Product standardINTL;
  Product benefitINTL;

  Products({
    required this.standardDK,
    required this.standardEU,
    required this.standardINTL,
    required this.benefitDK,
    required this.benefitEU,
    required this.benefitINTL,
  });
}

class Product {
  final String productId;
  final double unitPrice;
  final String currency;

  Product({
    required this.productId,
    required this.unitPrice,
    required this.currency,
  });
}

class IdName {
  final String id;
  final int productNo;

  IdName({
    required this.id,
    required this.productNo,
  });
}

Product emptyProduct = Product(productId: '', unitPrice: 50.0, currency: 'DKK');
Products products = Products(
  standardDK: emptyProduct,
  standardEU: emptyProduct,
  standardINTL: emptyProduct,
  benefitDK: emptyProduct,
  benefitEU: emptyProduct,
  benefitINTL: emptyProduct,
);
