import 'dart:io';
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
import 'package:mellonnSpeak/providers/promotionDbProvider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class MainPageProvider with ChangeNotifier {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  set isLoading(bool state) {
    _isLoading = state;
    notifyListeners();
  }
}

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
  return totalSeconds;
}

//Prompts the user to pick a file, returns the path or an error
Future<PickedFile> pickFile(UserData userData, String userGroup) async {
  List<String> fileTypes = ['wav', 'flac', 'm4p', 'm4a', 'm4b', 'mmf', 'aac', 'mp3', 'mp4', 'MP4'];

  try {
    final pickResult = await FilePicker.platform.pickFiles(allowMultiple: false);

    if (pickResult != null) {
      PlatformFile file = pickResult.files.single;
      double seconds = await getAudioDuration(file.path!);
      if (seconds > 9000) throw 'tooLong';
      if (!fileTypes.contains(file.path!.split('.').last.toLowerCase())) throw 'unsupported';
      Periods periods = getPeriods(seconds, userData, userGroup);

      PlatformFile newFile = new PlatformFile(
        name: file.name,
        path: (await createTempFile(file.path!)),
        size: file.size,
        bytes: file.bytes,
        readStream: file.readStream,
        identifier: file.identifier,
      );
      return PickedFile(file: newFile, duration: seconds, periods: periods, isError: false);
    } else {
      throw 'nonPicked';
    }
  } on PlatformException catch (err) {
    AnalyticsProvider().recordEventError('pickFile-platform', err.details);
    print('Unsupported operation' + err.toString());
    return PickedFile(file: PlatformFile(name: 'ERROR:An error happened while picking the file, please try again.', size: 0), isError: true);
  } catch (err) {
    if (err == 'unsupported') {
      return PickedFile(
        file: PlatformFile(
            name:
                'ERROR:The chosen file uses an unsupported file type, please choose another file.\nA list of supported file types can be found in Help on the profile page.',
            size: 0),
        isError: true,
      );
    } else if (err == 'tooLong') {
      return PickedFile(
          file: PlatformFile(name: 'ERROR:The chosen audio file is too long, max length for an audio file is 2.5 hours (150 minutes)', size: 0),
          isError: true);
    } else if (err == 'nonPicked') {
      return PickedFile(file: PlatformFile(name: 'ERROR:No file have been picked.', size: 0), isError: true);
    } else {
      AnalyticsProvider().recordEventError('pickFile-other', err.toString());
      print('Error: $err');
      return PickedFile(
          file: PlatformFile(
            name: 'ERROR:An error happened while picking the file, please try again.',
            size: 0,
          ),
          isError: true);
    }
  }
}

Future<void> uploadRecording(String title, String description, String languageCode, int speakerCount, PickedFile pickedFile) async {
  TemporalDateTime? date = TemporalDateTime.now();
  File file = File(pickedFile.file.path!);

  Recording newRecording = Recording(
    name: title,
    description: description,
    date: date,
    fileName: pickedFile.file.name,
    fileKey: '',
    speakerCount: speakerCount,
    languageCode: languageCode,
  );
  final fileType = file.path.split('.').last.toString();
  String newFileKey =
      supportedExtensions.contains(fileType.toLowerCase()) ? 'recordings/${newRecording.id}.$fileType' : 'recordings/${newRecording.id}.wav';

  newRecording = newRecording.copyWith(
    fileKey: newFileKey,
  );

  try {
    await Amplify.DataStore.save(newRecording);
    await StorageProvider().uploadFile(file, newFileKey, fileType, newRecording.id);
    await registerPurchase(pickedFile.periods!.duration);
  } on DataStoreException catch (e) {
    AnalyticsProvider().recordEventError('uploadRecording', e.message);
    print(e.message);
  }
}

///
///Creates a temporary file and returns the path
///
Future<String> createTempFile(String path) async {
  final dir = await getTemporaryDirectory();
  final newPath = '${dir.path}/${path.split('/').last}';
  final oldFile = new File(path);
  final newFile = new File(newPath);
  if (await newFile.exists()) {
    await newFile.delete();
  }
  await oldFile.copy(newPath);
  return newPath;
}

void deleteTempFile(String path) async {
  final file = new File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

class PickedFile {
  final PlatformFile file;
  final double? duration;
  final Periods? periods;
  final bool isError;

  const PickedFile({
    required this.file,
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
    duration: seconds,
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
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Spacer(),
              Text(
                itemTitle(), //product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          Divider(),
          Row(
            children: [
              Text(
                'Amount:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Spacer(),
              Text(
                '1', //'${periods.total}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          Divider(),
          Row(
            children: [
              Text(
                'Price per unit:',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Spacer(),
              Text(
                periods.productDetails.price, //'${product.price.unitPrice} ${product.price.currency}',
                style: Theme.of(context).textTheme.headlineSmall,
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
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Spacer(),
                    Text(
                      isDev ? '-${periods.productDetails.price}' : periods.discountText,
                      /*isDev
                          ? '-${periods.total * product.price.unitPrice} ${product.price.currency}'
                          : '-${(periods.total - periods.periods) * product.price.unitPrice} ${product.price.currency}',*/
                      style: Theme.of(context).textTheme.headlineSmall,
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
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Spacer(),
              Text(
                isDev || periods.periods == 0 ? 'FREE' : purchaseProduct.price,
                /*isDev
                    ? '0 ${product.price.currency}'
                    : '${product.price.unitPrice * periods.periods} ${product.price.currency}',*/
                style: Theme.of(context).textTheme.headlineSmall,
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
  double duration;

  Periods({
    required this.total,
    required this.periods,
    required this.freeLeft,
    required this.freeUsed,
    required this.productDetails,
    required this.discountText,
    required this.duration,
  });
}
