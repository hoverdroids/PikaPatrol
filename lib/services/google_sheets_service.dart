// ignore_for_file: constant_identifier_names
import 'dart:developer' as developer;
import 'package:pika_patrol/services/pika_patrol_spreadsheet_service.dart';

import '../model/google_sheets_credential.dart';

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

  GoogleSheetsService();

  void updateSpreadsheetServices(List<GoogleSheetsCredential> googleSheetsCredentials) {
    if (googleSheetsCredentials.isEmpty){
      //Account for the user signing out
      pikaPatrolSpreadsheetServices = [];
      return;
    }

    // Account for credentials being added dynamically, while also avoiding instantiating the same service multiple times as that causes more calls to the service than necessary
    for (var credential in googleSheetsCredentials) {
      credential.spreadsheets.forEach((projectName, spreadsheetId) {
        if (!pikaPatrolSpreadsheetServices.any((service) => service.spreadsheetId == spreadsheetId)) {
          developer.log("Adding service for projectName:$projectName spreadsheetId: $spreadsheetId");
          var service = PikaPatrolSpreadsheetService(projectName, credential.credential, spreadsheetId, false);
          pikaPatrolSpreadsheetServices.add(service);
        } else {
          developer.log("Service already exists for projectName:$projectName spreadsheetId: $spreadsheetId");
        }
      });
    }

    //Account for credentials being removed dynamically
    //TODO pikaPatrolSpreadsheetServices.removeWhere((service) => !googleSheetsCredentials.any((credential) => credential.spreadsheets.containsValue(service.spreadsheetId)));
  }

}