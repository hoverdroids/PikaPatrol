// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pika_patrol/app/observations_app.dart';
import 'package:pika_patrol/model/google_sheets_credential_adapter.dart';
import 'package:pika_patrol/project_config.dart';
import 'package:pika_patrol/providers/authentication/authentication_provider.dart';
import 'package:pika_patrol/providers/authentication/authentication_service.dart';
import 'package:pika_patrol/services/authentication/authentication_service.dart';
import 'package:pika_patrol/services/firebase/app_firebase_firestore_service.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_google_sheets_credentials_collection.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_observation_collection.dart';
import 'package:pika_patrol/services/firebase/firebase_firestore_service.dart';
import 'package:pika_patrol/services/firebase/firebase_service.dart';
import 'package:pika_patrol/services/observation/observations_service.dart';
import 'package:pika_patrol/services/settings_service.dart';
import 'package:pika_patrol/services/firebase/firebase_auth_service.dart';
import 'package:pika_patrol/app/my_app.dart';
import 'package:provider/provider.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'l10n/translations.dart';
import 'services/authentication/app_user.dart';
import 'services/user_profiles/app_user_profile.dart';
import 'services/google_sheets_credentials/google_sheets_credential.dart';
import 'services/observations/local_observation.dart';
import 'model/local_observation_adapter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase/firebase_options.dart';

import 'services/observations/observation.dart';

Future<void> main() async {
  initMain();

  // The following pattern allows for any implementation of AuthenticationService, ObservationsService, and UserProfilesService
  // so long as the relevant interfaces are implemented.
  // By default, FirebaseAuthentication, FirebaseFirestore, FirebaseStorage and GoogleSheets are used.
  final authenticationService = await initAuthenticationService();
  final googleSheetsCredentialsService = await initGoogleSheetsCredentialsService();
  final observationsService = await initObservationsService();
  final userProfilesService = await initUserProfilesService();
  initObservationsApp(authenticationService, googleSheetsCredentialsService, observationsService, userProfilesService);
}

initMain() {
  //debugPrintGestureArenaDiagnostics = true;
}

Future<AuthenticationService> initAuthenticationService() async {
  //TODO - this needs to be a generic authenticator or authProvider so that we could switch out for another option if desired
  final firebaseAuthServiceReturnValue = await FirebaseAuthService.create(
      useEmulator: FirebaseProjectConfig.AUTHENTICATION_USE_EMULATOR,
      emulatorHostnameOrIpAddress: FirebaseProjectConfig.AUTHENTICATION_EMULATOR_IP,
      emulatorPort: FirebaseProjectConfig.AUTHENTICATION_EMULATOR_PORT,
      persistenceForWeb: FirebaseProjectConfig.AUTHENTICATION_WEB_PERSISTENCE
  );
  return firebaseAuthServiceReturnValue.value ?? FirebaseAuthService();
}

Future initGoogleSheetsCredentialsService() async {
  //TODO - this needs to be handled generically by a local database.init
  Hive.registerAdapter(GoogleSheetsCredentialAdapter());
  await Hive.openBox<GoogleSheetsCredential>(FirebaseGoogleSheetsCredentialCollection.COLLECTION_NAME);
}

Future<ObservationsService> initObservationsService() async {
  //TODO - this needs to be handled generically by a local database.init
  await Hive.initFlutter();

  //TODO - this needs to be handled generically by a local database.init
  Hive.registerAdapter(LocalObservationAdapter());
  await Hive.openBox<LocalObservation>(FirebaseObservationCollection.COLLECTION_NAME);

  await FirebaseService.initialize(DefaultFirebaseOptions.currentPlatform);

  //TODO - this needs to be a generic database service so that we could switch out for another option if desired
  final appFirebaseFirestoreService = AppFirebaseFirestoreService(
      bucket: FirebaseProjectConfig.STORAGE_BUCKET,
      useEmulator: FirebaseProjectConfig.FIRESTORE_USE_EMULATOR,
      emulatorHostnameOrIpAddress: FirebaseProjectConfig.FIRESTORE_EMULATOR_IP,
      emulatorPort: FirebaseProjectConfig.FIRESTORE_EMULATOR_PORT,
      persistenceEnabled: FirebaseProjectConfig.FIRESTORE_PERSISTENCE_ENABLED,
      sslEnabled: FirebaseProjectConfig.FIRESTORE_SSL_ENABLED
  );
}

Future<UserProfilesService> initUserProfilesService() async {

}
