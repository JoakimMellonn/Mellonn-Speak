import 'dart:async';
import 'dart:io';
import 'package:amplify_analytics_pinpoint/amplify_analytics_pinpoint.dart';
import 'package:amplify_push_notifications_pinpoint/amplify_push_notifications_pinpoint.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mellonnSpeak/models/ModelProvider.dart';
import 'package:mellonnSpeak/pages/home/main/mainPage.dart';
import 'package:mellonnSpeak/pages/home/main/mainPageProvider.dart';
import 'package:mellonnSpeak/pages/home/onboarding/onboardingProvider.dart';
import 'package:mellonnSpeak/pages/home/profile/settings/settingsProvider.dart';
import 'package:mellonnSpeak/pages/home/main/shareIntent/shareIntentPage.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPage.dart';
import 'package:mellonnSpeak/pages/home/transcriptionPages/transcriptionPageProvider.dart';
import 'package:mellonnSpeak/pages/login/loginPage.dart';
import 'package:mellonnSpeak/providers/analyticsProvider.dart';
import 'package:mellonnSpeak/providers/mainProvider.dart';
import 'package:mellonnSpeak/providers/paymentProvider.dart';
import 'package:mellonnSpeak/utilities/.env.dart';
import 'package:mellonnSpeak/utilities/global.dart';
import 'package:mellonnSpeak/utilities/theme.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'amplifyconfiguration.dart';
import 'package:mellonnSpeak/providers/amplifyStorageProvider.dart';
import 'package:mellonnSpeak/providers/languageProvider.dart';
import 'package:mellonnSpeak/transcription/transcriptionProvider.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'providers/amplifyAuthProvider.dart';
import 'package:amplify_datastore/amplify_datastore.dart';
import 'providers/amplifyDataStoreProvider.dart';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:get/get.dart';

ThemeMode themeMode = ThemeMode.system;
final fbTracking = FacebookAppEvents();
late StreamSubscription<String> tokenReceivedSubscription;
late StreamSubscription<PushNotificationMessage> notificationReceivedSubscription;
late StreamSubscription<PushNotificationMessage> notificationOpenedSubscription;
String? launchRecordingId;
String? deviceToken;

//The first thing that is called, when running the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await _configureAmplify();

  //Setting the publishable key for Stripe, yes this is important, because it's about money
  //Stripe.publishableKey = stripePublishableKey;
  //Stripe.merchantIdentifier = merchantID;
  //await Stripe.instance.applySettings();

  // final _router = GoRouter(
  //   routes: [
  //     GoRoute(
  //       path: '/',
  //       builder: (context, state) => MainPage(),
  //     ),
  //     GoRoute(
  //       path: '/recording/:id',
  //       builder: (context, state) => TranscriptionPage(),
  //     )
  //   ],
  // );

  runApp(
    //Initializing the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MainProvider()),
        ChangeNotifierProvider(create: (_) => MainPageProvider()),
        ChangeNotifierProvider(create: (_) => AuthAppProvider()),
        ChangeNotifierProvider(create: (_) => DataStoreAppProvider()),
        ChangeNotifierProvider(create: (_) => StorageProvider()),
        ChangeNotifierProvider(create: (_) => TranscriptionProcessing()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => OnboardingProvider()),
        ChangeNotifierProvider(create: (_) => TranscriptionPageProvider()),
      ],
      child: GetMaterialApp(
        theme: lightModeTheme,
        darkTheme: darkModeTheme,
        themeMode: themeMode,
        navigatorKey: GlobalVariable.navState,
        debugShowCheckedModeBanner: false,
        home: MyApp(),
      ),
    ),
  );
}

///
///This function makes Amplify ready to be used
///If an error occurs it will just return _error true, and the app won't launch :(
///But we hope it's a good boy
///
Future<void> _configureAmplify() async {
  try {
    late AmplifyPushNotificationsPinpoint notificationsPlugin;
    bool notificationsAdded = false;
    List<AmplifyPluginInterface> plugins = [
      AmplifyAuthCognito(),
      AmplifyDataStore(modelProvider: ModelProvider.instance),
      AmplifyAPI(),
      AmplifyStorageS3(),
      AmplifyAnalyticsPinpoint(),
    ];

    try {
      print('Setting up notifications');
      notificationsPlugin = await setupNotifications();
      print('Notifications setup');
      plugins.add(notificationsPlugin);
      notificationsAdded = true;
    } catch (e) {
      print('Error while setting up notifications: ${e.toString()}');
      //context.read<AnalyticsProvider>().recordEventError('setupNotifications', e.toString());
    }

    await Amplify.addPlugins(plugins);
    if (!Amplify.isConfigured) {
      try {
        await Amplify.configure(amplifyconfig);
      } catch (e) {
        print('Error while configuring amplify: ${e.toString()}');
      }
    }

    if (notificationsAdded) {
      notificationReceivedSubscription = notificationsPlugin.onNotificationReceivedInForeground.listen(onNotificationReceived);

      notificationOpenedSubscription = notificationsPlugin.onNotificationOpened.listen(onNotificationOpened);

      final launchNotification = notificationsPlugin.launchNotification;

      if (launchNotification != null) {
        onLaunchNotificationOpened(launchNotification);
      }

      tokenReceivedSubscription = Amplify.Notifications.Push.onTokenReceived.listen((token) {
        print('Token received: $token');
        deviceToken = token;
      });
    }
  } catch (e) {
    print('An error occurred while configuring amplify: $e');
    MainProvider().error = true;
  }
}

