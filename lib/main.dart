// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pika_patrol/model/google_sheets_credential_adapter.dart';
import 'package:pika_patrol/services/firebase_google_sheets_database_service.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/services/google_sheets_service.dart';
import 'package:pika_patrol/services/pika_patrol_spreadsheet_service.dart';
import 'package:pika_patrol/services/settings_service.dart';
import 'package:pika_patrol/services/firebase_auth_service.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
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

const useEmulators = false;
const initSpreadsheets = false;

Future<void> main() async {

  //debugPrintGestureArenaDiagnostics = true;
  await Hive.initFlutter();
  Hive.registerAdapter(LocalObservationAdapter());
  await Hive.openBox<LocalObservation>(FirebaseObservationsService.OBSERVATIONS_COLLECTION_NAME);

  Hive.registerAdapter(GoogleSheetsCredentialAdapter());
  await Hive.openBox<GoogleSheetsCredential>(FirebaseGoogleSheetsDatabaseService.GOOGLE_SHEETS_COLLECTION_NAME);

  //https://codewithandrea.com/articles/flutter-firebase-flutterfire-cli/
  WidgetsFlutterBinding.ensureInitialized();

  //TODO - CHRIS - the following needs to come from Firebase
  var credentials = r''' 
  {
    "type": "service_account",
    "project_id": "pikajoe-97c5c",
    "private_key_id": "893d8476691eb166ca81eebfaaea2ddb6a78e9fb",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCjMe6TnRG+AvE6\nbEK+Vlchccb4QD5WpCMt8Vk+DFsslkvF+Bd+IxReHoi6PdiMX7kJDZl/+CExKTHq\nTtverDXF2kvjP+Q0Sj6VAjcnomNoKuEGmafOm09feGTyYroB75VJF72hELckrErs\nBYDOPPvTrjnye9hvrwh8jeFOCXkTh+tGCddZamToQAOk3r53B7xrlqTfCoWvZnKi\nlDK1ih3YNs7GAts82kcGxa3d1GkiINQsbRChy81HL1kiShQgGhpaN97M17vc1w49\nPnkpSK4/VMTPjxZeC/QAaxzZcCIZ4WULEzojg0LJkaxm2dXpsKpWuG3a0rfe1XPo\nfZZaE9BHAgMBAAECggEACgvgXoj8VyCyPgD9KN+C1KW+9Hhr/gRzv/fMISQ8lqWX\n+5N2ysaZEeQ6UZDOHHImH3cNXJHnZTHeh0icg3xBgTEbm91KjKeHa7/rqk52ZSrC\nmJfr+y2XeM6eFEfcoJLhs1K5U0mGpMTQhfAeylN5w0HGAnX6UIHLeXN4i8fMgtWx\ndPmTz8DksQyw907V6uhxDPSLPYInJKS05slWkEnhCgwvAfascZKXQV0zG4tsFTO9\nTI58VUiZoEolBRmOD1xiV1/vnFN9y3Ng5Bqp6p4rhVjWcOB5hIaZcnibQkBeOGYi\nr+TYligZdhmibr/wwEX6yRAT7/AIIG+CcyUaKLqzdQKBgQDe5k4ti7p0qWiSWDYR\nHZSA+F8iBn0z4iFbJeXoZ1cMjpoKFeJD/IR7LUw0Q97/9jZa3lHrXv7oJWJF9DLo\nZwEUE1aZA/ScguVUsZCmMJF8zMlPfMvZOMdIDePW+ZRqqmf13Ar1NTeZqb72JpNP\nL2l1jSn9Er7DQJbQT1RiTVPdVQKBgQC7bemd2nXBfAR2FxXtrM3gh2OI7x3Ckfuc\nU2O+KX7nilHsHVFkUJvLqXmy6lnxjibpmP5wsGtPfFzW0iyrzsU47Wz/FO3GXNIC\nKxm5YdnsuiDfBZwIIXxCClHc5qPAxxyY9yj6+f2jVmLn+T+L4q7SHZuzwUI9fuPw\nz3kia68XKwKBgQCBRR/h2j9wmS9EcFQq6PTPNzw1B35lMKgXrIsBla0uYyWC494t\nf611oneneBVEbQ5o9LadwqIjEEtGNrGvhs1hTzXR2DFs85z82V4Cg/hcYIf/yWiP\nuhYY+7U/X89rbRiNxee0/gAY5hERwJ1+Nwj6W7wWQWDQ7AyLEvbla+NPYQKBgAnV\nz69/2jQH/PfxaC4rpjYFBL0XxxkBrhFa8t30sXsW8AuS0kWQUUyTnRY9Y/DgA7y4\nUYm6SDdIkFqZdsyhMgo1s0WDZKLHFiIU/umSb+wTLExnr/NhRnL0ta0A0VD5Yc/J\nEHZzDdM3YkNH+gSuJXxTH2uEVaSCdxWY3YNn4S03AoGAewa1I1v5JcJdoFhy8Zu2\ntwmJPX34Bkg7IN8fo3A2HJgq9YK07fjdAJeJLTFrRETPugfcv2DB3S0zfvI5YjA2\nCLAxP+c3eOLz+Uyk5EKtpk6pT4ggQfm9+J1Xdcm8v4LCfFFP1xmEhDiVNbtZMKus\nKxEtBgJSv39bxqUQJ5lRuOo=\n-----END PRIVATE KEY-----\n",
    "client_email": "pika-patrol@pikajoe-97c5c.iam.gserviceaccount.com",
    "client_id": "102925647937041144152",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/pika-patrol%40pikajoe-97c5c.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }
  ''';

  var spreadsheetId = "1RXijstzfaWcl_xnHpF5iamS-lX-5FaTpcYoa9GsaX08";//TODO - CHRIS - this should be default and user should be allowed to change it

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
            create: (_) => FirebaseAuthService(useEmulators)//Only one service to avoid multiple connections to firebase
        ),
        Provider<FirebaseDatabaseService>(
            create: (_) => FirebaseDatabaseService(useEmulators)
        ),
        Provider<GoogleSheetsService>(
            create: (_) => GoogleSheetsService([PikaPatrolSpreadsheetService("Pika Patrol", credentials, spreadsheetId, initSpreadsheets)])
        ),
        ChangeNotifierProvider(
            create: (_) => SettingsService()
        ),
        ChangeNotifierProvider(
            create: (_) => Translations()
        )
      ],
      builder: (context, child) {
        //Using StreamBuilder here in order so that appUserSnapshot is the desired type
        //since it's used when building the other providers

        return StreamBuilder<AppUser?>(
          stream: Provider.of<FirebaseAuthService>(context).user,
          initialData: null,
          builder: (context, appUserSnapshot) {

            final AppUser? appUser = appUserSnapshot.hasData ? appUserSnapshot.data : null;

            var firebaseDatabaseService = Provider.of<FirebaseDatabaseService>(context);
            firebaseDatabaseService.uid = appUser?.uid;

            return StreamBuilder<AppUserProfile?>(
              stream: firebaseDatabaseService.userProfilesService.userProfile,
              initialData: null,
              builder: (context, appUserProfileSnapshot) {

                final AppUserProfile? appUserProfile = appUserProfileSnapshot.hasData ? appUserProfileSnapshot.data : null;

                //TODO - CHRIS - get the credentials from firebase
                // Initializing for all users so that user profile and observation data will be updated when the owner updates them, to decrease the need
                // for bulk exporting out of firebase.
                var googleSheetsService = Provider.of<GoogleSheetsService>(context, listen: false);

                return StreamBuilder<List<GoogleSheetsCredential>>(
                  stream: firebaseDatabaseService.googleSheetsService.credentials,
                  initialData: null,
                  builder: (context, googleSheetsCredentialsSnapshot) {

                    List<GoogleSheetsCredential> credentials = googleSheetsCredentialsSnapshot.hasData ? (googleSheetsCredentialsSnapshot.data ?? []) : [];

                    return MultiProvider(
                        providers: [
                          Provider<AppUser?>.value(
                              value: appUser
                          ),
                          Provider<AppUserProfile?>.value(
                              value: appUserProfile
                          ),
                          Provider<List<GoogleSheetsCredential>>.value(
                              value: credentials
                          )
                        ],
                        child: const MyApp()
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