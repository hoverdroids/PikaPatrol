import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/services/google_sheets/worksheet_service.dart';

abstract class SpreadsheetService {

  late Spreadsheet spreadsheet;
  List<WorksheetService> worksheetServices = [];
  final String organization;

  SpreadsheetService(
    this.organization,
    String credentials,
    String spreadsheetId,
    bool doInitHeaderRow,
    {int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) {
    _init(credentials, spreadsheetId, doInitHeaderRow, columnHeadersRowNumber);
  }


  _init(String credentials, String spreadsheetId, bool doInitHeaderRow, int columnHeadersRowNumber) async {
    spreadsheet = await GSheets(credentials).spreadsheet(spreadsheetId);
    initWorksheetServices(doInitHeaderRow, columnHeadersRowNumber);
  }

  void initWorksheetServices(bool doInitHeaderRow, int columnHeadersRowNumber);
}