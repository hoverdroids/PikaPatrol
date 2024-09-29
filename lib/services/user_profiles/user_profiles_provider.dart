import 'package:pika_patrol/model/value_exception_pair.dart';

abstract class UserProfilesProvider {
  Future<ValueExceptionPair> createUserProfile();
  Future<ValueExceptionPair> readUserProfile();
  Future<ValueExceptionPair> updateUserProfile();
  Future<ValueExceptionPair> deleteUserProfile();
}