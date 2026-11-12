// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:pika_patrol/l10n/l10n.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pika_patrol/l10n/app_localizations.dart';

import '../l10n/translations.dart';
import '../screens/home_with_drawer.dart';
import '../screens/splash/partners_splash_screens_pager.dart';
import '../services/settings_service.dart';

class MyApp extends StatelessWidget {

  // Decided once at startup (see main()) rather than watched reactively: MaterialApp only
  // consults `home` when it generates the initial route, so changing this value after the
  // Navigator's first route is built has no effect on the running app - the setting change
  // is picked up the next time the app is launched instead.
  final bool showSplashScreen;

  const MyApp({super.key, this.showSplashScreen = true});

  // The brand colors. Set once when the MaterialThemesManager is created (see main()), because
  // setting them during build notifies listeners mid-build, which Flutter rejects.
  static final ColorPalette colorPalette = ColorPalette(
      primary: Colors.teal,
      primaryAccent: Colors.tealAccent,
      secondary: const Color.fromARGB(255, 139, 69, 19),
      secondaryAccent: const Color.fromARGB(255, 111, 55, 15),
      lightPrimaryContrast: Colors.white,
      lightContrastImportant: Colors.grey
  );

  @override
  Widget build(BuildContext context) {

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

    //This must be called before MaterialApp sets localizations
    var translations = Provider.of<Translations>(context);
    translations.init(context);

    return MaterialApp(
        title: "Pika Patrol",//This doesn't matter and can't be translated because localization isn't applied until MaterialApp is instantiated
        home: showSplashScreen
            ? const PartnersSplashScreensPager()
            : const HomeWithDrawer(),
        debugShowCheckedModeBanner: false,
        themeMode: context.watch<MaterialThemesManager>().getThemeMode(),
        theme: context.watch<MaterialThemesManager>().getPrimaryLightTheme(),
        darkTheme: context.watch<MaterialThemesManager>().getPrimaryDarkTheme(),
        supportedLocales: L10n.ALL,
        locale: context.watch<SettingsService>().locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate
        ]
    );
  }
}