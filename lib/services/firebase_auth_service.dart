import 'dart:io';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/firebase_registration_result.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

class FirebaseAuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final String _host;

  Stream<AppUser?> get user {
    return _auth.userChanges().asyncMap((User? user) => _userFromFirebaseUser(user));
  }

  // NOTE: Keeping here in case we need it again, but this value is retrieved with AppUser stream above
  // Use as value for Stream provider or by using:
  //        isAdminStream.listen((bool isAdmin) {
  //          var isReallyAdmin = isAdmin;
  //        });
  Stream<bool> get isAdmin {
    return _auth.idTokenChanges().asyncMap((User? user) => getIsAdmin(user));
  }

  bool useEmulators;

  //TODO - CHRIS - this should be a stream that admins can change
  FirebaseAuthService(this.useEmulators) {
    if (useEmulators) {
      _host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      _auth.useAuthEmulator(_host, 9099);
      // _auth.setPersistence(Persistence.NONE);
    }
  }

  Future<bool> getIsAdmin(User? user) async {
    var idTokenResult = await user?.getIdTokenResult();
    return idTokenResult?.claims?.containsKey("admin") == true;
  }

  Future<String?> getCurrentUserIdToken() async => await _auth.currentUser?.getIdToken();

  Future<String?>? getUserIdToken(User? user) => user?.getIdToken();

  Future<AppUser?> _userFromFirebaseUser(User? user) async {
    if (user == null) {
      return null;
    }

    var idToken = await getUserIdToken(user);
    var isAdmin = await getIsAdmin(user);

    return AppUser(
      uid: user.uid,
      displayName: user.displayName,
      email: user.email,
      emailVerified: user.emailVerified,
      isAnonymous: user.isAnonymous,
      creationTimestamp: user.metadata.creationTime,
      lastSignInTime: user.metadata.lastSignInTime,
      phoneNumber: user.phoneNumber,
      photoUrl: user.photoURL,
      tenantId: user.tenantId,
      isAdmin: isAdmin,
      idToken: idToken
    );
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
        registrationResult.appUser = await _userFromFirebaseUser(result.user);

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
      await clearPersistedUserData();
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

  Future<FirebaseAuthException?> changeCurrentUserEmail(String email) async {
    try {
      var trimmedEmail = email.trim();
      if (trimmedEmail.isNotEmpty) {
        await _auth.currentUser?.updateEmail(trimmedEmail);
      }
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }

  Future<FirebaseAuthException?> changeCurrentUserPassword(String password) async {
    if (password.contains("*")) {
      return FirebaseAuthException(code: "invalid-password");
    }
    try {
      var trimmedPassword = password.trim();
      if (trimmedPassword.isNotEmpty) {
        await _auth.currentUser?.updatePassword(password);
      }
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }

  Future<FirebaseAuthException?> changeCurrentUserDisplayName(String displayName) async {
    try {
      var trimmedDisplayName = displayName.trim();
      if (trimmedDisplayName.isNotEmpty) {
        await _auth.currentUser?.updateDisplayName(trimmedDisplayName);
      }
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }

  Future<FirebaseAuthException?> changeCurrentUserPhoneNumber(PhoneAuthCredential phoneAuthCredential) async {
    try {
      await _auth.currentUser?.updatePhoneNumber(phoneAuthCredential);
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }

  Future<FirebaseAuthException?> changeCurrentUser(String? photoUrl) async {
    try {
      await _auth.currentUser?.updatePhotoURL(photoUrl);
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
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