// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:provider/provider.dart';
import '../screens/splash/partners_splash_screens_pager.dart';

class MyApp extends StatelessWidget {

  const MyApp({super.key});

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

    return MaterialApp(
        title: "Pika Patrol",
        home: const PartnersSplashScreensPager(),
        debugShowCheckedModeBanner: false,
        themeMode: context.watch<MaterialThemesManager>().getThemeMode(),
        theme: context.watch<MaterialThemesManager>().getPrimaryLightTheme(),
        darkTheme: context.watch<MaterialThemesManager>().getPrimaryDarkTheme()
    );
  }
}