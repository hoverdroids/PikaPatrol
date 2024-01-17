// ignore_for_file: constant_identifier_names
import 'dart:convert';

import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/services/worksheet_service.dart';

import '../model/app_user.dart';
import '../model/app_user_profile.dart';

class UserProfilesWorksheetService extends WorksheetService {
   
  static const String WORKSHEET_TITLE = "User Profiles";
  static const String IS_ADMIN_COLUMN_TITLE = "Is Admin";
  static const String FIRST_NAME_COLUMN_TITLE = "First Name";
  static const String LAST_NAME_COLUMN_TITLE = "Last Name";
  static const String EMAIL_COLUMN_TITLE = "Email";
  static const String TAGLINE_COLUMN_TITLE = "Tagline";
  static const String PRONOUNS_COLUMN_TITLE = "Pronouns";
  static const String ORGANIZATION_COLUMN_TITLE = "Organization";
  static const String ADDRESS_COLUMN_TITLE = "Address";
  static const String CITY_COLUMN_TITLE = "City";
  static const String STATE_COLUMN_TITLE = "State";
  static const String ZIP_COLUMN_TITLE = "Zip";
  static const String DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE = "Date Updated In Google Sheets";
  static const String DATE_ACCOUNT_CREATED_TITLE = "Account Created";
  static const String DATE_LAST_SIGNED_IN_TITLE = "Last Signed In";

  UserProfilesWorksheetService(
    Spreadsheet spreadsheet,
    bool doInitHeaderRow,
    {int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) : super(
    spreadsheet,
    WORKSHEET_TITLE,
    [
      WorksheetService.UID_COLUMN_TITLE,
      IS_ADMIN_COLUMN_TITLE,
      FIRST_NAME_COLUMN_TITLE,
      LAST_NAME_COLUMN_TITLE,
      EMAIL_COLUMN_TITLE,
      TAGLINE_COLUMN_TITLE,
      PRONOUNS_COLUMN_TITLE,
      ORGANIZATION_COLUMN_TITLE,
      ADDRESS_COLUMN_TITLE,
      CITY_COLUMN_TITLE,
      STATE_COLUMN_TITLE,
      ZIP_COLUMN_TITLE,
      DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE,
      DATE_ACCOUNT_CREATED_TITLE,
      DATE_LAST_SIGNED_IN_TITLE
    ],
    doInitHeaderRow,
    columnHeadersRowNumber: columnHeadersRowNumber
  );

  // There is no way to get all user emails and other credentials in bulk for Firebase Client SDK
  // Consequently, those fields must be ignored when bulk exporting user profiles from Firebase to Google Sheets
  // and then updated from a server with the Admin SDK
  Map<String, dynamic> toGoogleSheetJsonForBulkProfileExport(AppUserProfile appUserProfile) => {
    WorksheetService.UID_COLUMN_TITLE: appUserProfile.uid,
    FIRST_NAME_COLUMN_TITLE: appUserProfile.firstName,
    LAST_NAME_COLUMN_TITLE: appUserProfile.lastName,
    TAGLINE_COLUMN_TITLE: appUserProfile.tagline,
    PRONOUNS_COLUMN_TITLE: appUserProfile.pronouns,
    ORGANIZATION_COLUMN_TITLE: appUserProfile.organization,
    ADDRESS_COLUMN_TITLE: appUserProfile.address,
    CITY_COLUMN_TITLE: appUserProfile.city,
    STATE_COLUMN_TITLE: appUserProfile.state,
    ZIP_COLUMN_TITLE: appUserProfile.zip,
    DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: appUserProfile.dateUpdatedInGoogleSheets?.toUtc()
  };

  // Since the user is logged in, their individual information is available for update
  Map<String, dynamic> toGoogleSheetJsonForLoggedInUser(AppUser appUser, AppUserProfile appUserProfile) => {
    WorksheetService.UID_COLUMN_TITLE: appUserProfile.uid,
    IS_ADMIN_COLUMN_TITLE: appUser.isAdmin,
    FIRST_NAME_COLUMN_TITLE: appUserProfile.firstName,
    LAST_NAME_COLUMN_TITLE: appUserProfile.lastName,
    EMAIL_COLUMN_TITLE: appUser.email,
    TAGLINE_COLUMN_TITLE: appUserProfile.tagline,
    PRONOUNS_COLUMN_TITLE: appUserProfile.pronouns,
    ORGANIZATION_COLUMN_TITLE: appUserProfile.organization,
    ADDRESS_COLUMN_TITLE: appUserProfile.address,
    CITY_COLUMN_TITLE: appUserProfile.city,
    STATE_COLUMN_TITLE: appUserProfile.state,
    ZIP_COLUMN_TITLE: appUserProfile.zip,
    DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: appUserProfile.dateUpdatedInGoogleSheets?.toUtc().toString(),
    DATE_ACCOUNT_CREATED_TITLE: appUser.creationTimestamp?.toUtc().toString(),
    DATE_LAST_SIGNED_IN_TITLE: appUser.lastSignInTime?.toUtc().toString()
  };
  
  AppUserProfile fromGoogleSheetsJson(Map<String, dynamic> json) => AppUserProfile(
      json[FIRST_NAME_COLUMN_TITLE],
      json[LAST_NAME_COLUMN_TITLE],
      uid: json[WorksheetService.UID_COLUMN_TITLE],
      tagline: json[TAGLINE_COLUMN_TITLE],
      pronouns: json[PRONOUNS_COLUMN_TITLE],
      organization: json[ORGANIZATION_COLUMN_TITLE],
      address: json[ADDRESS_COLUMN_TITLE],
      city: json[CITY_COLUMN_TITLE],
      state: json[STATE_COLUMN_TITLE],
      zip: json[ZIP_COLUMN_TITLE],
      dateUpdatedInGoogleSheets: DateTime.parse(jsonDecode(json[DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE])),
      // creationTimestamp: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_ACCOUNT_CREATED_TITLE])), //No need; info is in AppUser
      // lastSignInTime: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_LAST_SIGNED_IN_TITLE])),     //No need; info is in Appuser
  );

  Future<AppUserProfile?> getAppUserProfile(String uid) async {
    final json = await worksheet?.values.map.rowByKey(uid, fromColumn: WorksheetService.UID_COLUMN_NUMBER);
    return json != null ? fromGoogleSheetsJson(json) : null;
  }

  Future<List<AppUserProfile>> getAppUserProfiles() async {
    final appUserProfiles = await worksheet?.values.map.allRows();
    return appUserProfiles == null ? <AppUserProfile>[] : appUserProfiles.map(fromGoogleSheetsJson).toList();
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
        await insertRow(json);
      } else {
        await updateRow(uid, json);
      }
    }
  }

  Future<void> addOrUpdateAppUserProfiles(List<AppUserProfile> appUserProfiles) async {
    for (var appUserProfile in appUserProfiles) {
      await addOrUpdateAppUserProfile(null, appUserProfile);
    }
  }
}