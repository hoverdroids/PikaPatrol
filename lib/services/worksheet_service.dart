// ignore_for_file: constant_identifier_names
import 'package:gsheets/gsheets.dart';
import 'dart:developer' as developer;

import 'package:pika_patrol/model/gsheets_value.dart';

class WorksheetService {

  static const int DEFAULT_COLUMN_HEADER_ROW_NUMBER = 1;
  static const int UID_COLUMN_NUMBER = 1;
  static const String UID_COLUMN_TITLE = "uid";
  static const int KEY_IS_NOT_FOUND = -1;

  static const String ROW_COUNT = "worksheet.rowCount";
  static const String ROW_COUNT_FROM_ALL_ROWS = "worksheet.values.allRows().length";
  static const String ROW_COUNT_FROM_ALL_ROWS_MAP = "worksheet.values.map.allRows().length";
  static const String ROW_COUNT_FROM_LAST_NON_EMPTY_ROW = "worksheet.values.lastRow().first as int";

  //GSheets v4 ValueRenderOption enum doesn't set the values to these strings
  static const String VALUE_RENDER_OPTION_FORMATTED_VALUE = "FORMATTED_VALUE";
  static const String VALUE_RENDER_OPTION_FORMULA = "FORMULA";
  static const String VALUE_RENDER_OPTION_UNFORMATTED_VALUE = "UNFORMATTED_VALUE";

  //GSheets v4 ValueInput enum doesn't set the values to these strings
  static const String VALUE_INPUT_OPTION_USER_ENTERED = "USER_ENTERED";
  static const String VALUE_INPUT_OPTION_RAW = "RAW";

  //GSheets v4 ExportFormat enum doesn't set the values to these strings
  static const String EXPORT_FORMAT_XLXS = "xlsx";
  static const String EXPORT_FORMAT_PDF = "pdf";
  static const String EXPORT_FORMAT_CSV = "csv";

  Worksheet? worksheet;
  List<String> columns;
  int columnHeadersRowNumber;

  WorksheetService(
      Spreadsheet spreadsheet,
      String worksheetTitle,
      this.columns,
      bool doInitHeaderRow,
      {
        this.columnHeadersRowNumber = DEFAULT_COLUMN_HEADER_ROW_NUMBER
      }
      ) {
    _init(spreadsheet, worksheetTitle, columns, doInitHeaderRow, columnHeadersRowNumber);
  }

  //#region Init
  _init(Spreadsheet spreadsheet, String worksheetTitle, List<String> columns, bool doInitHeaderRow, int columnHeadersRowNumber) async {

    final returnValue = await getWorksheet(spreadsheet, worksheetTitle);

    if (returnValue.exception != null) {
      developer.log("Google Sheets init error in $worksheetTitle :${returnValue.exception}");
    } else if (doInitHeaderRow) {

      worksheet = returnValue.value;

      final returnValue2 = await initHeaderRow();
      if (returnValue2.exception != null) {
        developer.log("Google sheets initHeaderRow error in $worksheetTitle :${returnValue2.exception}");
      }
    }
  }

