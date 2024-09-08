import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/services/spreadsheet_service.dart';
import 'package:pika_patrol/services/user_profiles_worksheet_service.dart';
import 'observations_worksheet_service.dart';

class PikaPatrolSpreadsheetService extends SpreadsheetService {

  ObservationsWorksheetService? observationWorksheetService;
  UserProfilesWorksheetService? userProfilesWorksheetService;

  PikaPatrolSpreadsheetService(
    super.organization,
    super.credentials,
    super.spreadsheetId,
    super.doInitHeaderRow
  );

  @override
  void initWorksheetServices(Spreadsheet spreadsheet, bool doInitHeaderRow, int columnHeadersRowNumber) {
    userProfilesWorksheetService = UserProfilesWorksheetService(spreadsheet, doInitHeaderRow, columnHeadersRowNumber: columnHeadersRowNumber);
    worksheetServices.add(userProfilesWorksheetService!);

    observationWorksheetService = ObservationsWorksheetService(spreadsheet, doInitHeaderRow, columnHeadersRowNumber: columnHeadersRowNumber);
    worksheetServices.add(observationWorksheetService!);
  }
}