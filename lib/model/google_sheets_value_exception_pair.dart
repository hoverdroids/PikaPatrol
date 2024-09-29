import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/model/value_exception_pair.dart';

class GoogleSheetsValueExceptionPair<T> extends ValueExceptionPair<T, GSheetsException>{
  GoogleSheetsValueExceptionPair(super.value, {super.exception});
}