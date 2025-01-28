import 'package:gsheets/gsheets.dart';

class GSheetsValue<T> {
  T? value;
  GSheetsException? exception;

  GSheetsValue(this.value, {this.exception});

  GSheetsValue.e(this.exception);
}