// ignore_for_file: depend_on_referenced_packages
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pika_patrol/model/google_sheets_credential_adapter.dart';
import 'package:pika_patrol/services/observations_service.dart';
import 'package:pika_patrol/services/firebase_google_sheets_database_service.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/services/google_sheets_service.dart';
import 'package:pika_patrol/services/settings_service.dart';
import 'package:pika_patrol/services/firebase_auth_service.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
import 'package:pika_patrol/services/native_land_service.dart';
import 'package:pika_patrol/widgets/my_app.dart';
import 'package:provider/provider.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'l10n/translations.dart';
import 'model/app_user.dart';
import 'model/app_user_profile.dart';
import 'model/google_sheets_credential.dart';
import 'model/local_observation.dart';
import 'model/local_observation_adapter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'model/observation.dart';

const useEmulators = false;

Future<void> main() async {

  //debugPrintGestureArenaDiagnostics = true;

  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  bool envLoaded = false;
  try {
    await dotenv.load(fileName: '.env');
    envLoaded = true;
    developer.log('[main] Loaded .env from project root asset path.');
  } catch (e) {
    developer.log('[main] Failed to load .env using fileName=.env: $e');
  }

  if (!envLoaded) {
    try {
      await dotenv.load(fileName: 'assets/.env');
      envLoaded = true;
      developer.log('[main] Loaded .env from assets/.env path.');
    } catch (e) {
      developer.log('[main] Failed to load .env using fileName=assets/.env: $e');
    }
  }

  if (!envLoaded) {
    developer.log('[main] No .env file was loaded. Environment variables may be missing.');
  }

  // Log key loading state once at startup (never logs the key value).
  NativeLandService.logApiKeyStatus();

  await Hive.initFlutter();
  Hive.registerAdapter(LocalObservationAdapter());
  Hive.registerAdapter(GoogleSheetsCredentialAdapter());

  await Hive.openBox<LocalObservation>(FirebaseObservationsService.OBSERVATIONS_COLLECTION_NAME);
  await Hive.openBox<GoogleSheetsCredential>(FirebaseGoogleSheetsDatabaseService.GOOGLE_SHEETS_COLLECTION_NAME);

  //https://codewithandrea.com/articles/flutter-firebase-flutterfire-cli/

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Read this ahead of runApp() so MyApp knows on its very first build whether to show the
  // splash screens - by the time SettingsService's own (async) load finishes, the Navigator has
  // already built its initial route and switching MaterialApp's `home` afterward has no effect.
  final prefs = await SharedPreferences.getInstance();
  final showSplashScreen = prefs.getBool(SettingsService.PREFERENCE_SHOW_SPLASH_SCREEN) ?? true;

  runApp(
    // Providers are above [MyApp] instead of inside it, so that tests can use [MyApp] while mocking the providers
    MultiProvider(
      // Globally useful providers that don't depend on other provider values or build context
      providers: [
        ChangeNotifierProvider(
            create: (_) => MaterialThemesManager()
        ),
        Provider<FirebaseAuthService>(
            create: (_) => FirebaseAuthService(useEmulators)//Only one service to avoid multiple connections to firebase
        ),
        Provider<FirebaseDatabaseService>(
            create: (_) => FirebaseDatabaseService(useEmulators)
        ),
        ChangeNotifierProvider(
            create: (_) => SettingsService()
        ),
        ChangeNotifierProvider(
            create: (_) => Translations()
        ),
        Provider<ObservationsService>(
            create: (_) => ObservationsService()
        ),
        Provider<GoogleSheetsService>(
          create: (_) => GoogleSheetsService(),
          lazy: false
        ),
      ],
      builder: (context, child) {
        //Using StreamBuilder here in order so that appUserSnapshot is the desired type
        //since it's used when building the other providers

        return StreamBuilder<AppUser?>(
          stream: Provider.of<FirebaseAuthService>(context).user,
          initialData: null,
          builder: (context, appUserSnapshot) {

            final Translations translations = Provider.of<Translations>(context);

            final ObservationsService observationsService = Provider.of<ObservationsService>(context);//TODO - aggregate into observations services
            observationsService.translations = translations;//TODO -aggregate into observations services

            final AppUser? appUser = appUserSnapshot.hasData ? appUserSnapshot.data : null;
            final userId = appUser?.uid ?? "";

            var firebaseDatabaseService = Provider.of<FirebaseDatabaseService>(context);
            firebaseDatabaseService.currentUserId = appUser?.uid;

            observationsService.firebaseDatabaseService = firebaseDatabaseService;

            return StreamBuilder<AppUserProfile?>(
              stream: firebaseDatabaseService.userProfilesService.userProfile,
              initialData: null,
              builder: (context, appUserProfileSnapshot) {

                final AppUserProfile? appUserProfile = appUserProfileSnapshot.hasData ? appUserProfileSnapshot.data : null;

                return StreamBuilder<List<GoogleSheetsCredential>>(
                  stream: firebaseDatabaseService.googleSheetsService.credentials,
                  initialData: null,
                  builder: (context, googleSheetsCredentialsSnapshot) {

                    List<GoogleSheetsCredential> googleSheetsCredentials = googleSheetsCredentialsSnapshot.hasData ? (googleSheetsCredentialsSnapshot.data ?? []) : [];

                    final googleSheetsService = Provider.of<GoogleSheetsService>(context);
                    googleSheetsService.updateSpreadsheetServices(googleSheetsCredentials);

                    observationsService.googleSheetsService = googleSheetsService;

                    return StreamBuilder<List<Observation>>(
                      stream: firebaseDatabaseService.observationsService.observations,//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)
                      initialData: const [],
                      builder: (context, sharedObservationsOnFirebase) {

                        observationsService.setSharedObservations(sharedObservationsOnFirebase);//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)

                        return ValueListenableBuilder(
                            valueListenable: Hive.box<LocalObservation>(FirebaseObservationsService.OBSERVATIONS_COLLECTION_NAME).listenable(),
                            builder: (context, box, widget2) {

                              observationsService.setLocalObservations(box, appUser);//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)

                              return StreamBuilder<List<Observation>>(
                                stream: userId.isNotEmpty ? firebaseDatabaseService.observationsService.userObservations(userId) : observationsService.emptyObservationsStream,//TODO -aggregate into observations services
                                initialData: const [],
                                builder: (context, userObservationsOnFirebase) {

                                  observationsService.setUserObservations(userObservationsOnFirebase);//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)

                                  return MultiProvider(
                                      providers: [
                                        Provider<AppUser?>.value(
                                            value: appUser
                                        ),
                                        Provider<AppUserProfile?>.value(
                                            value: appUserProfile
                                        ),
                                        Provider<List<GoogleSheetsCredential>>.value(
                                            value: googleSheetsCredentials
                                        )
                                      ],
                                      child: MyApp(showSplashScreen: showSplashScreen)
                                  );
                                }
                              );
                            }
                        );
                      }
                    );
                  }
                );
              }
            );
          }
        );
      },
    ),
  );
}