Future<AmplifyPushNotificationsPinpoint> setupNotifications() async {
  print("Creating notifications plugin");
  final notificationsPlugin = AmplifyPushNotificationsPinpoint();

  print("Getting launch notification");

  print("Subscribing to notifications in background");
  notificationsPlugin.onNotificationReceivedInBackground(onNotificationReceived);

  print("Return notifications plugin");
  return notificationsPlugin;
}

Future requestNotificationAccess(BuildContext context) async {
  try {
    print("Requesting access");
    PushNotificationPermissionStatus? status = context.read<MainProvider>().pushNotificationPermissionStatus;
    if (status == null) {
      print("Status is null");
      status = await Amplify.Notifications.Push.getPermissionStatus();
      context.read<MainProvider>().pushNotificationPermissionStatus = status;
    }
    if (status == PushNotificationPermissionStatus.shouldRequest || status == PushNotificationPermissionStatus.shouldExplainThenRequest) {
      final result = await Amplify.Notifications.Push.requestPermissions(badge: true);
      context.read<MainProvider>().pushNotificationPermissionStatus = status;
      if (!result) {
        print('User declined to enable notifications');
        return;
      }
    }
    if (status == PushNotificationPermissionStatus.denied) {
      print('User declined to enable notifications');
      context.read<MainProvider>().pushNotificationPermissionStatus = status;
      return;
    }

    final user = await Amplify.Auth.getCurrentUser();
    print("User: $user");
    final userProfile = AWSPinpointUserProfile(
      name: context.read<AuthAppProvider>().fullName,
      email: context.read<AuthAppProvider>().email,
      userAttributes: {},
    );
    print("Identifying user");

    await Amplify.Notifications.Push.identifyUser(
      userId: user.userId,
      userProfile: userProfile,
    );
  } catch (e) {
    print('An error occurred while requesting notification permissions: $e');
    context.read<AnalyticsProvider>().recordEventError('requestNotificationAccess', e.toString());
  }
}

Future onNotificationReceived(PushNotificationMessage notification) async {
  try {
    print('Notification received');
    print('Data: ${notification.data}');
  } catch (e) {
    print('An error occurred while receiving a notification: $e');
    AnalyticsProvider().recordEventError('onNotificationReceived', e.toString());
  }
}

Future onLaunchNotificationOpened(PushNotificationMessage notification) async {
  try {
    launchRecordingId = notification.deeplinkUrl!.split("/").last;
    // launchRecordingId = notification.data['recordingId']!.toString();
    print('Launch notification opened: $launchRecordingId');
  } catch (e) {
    print('An error occurred while opening a notification: $e');
    AnalyticsProvider().recordEventError('onNotificationOpened', e.toString());
  }
}

