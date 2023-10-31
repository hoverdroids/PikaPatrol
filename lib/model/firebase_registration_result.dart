import 'package:firebase_auth/firebase_auth.dart';
import 'app_user.dart';

class FirebaseRegistrationResult {
  AppUser? appUser;
  String? email;

  FirebaseAuthException? exception;

  FirebaseRegistrationResult({this.appUser, this.email, this.exception});
}