// ignore_for_file: constant_identifier_names
import 'package:gsheets/gsheets.dart';
import 'dart:developer' as developer;

class WorksheetService {

  static const int DEFAULT_COLUMN_HEADER_ROW_NUMBER = 1;
  static const int UID_COLUMN_NUMBER = 1;
  static const String UID_COLUMN_TITLE = "uid";

  Worksheet? worksheet;

  WorksheetService(
    Spreadsheet spreadsheet,
    String worksheetTitle,
    List<String> columns,
    bool doInitHeaderRow,
    {int columnHeadersRowNumber = DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) {
    _init(spreadsheet, worksheetTitle, columns, doInitHeaderRow, columnHeadersRowNumber);
  }

  _init(Spreadsheet spreadsheet, String worksheetTitle, List<String> columns, bool doInitHeaderRow, int columnHeadersRowNumber) async {
    try {
      worksheet = await getWorksheet(spreadsheet, worksheetTitle);

      if (doInitHeaderRow) {
        worksheet?.values.insertRow(columnHeadersRowNumber, columns);
      }
    } catch(e) {
      developer.log("Google Sheets init error in $worksheetTitle :$e");
    }
  }

  Future<Worksheet?> getWorksheet (Spreadsheet spreadsheet, String title) async {
    try {
      return await spreadsheet.addWorksheet(title);
    } catch (e) {
      return spreadsheet.worksheetByTitle(title)!;
    }
  }
}