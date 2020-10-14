import 'package:firebase_auth/firebase_auth.dart';
import 'package:pika_joe/model/user.dart';
import 'package:pika_joe/model/user_profile.dart';
import 'firebase_database_service.dart';

class FirebaeAuthService {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  //TODO - use the User's info from the provider 
  UserInfo userInfo;

  User _userFromFirebaseUser(FirebaseUser user) {
    return user != null ? User(uid: user.uid) : null;
  }

  Stream<User> get user {
    return _auth.onAuthStateChanged.map((FirebaseUser user) => _userFromFirebaseUser(user));
  }

  Future signInAnonomously() async {
    try {
      AuthResult result = await _auth.signInAnonymously();
      FirebaseUser user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      AuthResult result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      FirebaseUser user = result.user;
      return _userFromFirebaseUser(user);
    } catch(e) {
      print("Failed to sign in user:" + e.toString());
      return null;
    }
  }

  Future registerWithEmailAndPassword(
    String email,
    String password,
    UserProfile userProfile
  ) async {
    try {
      AuthResult result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      FirebaseUser user = result.user;

      await FirebaseDatabaseService(uid: user.uid).updateUserProfile(userProfile);
    } catch (e) {
      print('Failed to create user:' + e.toString());
      return null;
    }
  }

  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch(e) {
      print(e.toString());
      return null;
    }
  }
}