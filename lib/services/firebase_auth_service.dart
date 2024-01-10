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

  //TODO - use the User's info from the provider
  //UserInfo userInfo;

  Stream<AppUser?> get user {
    return _auth.userChanges().asyncMap((User? user) => _userFromFirebaseUser(user));
  }

  /*StreamSubscription<User?> get idToken {
    return _auth.idTokenChanges().listen((User? user) { return user;});
  }*/

      // .map((User? user) async => await _userIdTokenFromFirebaseUser(user))

  bool useEmulators;
  bool isAdmin = false;
  String? userTokenId;

  late Stream<bool> isAdminStream;

  /*late Stream<bool> isAdminStream = _auth.idTokenChanges().asyncMap((User? user) async {
    userTokenId = await user?.getIdToken();

    user?.getIdTokenResult().then((IdTokenResult? idTokenResult) {
      isAdmin = idTokenResult?.claims?.containsKey("admin") == true;

      //isAdminStreamController.add(isAdmin);
    });



    return await user?.getIdTokenResult().then((IdTokenResult? idTokenResult) {
      return true;
    };
  });*/

  //late StreamController<bool> isAdminStreamController;

  FirebaseAuthService(this.useEmulators) {
    if (useEmulators) {
      _host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      _auth.useAuthEmulator(_host, 9099);
      // _auth.setPersistence(Persistence.NONE);
    }

    initIsAdminStream();

    isAdminStream = _auth.idTokenChanges().asyncMap((User? user) => getIsAdminFromFirebase(user));
    isAdminStream.listen((bool isAdmin) {
      var isReallyAdmin = isAdmin;
    });


    /*isAdminStream = mapStreamBla(_auth.idTokenChanges());

    isAdminStream = _auth.idTokenChanges().map((User? user) async {
    userTokenId = await user?.getIdToken();

    user?.getIdTokenResult().then((IdTokenResult? idTokenResult) {
    isAdmin = idTokenResult?.claims?.containsKey("admin") == true;
    isAdminStreamController.add(isAdmin);
    });
    })*/


        /*_auth.idTokenChanges().map((User? user) async {
      await _updateUserTokenAndAdmin(user);

      return false;
    });*/

    /*_auth.idTokenChanges().listen((User? user) {
      _updateUserTokenAndAdmin(user);
    });*/
  }

  Future<bool> getIsAdminFromFirebase(User? user) async {
    userTokenId = await user?.getIdToken();

    var idTokenResult = await user?.getIdTokenResult();


    /*user?.getIdTokenResult().then((IdTokenResult? idTokenResult) {
      isAdmin = idTokenResult?.claims?.containsKey("admin") == true;

      //isAdminStreamController.add(isAdmin);
    });*/

    isAdmin = idTokenResult?.claims?.containsKey("admin") == true;
    return isAdmin;
  }

  /*Stream<bool> mapStreamBla(
      Stream<User?> stream,
      // S Function(T event) convert,
  ) async* {
    stream.map((User? user) async {
      userTokenId = await user?.getIdToken();

      user?.getIdTokenResult().then((IdTokenResult? idTokenResult) {
        isAdmin = idTokenResult?.claims?.containsKey("admin") == true;
        isAdminStreamController.add(isAdmin);
      });
    });


    *//*stream.map((User? user) async {
      await _updateUserTokenAndAdmin(user);

      return false;
    }

    stream.map((event) => null)
    var streamWithoutErrors = stream.handleError((e) => log(e));
    await for (final event in streamWithoutErrors) {
      yield true;//convert(event);
    }*//*
  }*/

  void initIsAdminStream() {

  }

  /*void _updateUserTokenAndAdmin(User? user) async {
    userTokenId = await user?.getIdToken();

    user?.getIdTokenResult().then((IdTokenResult? idTokenResult) {
      isAdmin = idTokenResult?.claims?.containsKey("admin") == true;
      isAdminStreamController.add(isAdmin);
    });
  }*/

  Future<String?> getCurrentUserIdToken() async => await _auth.currentUser?.getIdToken();

  Future<AppUser?> _userFromFirebaseUser(User? user) async {
    if (user == null) {
      return null;
    }

    var isAdmin = await getIsAdminFromFirebase(user);

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
      isAdmin: isAdmin
    );
  }

  Future<String?>? _userIdTokenFromFirebaseUser(User? user) {
    return user?.getIdToken();
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
