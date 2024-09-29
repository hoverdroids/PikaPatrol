// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pika_patrol/model/google_sheets_credential_adapter.dart';
import 'package:pika_patrol/project_config.dart';
import 'package:pika_patrol/services/firebase/animal_observations_firebase_firestore_service.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_google_sheets_credentials_collection.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_observation_collection.dart';
import 'package:pika_patrol/services/firebase/firebase_firestore_service.dart';
import 'package:pika_patrol/services/firebase/firebase_service.dart';
import 'package:pika_patrol/services/observations_service.dart';
import 'package:pika_patrol/services/settings_service.dart';
import 'package:pika_patrol/services/firebase/firebase_auth_service.dart';
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
import 'services/firebase/firebase_options.dart';

import 'model/observation.dart';

Future<void> main() async {
  //debugPrintGestureArenaDiagnostics = true;

  //TODO - this needs to be handled generically by a local database.init
  await Hive.initFlutter();

  //TODO - this needs to be handled generically by a local database.init
  Hive.registerAdapter(LocalObservationAdapter());
  await Hive.openBox<LocalObservation>(FirebaseObservationCollection.COLLECTION_NAME);

  //TODO - this needs to be handled generically by a local database.init
  Hive.registerAdapter(GoogleSheetsCredentialAdapter());
  await Hive.openBox<GoogleSheetsCredential>(FirebaseGoogleSheetsCredentialCollection.COLLECTION_NAME);

  await FirebaseService.initialize(DefaultFirebaseOptions.currentPlatform);

  //TODO - this needs to be a generic authenticator or authProvider so that we could switch out for another option if desired
  final firebaseAuthServiceReturnValue = await FirebaseAuthService.create(
    useEmulator: FirebaseProjectConfig.AUTHENTICATION_USE_EMULATOR,
    emulatorHostnameOrIpAddress: FirebaseProjectConfig.AUTHENTICATION_EMULATOR_IP,
    emulatorPort: FirebaseProjectConfig.AUTHENTICATION_EMULATOR_PORT,
    persistenceForWeb: FirebaseProjectConfig.AUTHENTICATION_WEB_PERSISTENCE
  );
  final firebaseAuthService = firebaseAuthServiceReturnValue.value ?? FirebaseAuthService();

  //TODO - this needs to be a generic database service so that we could switch out for another option if desired
  final animalObservationsFirebaseFirestoreService = AnimalObservationsFirebaseFirestoreService(
    bucket: FirebaseProjectConfig.STORAGE_BUCKET,
    useEmulator: FirebaseProjectConfig.FIRESTORE_USE_EMULATOR,
    emulatorHostnameOrIpAddress: FirebaseProjectConfig.FIRESTORE_EMULATOR_IP,
    emulatorPort: FirebaseProjectConfig.FIRESTORE_EMULATOR_PORT,
    persistenceEnabled: FirebaseProjectConfig.FIRESTORE_PERSISTENCE_ENABLED,
    sslEnabled: FirebaseProjectConfig.FIRESTORE_SSL_ENABLED
  );

  runApp(
    // Providers are above [MyApp] instead of inside it, so that tests can use [MyApp] while mocking the providers
    MultiProvider(
      // Globally useful providers that don't depend on other provider values or build context
      providers: [
        ChangeNotifierProvider(
            create: (_) => MaterialThemesManager()
        ),
        Provider<FirebaseAuthService>(
            create: (_) => firebaseAuthService//Only one service to avoid multiple connections to firebase
        ),
        Provider<AnimalObservationsFirebaseFirestoreService>(
            create: (_) => animalObservationsFirebaseFirestoreService//Only one service to avoid multiple connections to firebase
        ),
        ChangeNotifierProvider(
            create: (_) => SettingsService()
        ),
        ChangeNotifierProvider(
            create: (_) => Translations()
        ),
        Provider<ObservationsService>(
            create: (_) => ObservationsService()//TODO - what is the difference between ObservationsService and AnimalObservations service?
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
            observationsService.translations = translations;//TODO - aggregate into observations services

            final AppUser? appUser = appUserSnapshot.hasData ? appUserSnapshot.data : null;
            final userId = appUser?.uid ?? "";

            var firebaseFirestoreService = Provider.of<FirebaseFirestoreService>(context);
            firebaseFirestoreService.currentUserId = appUser?.uid;

            observationsService.firebaseFirestoreService = firebaseFirestoreService;

            return StreamBuilder<AppUserProfile?>(
              stream: firebaseFirestoreService.userProfilesCollection.userProfileStream,
              initialData: null,
              builder: (context, appUserProfileSnapshot) {

                final AppUserProfile? appUserProfile = appUserProfileSnapshot.hasData ? appUserProfileSnapshot.data : null;

                return StreamBuilder<List<GoogleSheetsCredential>>(
                  stream: firebaseFirestoreService.googleSheetsCredentialsCollection.credentials,
                  initialData: null,
                  builder: (context, googleSheetsCredentialsSnapshot) {

                    List<GoogleSheetsCredential> googleSheetsCredentials = googleSheetsCredentialsSnapshot.hasData ? (googleSheetsCredentialsSnapshot.data ?? []) : [];

                    return StreamBuilder<List<Observation>>(
                      stream: firebaseFirestoreService.observationsCollection.observationsStream,//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)
                      initialData: const [],
                      builder: (context, sharedObservationsOnFirebase){

                        observationsService.setSharedObservations(sharedObservationsOnFirebase);//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)

                        return ValueListenableBuilder(
                            valueListenable: Hive.box<LocalObservation>(FirebaseObservationProvider.COLLECTION_NAME).listenable(),
                            builder: (context, box, widget2){

                              observationsService.setLocalObservations(box, userId);//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)

                              return StreamBuilder<List<Observation>>(
                                stream: userId.isNotEmpty ? firebaseFirestoreService.observationsCollection.getUserObservationsStream(userId) : observationsService.emptyObservationsStream,//TODO - aggregate into observations services (see stashes: shared observations attempt 1 and 2)
                                initialData: const[],
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
                                        ),
                                        Provider<GoogleSheetsService>(
                                            create: (_) {
                                              List<PikaPatrolSpreadsheetService> services = [];

                                              for (var credential in googleSheetsCredentials) {
                                                credential.spreadsheets.forEach((projectName, spreadsheetId) {
                                                  var service = PikaPatrolSpreadsheetService(projectName, credential.credential, spreadsheetId, false);
                                                  services.add(service);
                                                });
                                              }

                                              final googleSheetsService = GoogleSheetsService(services);

                                              observationsService.googleSheetsService = googleSheetsService;

                                              return googleSheetsService;
                                            }
                                        ),
                                      ],
                                      child: const MyApp()
                                  );
                                }
                              );
                            }
                        );
                      },
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