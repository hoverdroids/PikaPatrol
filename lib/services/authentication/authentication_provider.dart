import 'package:pika_patrol/services/emulatable_service.dart';

import 'app_user.dart';
import '../../model/value_exception_pair.dart';

abstract interface class AuthenticationProvider<E> implements EmulatableService {

  //TODO - should this implement EmulatableService or leave that up to the caller since
  //it's likely that some auth providers do not have emulators

  Future<ValueExceptionPair<AppUser, E>> registerWithEmailAndPassword(String email, String password);
  Future requestPasswordReset(String email);

  Future signInAnonymously();
  Future signInWithEmailAndPassword(String email, String password);
  Future signInWithGoogle();
  Future signInWithApple();
  Future signOut();

  Future<ValueExceptionPair<String, E>> getCurrentUserIdToken();
  Stream<bool> get isAdminStream;
  Stream<AppUser?> get appUserStream;

  Future changeCurrentUserDisplayName(String displayName);
  Future changeCurrentUserPassword(String password);
  Future changeCurrentUserEmail(String email);
  Future changeCurrentUserPhoneNumber(String phoneNumber);
  Future<ValueExceptionPair<bool, E>> updateCurrentUserPhotoUrl(String? photoUrl);

  Future<ValueExceptionPair<bool, E>> deleteUser();
}