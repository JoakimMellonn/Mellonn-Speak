import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:mellonnSpeak/main.dart';
import 'package:mellonnSpeak/pages/home/record/recordPageProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'package:http/http.dart' as http;

InAppPurchase iap = InAppPurchase.instance;
List<ProductDetails> productsIAP = [];
List<PurchaseDetails> purchasesIAP = [];
String standardIAP = 'speak15minutes';
String benefitIAP = 'benefit15minutes';
late StreamSubscription subscriptionIAP;

Future<List<ProductDetails>> getProductsIAP(int totalPeriods) async {
  int minutes = totalPeriods * 15;
  standardIAP = 'speak' + '$minutes' + 'minutes';
  benefitIAP = 'benefit' + '$minutes' + 'minutes';
  print('Getting products: $standardIAP, $benefitIAP');
  Set<String> ids = Set.from([standardIAP, 'standard', benefitIAP, 'benefit']);
  ProductDetailsResponse response = await iap.queryProductDetails(ids);

  productsIAP = response.productDetails;

  productsIAP.forEach((element) {
    print(element.price);
  });
  return response.productDetails;
}

PurchaseDetails _hasPurchased(String productID) {
  return purchasesIAP.lastWhere((purchase) => purchase.productID == productID);
}

Future<String> verifyPurchase(String id) async {
  PurchaseDetails purchase = _hasPurchased(id);

  if (purchase.status == PurchaseStatus.purchased) {
    await iap.completePurchase(purchase);
    print('Successful purchase');
    ProductDetails product =
        productsIAP.firstWhere((element) => element.id == purchase.productID);
    recordPurchase(product.id, product.price);
    return 'purchased';
  } else if (purchase.status == PurchaseStatus.canceled) {
    await iap.completePurchase(purchase);
    print('Canceled');
    return 'canceled';
  } else if (purchase.status == PurchaseStatus.error) {
    await iap.completePurchase(purchase);
    print('Error');
    return 'error';
  } else if (purchase.status == PurchaseStatus.restored) {
    await iap.completePurchase(purchase);
    print('Restored');
    return 'restored';
  } else {
    return 'pending';
  }
}

Future<bool> buyProduct(ProductDetails prod) async {
  print(
      'Buying product: ${prod.id}, purchaseList length: ${purchasesIAP.length}');
  final PurchaseParam purchaseParam = PurchaseParam(productDetails: prod);

  try {
    bool purchased = await iap.buyConsumable(purchaseParam: purchaseParam);

    if (purchased) {
      await verifyPurchase(prod.id);
      return true;
    } else {
      return false;
    }
  } catch (e) {
    recordEventError('buyProduct', e.toString());
    print('Error: $e');
    if (purchasesIAP.length > 0) {
      await iap.completePurchase(purchasesIAP.last);
    }
    return false;
  }
}

enum PurchaseType {
  standard,
  benefit,
}

///
///Everything Stripe related, maybe some day I will use this again... (hopefully)
///

