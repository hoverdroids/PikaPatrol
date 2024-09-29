import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pika_patrol/services/firebase/firebase_constants.dart';
import 'package:pika_patrol/services/firebase/firebase_service.dart';
import '../../model/firebase_registration_result.dart';
import 'package:pika_patrol/model/app_user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;

import '../../model/firebase_value_exception_pair.dart';
import '../../utils/constants.dart';

class FirebaseAuthService extends FirebaseService {

  //region Constructors
  //Use this constructor when not using the emulator
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    super.useEmulator = false,
    super.emulatorHostnameOrIpAddress = Constants.LOCALHOST,
    super.emulatorPort = FirebaseConstants.EMULATOR_PORT_AUTHENTICATION
  }) : super() {
    _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

    if (Platform.isAndroid && emulatorHostnameOrIpAddress == Constants.LOCALHOST) {
      emulatorHostnameOrIpAddress = Constants.LOCALHOST_ANDROID;
    }
  }

  //Use this constructor when using the emulator
  static Future<FirebaseValueExceptionPair<FirebaseAuthService>> create({
    FirebaseAuth? firebaseAuth,
    bool useEmulator = false,
    String emulatorHostnameOrIpAddress = Constants.LOCALHOST,
    int emulatorPort = FirebaseConstants.EMULATOR_PORT_AUTHENTICATION,
    Persistence? persistenceForWeb
  }) async {

    final service = FirebaseAuthService(firebaseAuth: firebaseAuth, useEmulator: useEmulator, emulatorHostnameOrIpAddress: emulatorHostnameOrIpAddress, emulatorPort: emulatorPort);

    final emulatorReturnValue = await service.applyEmulatorSettings();
    final settingsReturnValue = await service.applySettings();
    final persistenceReturnValue = await service.setPersistenceForWeb(persistence: persistenceForWeb);

    return FirebaseValueExceptionPair(service, exception: emulatorReturnValue.exception ?? settingsReturnValue.exception ?? persistenceReturnValue.exception);
  }
  //endregion

  //region FirebaseAut
  late FirebaseAuth _firebaseAuth;
  //endregion

  //region Admin
  // NOTE: Keeping here in case we need it again, but this value is retrieved with AppUser stream above
  // Use as value for Stream provider or by using:
  //        isAdminStream.listen((bool isAdmin) {
  //          var isReallyAdmin = isAdmin;
  //        });
  Stream<bool> get isAdminStream {
    return _firebaseAuth.idTokenChanges().asyncMap((User? user) => await user.isAdmin().value);
  }


  //endregion

  //region User ID Token
  Future<String?> getCurrentUserIdToken() async => await _firebaseAuth.currentUser?.getIdToken();
  //endregion

  //region User
  Stream<AppUser?> get user {
    return _firebaseAuth.userChanges().asyncMap((User? user) => _userFromFirebaseUser(user));
  }

  Future<FirebaseAuthException?> changeCurrentUser(String? photoUrl) async {
    try {
      await _firebaseAuth.currentUser?.updatePhotoURL(photoUrl);
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }

  Future<FirebaseAuthException?> deleteUser() async {
    try {
      User? user = _firebaseAuth.currentUser;
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

  Future<AppUser?> _tryConvertUserToAppUser(User? user, {bool forceRefresh = false}) async {
    final isAdmin = await user.isAdmin();
    final isAdminValue = isAdmin.value ?? false;
    final idToken = await user.idToken(forceRefresh: forceRefresh);
    return user.toAppUser(isAdminValue, idToken.value);
  }

  //endregion

  //region Register
  Future<FirebaseRegistrationResult> registerWithEmailAndPassword(String email, String password) async {

    final registrationResult = FirebaseRegistrationResult(email: email);

    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      registrationResult.appUser = await _userFromFirebaseUser(result.user);

    } on FirebaseAuthException catch(exception) {
      registrationResult.exception = exception;
    }
    return registrationResult;
  }
  //endregion

  //region Sign-in
  Future signInAnonymously() async {
    try {
      UserCredential result = await _firebaseAuth.signInAnonymously();
      User? user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e) {
      developer.log(e.toString());
      return null;
    }
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
      return _tryConvertUserToAppUser(result.user);
    } catch(e) {
      developer.log("Failed to sign in user:$e");
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
  //endregion

  //region Sign-out
  Future<FirebaseAuthException?> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await clearPersistedUserData();
      return null;
    } on FirebaseAuthException catch(e) {
      developer.log(e.toString());
      return e;
    }
  }
  //endregion

  //region Password
  Future<FirebaseAuthException?> requestPasswordReset(String email) async {
    try {
      await _firebaseAuth
        .sendPasswordResetEmail(email: email)
        .then((value) => {
        });
    } on FirebaseAuthException catch(e) {
      developer.log(e.toString());
      return e;
    }
    return null;
  }

  Future<FirebaseAuthException?> changeCurrentUserPassword(String password) async {
    if (password.contains("*")) {
      return FirebaseAuthException(code: "invalid-password");
    }
    try {
      var trimmedPassword = password.trim();
      if (trimmedPassword.isNotEmpty) {
        await _firebaseAuth.currentUser?.updatePassword(password);
      }
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }
  //endregion

  //region Email
  Future<FirebaseAuthException?> changeCurrentUserEmail(String email) async {
    try {
      var trimmedEmail = email.trim();
      if (trimmedEmail.isNotEmpty) {
        await _firebaseAuth.currentUser?.updateEmail(trimmedEmail);
      }
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }
  //endregion

  //region Display Name
  Future<FirebaseAuthException?> changeCurrentUserDisplayName(String displayName) async {
    try {
      var trimmedDisplayName = displayName.trim();
      if (trimmedDisplayName.isNotEmpty) {
        await _firebaseAuth.currentUser?.updateDisplayName(trimmedDisplayName);
      }
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }
  //endregion

  //region Phone
  Future<FirebaseAuthException?> changeCurrentUserPhoneNumber(PhoneAuthCredential phoneAuthCredential) async {
    try {
      await _firebaseAuth.currentUser?.updatePhoneNumber(phoneAuthCredential);
      return null;
    } on FirebaseAuthException catch(e) {
      return e;
    }
  }
  //endregion

  //region Emulator
  //Emulator selection/settings/modifications must be called immediately, prior to accessing FirebaseFirestore or FirebaseAuth methods.
  //To comply, only allow settings to be applied once, after instantiation
  bool _hasAppliedEmulatorSettings = false;

  Future<FirebaseValueExceptionPair<bool>> applyEmulatorSettings() async {
    final returnValue = FirebaseValueExceptionPair(false);

    if (super.useEmulator && !_hasAppliedEmulatorSettings) {
      try {
        await _firebaseAuth.useAuthEmulator(emulatorHostnameOrIpAddress, emulatorPort);
        returnValue.value = true;
      } on FirebaseException catch (e) {
        returnValue.exception = e;
      }
    }

    _hasAppliedEmulatorSettings = true;
    return returnValue;
  }
  //endregion

  //region Persistence
  //There are no persistence options except for web
  Future<FirebaseValueExceptionPair<bool>> setPersistenceForWeb({Persistence? persistence}) async {
    if (kIsWeb && persistence != null) {//This doesn't check canModifySettings as the following settings can apparently be set as desired
      try {
        await _firebaseAuth.setPersistence(persistence);
        return FirebaseValueExceptionPair(true);
      } on FirebaseException catch(e) {
        return FirebaseValueExceptionPair(false, exception: e);
      }
    }
    return FirebaseValueExceptionPair(false);
  }
  //endregion

  //region Settings
  bool appVerificationDisabledForTesting = false;
  String? userAccessGroup;
  String? phoneNumber;
  String? smsCode;
  bool? forceRecaptchaFlow;

  Future<FirebaseValueExceptionPair<bool>> applySettings() async {
    //This doesn't check canModifySettings as the following settings can apparently be set as desired
    try {
      await _firebaseAuth.setSettings(
        appVerificationDisabledForTesting: appVerificationDisabledForTesting,
        userAccessGroup: userAccessGroup,
        phoneNumber: phoneNumber,
        smsCode: smsCode,
        forceRecaptchaFlow: forceRecaptchaFlow
      );
      return FirebaseValueExceptionPair(true);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }
  //endregion
}

extension FirebaseAuthNullExtensions on User? {

  AppUser? toAppUser(bool isAdmin, String? idToken) {
    final user = this;
    if (user == null) {
      return null;
    }

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

  Future<FirebaseValueExceptionPair<bool>> isAdmin() async {
    try {
      final idTokenResult = await this?.getIdTokenResult();
      final returnValue = idTokenResult?.claims?.containsKey("admin") == true;
      return FirebaseValueExceptionPair(returnValue);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }

  Future<FirebaseValueExceptionPair<String>> idToken({bool forceRefresh = false}) async {
    try {
      final returnValue = await this?.getIdToken(forceRefresh);
      return FirebaseValueExceptionPair(returnValue);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(null, exception: e);
    }
  }
}