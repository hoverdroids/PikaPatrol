import 'package:pika_patrol/model/value_exception_pair.dart';

abstract class ObservationProvider {
  Future<ValueExceptionPair> createObservation();
  Future<ValueExceptionPair> readObservation();
  Future<ValueExceptionPair> updateObservation();
  Future<ValueExceptionPair> deleteObservation();
}