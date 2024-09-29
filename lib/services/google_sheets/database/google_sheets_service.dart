// ignore_for_file: constant_identifier_names
import 'package:pika_patrol/services/google_sheets/pika_patrol_spreadsheet_service.dart';

class GoogleSheetsService {

  //Google Docs Read/Write limits
  //https://developers.google.com/docs/api/limits
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_PROJECT = 3000;
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 300;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_PROJECT = 600;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 60;

  static const int LESS_THAN_60_WRITES_DELAY_MS = 100;
  static const int MORE_THAN_60_WRITES_DELAY_MS = 2000;
  static const int WRITE_THEN_TOAST_DELAY_MS = 1000;


  List<PikaPatrolSpreadsheetService> pikaPatrolSpreadsheetServices = [];

  List<String> get organizations {
    return pikaPatrolSpreadsheetServices.map((service) => service.organization).nonNulls.toList();
  }

  GoogleSheetsService(this.pikaPatrolSpreadsheetServices);
}