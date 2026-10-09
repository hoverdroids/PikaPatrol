// ignore_for_file: constant_identifier_names
import 'dart:developer' as developer;
import 'package:pika_patrol/services/pika_patrol_spreadsheet_service.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';

import '../model/google_sheets_credential.dart';
import '../model/observation.dart';

class GoogleSheetsService {

  //Google Docs Read/Write limits
  //https://developers.google.com/docs/api/limits
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_PROJECT = 3000;
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 300;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_PROJECT = 600;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 60;

  static const int LESS_THAN_60_WRITES_DELAY_MS = 100;
  static const int MORE_THAN_60_WRITES_DELAY_MS = 500;
  static const int WRITE_THEN_TOAST_DELAY_MS = 1000;


  /// The master project: every observation goes to its sheet, and users never see it in the app
  static const String MASTER_PROJECT = "Pika Patrol";

  /// Every Collared pika observation also goes to this project's sheet, for provincial governments
  /// and land managers (Yukon partner via Jo, Oct 2025). Like the master project, users never see
  /// it in the app. It takes effect once an admin adds a spreadsheet under this name to the
  /// googleSheets credentials in Firestore.
  static const String COLLARED_PIKA_PROJECT = "Collared Pika";

  // The species is saved in the user's language, so match the Collared pika's name in every one
  static final Set<String> _collaredPikaNames = {
    for (var locale in L10n.ALL) lookupAppLocalizations(locale).collaredPika.trim().toLowerCase(),
  };

  static bool isCollaredPika(String? species) =>
      species != null && _collaredPikaNames.contains(species.trim().toLowerCase());

  /// The sheets an observation belongs in: the projects the user shared it with, the master sheet,
  /// and the Collared pika sheet for Collared pikas. Used by every save and by the admin export,
  /// so they always agree.
  static Set<String> projectsFor(Observation observation) => {
    ...?observation.sharedWithProjects,
    MASTER_PROJECT,
    if (isCollaredPika(observation.species)) COLLARED_PIKA_PROJECT,
  };

  List<PikaPatrolSpreadsheetService> pikaPatrolSpreadsheetServices = [];

  /// Only the master sheet holds user profiles (names and emails). Partner sheets get observations only.
  Iterable<PikaPatrolSpreadsheetService> get masterSpreadsheetServices {
    return pikaPatrolSpreadsheetServices.where((service) => service.organization == MASTER_PROJECT);
  }

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