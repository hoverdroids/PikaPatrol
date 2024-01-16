import 'dart:convert';
import 'dart:developer' as developer;

import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/services/worksheet_service.dart';

import '../model/app_user.dart';
import '../model/app_user_profile.dart';

class UserProfilesWorksheetService extends WorksheetService {
   
  static const String USER_PROFILES_WORKSHEET_TITLE = "User Profiles";
  static const String USER_PROFILES_IS_ADMIN_COLUMN_TITLE = "Is Admin";
  static const String USER_PROFILES_FIRST_NAME_COLUMN_TITLE = "First Name";
  static const String USER_PROFILES_LAST_NAME_COLUMN_TITLE = "Last Name";
  static const String USER_PROFILES_EMAIL_COLUMN_TITLE = "Email";
  static const String USER_PROFILES_TAGLINE_COLUMN_TITLE = "Tagline";
  static const String USER_PROFILES_PRONOUNS_COLUMN_TITLE = "Pronouns";
  static const String USER_PROFILES_ORGANIZATION_COLUMN_TITLE = "Organization";
  static const String USER_PROFILES_ADDRESS_COLUMN_TITLE = "Address";
  static const String USER_PROFILES_CITY_COLUMN_TITLE = "City";
  static const String USER_PROFILES_STATE_COLUMN_TITLE = "State";
  static const String USER_PROFILES_ZIP_COLUMN_TITLE = "Zip";
  static const String USER_PROFILES_DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE = "Date Updated In Google Sheets";
  static const String USER_PROFILES_DATE_ACCOUNT_CREATED_TITLE = "Account Created";
  static const String USER_PROFILES_DATE_LAST_SIGNED_IN_TITLE = "Last Signed In";