  Future<GSheetsValue<bool>> initHeaderRow() async {

    try {
      final returnValue = await worksheet?.values.insertRow(columnHeadersRowNumber, columns) ?? false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion

  //#region Worksheet
  Future<GSheetsValue<Worksheet>> getWorksheet (Spreadsheet spreadsheet, String title) async {
    try {
      final returnValue = await spreadsheet.addWorksheet(title);
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      final returnValue = spreadsheet.worksheetByTitle(title);
      return GSheetsValue(returnValue, exception: e);
    }
  }
  //#endregion

  //#region Render Options
  /*Future<GSheetsValue<ValueRenderOption>> getRenderOption() async {
    try {
      final sheet = worksheet;
      final returnValue = sheet != null ? sheet.renderOption : "";
      switch (returnValue) {
        case GSheets.ValueRenderOption.formattedValue:
          break;
        default:
          break;
      }
    } on GSheetsException catch(e) {
      return GSheetsValue(null, exception: e);
    }
  }*/
  //#endregion
  /* bla() {
    final currentCountOfAvailableRows = worksheet?.rowCount;
    worksheet.columnCount;
    worksheet.values.allRows();
    worksheet.values.allColumns();
    worksheet.title;
    worksheet.spreadsheetId;
    worksheet.
  }*/

  //#region Row(s): Get Index
  Future<GSheetsValue<int>> getRowIndexWithUid(String? uid, {int inColumn = UID_COLUMN_NUMBER}) async {
    return await getRowIndexOfKeyInColumn(uid, inColumn: inColumn);
  }

  Future<GSheetsValue<int>> getRowIndexOfKeyInColumn(Object? key, {int inColumn = UID_COLUMN_NUMBER}) async {
    try {
      final sheet = worksheet;
      final index = key != null && sheet != null ? await sheet.values.rowIndexOf(key, inColumn: inColumn) : KEY_IS_NOT_FOUND;
      return GSheetsValue(index);
    } on GSheetsException catch(e) {
      return GSheetsValue(KEY_IS_NOT_FOUND, exception: e);
    }
  }
  //#endregion

  //#region Row(s): Get
  Future<GSheetsValue<Map<String, String>>> getRowByUid(
      String uid,
      {
        int fromColumn = WorksheetService.UID_COLUMN_NUMBER,
        int length = -1,
        dynamic mapTo,
      }
      ) async {
    return await getRowByKey(uid, fromColumn: fromColumn, length: length, mapTo: mapTo);
  }

  Future<GSheetsValue<Map<String, String>>> getRowByKey(
      Object key,
      {
        int fromColumn = WorksheetService.UID_COLUMN_NUMBER,
        int length = -1,
        dynamic mapTo,
      }
      ) async {
    try {
      final row = await worksheet?.values.map.rowByKey(key, fromColumn: fromColumn, length: length, mapTo: mapTo);
      return GSheetsValue(row);
    } on GSheetsException catch (e) {
      return GSheetsValue(null, exception: e);
    }
  }

  Future<GSheetsValue<List<Map<String, String>>>> getAllRows() async => await getRows();

  Future<GSheetsValue<List<Map<String, String>>>> getRows(
      {
        int fromRow = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER,
        int fromColumn = WorksheetService.UID_COLUMN_NUMBER,
        int length = -1,
        int count = -1,
        int mapTo = 1
      }
      ) async {
    try {
      final rows = await worksheet?.values.map.allRows(fromRow: fromRow, fromColumn: fromColumn, length: length, count: count, mapTo: mapTo);
      return GSheetsValue(rows);
    } on GSheetsException catch (e) {
      return GSheetsValue(null, exception: e);
    }
  }

  Future<GSheetsValue<Map<String, String>>> getRow(
      int index, {
        int fromColumn = WorksheetService.UID_COLUMN_NUMBER,
        int length = -1,
        int mapTo = 1,
      }
      ) async {
    try {
      final row = await worksheet?.values.map.row(index, fromColumn: fromColumn, length: length, mapTo: mapTo);
      return GSheetsValue(row);
    } on GSheetsException catch (e) {
      return GSheetsValue(null, exception: e);
    }
  }
  //#endregion

  //#region Row(s): Count
  Future<GSheetsValue<int>> getNumberOfRowsInSheet({bool includeEmptyRowsInCount = false}) async {
    final returnValue = await getAllRowCounts();
    final value = returnValue.value;

    if (returnValue.exception != null) {
      return GSheetsValue(0, exception: returnValue.exception);
    }
    if (value == null) {
      return GSheetsValue(0);
    }
    return GSheetsValue(value[includeEmptyRowsInCount ? ROW_COUNT : ROW_COUNT_FROM_LAST_NON_EMPTY_ROW]);
  }

  // It returns total number of rows, even the ones that have no data
  int getRowCount() {
    return worksheet?.rowCount ?? 0;
  }

  Future<GSheetsValue<int>> getRowCountFromAllRows() async {
    try {
      var allRows = await worksheet?.values.allRows();
      var value = allRows?.length ?? 0;
      return GSheetsValue(value);
    } on GSheetsException catch(e) {
      return GSheetsValue(0, exception: e);
    }
  }

  Future<GSheetsValue<int>> getRowCountFromAllRowsMap() async {
    try {
      var allRows = await worksheet?.values.map.allRows();
      var value = allRows?.length ?? 0;
      return GSheetsValue(value);
    } on GSheetsException catch(e) {
      return GSheetsValue(0, exception: e);
    }
  }

  Future<GSheetsValue<int>> getRowCountFromLastNonEmptyRow() async {
    try {
      var lastRow = await worksheet?.values.lastRow();
      var hasRows = lastRow != null;
      var returnValue = hasRows ? int.parse(lastRow.first) : 0;
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      return GSheetsValue(KEY_IS_NOT_FOUND, exception: e);
    } on FormatException catch(e) {
      return GSheetsValue(0);
    }
  }

  Future<GSheetsValue<Map<String, int>>> getAllRowCounts() async {
    final Map<String, int> rowCounts = {
      ROW_COUNT : 0,
      ROW_COUNT_FROM_ALL_ROWS : 0,
      ROW_COUNT_FROM_ALL_ROWS_MAP : 0,
      ROW_COUNT_FROM_LAST_NON_EMPTY_ROW : 0
    };

    rowCounts[ROW_COUNT] = getRowCount();

    var returnValue = await getRowCountFromAllRows();
    var value = returnValue.value;
    if (returnValue.exception != null) {
      return GSheetsValue(rowCounts, exception: returnValue.exception);
    }
    rowCounts[ROW_COUNT_FROM_ALL_ROWS] = value ?? 0;

    returnValue = await getRowCountFromAllRowsMap();
    value = returnValue.value;
    if (returnValue.exception != null) {
      return GSheetsValue(rowCounts, exception: returnValue.exception);
    }
    rowCounts[ROW_COUNT_FROM_ALL_ROWS_MAP] = value ?? 0;

    returnValue = await getRowCountFromLastNonEmptyRow();
    value = returnValue.value;
    if (returnValue.exception != null) {
      return GSheetsValue(rowCounts, exception: returnValue.exception);
    }
    rowCounts[ROW_COUNT_FROM_LAST_NON_EMPTY_ROW] = value ?? 0;

    return GSheetsValue(rowCounts);
  }
  //#endregion

  //#region Row(s): Insert
  Future<GSheetsValue<bool>> insertRowAbove(int index, { bool inheritFromBefore = false}) async {
    return await insertRowsAbove(index, count: 1, inheritFromBefore: inheritFromBefore);
  }

  Future<GSheetsValue<bool>> insertRowBelow(int index, { bool inheritFromBefore = false}) async {
    return await insertRowsBelow(index, count: 1, inheritFromBefore: inheritFromBefore);
  }

  //This is the same a insertRows, but I think the name is clearer
  Future<GSheetsValue<bool>> insertRowsAbove(
      int index,
      {
        int count = 1,
        bool inheritFromBefore = false
      }
      ) async {
    return await insertRows(index, count: count, inheritFromBefore: inheritFromBefore);
  }

  Future<GSheetsValue<bool>> insertRowsBelow(
      int index,
      {
        int count = 1,
        bool inheritFromBefore = false
      }
      ) async {
    return await insertRows(index + 1, count: count, inheritFromBefore: inheritFromBefore);
  }

  Future<GSheetsValue<bool>> insertRows(
      int index,
      {
        int count = 1,
        bool inheritFromBefore = false
      }
      ) async {
    try {
      final returnValue = await worksheet?.insertRow(index, count: count, inheritFromBefore: inheritFromBefore);
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion

  //#region Row(s): AddOrUpdate
  Future<GSheetsValue<bool>> addOrUpdateRowByUid(
      String? uid,
      Map<String, dynamic> row,
      {
        int uidInColumn = UID_COLUMN_NUMBER,
        int fromColumn = UID_COLUMN_NUMBER,
        int mapTo = 1,
        bool appendMissing = false,
        bool inRange = false,
        bool overwrite = false
      }
      ) async {
    final returnValue = await getRowIndexWithUid(uid, inColumn: uidInColumn);
    final value = returnValue.value;
    if (returnValue.exception != null){
      return GSheetsValue(false, exception: returnValue.exception);
    }
    return await addOrUpdateRow(value, row, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, inRange: inRange, overwrite: overwrite);
  }

  Future<GSheetsValue<bool>> addOrUpdateRow(
      int? index,
      Map<String, dynamic> row,
      {
        int fromColumn = UID_COLUMN_NUMBER,
        int mapTo = 1,
        bool appendMissing = false,
        bool inRange = false,
        bool overwrite = false
      }
      ) async {
    if (index == null || index == KEY_IS_NOT_FOUND) {
      return await appendRow(row, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, inRange: inRange);
    } else {
      return await updateRow(index, row, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite);
    }
  }
  //#endregion

  //#region Row(s): Append
  Future<GSheetsValue<bool>> appendRow(
      Map<String, dynamic> row,
      {
        int fromColumn = UID_COLUMN_NUMBER,
        int mapTo = 1,
        bool appendMissing = false,
        bool inRange = false
      }
      ) async {
    try {
      final returnValue = await worksheet?.values.map.appendRow(row, mapTo: mapTo, appendMissing: appendMissing, inRange: inRange) ?? false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      return GSheetsValue(false, exception: e);
    }
  }

  Future<GSheetsValue<bool>> appendRows(
      List<Map<String, dynamic>> rows,
      {
        int fromColumn = UID_COLUMN_NUMBER,
        int mapTo = 1,
        bool appendMissing = false,
        bool inRange = false
      }
      ) async {
    try {
      final returnValue = await worksheet?.values.map.appendRows(rows, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, inRange: inRange) ?? false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion

  //#region Row(s): Update
  Future<GSheetsValue<bool>> updateRow(
      int? index,
      Map<String, dynamic> rowValuesByColumn,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesByColumn contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false
      }
      ) async {
    try {
      final sheet = worksheet;
      final returnValue = index != null && index != KEY_IS_NOT_FOUND && sheet != null
          ? await sheet.values.map.insertRow(index, rowValuesByColumn, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite)
          : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      return GSheetsValue(false, exception: e);
    }
  }

  Future<GSheetsValue<bool>> updateRowByUid(
      String? uid,
      Map<String, dynamic> rowValuesByColumn,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesByColumn contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false,
        bool eager = true
      }
      ) async {
    return await updateRowByKey(uid, rowValuesByColumn, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite, eager: eager);
  }

  Future<GSheetsValue<bool>> updateRowById(
      int? id,
      Map<String, dynamic> rowValuesByColumn,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesByColumn contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false,
        bool eager = true
      }
      ) async {
    return await updateRowByKey(id, rowValuesByColumn, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite, eager: eager);
  }

  Future<GSheetsValue<bool>> updateRowByKey(
      Object? key,
      Map<String, dynamic> rowValuesByColumn,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesByColumn contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false,
        bool eager = true
      }
      ) async {
    try {
      final sheet = worksheet;
      final returnValue = key != null && sheet != null
          ? await sheet.values.map.insertRowByKey(key, rowValuesByColumn, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite, eager: eager)
          : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion

  //#region Row(s): Delete
  Future<GSheetsValue<bool>> deleteRowByUid(String? uid, {int inColumn = UID_COLUMN_NUMBER}) async {
    return await deleteRowByKey(uid, inColumn: inColumn);
  }

  Future<GSheetsValue<bool>> deleteRowById(int? id, {int inColumn = UID_COLUMN_NUMBER}) async {
    return await deleteRowByKey(id, inColumn: inColumn);
  }

  Future<GSheetsValue<bool>> deleteRowByKey<T>(Object? key, {int inColumn = UID_COLUMN_NUMBER}) async {
    final returnValue = await getRowIndexOfKeyInColumn(key, inColumn: inColumn);
    if (returnValue.exception != null) {
      return GSheetsValue(false, exception: returnValue.exception);
    }
    return await deleteRow(returnValue.value);
  }

  Future<GSheetsValue<bool>> deleteRow(int? index) async => await deleteRows(index, 1);

  Future<GSheetsValue<bool>> deleteRows(int? index, int numberOfRows) async {
    try {
      final sheet = worksheet;
      final returnValue = index != null && index != KEY_IS_NOT_FOUND && sheet != null ? await sheet.deleteRow(index, count: numberOfRows) : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion

  //#region Values
  Future<GSheetsValue<bool>> updateValue(dynamic value, int rowNumber, String columnName, {bool eager = true}) async {
    return insertValueByKeys(value, columnKey: columnName, rowKey: rowNumber, eager: eager);
  }

  Future<GSheetsValue<bool>> insertValueByKeys(
      Object? value,
      {
        required Object columnKey,
        required Object rowKey,
        bool eager = true,
      }
      ) async {
    try {
      final sheet = worksheet;
      final returnValue = value != null && sheet != null ? await sheet.values.insertValueByKeys(value, columnKey: columnKey, rowKey: rowKey, eager: eager) : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion
}