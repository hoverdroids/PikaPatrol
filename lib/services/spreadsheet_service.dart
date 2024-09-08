import 'dart:async';
import 'dart:typed_data';
import 'package:gsheets/gsheets.dart';
import 'package:googleapis/sheets/v4.dart' as v4;
import 'package:googleapis_auth/auth_io.dart';
import 'package:pika_patrol/model/gsheets_value.dart';
import 'package:pika_patrol/services/worksheet_service.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;

abstract class SpreadsheetService {

  //#region Fields: Spreadsheet
  GSheets? _gSheets;
  bool isClosed = false;

  Spreadsheet? spreadsheet;
  String? get spreadsheetId => spreadsheet?.id;
  String? get spreadsheetUrl => spreadsheet?.url;
  SpreadsheetData? get spreadsheetData => spreadsheet?.data;
  List<Worksheet>? get spreadsheetWorksheets => spreadsheet?.sheets;
  String? get renderOption => spreadsheet?.renderOption;
  String? get inputOption => spreadsheet?.inputOption;
  //#endregion

  //#region Fields: Worksheet
  List<WorksheetService> worksheetServices = [];
  //#endregion

  //#region Fields: Other
  final String organization;
  //#endregion

  //#region Constructors
  SpreadsheetService(
      this.organization,
      dynamic credentialsJson,
      String spreadsheetId,
      bool doInitHeaderRow,
      {
        int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER,
        String? impersonatedUser,
        List<String> scopes = const [
          v4.SheetsApi.spreadsheetsScope,
          v4.SheetsApi.driveScope,
        ],
        ValueRenderOption render = ValueRenderOption.unformattedValue,
        ValueInputOption input = ValueInputOption.userEntered
      }
      ) {
    _gSheets = GSheets(credentialsJson, impersonatedUser: impersonatedUser, scopes: scopes);

    _init(spreadsheetId, doInitHeaderRow, columnHeadersRowNumber);
  }

  SpreadsheetService.withServiceAccountCredentials(
      this.organization,
      ServiceAccountCredentials credentials,
      String spreadsheetId,
      bool doInitHeaderRow,
      {
        int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER,
        String? impersonatedUser,
        List<String> scopes = const [
          v4.SheetsApi.spreadsheetsScope,
          v4.SheetsApi.driveScope,
        ],
        ValueRenderOption render = ValueRenderOption.unformattedValue,
        ValueInputOption input = ValueInputOption.userEntered
      }
      ) {
    _gSheets = GSheets(credentials, impersonatedUser: impersonatedUser, scopes: scopes);

    _init(spreadsheetId, doInitHeaderRow, columnHeadersRowNumber);
  }

  SpreadsheetService.withClient(
      this.organization,
      FutureOr<AutoRefreshingAuthClient> client,
      String spreadsheetId,
      bool doInitHeaderRow,
      {
        int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER,
        ValueRenderOption render = ValueRenderOption.unformattedValue,
        ValueInputOption input = ValueInputOption.userEntered
      }
      ) {
    _gSheets = GSheets(client);

    _init(spreadsheetId, doInitHeaderRow, columnHeadersRowNumber);
  }
  //#endregion

  //#region Lifecycle
  _init(
    String spreadsheetId,
    bool doInitHeaderRow,
    int columnHeadersRowNumber,
    {
      ValueRenderOption render = ValueRenderOption.unformattedValue,
      ValueInputOption input = ValueInputOption.userEntered
    }
  ) async {
    final returnValue = await getSpreadsheet(spreadsheetId, render: render, input: input);
    final spreadsheet = returnValue.value;
    if (spreadsheet == null) {
      developer.log("Spreadsheet init error:${returnValue.exception}");
    } else {
      this.spreadsheet = spreadsheet;
      initWorksheetServices(spreadsheet, doInitHeaderRow, columnHeadersRowNumber);
    }
  }

  void initWorksheetServices(Spreadsheet spreadsheet, bool doInitHeaderRow, int columnHeadersRowNumber);

  Future<void> close({bool closeExternal = true}) async {
    await _gSheets?.close(closeExternal: closeExternal);
    isClosed = true;
  }
  //#endregion

  //#region Spreadsheet
  Future<GSheetsValue<Spreadsheet>> createSpreadsheet(
      String title, {
        List<String> worksheetTitles = const <String>['Sheet1'],
        ValueRenderOption render = ValueRenderOption.unformattedValue,
        ValueInputOption input = ValueInputOption.userEntered,
      }
      ) async {
    try {
      final returnValue = await _gSheets?.createSpreadsheet(title, worksheetTitles: worksheetTitles, render: render, input: input);
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      return GSheetsValue(null, exception: e);
    }
  }

