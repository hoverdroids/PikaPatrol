import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pika_patrol/screens/splash/partners_splash_screens_pager.dart';
import 'package:pika_patrol/services/firebase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'model/local_observation.dart';
import 'model/local_observation_adapter.dart';
import 'model/app_user.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {

  //debugPrintGestureArenaDiagnostics = true;
  await Hive.initFlutter();
  Hive.registerAdapter(LocalObservationAdapter());
  await Hive.openBox<LocalObservation>('observations');

  //https://codewithandrea.com/articles/flutter-firebase-flutterfire-cli/
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    // Providers are above [MyApp] instead of inside it, so that tests can use [MyApp] while mocking the providers
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MaterialThemesManager()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    //First things first...set our theme to fit our brand!
    ColorPalette colorPalette = ColorPalette(
        primary: Colors.teal,
        primaryAccent: Colors.tealAccent,
        secondary: const Color.fromARGB(255, 139, 69, 19),
        secondaryAccent: const Color.fromARGB(255, 111, 55, 15),
        lightPrimaryContrast: Colors.white,
        lightContrastImportant: Colors.grey
    );
    context.watch<MaterialThemesManager>().updateColorPalette(colorPalette);

    //Lock the app to one orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp
    ]);

    //Colorize the system status bar and system navigation
    //TODO - revisit and determine if we want a light/dark theme mode adjustment
    /*SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: context.watch<MaterialThemesManager>().colorPalette().primary,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark
    ));*/

    return StreamProvider<AppUser?>.value(
      value: FirebaseAuthService().user,
      initialData: null,
      child: MaterialApp(
          title: "Pika Patrol",
          home: PartnersSplashScreensPager(),
          debugShowCheckedModeBanner: false,
          themeMode: context.watch<MaterialThemesManager>().getThemeMode(),
          theme: context.watch<MaterialThemesManager>().getPrimaryLightTheme(),
          darkTheme: context.watch<MaterialThemesManager>().getPrimaryDarkTheme()
      ),
    );
  }
}
