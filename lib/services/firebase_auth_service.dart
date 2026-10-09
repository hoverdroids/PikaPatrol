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

  // OAuth client IDs from google-services.json (web client) and GoogleService-Info.plist (iOS client).
  // These are public identifiers, not secrets.
  static const String _googleWebClientId = "954700599379-ufpa7kr9jvqfvk5ael476cp6dbffmc8b.apps.googleusercontent.com";
  static const String _googleIosClientId = "954700599379-qp2i96hjt2shcf3hmkoa8dvrb3nvpmp7.apps.googleusercontent.com";
  bool _isGoogleSignInInitialized = false;

  Future<void> _initializeGoogleSignIn() async {
    if (_isGoogleSignInInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: Platform.isIOS ? _googleIosClientId : null,
      serverClientId: _googleWebClientId,
    );
    _isGoogleSignInInitialized = true;
  }

  Future<AuthCredential> _getGoogleCredential() async {
    await _initializeGoogleSignIn();
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
    // Firebase only needs the ID token from the Google account
    return GoogleAuthProvider.credential(idToken: googleUser.authentication.idToken);
  }

  AppleAuthProvider get _appleProvider => AppleAuthProvider()
    ..addScope('email')
    ..addScope('name');

  /// Returns the signed-in credential, or null if the user cancelled. Throws on other errors.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      return await _auth.signInWithCredential(await _getGoogleCredential());
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// Returns the signed-in credential, or null if the user cancelled. Throws on other errors.
  /// Apple sign-in is offered on iOS only, where Apple requires it alongside Google sign-in.
  Future<UserCredential?> signInWithApple() async {
    try {
      return await _auth.signInWithProvider(_appleProvider);
    } on FirebaseAuthException catch (e) {
      if (e.code == "canceled" || e.code == "web-context-canceled") return null;
      rethrow;
    }
  }

  /// The sign-in methods on the current account, e.g. "password", "google.com", "apple.com"
  List<String> get currentUserProviderIds {
    return _auth.currentUser?.providerData.map((info) => info.providerId).toList() ?? <String>[];
  }

  /// Firebase only deletes an account after a recent sign-in, so confirm it again first.
  /// Uses the password for email accounts, or the Google/Apple sign-in sheet otherwise.
  Future<Object?> reauthenticateCurrentUser({String? password}) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        return FirebaseAuthException(code: "no-current-user");
      }
      final providers = currentUserProviderIds;
      if (providers.contains("password")) {
        final email = user.email;
        if (email == null || password == null) {
          return FirebaseAuthException(code: "missing-password");
        }
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(email: email, password: password));
      } else if (providers.contains("google.com")) {
        await user.reauthenticateWithCredential(await _getGoogleCredential());
      } else if (providers.contains("apple.com")) {
        await user.reauthenticateWithProvider(_appleProvider);
      }
      return null;
    } catch (e) {
      return e;
    }
  }

  Future<FirebaseAuthException?> signOut() async {
    try {
      if (currentUserProviderIds.contains("google.com")) {
        // Otherwise Google silently signs the same account back in next time
        await _initializeGoogleSignIn();
        await GoogleSignIn.instance.signOut();
      }
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
        // Firebase sends a verification link to the new address; the email changes once it's clicked
        await _auth.currentUser?.verifyBeforeUpdateEmail(trimmedEmail);
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