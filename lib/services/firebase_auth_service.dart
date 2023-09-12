import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
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

  Future registerWithEmailAndPassword(
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
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;

      await FirebaseDatabaseService(uid: user?.uid).updateUserProfile(
          firstName,
          lastName,
          tagline,
          pronouns,
          organization,
          address,
          city,
          state,
          zip,
          frppOptIn,
          rmwOptIn,
          dzOptIn
      );

      return _userFromFirebaseUser(user);
    } catch (e) {
      developer.log('Failed to create user:$e');
      return null;
    }
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

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch(e) {
      developer.log(e.toString());
      return null;
    }
  }

  Future deleteUser() async {
      try {
        User? user = _auth.currentUser;
        user?.delete();
      } catch(e) {
        developer.log(e.toString());
      }
  }
}
