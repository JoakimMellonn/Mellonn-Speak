import 'dart:io';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mellonnSpeak/models/Recording.dart';
import 'package:mellonnSpeak/pages/home/record/recordPage.dart';
import 'package:mellonnSpeak/providers/amplifyAuthProvider.dart';
import 'package:mellonnSpeak/providers/amplifyDataStoreProvider.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:mellonnSpeak/utilities/standardWidgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:provider/src/provider.dart';

//Variables
String title = '';
String description = '';
int speakerCount = 2;
TemporalDateTime? date = TemporalDateTime.now();
bool uploadActive = false;
String languageCode = '';

//File Picker Variables
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
String? fileName = 'None';
FilePickerResult? result;
FileType pickingType = FileType.any;
String filePath = '';
List<String> fileTypes = [
  'waw',
  'flac',
  'm4p',
  'm4a',
  'm4b',
  'mmf',
  'aac',
  'mp3',
  'mp4'
];
//Variables to AWS Storage
File? file;
File? newFile;
String key = '';
String fileType = '';
bool filePicked = false;
String localFilePath = '';

//Price variables (EXTREMELY IMPORTANT)
double pricePerQ = 50.0; //DKK

class RecordPageProvider with ChangeNotifier {}

Future<double> getAudioDuration(String path) async {
  final player = AudioPlayer();
  var duration = await player.setFilePath(path);
  List<String> durationSplit = duration.toString().split(':');
  double hours = double.parse(durationSplit[0]);
  double minutes = double.parse(durationSplit[1]);
  double seconds = double.parse(durationSplit[2]);
  double totalSeconds = 3600 * hours + 60 * minutes + seconds;
  print(totalSeconds);
  return totalSeconds;
}

Future<Periods> getPeriods(double seconds, UserData userData) async {
  double minutes = seconds / 60;
  double qPeriods = minutes.round() / 15;
  int totalPeriods = qPeriods.ceil();
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
  print(
      'totalPeriods: $totalPeriods, freePeriods: $freePeriods, periods: $periods, freeLeft: $freeLeft');
  return Periods(
    total: totalPeriods,
    periods: periods,
    freeLeft: freeLeft,
    freeUsed: freeUsed,
  );
}

///
///This function first creates a new element in datastore
///Then it gets the ID of that element
///After that it uploads the selected file with the ID as the key (fancy word for filename)
///
Future<void> uploadRecording(Function() clearFilePicker) async {
  print(
      'Uploading recording with title: $title, path: $filePath, description: $description and date: $date...');
  Recording newRecording = Recording(
    name: title,
    description: description,
    date: date,
    fileName: fileName,
    fileKey: '',
    speakerCount: speakerCount,
    languageCode: languageCode,
  );
  fileType =
      key.split('.').last.toString(); //Gets the filetype of the selected file
  String newFileKey =
      'recordings/${newRecording.id}.$fileType'; //Creates the filekey from ID and filetype

  newRecording = newRecording.copyWith(
    fileKey: newFileKey,
  );

  print(
      'newRecording: ${newRecording.name}, ${newRecording.id}, ${newRecording.fileKey}');

  //Creates a new element in DataStore
  try {
    await Amplify.DataStore.save(newRecording);
  } on DataStoreException catch (e) {
    recordEventError('uploadRecording', e.message);
    print(e.message);
  }

  final docDir = await getLibraryDirectory();
  localFilePath = docDir.path + '/$key';

  //Saves the audio file in the app directory, so it doesn't have to be downloaded every time.
  File uploadFile = await newFile!.copy(localFilePath);

  //Uploads the selected file with the filekey
  await StorageProvider()
      .uploadFile(uploadFile, result, newFileKey, title, description);

  clearFilePicker(); //clears the filepicker, doesn't work tho...
}

