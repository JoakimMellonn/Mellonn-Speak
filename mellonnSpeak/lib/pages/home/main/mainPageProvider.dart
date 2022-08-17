import 'dart:io';

import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:provider/provider.dart';

String greetingsString() {
  int time = DateTime.now().hour;
  if (time >= 0 && time < 5) return 'Good night';
  if (time >= 5 && time < 12) return 'Good morning';
  if (time >= 12 && time < 18) return 'Good afternoon';
  if (time >= 18 && time < 24) return 'Good evening';
  return 'Hi';
}

Future<double> getAudioDuration(String path) async {
  final player = AudioPlayer();
  var duration = await player.setFilePath(path);
  await player.dispose();
  List<String> durationSplit = duration.toString().split(':');
  double hours = double.parse(durationSplit[0]);
  double minutes = double.parse(durationSplit[1]);
  double seconds = double.parse(durationSplit[2]);
  double totalSeconds = 3600 * hours + 60 * minutes + seconds;
  print(totalSeconds);
  return totalSeconds;
}

//Prompts the user to pick a file, returns the path or an error
Future<PickedFile> pickFile(UserData userData, String userGroup) async {
  List<String> fileTypes = ['waw', 'flac', 'm4p', 'm4a', 'm4b', 'mmf', 'aac', 'mp3', 'mp4', 'MP4'];

  try {
    final pickResult = await FilePicker.platform.pickFiles();

    if (pickResult != null) {
      final path = pickResult.files.single.path!;
      double seconds = await getAudioDuration(path);
      if (seconds > 9000) throw 'tooLong';
      if (!fileTypes.contains(path.split('.').last)) throw 'unsupported';
      Periods periods = getPeriods(seconds, userData, userGroup);
      return PickedFile(path: path, fileName: pickResult.files.single.name, duration: seconds, periods: periods, isError: false);
    } else {
      throw 'nonPicked';
    }
  } on PlatformException catch (err) {
    recordEventError('pickFile-platform', err.details);
    print('Unsupported operation' + err.toString());
    return PickedFile(path: 'ERROR:An error happened while picking the file, please try again.', isError: true);
  } catch (err) {
    if (err == 'unsupported') {
      return PickedFile(
        path:
            'ERROR:The chosen file uses an unsupported file type, please choose another file.\nA list of supported file types can be found in Help on the profile page.',
        isError: true,
      );
    } else if (err == 'tooLong') {
      return PickedFile(path: 'ERROR:The chosen audio file is too long, max length for an audio file is 2.5 hours (150 minutes)', isError: true);
    } else if (err == 'nonPicked') {
      return PickedFile(path: 'ERROR:No file have been picked.', isError: true);
    } else {
      recordEventError('pickFile-other', err.toString());
      print('Error: $err');
      return PickedFile(path: 'ERROR:An error happened while picking the file, please try again.', isError: true);
    }
  }
}

Future<void> uploadRecording(String title, String description, String languageCode, int speakerCount, PickedFile pickedFile) async {
  TemporalDateTime? date = TemporalDateTime.now();
  File file = File(pickedFile.path);

  Recording newRecording = Recording(
    name: title,
    description: description,
    date: date,
    fileName: pickedFile.fileName,
    fileKey: '',
    speakerCount: speakerCount,
    languageCode: languageCode,
  );
  final fileType = file.path.split('.').last.toString();
  String newFileKey = 'recordings/${newRecording.id}.$fileType';

  newRecording = newRecording.copyWith(
    fileKey: newFileKey,
  );

  try {
    await Amplify.DataStore.save(newRecording);
    await StorageProvider().uploadFile(file, newFileKey, title, description);
  } on DataStoreException catch (e) {
    recordEventError('uploadRecording', e.message);
    print(e.message);
  }
}

class PickedFile {
  final String path;
  final String? fileName;
  final double? duration;
  final Periods? periods;
  final bool isError;

  const PickedFile({
    required this.path,
    this.fileName,
    this.duration,
    this.periods,
    required this.isError,
  });
}

///
///Stuff used to control the page, and the measure size widget (quite smart)
///
enum StackSequence { standard, upload }

typedef void OnWidgetSizeChange(Size size);

class MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;
  final OnWidgetSizeChange onChange;

  MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    Size newSize = child!.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class MeasureSize extends SingleChildRenderObjectWidget {
  final OnWidgetSizeChange onChange;

  const MeasureSize({
    Key? key,
    required this.onChange,
    required Widget child,
  }) : super(key: key, child: child);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return MeasureSizeRenderObject(onChange);
  }
}

///
///Stuff for payments
///
late ProductDetails purchaseProduct;

