import 'package:pika_patrol/model/value_exception_pair.dart';

abstract class ObservationsProvider {
  Future<ValueExceptionPair> createObservation();
  Future<ValueExceptionPair> readObservation();
  Future<ValueExceptionPair> updateObservation();
  Future<ValueExceptionPair> deleteObservation();
}