// ignore_for_file: constant_identifier_names
import 'package:gsheets/gsheets.dart';
import 'dart:developer' as developer;

class WorksheetService {

  static const int DEFAULT_COLUMN_HEADER_ROW_NUMBER = 1;
  static const int UID_COLUMN_NUMBER = 1;
  static const String UID_COLUMN_TITLE = "uid";

  Worksheet? worksheet;
  List<String> columns;
  int columnHeadersRowNumber;

  WorksheetService(
    Spreadsheet spreadsheet,
    String worksheetTitle,
    this.columns,
    bool doInitHeaderRow,
    {this.columnHeadersRowNumber = DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) {
    _init(spreadsheet, worksheetTitle, columns, doInitHeaderRow, columnHeadersRowNumber);
  }

  _init(Spreadsheet spreadsheet, String worksheetTitle, List<String> columns, bool doInitHeaderRow, int columnHeadersRowNumber) async {
    try {
      worksheet = await getWorksheet(spreadsheet, worksheetTitle);
    } catch(e) {
      developer.log("Google Sheets init error in $worksheetTitle :$e");
    }

    if (doInitHeaderRow) {
      initHeaderRow();
    }
  }

  initHeaderRow() {
    try {
      worksheet?.values.insertRow(columnHeadersRowNumber, columns);
    } catch(e) {
      developer.log("Google Sheets init error in ${worksheet?.title} :$e");
    }
  }

  Future<Worksheet?> getWorksheet (Spreadsheet spreadsheet, String title) async {
    try {
      return await spreadsheet.addWorksheet(title);
    } catch (e) {
      return spreadsheet.worksheetByTitle(title)!;
    }
  }

  Future<int> getRowCount() async {
    var lastRow = await worksheet?.values.lastRow();
    return int.tryParse(lastRow?.first ?? "0") ?? 0;
  }

  Future insertRow(Map<String, dynamic> row) async {
    try {
      await worksheet?.values.map.appendRow(row);
    } catch (e) {
      developer.log("Insert error:$e");
    }
  }

  Future insertRows(List<Map<String, dynamic>> rowList) async {
    try {
      worksheet?.values.map.appendRows(rowList);
    } catch(e) {
      developer.log("Insert error:$e");
    }
  }

  Future<bool> updateRow(String uid, Map<String, dynamic> row) async {
    return await worksheet?.values.map.insertRowByKey(uid, row) ?? false;
  }

  Future<bool> updateValue(int id, String columnName, dynamic value) async {
    return await worksheet?.values.insertValueByKeys(value, columnKey: columnName, rowKey: id) ?? false;
  }

  Future<bool> deleteValue(int id) async {
    final index = await worksheet?.values.rowIndexOf(id);
    if (index == null || index == -1) return false;
    return await worksheet?.deleteRow(index) ?? false;
  }
}