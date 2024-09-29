// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pika_patrol/services/firebase/app_firebase_firestore_service.dart';
import 'package:pika_patrol/services/firebase/firebase_firestore_service.dart';
import 'package:pika_patrol/services/google_sheets_credentials/google_sheets_credentials_service.dart';
import 'package:pika_patrol/services/settings_service.dart';
import 'package:pika_patrol/app/my_app.dart';
import 'package:provider/provider.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import '../l10n/translations.dart';
import '../services/authentication/app_user.dart';
import '../services/authentication/authentication_service.dart';
import '../services/observations/observations_service.dart';
import '../services/user_profiles/app_user_profile.dart';
import '../services/observations/local_observation.dart';
import '../services/observations/observation.dart';
import '../services/user_profiles/user_profiles_service.dart';

initObservationsApp(
  AuthenticationService authenticationService,
  GoogleSheetsCredentialsService googleSheetsCredentialsService,
  ObservationsService observationsService,
  UserProfilesService userProfilesService
) {
  runApp(
    // Providers are above [MyApp] instead of inside it, so that tests can use [MyApp] while mocking the providers
    MultiProvider(
      // Globally useful providers that don't depend on other provider values or build context
      providers: [
        ChangeNotifierProvider(
            create: (_) => MaterialThemesManager()
        ),
        Provider<AuthenticationService>(
            create: (_) => authenticationService
        ),
        Provider<AppFirebaseFirestoreService>(
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
            stream: Provider.of<AuthenticationProvider>(context).appUserStream,
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