Periods getPeriods(double seconds, UserData userData, String userGroup) {
  int totalPeriods = ((seconds / 60) / 15).ceil();
  final int freePeriods = userData.freePeriods;
  int periods = 0;
  int freeLeft = 0;
  bool freeUsed = false;

  if (freePeriods > 0) {
    freeUsed = true;
  }

  if (totalPeriods >= freePeriods) {
    freeLeft = 0;
    periods = totalPeriods - freePeriods;
  } else {
    freeLeft = freePeriods - totalPeriods;
    periods = 0;
  }

  final productDetails = getProductsIAP(
    totalPeriods,
    userGroup,
  );
  final discountText = getDiscount(
    totalPeriods - periods,
    totalPeriods,
    userGroup,
  );

  return Periods(
    total: totalPeriods,
    periods: periods,
    freeLeft: freeLeft,
    freeUsed: freeUsed,
    productDetails: productDetails,
    discountText: discountText,
  );
}

class CheckoutPage extends StatelessWidget {
  final Periods periods;

  const CheckoutPage({
    Key? key,
    required this.periods,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isDev = false;

    String itemTitle() {
      String type = 'standard';
      if (context.read<AuthAppProvider>().userGroup == 'benefit') {
        type = 'benefit';
      }
      String minutes = (periods.total * 15).toString();
      return 'Speak $type $minutes minutes';
    }

    if (context.read<AuthAppProvider>().userGroup == 'dev') {
      isDev = true;
    } else {
      isDev = false;
    }
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Item:',
                style: Theme.of(context).textTheme.headline6,
              ),
              Spacer(),
              Text(
                itemTitle(), //product.name,
                style: Theme.of(context).textTheme.headline6,
              ),
            ],
          ),
          Divider(),
          Row(
            children: [
              Text(
                'Amount:',
                style: Theme.of(context).textTheme.headline6,
              ),
              Spacer(),
              Text(
                '1', //'${periods.total}',
                style: Theme.of(context).textTheme.headline6,
              ),
            ],
          ),
          Divider(),
          Row(
            children: [
              Text(
                'Price per unit:',
                style: Theme.of(context).textTheme.headline6,
              ),
              Spacer(),
              Text(
                periods.productDetails.price, //'${product.price.unitPrice} ${product.price.currency}',
                style: Theme.of(context).textTheme.headline6,
              ),
            ],
          ),
          if (periods.freeUsed || isDev)
            Column(
              children: [
                Divider(),
                Row(
                  children: [
                    Text(
                      'Total discount:',
                      style: Theme.of(context).textTheme.headline6,
                    ),
                    Spacer(),
                    Text(
                      isDev ? '-${periods.productDetails.price}' : periods.discountText,
                      /*isDev
                          ? '-${periods.total * product.price.unitPrice} ${product.price.currency}'
                          : '-${(periods.total - periods.periods) * product.price.unitPrice} ${product.price.currency}',*/
                      style: Theme.of(context).textTheme.headline6,
                    ),
                  ],
                ),
              ],
            ),
          Divider(
            height: 50,
          ),
          Row(
            children: [
              Text(
                'Total:',
                style: Theme.of(context).textTheme.headline6,
              ),
              Spacer(),
              Text(
                isDev || periods.periods == 0 ? 'FREE' : purchaseProduct.price,
                /*isDev
                    ? '0 ${product.price.currency}'
                    : '${product.price.unitPrice * periods.periods} ${product.price.currency}',*/
                style: Theme.of(context).textTheme.headline6,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String getDiscount(int freeUsed, int totalPeriods, String userType) {
  String returnString = '';
  int discountMinutes = freeUsed * 15;
  int purchaseMinutes = (totalPeriods - freeUsed) * 15;
  print('discountMinutes: $discountMinutes, purchaseMinutes: $purchaseMinutes');
  if (userType == 'user') {
    if (freeUsed != 0) {
      ProductDetails prod = productsIAP.firstWhere((element) => element.id == 'speak${discountMinutes}minutes');
      returnString = '-${prod.price}';
    } else {
      returnString = '';
    }
    if (purchaseMinutes != 0) {
      purchaseProduct = productsIAP.firstWhere((element) => element.id == 'speak${purchaseMinutes}minutes');
    }
  } else if (userType == 'benefit') {
    if (freeUsed != 0) {
      ProductDetails prod = productsIAP.firstWhere((element) => element.id == 'benefit${discountMinutes}minutes');
      returnString = '-${prod.price}';
    } else {
      returnString = '';
    }
    if (purchaseMinutes != 0) {
      purchaseProduct = productsIAP.firstWhere((element) => element.id == 'benefit${purchaseMinutes}minutes');
      print('Purchase product: ${purchaseProduct.id}');
    }
  } else if (userType == 'dev') {
    return '';
  }
  return returnString;
}

String estimatedTime(int totalPeriods) {
  String returnString = '';
  if (totalPeriods <= 4) {
    returnString = 'ca. 10-15 minutes';
  } else if (totalPeriods <= 8) {
    returnString = 'ca. 20-30 minutes';
  } else {
    returnString = 'ca. 35-45 minutes';
  }
  return returnString;
}

class Periods {
  int total;
  int periods;
  int freeLeft;
  bool freeUsed;
  ProductDetails productDetails;
  String discountText;

  Periods({
    required this.total,
    required this.periods,
    required this.freeLeft,
    required this.freeUsed,
    required this.productDetails,
    required this.discountText,
  });
}
