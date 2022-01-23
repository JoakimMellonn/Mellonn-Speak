import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transscriber/models/ModelProvider.dart';
import 'package:transscriber/pages/mainAppPage.dart';
import 'amplifyconfiguration.dart';
import 'package:transscriber/providers/amplifyStorageProvider.dart';
import 'package:transscriber/providers/languageProvider.dart';
import 'package:transscriber/providers/settingsProvider.dart';
import 'package:transscriber/providers/transcriptionEditProvider.dart';
import 'package:transscriber/transcription/transcriptionProvider.dart';
import 'pages/awsLoginPages/loginPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify.dart';
import 'providers/amplifyAuthProvider.dart';
import 'providers/colorProvider.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'models/ModelProvider.dart';
import 'providers/amplifyDataStoreProvider.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'transcription/transcriptionProvider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

ThemeMode themeMode = ThemeMode.system;

//The first thing that is called, when running the app
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  //Setting the publishable key for Stripe, yes this is important, because it's about money
  Stripe.publishableKey =
      'pk_live_51K1CskBLC2uA76LRiLT8CHp9jweq66Abx9Iud3ZkzF6pQGZzQglbQqAFiajReDMMVrlyAJbGr9ngR8qN2P2jB46t00KuvBiqrB';

  runApp(
    //Initializing the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthAppProvider()),
        ChangeNotifierProvider(create: (_) => ColorProvider()),
        ChangeNotifierProvider(create: (_) => DataStoreAppProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => TranscriptionProcessing()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => TranscriptionEditProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData(
          brightness: Brightness.light,
          primaryColor: Color(0xFFFAB228),
          primarySwatch: Colors.amber,
          colorScheme: ColorScheme(
            primary: Color(0xFFFAB228),
            primaryVariant: Color(0xFFFAB228),
            secondary: Color(0xFF505050),
            secondaryVariant: Colors.black26,
            surface: Color(0xFFF8F8F8),
            background: Color(0xFFFFFFFF),
            error: Colors.red,
            onPrimary: Color(0xFFFAB228),
            onSecondary: Color(0xFF505050),
            onSurface: Color(0xFFA5C644),
            onBackground: Color(0xFFFFFFFF),
            onError: Color(0xFFFAB228),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.ralewayTextTheme(),
          dividerTheme: DividerThemeData(
            space: 25,
            thickness: 1,
            color: Colors.black26,
            indent: 5,
            endIndent: 5,
          ),
          inputDecorationTheme: InputDecorationTheme(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF505050),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFFAB228),
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: Color(0xFFFAB228),
          primarySwatch: Colors.amber,
          colorScheme: ColorScheme(
            primary: Color(0xFFFAB228),
            primaryVariant: Color(0xFFFAB228),
            secondary: Color(0xFFF8F8F8),
            secondaryVariant: Color(0x42000000),
            surface: Color(0xFF505050),
            background: Color(0xFF404040),
            error: Colors.red,
            onPrimary: Color(0xFFFAB228),
            onSecondary: Color(0xFF505050),
            onSurface: Color(0xFFA5C644),
            onBackground: Color(0xFFFFFFFF),
            onError: Color(0xFFFAB228),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.ralewayTextTheme(),
          dividerTheme: DividerThemeData(
            space: 25,
            thickness: 1,
            color: Colors.black26,
            indent: 5,
            endIndent: 5,
          ),
          inputDecorationTheme: InputDecorationTheme(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFF505050),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Color(0xFFFAB228),
              ),
            ),
          ),
        ),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        //Calling the widget MyApp(), which you can see below
        home: MyApp(),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  //Essential variables for the app to start
  bool _isLoading = true;
  bool _error = false;
  bool isSignedIn = false;

  //Not essential, idk why I still use this
  final AmplifyAuthCognito _authPlugin = AmplifyAuthCognito();

  //This runs first, when the widget is called
  @override
  void initState() {
    _initializeApp();
    super.initState();
  }

  /*
  * This function waits for everything to start up
  * Primarily configuring Amplify and checking if anyone is logged in on the device
  */
  Future<void> _initializeApp() async {
    await _configureAmplify();
    await _checkIfSignedIn();
    await context.read<LanguageProvider>().webScraber();
    await setSettings();
    var brightness = MediaQuery.of(context).platformBrightness;
    bool isDarkMode = brightness == Brightness.dark;
    if (isDarkMode) {
      context.read<ColorProvider>().setDarkMode();
    } else {
      context.read<ColorProvider>().setLightMode();
    }
    setState(() {
      _isLoading = false;
      _error = false;
    });
  }

  ///
  ///This function is to be called when the app starts
  ///It will then apply the loaded settings
  ///
  Future<void> setSettings() async {
    await context.read<SettingsProvider>().setCurrentSettings();
    Settings cSettings = context.read<SettingsProvider>().currentSettings;
    if (cSettings.darkMode) {
      themeMode = ThemeMode.dark;
      context.read<ColorProvider>().setDarkMode();
    }
    context.read<LanguageProvider>().setDefaultLanguage(cSettings.languageCode);
  }

  /*
  * This function checks if there is any userdata on the device
  * If this is true, it will get the recordings of the user, and return isSignedIn true
  * If not, it will clear everything stored on the device, and return isSignedIn false
  */
  Future<void> _checkIfSignedIn() async {
    try {
      final currentUser = await Amplify.Auth
          .getCurrentUser(); //Check if there's a user currently logged in
      isSignedIn = true;
      await context
          .read<AuthAppProvider>()
          .getUserAttributes(); //Using the AuthAppProvider to get the user attributes
      await context
          .read<DataStoreAppProvider>()
          .getRecordings(); //Using the DataStoreAppProvider to get the recordings of the user
      print('user already signed in');
    } on AuthException catch (e) {
      await Amplify.DataStore
          .clear(); //Clearing all data from DataStore, from potential earlier users
      // ignore: unnecessary_statements
      context
          .read<DataStoreAppProvider>()
          .clearRecordings; //Clearing the list of recordings
      print(e.message);
      isSignedIn = false;
    }
  }

  /*
  * This function makes Amplify ready to be used
  * If an error occures it will just return _error true, and the app won't launch :(
  * But we hope it's a good boy
  */
  Future<void> _configureAmplify() async {
    try {
      AmplifyDataStore datastorePlugin =
          AmplifyDataStore(modelProvider: ModelProvider.instance);
      await Amplify.addPlugins([
        _authPlugin,
        datastorePlugin,
        AmplifyAPI(),
        AmplifyStorageS3(),
      ]);
      await Amplify.configure(amplifyconfig);
    } catch (e) {
      print('An error occured while configuring amplify: $e');
      _error = true;
    }
  }

  /*
  * Building the main scaffold of the app
  * Which one will be shown is defined by wether the app launched successfully
  * And wether a user is logged in or not
  */
  @override
  Widget build(BuildContext context) {
    //If an error occurs during the setup, this will be shown :(
    if (_error) {
      return Scaffold(
        body: Center(
          child: Text('Something went wrong'),
        ),
      );
    }

    //This is just so it doesn't show a blank screen while loading
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    //If anyone is signed in, it will show the MainAppPage()
    if (isSignedIn) {
      return MainAppPage();
    }

    //And of course, if no one is signed in, it will direct the user to the login screen... Genious
    return LoginScreen();
  }
}
