// ignore_for_file: constant_identifier_names
import 'package:pika_patrol/services/pika_patrol_spreadsheet_service.dart';

class GoogleSheetsService {

  //Google Docs Read/Write limits
  //https://developers.google.com/docs/api/limits
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_PROJECT = 3000;
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 300;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_PROJECT = 600;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 60;

  List<PikaPatrolSpreadsheetService> pikaPatrolSpreadsheetServices = [];

  GoogleSheetsService(this.pikaPatrolSpreadsheetServices);
}