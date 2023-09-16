// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pika_patrol/services/firebase_auth_service.dart';
import 'package:pika_patrol/services/firebase_database_service.dart';
import 'package:pika_patrol/widgets/my_app.dart';
import 'package:provider/provider.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'model/app_user.dart';
import 'model/app_user_profile.dart';
import 'model/local_observation.dart';
import 'model/local_observation_adapter.dart';
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
      // Globally useful providers that don't depend on other provider values or build context
      providers: [
        ChangeNotifierProvider(
            create: (_) => MaterialThemesManager()
        ),
        Provider<FirebaseAuthService>(
            create: (_) => FirebaseAuthService()//Only one service to avoid multiple connections to firebase
        )
      ],
      builder: (context, child) {

        final firebaseAuthService = Provider.of<FirebaseAuthService>(context);//, listen: false TODO - CHRIS - in order to avoid rebuilding the entire view tree

        return StreamBuilder<AppUser?>(
          stream: firebaseAuthService.user,
          initialData: null,
          builder: (context, appUserSnapshot) {

            final AppUser? appUser = appUserSnapshot.data;

            return MultiProvider(
              // Globally useful providers that don't depend on app user
              providers: [
                Provider<AppUser?>.value(value: appUser),//TODO - CHRIS - does this need to be a stream?
                Provider<FirebaseDatabaseService>(
                  create: (_) => FirebaseDatabaseService(uid: appUser?.uid)
                )
              ],
              builder: (context, child) {
                return StreamProvider<AppUserProfile?>.value(
                    value: Provider.of<FirebaseDatabaseService>(context).userProfile,
                    initialData: null,
                    child: const MyApp()
                );
              }
            );
          }
        );
      },
    ),
  );
}