  Future<GSheetsValue<Spreadsheet>> getSpreadsheet(
      String spreadsheetId, {
        ValueRenderOption render = ValueRenderOption.unformattedValue,
        ValueInputOption input = ValueInputOption.userEntered,
      }
      ) async {
    try {
      final returnValue = await _gSheets?.spreadsheet(spreadsheetId, render: render, input: input);
      return GSheetsValue(returnValue);
    } on GSheetsException catch (e) {
      return GSheetsValue(null, exception: e);
    }
  }

  String? spreadSheetId() => spreadsheet?.id;
  //#endregion

  //#region Client
  Future<GSheetsValue<AutoRefreshingAuthClient>> getClient() async {
    try {
      final returnValue = await _gSheets?.client;
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      return GSheetsValue(null, exception: e);
    }
  }

  Future<AutoRefreshingAuthClient?> resolveClient(AutoRefreshingAuthClient? client) async {
    var resolvedClient = client;
    if (client == null) {
      final returnValue = await getClient();
      if (returnValue.exception != null) {
        developer.log("Could not get client for ${returnValue.exception}");
      } else {
        resolvedClient = returnValue.value;
      }
    }
    return resolvedClient;
  }
  //#endregion

  //#region Updates
  Future<GSheetsValue<http.Response>> batchUpdate(
      List<Map<String, dynamic>> requests,
      {
        String? spreadsheetId,
        AutoRefreshingAuthClient? client,
      }
      ) async {

    final resolvedClient = await resolveClient(client);
    final resolvedSpreadsheetId = spreadsheetId ?? this.spreadsheetId;

    if (resolvedClient == null || resolvedSpreadsheetId == null) {
      return GSheetsValue(null);
    }

    try {
      final returnValue = await GSheets.batchUpdate(resolvedClient, resolvedSpreadsheetId, requests);
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      return GSheetsValue(null, exception: e);
    }
  }
  //#endregion

  //#region Import/Export
  Future<GSheetsValue<List<Uint8List>>> exportSpreadsheetWorksheets(
    {
      List<int> worksheetIdsToIgnore = const [],
      AutoRefreshingAuthClient? client,
      String? spreadsheetId,
      String? spreadsheetUrl,
      ExportFormat format = ExportFormat.csv,
    }
  ) async {

    final List<int> worksheetIdsToExport = [];

    spreadsheetWorksheets?.forEach((worksheet) {
      if (!worksheetIdsToIgnore.contains(worksheet.id)) {
        worksheetIdsToExport.add(worksheet.id);
      }
    });

    return await exportAnySpreadsheetWorksheets(worksheetIdsToExport);
  }

  Future<GSheetsValue<List<Uint8List>>> exportAnySpreadsheetWorksheets(
    List<int> worksheetIdsToExport,
    {
      AutoRefreshingAuthClient? client,
      String? spreadsheetId,
      String? spreadsheetUrl,
      ExportFormat format = ExportFormat.csv,
    }
  ) async {
    final resolvedClient = await resolveClient(client);
    final resolvedSpreadsheetId = spreadsheetId ?? this.spreadsheetId;
    final resolvedSpreadsheetUrl = spreadsheetUrl ?? this.spreadsheetUrl;

    if (resolvedClient == null || resolvedSpreadsheetId == null || resolvedSpreadsheetUrl == null) {
      return GSheetsValue(null);
    }

    try {
      List<Uint8List> exportedWorksheets = [];

      for (var worksheetId in worksheetIdsToExport) {
        final returnValue = await exportAnyWorksheet(worksheetId, client: resolvedClient, spreadsheetId: resolvedSpreadsheetId, spreadsheetUrl: resolvedSpreadsheetUrl, format: format);
        final value = returnValue.value;

        if (returnValue.exception != null) {
          developer.log("Error exporting worksheet with id:$worksheetId");
        } else if (value != null) {
          exportedWorksheets.add(value);
        }
      }
      return GSheetsValue(exportedWorksheets);
    } on GSheetsException catch(e) {
      return GSheetsValue(null, exception: e);
    }
  }

  Future<GSheetsValue<Uint8List>> exportAnyWorksheet(
    int worksheetIdToExport,
    {
      AutoRefreshingAuthClient? client,
      String? spreadsheetId,
      String? spreadsheetUrl,
      ExportFormat format = ExportFormat.csv,
    }
  ) async {
    final resolvedClient = await resolveClient(client);
    final resolvedSpreadsheetId = spreadsheetId ?? this.spreadsheetId;
    final resolvedSpreadsheetUrl = spreadsheetUrl ?? this.spreadsheetUrl;

    if (resolvedClient == null || resolvedSpreadsheetId == null || resolvedSpreadsheetUrl == null) {
      return GSheetsValue(null);
    }

    try {
      final returnValue = await GSheets.export(client: resolvedClient, spreadsheetId: resolvedSpreadsheetId, spreadsheetUrl: resolvedSpreadsheetUrl, format: format, worksheetId: worksheetIdToExport);
      return GSheetsValue(returnValue);
    } on GSheetsException catch(e) {
      return GSheetsValue(null, exception: e);
    }
  }
  //#endregion
}