Future<void> initPayment(
  context, {
  required String email,
  required StProduct product,
  required Periods periods,
  required Function() paySuccess,
  required Function() payFailed,
}) async {
  int amount = (product.price.unitPrice * periods.periods * 100).toInt();
  //int unitAmount = (product.price.unitPrice * 100).toInt();

  if (amount == 0) {
    paySuccess();
  } else {
    try {
      //Step 1: Getting information on the client (user and Stripe id)
      RestOptions options = RestOptions(
        apiName: 'stripeFunction',
        path: '/stripeFunction',
        body: Uint8List.fromList(
            '{\'email\':\'$email\',\'amount\':\'${amount.toString()}\',\'periods\':\'${periods.periods}\',\'currency\':\'${product.price.currency}\',\'prodID\':\'${product.productId}\',\'priceID\':\'${product.price.priceId}\',\'unitAmount\':\'${product.price.unitPrice}\',\'prodName\':\'${product.name}\'}'
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
          testEnv: false,
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
      paySuccess();
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
        log('Payment Error (not Stripe): $e');
      }
      payFailed();
    }
  }
}

Future<void> getProducts(String userGroup, String region) async {
  List<Price> priceList = [];

  for (var id in priceIDs) {
    var response = await http.get(
      Uri.parse(
        stripeEndPoint + '/v1/prices/$id',
      ),
      headers: {
        'Authorization': 'Bearer $stripeProductsKey',
      },
    );

    final jsonPrices = json.decode(response.body);
    //print(jsonResponse);

    priceList.add(Price(
      priceId: id,
      unitPrice: jsonPrices['unit_amount'] / 100,
      currency: jsonPrices['currency'],
      name: '',
    ));
  }

  var productResponse = await http.get(
    Uri.parse(stripeEndPoint + '/v1/products'),
    headers: {
      'Authorization': 'Bearer $stripeProductsKey',
    },
  );

  var jsonProducts = json.decode(productResponse.body);
  List data = jsonProducts['data'];

  for (var object in data) {
    if (object['name'] == 'Mellonn Speak Standard') {
      standardProduct = Product(
        productId: object['id'],
        name: object['name'],
        dk: priceList[0],
        eu: priceList[1],
        intl: priceList[2],
      );
    } else if (object['name'] == 'Mellonn Speak Benefit') {
      benefitProduct = Product(
        productId: object['id'],
        name: object['name'],
        dk: priceList[3],
        eu: priceList[4],
        intl: priceList[5],
      );
    }
  }

  if (userGroup == 'dev') {
    stProduct = StProduct(
      productId: 'dev',
      name: 'dev',
      price: Price(priceId: 'dev', unitPrice: 0, currency: 'dkk', name: 'dev'),
    );
  } else if (userGroup == 'benefit') {
    if (region == 'dk') {
      stProduct = StProduct(
        productId: benefitProduct.productId,
        name: benefitProduct.name,
        price: benefitProduct.dk,
      );
    } else if (region == 'eu') {
      stProduct = StProduct(
        productId: benefitProduct.productId,
        name: benefitProduct.name,
        price: benefitProduct.eu,
      );
    } else {
      stProduct = StProduct(
        productId: benefitProduct.productId,
        name: benefitProduct.name,
        price: benefitProduct.intl,
      );
    }
  } else {
    if (region == 'dk') {
      stProduct = StProduct(
        productId: standardProduct.productId,
        name: standardProduct.name,
        price: standardProduct.dk,
      );
    } else if (region == 'eu') {
      stProduct = StProduct(
        productId: standardProduct.productId,
        name: standardProduct.name,
        price: standardProduct.eu,
      );
    } else {
      stProduct = StProduct(
        productId: standardProduct.productId,
        name: standardProduct.name,
        price: standardProduct.intl,
      );
    }
  }

  //print(
  //    'Standard (id: ${stProduct.productId}, name: ${stProduct.name}, price: ${stProduct.price.unitPrice}${stProduct.price.currency})');
}

class Price {
  String priceId;
  double unitPrice;
  String currency;
  String name;

  Price({
    required this.priceId,
    required this.unitPrice,
    required this.currency,
    required this.name,
  });
}

class Product {
  String productId;
  String name;
  Price dk;
  Price eu;
  Price intl;

  Product({
    required this.productId,
    required this.name,
    required this.dk,
    required this.eu,
    required this.intl,
  });
}

class StProduct {
  String productId;
  String name;
  Price price;

  StProduct({
    required this.productId,
    required this.name,
    required this.price,
  });
}

Price emptyPrice =
    Price(priceId: '', unitPrice: 50.0, currency: 'DKK', name: '');
Product emptyProduct = Product(
  productId: '',
  name: '',
  dk: emptyPrice,
  eu: emptyPrice,
  intl: emptyPrice,
);
Product standardProduct = emptyProduct;
Product benefitProduct = emptyProduct;
StProduct stProduct = StProduct(productId: '', name: '', price: emptyPrice);

///
///Billy stuff, not in use right now...
///
Future<void> sendInvoice(String email, String name, String countryId,
    Product product, double quantity) async {
  final DateTime now = DateTime.now();
  final DateFormat formatter = DateFormat('yyyy-MM-dd');
  final String date = formatter.format(now);
  final String contactId = await getBillyContactId(email, name, countryId);
  final invoice = {
    'entryDate': date,
    'contactId': contactId,
    'taxMode': 'incl',
    'lines': [
      {
        'productId': product.productId,
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

Future<String> getBillyContactId(
    String email, String name, String countryId) async {
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
    //print('Contact exists returning id: ${contacts.first['id']}');
    return contacts.first['id'];
  } else {
    //print('Contact doesnt exist, creating a new one...');
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
    //print('New user id: ${contacts.first['id']}');

    var res = await http.post(
      Uri.parse(
          billyEndPoint + '/contactPersons?contactId=${contacts.first['id']}'),
      headers: {
        'X-Access-Token': billyToken,
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'contactPerson': {
          'contactId': contacts.first['id'],
          'isPrimary': true,
          'name': name,
          'email': email,
        },
      }),
    );
    return contacts.first['id'];
  }
}

/*Future<Products> getProducts() async {
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
}*/