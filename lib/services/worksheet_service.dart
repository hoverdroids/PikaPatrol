// ignore_for_file: constant_identifier_names
import 'package:gsheets/gsheets.dart';
import 'dart:developer' as developer;

import 'package:pika_patrol/model/gsheets_value.dart';
import 'package:pika_patrol/utils/collection_utils.dart';

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

  Spreadsheet spreadsheet;
  String? spreadsheetTitle;
  String worksheetTitle;
  Worksheet? worksheet;
  List<String> columnHeaderKeys;
  int columnHeadersRowNumber;

  WorksheetService(
      this.spreadsheet,
      this.worksheetTitle,
      this.columnHeaderKeys,
      bool doInitHeaderRow,
      {
        this.columnHeadersRowNumber = DEFAULT_COLUMN_HEADER_ROW_NUMBER
      }
      ) {

    _init(doInitHeaderRow);
  }

  //#region Init
  _init(bool doInitHeaderRow) async {

    spreadsheetTitle = spreadsheet.data.properties.title;
    developer.log("[READ] Excel sheet properties.title $spreadsheetTitle $worksheetTitle");

    final returnValue = await getWorksheet();
    worksheet = returnValue.value;

    if (returnValue.exception != null) {
      developer.log("Google Sheets init error in $worksheetTitle :${returnValue.exception}");
    }

    if (doInitHeaderRow) {
      final returnValue = await initHeaderRow();
      if (returnValue.exception != null) {
        developer.log("Google sheets initHeaderRow error in $worksheetTitle :${returnValue.exception}");
      }
    }
  }

  Future<GSheetsValue<bool>> initHeaderRow() async {
    final returnValue = await updateRowWithoutColumnHeaderKeys(columnHeadersRowNumber, columnHeaderKeys);
    if (returnValue.exception != null) {
      return GSheetsValue.e(returnValue.exception);
    }
    return GSheetsValue(returnValue.value);

  }
  //#endregion

  //#region Worksheet
  Future<GSheetsValue<Worksheet>> getWorksheet({Spreadsheet? spreadsheet, String? title, bool addWorksheetIfDoesNotExist = true}) async {
    final sheet = spreadsheet ?? this.spreadsheet;
    final worksheetTitle = title ?? this.worksheetTitle;

    final worksheet = sheet.worksheetByTitle(worksheetTitle);
    developer.log("[READ] Excel sheet worksheetByTitle $spreadsheetTitle $worksheetTitle");
    if (worksheet != null) {
      return GSheetsValue(worksheet);
    }

    if (addWorksheetIfDoesNotExist) {
      try {
        final returnValue = await addWorksheet(worksheetTitle);
        final exception = returnValue.exception;
        if (exception != null) {
          throw GSheetsException(exception.cause);
        }
        return GSheetsValue(returnValue.value);
      } on GSheetsException catch (e) {
        return GSheetsValue(null, exception: e);
      }
    }
    return GSheetsValue(null);
  }

  Future<GSheetsValue<Worksheet>> addWorksheet(String title) async {
    try {
      developer.log("[WRITE] Excel sheet addWorksheet $spreadsheetTitle $worksheetTitle title:$title");
      final returnValue = await spreadsheet.addWorksheet(title);
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      developer.log("[WRITE] Excel sheet addWorksheet $spreadsheetTitle $worksheetTitle title:$title [ERROR] ${e.cause}");
      return GSheetsValue(null, exception: e);
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
      developer.log("[READ] Excel sheet rowIndexOf $spreadsheetTitle $worksheetTitle row:$key column:$inColumn");
      final index = key != null && sheet != null ? await sheet.values.rowIndexOf(key, inColumn: inColumn) : KEY_IS_NOT_FOUND;
      return GSheetsValue(index);
    } on GSheetsException catch(e) {
      developer.log("[READ] Excel sheet rowIndexOf $spreadsheetTitle $worksheetTitle row:$key column:$inColumn [ERROR] ${e.cause}");
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
      developer.log("[READ] Excel sheet getRowByKey $spreadsheetTitle $worksheetTitle key:$key column:$fromColumn");
      final row = await worksheet?.values.map.rowByKey(key, fromColumn: fromColumn, length: length, mapTo: mapTo);
      return GSheetsValue(row);
    } on GSheetsException catch (e) {
      developer.log("[READ] Excel sheet getRowByKey $spreadsheetTitle $worksheetTitle key:$key column:$fromColumn");
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
      developer.log("[READ] Excel sheet getRows $spreadsheetTitle $worksheetTitle fromRow:$fromRow fromColumn:$fromColumn length:$length count:$count mapTo:$mapTo");
      final rows = await worksheet?.values.map.allRows(fromRow: fromRow, fromColumn: fromColumn, length: length, count: count, mapTo: mapTo);
      return GSheetsValue(rows);
    } on GSheetsException catch (e) {
      developer.log("[READ] Excel sheet getRows $spreadsheetTitle $worksheetTitle fromRow:$fromRow fromColumn:$fromColumn length:$length count:$count mapTo:$mapTo [ERROR] ${e.cause}");
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
      developer.log("[READ] Excel sheet getRow $spreadsheetTitle $worksheetTitle index:$index fromColumn:$fromColumn length:$length mapTo:$mapTo");
      final row = await worksheet?.values.map.row(index, fromColumn: fromColumn, length: length, mapTo: mapTo);
      return GSheetsValue(row);
    } on GSheetsException catch (e) {
      developer.log("[READ] Excel sheet getRow $spreadsheetTitle $worksheetTitle index:$index fromColumn:$fromColumn length:$length mapTo:$mapTo");
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
    developer.log("[READ] Excel sheet getRowCount $spreadsheetTitle $worksheetTitle");
    return worksheet?.rowCount ?? 0;
  }

  Future<GSheetsValue<int>> getRowCountFromAllRows() async {
    try {
      developer.log("[READ] Excel sheet getRowCountFromAllRows $spreadsheetTitle $worksheetTitle");
      var allRows = await worksheet?.values.allRows();
      var value = allRows?.length ?? 0;
      return GSheetsValue(value);
    } on GSheetsException catch(e) {
      developer.log("[READ] Excel sheet getRowCountFromAllRows $spreadsheetTitle $worksheetTitle [ERROR] ${e.cause}");
      return GSheetsValue(0, exception: e);
    }
  }

  Future<GSheetsValue<int>> getRowCountFromAllRowsMap() async {
    try {
      developer.log("[READ] Excel sheet getRowCountFromAllRowsMap $spreadsheetTitle $worksheetTitle");
      var allRows = await worksheet?.values.map.allRows();
      var value = allRows?.length ?? 0;
      return GSheetsValue(value);
    } on GSheetsException catch(e) {
      developer.log("[READ] Excel sheet getRowCountFromAllRowsMap $spreadsheetTitle $worksheetTitle [ERROR] ${e.cause}");
      return GSheetsValue(0, exception: e);
    }
  }

  Future<GSheetsValue<int>> getRowCountFromLastNonEmptyRow() async {
    try {
      developer.log("[READ] Excel sheet getRowCountFromLastNonEmptyRow $spreadsheetTitle $worksheetTitle");
      var lastRow = await worksheet?.values.lastRow();
      var hasRows = lastRow != null;
      var returnValue = hasRows ? int.parse(lastRow.first) : 0;
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      developer.log("[READ] Excel sheet getRowCountFromLastNonEmptyRow $spreadsheetTitle $worksheetTitle [ERROR] ${e.cause}");
      return GSheetsValue(KEY_IS_NOT_FOUND, exception: e);
    } on FormatException catch(e) {
      developer.log("[READ] Excel sheet read getRowCountFromLastNonEmptyRow $spreadsheetTitle $worksheetTitle [ERROR] ${e}");
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

  //This is the same a insertRows, but I think the name is clearer
  Future<GSheetsValue<bool>> insertRowsAbove(
      int index,
      {
        int count = 1,
        bool inheritFromBefore = false
      }
      ) async {
    return await insertEmptyRowsAtIndex(index, count: count, inheritFromBefore: inheritFromBefore);
  }

  Future<GSheetsValue<bool>> insertRowBelow(int index, { bool inheritFromBefore = false}) async {
    return await insertRowsBelow(index, count: 1, inheritFromBefore: inheritFromBefore);
  }

  Future<GSheetsValue<bool>> insertRowsBelow(
      int index,
      {
        int count = 1,
        bool inheritFromBefore = false
      }
      ) async {
    return await insertEmptyRowsAtIndex(index + 1, count: count, inheritFromBefore: inheritFromBefore);
  }

  //Row, Indexes, Values
  Future<GSheetsValue<bool>> insertRowAtIndexes(
      List<int> indexes,
      {
        bool inheritFromBefore = false,
        Map<String, dynamic> rowValuesWithColumnHeaderKeys = const {},
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false
      }
      ) async {
    return await insertRowsAtIndexes(
        indexes,
        count: 1,
        inheritFromBefore: inheritFromBefore,
        rowsValuesByColumn: rowValuesWithColumnHeaderKeys.isEmpty ? [] : [rowValuesWithColumnHeaderKeys],
        fromColumn: fromColumn,
        mapTo: mapTo,
        appendMissing: appendMissing,
        overwrite: overwrite
    );
  }

  //Rows, Indexes, Values
  Future<GSheetsValue<bool>> insertRowsAtIndexes(
      List<int> indexes,
      {
        int count = 1,
        bool inheritFromBefore = false,
        List<Map<String, dynamic>> rowsValuesByColumn = const [],
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false
      }
      ) async {
    try {
      var allSucceeded = true;

      //Insert from the highest index and to lowest index to avoid changing the referenced rows
      final uniqueReversedSortedIndexes = indexes.clone(isUnique: true, isSorted: true, isReversed: true);
      for (var index in uniqueReversedSortedIndexes) {
        final returnValue = await insertRowsAtIndex(
            index,
            count: count,
            inheritFromBefore: inheritFromBefore,
            rowsValuesByColumn: rowsValuesByColumn,
            fromColumn: fromColumn,
            mapTo: mapTo,
            appendMissing: appendMissing,
            overwrite: overwrite
        );

        final exception = returnValue.exception;
        if (exception != null) {
          throw GSheetsException(exception.cause);
        }

        if (returnValue.value == false) {
          allSucceeded = false;
        }
      }

      return GSheetsValue(allSucceeded);
    } on GSheetsException catch(e) {
      return GSheetsValue(false, exception: e);
    }
  }

  //Row, Index, Values
  Future<GSheetsValue<bool>> insertRowAtIndex(
      int index,
      {
        bool inheritFromBefore = false,
        Map<String, dynamic> rowValuesWithColumnHeaderKeys = const {},
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false
      }
      ) async {
    return await insertRowsAtIndex(
        index,
        count: 1,
        inheritFromBefore: inheritFromBefore,
        rowsValuesByColumn: rowValuesWithColumnHeaderKeys.isEmpty ? [] : [rowValuesWithColumnHeaderKeys],
        fromColumn: fromColumn,
        mapTo: mapTo,
        appendMissing: appendMissing,
        overwrite: overwrite
    );
  }

  //Rows, Index, Values
  Future<GSheetsValue<bool>> insertRowsAtIndex(
      int index,
      {
        int count = 1,
        bool inheritFromBefore = false,
        List<Map<String, dynamic>> rowsValuesByColumn = const [],
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false
      }
      ) async {
    try {
      var allSucceeded = true;

      final resolvedCount = rowsValuesByColumn.isNotEmpty ? rowsValuesByColumn.length : count;

      var returnValue = await insertEmptyRowsAtIndex(index, count: resolvedCount, inheritFromBefore: inheritFromBefore);
      var exception = returnValue.exception;
      if (exception != null) {
        throw GSheetsException(exception.cause);
      }
      if (returnValue.value != true) {
        allSucceeded = false;
      }

      for (int i = 0; i < rowsValuesByColumn.length; i++) {
        returnValue = await updateRow(index + i, rowsValuesByColumn[i], fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite);
        exception = returnValue.exception;
        if (exception != null) {
          throw GSheetsException(exception.cause);
        }
        if (returnValue.value != true) {
          allSucceeded = false;
        }
      }

      return GSheetsValue(allSucceeded);
    } on GSheetsException catch(e) {
      return GSheetsValue(false, exception: e);
    }
  }

  //Row, Indexes, No Values
  Future<GSheetsValue<bool>> insertEmptyRowAtIndexes(List<int> indexes, {bool inheritFromBefore = false}) async {
    return await insertEmptyRowsAtIndexes(indexes, count: 1, inheritFromBefore: inheritFromBefore);
  }

  //Rows, Indexes, No Values
  Future<GSheetsValue<bool>> insertEmptyRowsAtIndexes(
      List<int> indexes,
      {
        int count = 1,
        bool inheritFromBefore = false
      }
      ) async {
    try {
      var allSucceeded = true;

      //Insert from the highest index and to lowest index to avoid changing the referenced rows
      final uniqueReversedSortedIndexes = indexes.clone(isUnique: true, isSorted: true, isReversed: true);
      for (var index in uniqueReversedSortedIndexes) {
        final returnValue = await insertEmptyRowsAtIndex(index, count: count, inheritFromBefore: inheritFromBefore);
        final exception = returnValue.exception;
        if (exception != null) {
          throw GSheetsException(exception.cause);
        }

        if (returnValue.value == false) {
          allSucceeded = false;
        }
      }

      return GSheetsValue(allSucceeded);
    } on GSheetsException catch(e) {
      return GSheetsValue(false, exception: e);
    }
  }

  //Row, Index, No Values
  Future<GSheetsValue<bool>> insertEmptyRowAtIndex(int index, {bool inheritFromBefore = false}) async {
    return await insertEmptyRowsAtIndex(index, count: 1, inheritFromBefore: inheritFromBefore);
  }

  //Rows, Index, No Values
  Future<GSheetsValue<bool>> insertEmptyRowsAtIndex(
      int index,
      {
        int count = 1,
        bool inheritFromBefore = false
      }
      ) async {
    try {
      developer.log("[WRITE] Excel sheet insertEmptyRowsAtIndex $spreadsheetTitle $worksheetTitle index:$index count:$count");
      final returnValue = await worksheet?.insertRow(index, count: count, inheritFromBefore: inheritFromBefore);
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      developer.log("[WRITE] Excel sheet insertEmptyRowsAtIndex $spreadsheetTitle $worksheetTitle index:$index count:$count");
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
      developer.log("[WRITE] Excel sheet appendRow $spreadsheetTitle $worksheetTitle row:$row fromColumn:$fromColumn");
      final returnValue = await worksheet?.values.map.appendRow(row, mapTo: mapTo, appendMissing: appendMissing, inRange: inRange) ?? false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      developer.log("[WRITE] Excel sheet appendRow $spreadsheetTitle $worksheetTitle row:$row fromColumn:$fromColumn [ERROR] ${e.cause}");
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
      developer.log("[WRITE] Excel sheet appendRows $spreadsheetTitle $worksheetTitle rows:$rows fromColumn:$fromColumn");
      final returnValue = await worksheet?.values.map.appendRows(rows, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, inRange: inRange) ?? false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      developer.log("[WRITE] Excel sheet appendRows $spreadsheetTitle $worksheetTitle rows:$rows fromColumn:$fromColumn [ERROR] ${e.cause}");
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion

  //#region Row(s): Update
  Future<GSheetsValue<bool>> updateRowWithoutColumnHeaderKeys(
      int? index,
      List<dynamic> rowValues,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
      }
      ) async {
    try {
      final sheet = worksheet;
      developer.log("[WRITE] Excel sheet updateRowWithoutColumnHeaderKeys $spreadsheetTitle $worksheetTitle index:$index rowValues:$rowValues");
      final returnValue = index != null && index != KEY_IS_NOT_FOUND && sheet != null
          ? await sheet.values.insertRow(index, rowValues, fromColumn: fromColumn)
          : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      developer.log("[WRITE] Excel sheet updateRowWithoutColumnHeaderKeys $spreadsheetTitle $worksheetTitle index:$index rowValues:$rowValues [ERROR] ${e.cause}");
      return GSheetsValue(false, exception: e);
    }
  }

  Future<GSheetsValue<bool>> updateRow(
      int? index,
      Map<String, dynamic> rowValuesWithColumnHeaderKeys,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false
      }
      ) async {
    try {
      final sheet = worksheet;
      developer.log("[WRITE] Excel sheet updateRow $spreadsheetTitle $worksheetTitle");
      final returnValue = index != null && index != KEY_IS_NOT_FOUND && sheet != null
          ? await sheet.values.map.insertRow(index, rowValuesWithColumnHeaderKeys, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite)
          : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      developer.log("[WRITE] Excel sheet updateRow $spreadsheetTitle $worksheetTitle [ERROR] ${e.cause}");
      return GSheetsValue(false, exception: e);
    }
  }

  Future<GSheetsValue<bool>> updateRowByUid(
      String? uid,
      Map<String, dynamic> rowValuesWithColumnHeaderKeys,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false,
        bool eager = true
      }
      ) async {
    return await updateRowByKey(uid, rowValuesWithColumnHeaderKeys, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite, eager: eager);
  }

  Future<GSheetsValue<bool>> updateRowById(
      int? id,
      Map<String, dynamic> rowValuesWithColumnHeaderKeys,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false,
        bool eager = true
      }
      ) async {
    return await updateRowByKey(id, rowValuesWithColumnHeaderKeys, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite, eager: eager);
  }

  Future<GSheetsValue<bool>> updateRowByKey(
      Object? key,
      Map<String, dynamic> rowValuesWithColumnHeaderKeys,
      {
        int fromColumn = UID_COLUMN_NUMBER,//default was 2; assume rowValuesWithColumnHeaderKeys contain data for all columns including uid column
        dynamic mapTo,
        bool appendMissing = false,
        bool overwrite = false,
        bool eager = true
      }
      ) async {
    try {
      final sheet = worksheet;
      developer.log("[WRITE] Excel sheet updateRowByKey $spreadsheetTitle $worksheetTitle row:$key rowValues:$rowValuesWithColumnHeaderKeys");
      final returnValue = key != null && sheet != null
          ? await sheet.values.map.insertRowByKey(key, rowValuesWithColumnHeaderKeys, fromColumn: fromColumn, mapTo: mapTo, appendMissing: appendMissing, overwrite: overwrite, eager: eager)
          : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      developer.log("[WRITE] Excel sheet updateRowByKey $spreadsheetTitle $worksheetTitle row:$key rowValues:$rowValuesWithColumnHeaderKeys [ERROR] ${e.cause}");
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
      developer.log("[WRITE] Excel sheet deleteRows $spreadsheetTitle $worksheetTitle index:$index numberOfRows:$numberOfRows");
      final returnValue = index != null && index != KEY_IS_NOT_FOUND && sheet != null ? await sheet.deleteRow(index, count: numberOfRows) : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      developer.log("[WRITE] Excel sheet deleteRows $spreadsheetTitle $worksheetTitle index:$index numberOfRows:$numberOfRows [ERROR] ${e.cause}");
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
      developer.log("[WRITE] Excel sheet insertValueByKeys $spreadsheetTitle $worksheetTitle value:$value columnKey:$columnKey rowKey:$rowKey");
      final returnValue = value != null && sheet != null ? await sheet.values.insertValueByKeys(value, columnKey: columnKey, rowKey: rowKey, eager: eager) : false;
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      developer.log("[WRITE] Excel sheet insertValueByKeys $spreadsheetTitle $worksheetTitle value:$value columnKey:$columnKey rowKey:$rowKey [ERROR] ${e.cause}");
      return GSheetsValue(false, exception: e);
    }
  }
  //#endregion
}