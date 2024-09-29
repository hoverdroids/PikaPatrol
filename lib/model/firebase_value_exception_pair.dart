import 'package:firebase_core/firebase_core.dart';
import 'package:pika_patrol/model/value_exception_pair.dart';

class FirebaseValueExceptionPair<T> extends ValueExceptionPair<T, FirebaseException> {
  FirebaseValueExceptionPair(super.value, {super.exception});
}