Future onNotificationOpened(PushNotificationMessage notification) async {
  print('Notification opened: ${notification.body}');
  try {
    final recordingId = notification.deeplinkUrl!.split("/").last;
    // final recordingId = notification.data['recordingId']!.toString();
    print('Notification opened: $recordingId');
    final recording = await DataStoreAppProvider().getRecording(recordingId);
    if (recording != null) {
      Navigator.push(
        GlobalVariable.navState.currentContext!,
        MaterialPageRoute(
          builder: (context) => TranscriptionPage(recording: recording),
        ),
      );
    }
  } catch (e) {
    print('An error occurred while opening a notification: $e');
    AnalyticsProvider().recordEventError('onNotificationOpened', e.toString());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late StreamSubscription intentDataStreamSubscription;

  List<File> sharedFiles = [];

  //This runs first, when the widget is called
  @override
  void initState() {
    ///
    ///This subscription will check if the app receives sharing intents
    ///
    intentDataStreamSubscription = ReceiveSharingIntent.getMediaStream().listen((List<SharedMediaFile> value) async {
      if (value.isNotEmpty) {
        bool permission = await checkStoragePermission();
        if (permission) {
          print('Received file: ${value.last.path}');
          context.read<MainProvider>().isSharedData = true;
          value.forEach(
            (element) {
              sharedFiles.add(
                File(
                  Platform.isIOS
                      ? element.type == SharedMediaType.FILE
                          ? Uri.decodeFull(element.path.toString().replaceAll('file://', ''))
                          : element.path
                      : element.path,
                ),
              );
            },
          );
          if (Platform.isIOS) {
            if (await _checkIfSignedIn()) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return ShareIntentPage(
                      files: sharedFiles,
                    );
                  },
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) {
                    return LoginPage();
                  },
                ),
              );
            }
          }
        }
      }
    }, onError: (err) {
      print("$err");
    });

    ReceiveSharingIntent.getInitialMedia().then((List<SharedMediaFile> value) async {
      if (value.isNotEmpty) {
        bool permission = await checkStoragePermission();
        if (permission) {
          print('Received initial file: ${value.last.path}');
          context.read<MainProvider>().isSharedData = true;
          value.forEach(
            (element) {
              sharedFiles.add(
                File(
                  Platform.isIOS
                      ? element.type == SharedMediaType.FILE
                          ? Uri.decodeFull(element.path.toString().replaceAll('file://', ''))
                          : element.path
                      : element.path,
                ),
              );
            },
          );
          if (await _checkIfSignedIn()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return ShareIntentPage(
                    files: sharedFiles,
                  );
                },
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return LoginPage();
                },
              ),
            );
          }
        }
      }
    });

    _initializeApp();
    super.initState();
  }

  void dispose() {
    intentDataStreamSubscription.cancel();
    notificationReceivedSubscription.cancel();
    notificationOpenedSubscription.cancel();
    super.dispose();
  }

  ///
  ///This function waits for everything to start up
  ///Primarily configuring Amplify and checking if anyone is logged in on the device
  ///
  Future<void> _initializeApp() async {
    if (context.read<MainProvider>().isLoading) {
      context.read<MainProvider>().pushNotificationPermissionStatus = await Amplify.Notifications.Push.getPermissionStatus();
      await _checkIfSignedIn();
      await context.read<LanguageProvider>().webScraper();
      if (context.read<AuthAppProvider>().isSignedIn) {
        await setSettings();
        // if (deviceToken != null) context.read<AnalyticsProvider>().registerToken(deviceToken!);
      }
      await requestNotificationAccess(context);
      productsIAP = await getAllProductsIAP();
      bool tracking = await checkTrackingPermission();
      if (launchRecordingId != null) {
        await context.read<MainProvider>().setLaunchRecording(launchRecordingId!);
      }

      appTrackingAllowed = tracking;
      context.read<MainProvider>().isLoading = false;
      context.read<MainProvider>().error = false;
    }
  }

  ///
  ///This function asks the user for permission to track their activity.
  ///It will only track downloads, login and purchases.
  ///
  Future<bool> checkTrackingPermission() async {
    var status = await Permission.appTrackingTransparency.status;
    if (status.isDenied) {
      var askResult = await Permission.appTrackingTransparency.request();
      if (askResult.isGranted) {
        await fbTracking.setAdvertiserTracking(enabled: true);
        return true;
      } else {
        await fbTracking.setAdvertiserTracking(enabled: false);
        return false;
      }
    } else if (status.isGranted) {
      await fbTracking.setAdvertiserTracking(enabled: true);
      return true;
    } else {
      await fbTracking.setAdvertiserTracking(enabled: false);
      return false;
    }
  }

  ///
  ///This function asks the user for permission to access local storage on the device.
  ///
  Future<bool> checkStoragePermission() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      var askResult = await Permission.storage.request();
      if (askResult.isGranted) {
        return true;
      } else {
        return false;
      }
    } else if (status.isGranted) {
      return true;
    } else {
      return false;
    }
  }

  ///
  ///This function is to be called when the app starts
  ///It will then apply the loaded settings
  ///
  Future<void> setSettings() async {
    await context.read<SettingsProvider>().setCurrentSettings();
    Settings cSettings = context.read<SettingsProvider>().currentSettings;
    if (cSettings.themeMode == 'Dark') {
      themeMode = ThemeMode.dark;
      currentLogo = darkModeLogo;
    } else if (cSettings.themeMode == 'Light') {
      currentLogo = lightModeLogo;
    }
    context.read<LanguageProvider>().setDefaultLanguage(cSettings.languageCode);
  }

  ///
  ///This function checks if there is any user data on the device
  ///If this is true, it will get the recordings of the user, and return isSignedIn true
  ///If not, it will clear everything stored on the device, and return isSignedIn false
  ///
  Future<bool> _checkIfSignedIn() async {
    try {
      await Amplify.Auth.getCurrentUser();
      context.read<AuthAppProvider>().isSignedIn = true;
      await context.read<AuthAppProvider>().getUserAttributes();
      return true;
    } on AuthException catch (e) {
      await Amplify.DataStore.clear();
      print(e.message);
      AuthAppProvider().isSignedIn = false;
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (context.watch<MainProvider>().error) {
      return Scaffold(
        body: Center(
          child: Text('Something went wrong'),
        ),
      );
    }

    if (context.watch<MainProvider>().isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
          ),
        ),
      );
    }

    if (context.watch<MainProvider>().launchRecording != null) {
      return TranscriptionPage(recording: context.watch<MainProvider>().launchRecording!);
    }

    if (context.watch<AuthAppProvider>().isSignedIn && !context.watch<MainProvider>().isSharedData) {
      return MainPage();
    }

    if (context.watch<AuthAppProvider>().isSignedIn && context.watch<MainProvider>().isSharedData) {
      return ShareIntentPage(
        files: sharedFiles,
      );
    }

    if (!context.watch<AuthAppProvider>().isSignedIn && context.watch<MainProvider>().isSharedData) {
      return LoginPage();
    }

    return LoginPage();
  }
}
