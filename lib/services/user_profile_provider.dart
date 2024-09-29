import 'package:pika_patrol/model/value_exception_pair.dart';

abstract class UserProfileProvider {
  Future<ValueExceptionPair> createUserProfile();
  Future<ValueExceptionPair> readObservation();
  Future<ValueExceptionPair> updateObservation();
  Future<ValueExceptionPair> deleteObservation();
}