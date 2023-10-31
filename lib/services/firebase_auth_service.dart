import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import '../model/firebase_registration_result.dart';
import 'firebase_database_service.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class FirebaseAuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  //TODO - use the User's info from the provider
  //UserInfo userInfo;

  AppUser? _userFromFirebaseUser(User? user) {
    return user != null ? AppUser(uid: user.uid) : null;
  }

  Stream<AppUser?> get user {
    return _auth.authStateChanges().map((User? user) => _userFromFirebaseUser(user));
  }

  Future signInAnonymously() async {
    try {
      UserCredential result = await _auth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e) {
      developer.log(e.toString());
      return null;
    }
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e) {
      developer.log("Failed to sign in user:$e");
      return null;
    }
  }

  Future<FirebaseRegistrationResult> registerWithEmailAndPassword(
      String email,
      String password,
      String firstName,
      String lastName,
      String tagline,
      String pronouns,
      String organization,
      String address,
      String city,
      String state,
      String zip,
      bool frppOptIn,
      bool rmwOptIn,
      bool dzOptIn
    ) async {

      final registrationResult = FirebaseRegistrationResult(email: email);

      try {
        UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        registrationResult.appUser = _userFromFirebaseUser(result.user);

      } on FirebaseAuthException catch(exception) {
        registrationResult.exception = exception;
      }
      return registrationResult;
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication? googleAuth = await googleUser
          ?.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      // Once signed in, return the UserCredential
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch(e) {
      return null;
    }
  }

  Future<FirebaseAuthException?> signOut() async {
    try {
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch(e) {
      developer.log(e.toString());
      return e;
    }
  }

  Future<FirebaseAuthException?> requestPasswordReset(String email) async {
    try {
      await _auth
        .sendPasswordResetEmail(email: email)
        .then((value) => {
        });
    } on FirebaseAuthException catch(e) {
      developer.log(e.toString());
      return e;
    }
    return null;
  }

  Future<FirebaseAuthException?> deleteUser() async {
      try {
        User? user = _auth.currentUser;
        await user?.delete();

        // Don't sign out before deleting user because the user must be signed into to delete themselves
        await signOut();

        // Old user data will remain cached and the user can't re-register with the same email - even if the email isn't in Firebase!
        await clearPersistedUserData();

        return null;
      } on FirebaseAuthException catch(e) {
        developer.log(e.toString());
        return e;
      }
  }


  //https://stackoverflow.com/questions/63930954/how-to-properly-call-firebasefirestore-instance-clearpersistence-in-flutter/64380036#64380036
  Future<FirebaseAuthException?> clearPersistedUserData() async {
    try {
      //await FirebaseFirestore.instance.terminate();//<-I'm hoping this isn't required as stated in the SO post, because it'll mean restarting Firestore :(
      await FirebaseFirestore.instance.clearPersistence();
      return null;
    } on FirebaseAuthException catch (e) {
      return e;
    }
  }
}