  UserProfilesWorksheetService(
    Spreadsheet spreadsheet,
    bool doInitHeaderRow,
    {int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) : super(
    spreadsheet,
    USER_PROFILES_WORKSHEET_TITLE,
    [
      WorksheetService.UID_COLUMN_TITLE,
      USER_PROFILES_IS_ADMIN_COLUMN_TITLE,
      USER_PROFILES_FIRST_NAME_COLUMN_TITLE,
      USER_PROFILES_LAST_NAME_COLUMN_TITLE,
      USER_PROFILES_EMAIL_COLUMN_TITLE,
      USER_PROFILES_TAGLINE_COLUMN_TITLE,
      USER_PROFILES_PRONOUNS_COLUMN_TITLE,
      USER_PROFILES_ORGANIZATION_COLUMN_TITLE,
      USER_PROFILES_ADDRESS_COLUMN_TITLE,
      USER_PROFILES_CITY_COLUMN_TITLE,
      USER_PROFILES_STATE_COLUMN_TITLE,
      USER_PROFILES_ZIP_COLUMN_TITLE,
      USER_PROFILES_DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE,
      USER_PROFILES_DATE_ACCOUNT_CREATED_TITLE,
      USER_PROFILES_DATE_LAST_SIGNED_IN_TITLE
    ],
    doInitHeaderRow,
    columnHeadersRowNumber: columnHeadersRowNumber
  );

  // There is no way to get all user emails and other credentials in bulk for Firebase Client SDK
  // Consequently, those fields must be ignored when bulk exporting user profiles from Firebase to Google Sheets
  // and then updated from a server with the Admin SDK
  Map<String, dynamic> toGoogleSheetJsonForBulkProfileExport(AppUserProfile appUserProfile) => {
    WorksheetService.UID_COLUMN_TITLE: appUserProfile.uid,
    USER_PROFILES_FIRST_NAME_COLUMN_TITLE: appUserProfile.firstName,
    USER_PROFILES_LAST_NAME_COLUMN_TITLE: appUserProfile.lastName,
    USER_PROFILES_TAGLINE_COLUMN_TITLE: appUserProfile.tagline,
    USER_PROFILES_PRONOUNS_COLUMN_TITLE: appUserProfile.pronouns,
    USER_PROFILES_ORGANIZATION_COLUMN_TITLE: appUserProfile.organization,
    USER_PROFILES_ADDRESS_COLUMN_TITLE: appUserProfile.address,
    USER_PROFILES_CITY_COLUMN_TITLE: appUserProfile.city,
    USER_PROFILES_STATE_COLUMN_TITLE: appUserProfile.state,
    USER_PROFILES_ZIP_COLUMN_TITLE: appUserProfile.zip,
    USER_PROFILES_DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: appUserProfile.dateUpdatedInGoogleSheets?.toUtc()
  };

  // Since the user is logged in, their individual information is available for update
  Map<String, dynamic> toGoogleSheetJsonForLoggedInUser(AppUser appUser, AppUserProfile appUserProfile) => {
    WorksheetService.UID_COLUMN_TITLE: appUserProfile.uid,
    USER_PROFILES_IS_ADMIN_COLUMN_TITLE: appUser.isAdmin,
    USER_PROFILES_FIRST_NAME_COLUMN_TITLE: appUserProfile.firstName,
    USER_PROFILES_LAST_NAME_COLUMN_TITLE: appUserProfile.lastName,
    USER_PROFILES_EMAIL_COLUMN_TITLE: appUser.email,
    USER_PROFILES_TAGLINE_COLUMN_TITLE: appUserProfile.tagline,
    USER_PROFILES_PRONOUNS_COLUMN_TITLE: appUserProfile.pronouns,
    USER_PROFILES_ORGANIZATION_COLUMN_TITLE: appUserProfile.organization,
    USER_PROFILES_ADDRESS_COLUMN_TITLE: appUserProfile.address,
    USER_PROFILES_CITY_COLUMN_TITLE: appUserProfile.city,
    USER_PROFILES_STATE_COLUMN_TITLE: appUserProfile.state,
    USER_PROFILES_ZIP_COLUMN_TITLE: appUserProfile.zip,
    USER_PROFILES_DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: appUserProfile.dateUpdatedInGoogleSheets?.toUtc().toString(),
    USER_PROFILES_DATE_ACCOUNT_CREATED_TITLE: appUser.creationTimestamp?.toUtc().toString(),
    USER_PROFILES_DATE_LAST_SIGNED_IN_TITLE: appUser.lastSignInTime?.toUtc().toString()
  };
  
  AppUserProfile fromGoogleSheetsJson(Map<String, dynamic> json) => AppUserProfile(
      json[USER_PROFILES_FIRST_NAME_COLUMN_TITLE],
      json[USER_PROFILES_LAST_NAME_COLUMN_TITLE],
      uid: json[WorksheetService.UID_COLUMN_TITLE],
      tagline: json[USER_PROFILES_TAGLINE_COLUMN_TITLE],
      pronouns: json[USER_PROFILES_PRONOUNS_COLUMN_TITLE],
      organization: json[USER_PROFILES_ORGANIZATION_COLUMN_TITLE],
      address: json[USER_PROFILES_ADDRESS_COLUMN_TITLE],
      city: json[USER_PROFILES_CITY_COLUMN_TITLE],
      state: json[USER_PROFILES_STATE_COLUMN_TITLE],
      zip: json[USER_PROFILES_ZIP_COLUMN_TITLE],
      dateUpdatedInGoogleSheets: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE])),
      // creationTimestamp: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_ACCOUNT_CREATED_TITLE])), //No need; info is in AppUser
      // lastSignInTime: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_LAST_SIGNED_IN_TITLE])),     //No need; info is in Appuser
  );

  Future<int> getRowCount() async {
    var lastRow = await worksheet?.values.lastRow();
    return int.tryParse(lastRow?.first ?? "0") ?? 0;
  }

  Future<AppUserProfile?> getAppUserProfile(String uid) async {
    final json = await worksheet?.values.map.rowByKey(uid, fromColumn: WorksheetService.UID_COLUMN_NUMBER);
    return json != null ? fromGoogleSheetsJson(json) : null;
  }

  Future<void> addOrUpdateAppUserProfile(AppUser? appUser, AppUserProfile appUserProfile) async {
    var uid = appUserProfile.uid;
    if (uid != null) {
      final index = await worksheet?.values.rowIndexOf(uid, inColumn: WorksheetService.UID_COLUMN_NUMBER);

      Map<String, dynamic> json;
      if (appUser == null) {
        json = toGoogleSheetJsonForBulkProfileExport(appUserProfile);
      } else {
        json = toGoogleSheetJsonForLoggedInUser(appUser, appUserProfile);
      }

      if (index == null || index == -1) {
        await insertAppUserProfile(json);
      } else {
        await updateAppUserProfile(uid, json);
      }
    }
  }

  Future<void> addOrUpdateAppUserProfiles(List<AppUserProfile> appUserProfiles) async {
    for (var appUserProfile in appUserProfiles) {
      await addOrUpdateAppUserProfile(null, appUserProfile);
    }
  }

  Future insertAppUserProfile(Map<String, dynamic> row) async {
    try {
      await worksheet?.values.map.appendRow(row);
    } catch (e) {
      developer.log("Insert appUserProfile error:$e");
    }
  }

  Future insertAppUserProfiles(List<Map<String, dynamic>> rowList) async {
    try {
      worksheet?.values.map.appendRows(rowList);
    } catch(e) {
      developer.log("Insert appUserProfiles error:$e");
    }
  }

  Future<List<AppUserProfile>> getAppUserProfiles() async {
    final appUserProfiles = await worksheet?.values.map.allRows();
    return appUserProfiles == null ? <AppUserProfile>[] : appUserProfiles.map(fromGoogleSheetsJson).toList();
  }

  Future<bool> updateAppUserProfile(String uid, Map<String, dynamic> appUserProfile) async {
    return await worksheet?.values.map.insertRowByKey(uid, appUserProfile) ?? false;
  }

  Future<bool> updateAppUserProfileCell(int id, String columnName, dynamic value) async {
    return await worksheet?.values.insertValueByKeys(value, columnKey: columnName, rowKey: id) ?? false;
  }

  Future<bool> deleteAppUserProfileById(int id) async {
    final index = await worksheet?.values.rowIndexOf(id);
    if (index == null || index == -1) return false;
    return await worksheet?.deleteRow(index) ?? false;
  }
}