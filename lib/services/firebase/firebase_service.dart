import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:pika_patrol/services/emulatable_service.dart';

import '../../model/firebase_value_exception_pair.dart';

abstract class FirebaseService extends EmulatableService {

  static Future<FirebaseValueExceptionPair<bool>> initialize(FirebaseOptions? options) async {
    //https://codewithandrea.com/articles/flutter-firebase-flutterfire-cli/
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
          options: options
      );
      return FirebaseValueExceptionPair(true);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }

  FirebaseService({
    super.useEmulator = false,
    required super.emulatorHostnameOrIpAddress,
    required super.emulatorPort
  });
}