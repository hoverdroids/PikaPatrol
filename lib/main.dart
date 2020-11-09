import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:pika_joe/screens/home_with_drawer.dart';
import 'package:pika_joe/screens/splash/partners_splash_screens_pager.dart';
import 'package:pika_joe/services/firebase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:pika_joe/screens/tools/image_capture.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'model/local_observation.dart';
import 'model/local_observation_adapter.dart';
import 'model/user.dart';

void main() async {
  //debugPrintGestureArenaDiagnostics = true;
  await Hive.initFlutter();
  Hive.registerAdapter(LocalObservationAdapter());
  await Hive.openBox<LocalObservation>('observations');
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
      secondary: Color.fromARGB(255, 139, 69, 19),
      secondaryAccent: Color.fromARGB(255, 111, 55, 15),
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

    return StreamProvider<User>.value(
      value: FirebaseAuthService().user,
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