///
///This function opens the filepicker and let's the user pick an audio file (not audiophile, that would be human trafficing)
///
Future<Periods> pickFile(Function() resetState, StateSetter setSheetState,
    UserData userData, context) async {
  resetState(); //Resets all variables to ZERO (not actually but it sounds cool)
  Periods periods = Periods(total: 0, periods: 0, freeLeft: 0, freeUsed: false);
  try {
    result = await FilePicker.platform.pickFiles(
        type: pickingType); //Opens the file picker, and only shows audio files

    ///
    ///Checks if the result isn't null, which means the user actually picked something, HURRAY!
    ///
    if (result != null) {
      //Defines all the necessary variables, and some that isn't but f**k that
      final platformFile = result!.files.single;
      final path = platformFile.path!;
      filePath = path;
      fileName = platformFile.name;
      if (!fileTypes.contains(fileName?.split('.').last)) {
        throw 'unsupported';
      }
      double seconds = await getAudioDuration(path);
      if (seconds > 9000) {
        throw 'tooLong';
      }
      filePicked = true;
      key = '${platformFile.name}';
      key = key.replaceAll(' ', '');
      file = File(result!.files.single.path!);
      if (Platform.isIOS) {
        final documentPath = (await getLibraryDirectory()).path;
        file = await file!.copy('$documentPath/${p.basename(file!.path)}');
      } else {
        file = File(path);
      }
      final docDir = await getLibraryDirectory();
      newFile = await file!.copy('${docDir.path}/$fileName');
      periods = await getPeriods(seconds, userData);
      StorageProvider().setFileName('$fileName');
      setSheetState(() {});
    } else {
      filePicked = false;
      resetState();
    }
  } on PlatformException catch (e) {
    recordEventError('pickFile-platform', e.details);
    resetState();
    //If error return error message
    print('Unsupported operation' + e.toString());
  } catch (e) {
    resetState();
    if (e == 'unsupported') {
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Unsupported file type',
          text:
              'The chosen file uses an unsupported file type, please choose another file.\nA list of supported file types can be found in Help on the profile page.',
        ),
      );
    } else if (e == 'tooLong') {
      showDialog(
        context: context,
        builder: (BuildContext context) => OkAlert(
          title: 'Recording is too long',
          text:
              'The chosen audio file is too long, max length for an audio file is 2.5 hours (150 minutes)',
        ),
      );
    } else {
      recordEventError('pickFile-other', e.toString());
      print('Error: $e');
    }
  }
  return periods;
}

class CheckoutPage extends StatelessWidget {
  final StProduct product;
  final Periods periods;
  final List<ProductDetails> productDetails;
  final String discountText;
  const CheckoutPage({
    Key? key,
    required this.product,
    required this.periods,
    required this.productDetails,
    required this.discountText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late ProductDetails productIAP;
    if (context.read<AuthAppProvider>().userGroup == 'benefit') {
      for (var prod in productsIAP) {
        if (prod.id == benefitIAP) {
          productIAP = prod;
        }
      }
    } else {
      for (var prod in productsIAP) {
        if (prod.id == standardIAP) {
          productIAP = prod;
        }
      }
    }
    bool isDev = false;
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
                productIAP.title, //product.name,
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
                productIAP
                    .price, //'${product.price.unitPrice} ${product.price.currency}',
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
                      isDev ? '-${productIAP.price}' : discountText,
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
                isDev || periods.periods == 0
                    ? '0 ${product.price.currency}'
                    : productIAP.price,
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

Future<String> getDiscount(int freeUsed, String userType) async {
  if (freeUsed != 0) {
    print('getting discount: $freeUsed, $userType');
    int minutes = freeUsed * 15;
    if (userType == 'user') {
      standardIAP = 'speak' + '$minutes' + 'minutes';
    } else if (userType == 'benefit') {
      standardIAP = 'benefit' + '$minutes' + 'minutes';
    } else if (userType == 'dev') {
      return '';
    }
    Set<String> ids = Set.from([standardIAP, 'standard']);
    ProductDetailsResponse response = await iap.queryProductDetails(ids);

    ProductDetails details = response.productDetails.last;
    return '-${details.price}';
  } else {
    return '';
  }
}

class Periods {
  int total;
  int periods;
  int freeLeft;
  bool freeUsed;

  Periods({
    required this.total,
    required this.periods,
    required this.freeLeft,
    required this.freeUsed,
  });
}
