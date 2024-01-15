// ignore_for_file: constant_identifier_names

import 'dart:convert';

import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/model/app_user_profile.dart';
import 'dart:developer' as developer;

import '../model/app_user.dart';

class GoogleSheetsService {
  static const _credentials = r''' 
  {
    "type": "service_account",
    "project_id": "pikajoe-97c5c",
    "private_key_id": "893d8476691eb166ca81eebfaaea2ddb6a78e9fb",
    "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCjMe6TnRG+AvE6\nbEK+Vlchccb4QD5WpCMt8Vk+DFsslkvF+Bd+IxReHoi6PdiMX7kJDZl/+CExKTHq\nTtverDXF2kvjP+Q0Sj6VAjcnomNoKuEGmafOm09feGTyYroB75VJF72hELckrErs\nBYDOPPvTrjnye9hvrwh8jeFOCXkTh+tGCddZamToQAOk3r53B7xrlqTfCoWvZnKi\nlDK1ih3YNs7GAts82kcGxa3d1GkiINQsbRChy81HL1kiShQgGhpaN97M17vc1w49\nPnkpSK4/VMTPjxZeC/QAaxzZcCIZ4WULEzojg0LJkaxm2dXpsKpWuG3a0rfe1XPo\nfZZaE9BHAgMBAAECggEACgvgXoj8VyCyPgD9KN+C1KW+9Hhr/gRzv/fMISQ8lqWX\n+5N2ysaZEeQ6UZDOHHImH3cNXJHnZTHeh0icg3xBgTEbm91KjKeHa7/rqk52ZSrC\nmJfr+y2XeM6eFEfcoJLhs1K5U0mGpMTQhfAeylN5w0HGAnX6UIHLeXN4i8fMgtWx\ndPmTz8DksQyw907V6uhxDPSLPYInJKS05slWkEnhCgwvAfascZKXQV0zG4tsFTO9\nTI58VUiZoEolBRmOD1xiV1/vnFN9y3Ng5Bqp6p4rhVjWcOB5hIaZcnibQkBeOGYi\nr+TYligZdhmibr/wwEX6yRAT7/AIIG+CcyUaKLqzdQKBgQDe5k4ti7p0qWiSWDYR\nHZSA+F8iBn0z4iFbJeXoZ1cMjpoKFeJD/IR7LUw0Q97/9jZa3lHrXv7oJWJF9DLo\nZwEUE1aZA/ScguVUsZCmMJF8zMlPfMvZOMdIDePW+ZRqqmf13Ar1NTeZqb72JpNP\nL2l1jSn9Er7DQJbQT1RiTVPdVQKBgQC7bemd2nXBfAR2FxXtrM3gh2OI7x3Ckfuc\nU2O+KX7nilHsHVFkUJvLqXmy6lnxjibpmP5wsGtPfFzW0iyrzsU47Wz/FO3GXNIC\nKxm5YdnsuiDfBZwIIXxCClHc5qPAxxyY9yj6+f2jVmLn+T+L4q7SHZuzwUI9fuPw\nz3kia68XKwKBgQCBRR/h2j9wmS9EcFQq6PTPNzw1B35lMKgXrIsBla0uYyWC494t\nf611oneneBVEbQ5o9LadwqIjEEtGNrGvhs1hTzXR2DFs85z82V4Cg/hcYIf/yWiP\nuhYY+7U/X89rbRiNxee0/gAY5hERwJ1+Nwj6W7wWQWDQ7AyLEvbla+NPYQKBgAnV\nz69/2jQH/PfxaC4rpjYFBL0XxxkBrhFa8t30sXsW8AuS0kWQUUyTnRY9Y/DgA7y4\nUYm6SDdIkFqZdsyhMgo1s0WDZKLHFiIU/umSb+wTLExnr/NhRnL0ta0A0VD5Yc/J\nEHZzDdM3YkNH+gSuJXxTH2uEVaSCdxWY3YNn4S03AoGAewa1I1v5JcJdoFhy8Zu2\ntwmJPX34Bkg7IN8fo3A2HJgq9YK07fjdAJeJLTFrRETPugfcv2DB3S0zfvI5YjA2\nCLAxP+c3eOLz+Uyk5EKtpk6pT4ggQfm9+J1Xdcm8v4LCfFFP1xmEhDiVNbtZMKus\nKxEtBgJSv39bxqUQJ5lRuOo=\n-----END PRIVATE KEY-----\n",
    "client_email": "pika-patrol@pikajoe-97c5c.iam.gserviceaccount.com",
    "client_id": "102925647937041144152",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/pika-patrol%40pikajoe-97c5c.iam.gserviceaccount.com",
    "universe_domain": "googleapis.com"
  }
  ''';
  static const _spreadsheetId = "1RXijstzfaWcl_xnHpF5iamS-lX-5FaTpcYoa9GsaX08";//TODO - CHRIS - this should be default and user should be allowed to change it

  //Google Docs Read/Write limits
  //https://developers.google.com/docs/api/limits
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_PROJECT = 3000;
  static const int GOOGLE_API_USAGE_LIMIT_READ_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 300;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_PROJECT = 600;
  static const int GOOGLE_API_USAGE_LIMIT_WRITE_REQUESTS_PER_MINUTE_PER_USER_PER_PROJECT = 60;

  static final _gsheets = GSheets(_credentials);

  static Worksheet? _userProfilesWorksheet;
  static const String USER_PROFILES_WORKSHEET_TITLE = "User Profiles";
  static const int USER_PROFILES_WORKSHEET_COLUMN_HEADERS_ROW_NUMBER = 1;
  static const String USER_PROFILES_UID_COLUMN_TITLE = "uid";
  static const int USER_PROFILES_UID_COLUMN_NUMBER = 1;
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

  static const List<String> USER_PROFILES_COLUMNS = [
    USER_PROFILES_UID_COLUMN_TITLE,
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
  ];

  // There is no way to get all user emails and other credentials in bulk for Firebase Client SDK
  // Consequently, those fields must be ignored when bulk exporting user profiles from Firebase to Google Sheets
  // and then updated from a server with the Admin SDK
  static Map<String, dynamic> toGoogleSheetJsonForBulkProfileExport(AppUserProfile appUserProfile) => {
    USER_PROFILES_UID_COLUMN_TITLE: appUserProfile.uid,
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
  static Map<String, dynamic> toGoogleSheetJsonForLoggedInUser(AppUser appUser, AppUserProfile appUserProfile) => {
    USER_PROFILES_UID_COLUMN_TITLE: appUserProfile.uid,
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

  //For non string fields, need to user jsonDecode(json[thekey])
  static AppUserProfile fromGoogleSheetsJson(Map<String, dynamic> json) => AppUserProfile(
    json[USER_PROFILES_FIRST_NAME_COLUMN_TITLE],
    json[USER_PROFILES_LAST_NAME_COLUMN_TITLE],
    uid: json[USER_PROFILES_UID_COLUMN_TITLE],
    tagline: json[USER_PROFILES_TAGLINE_COLUMN_TITLE],
    pronouns: json[USER_PROFILES_PRONOUNS_COLUMN_TITLE],
    organization: json[USER_PROFILES_ORGANIZATION_COLUMN_TITLE],
    address: json[USER_PROFILES_ADDRESS_COLUMN_TITLE],
    city: json[USER_PROFILES_CITY_COLUMN_TITLE],
    state: json[USER_PROFILES_STATE_COLUMN_TITLE],
    zip: json[USER_PROFILES_ZIP_COLUMN_TITLE],
    dateUpdatedInGoogleSheets: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE]))
  );
  //NOTE: if we wanted to retrieve the utc times from google sheets and save to user profile, do the following:
  //            DateTime.parse('1969-07-20 20:18:04Z');
  //      There is no need though, since that data is stored in Firebase and available in the AppUser

  static Worksheet? _observationsWorksheet;

  // Initializing for all users so that user profile and observation data will be updated when the owner updates them, to decrease the need
  // for bulk exporting out of firebase.
  static Future init() async {
    try {
      final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
      _userProfilesWorksheet = await _getWorksheet(spreadsheet, USER_PROFILES_WORKSHEET_TITLE);
      _userProfilesWorksheet?.values.insertRow(USER_PROFILES_WORKSHEET_COLUMN_HEADERS_ROW_NUMBER, USER_PROFILES_COLUMNS);

      _observationsWorksheet = await _getWorksheet(spreadsheet, "Observations");
    } catch(e) {
      developer.log("Google Sheets init error:$e");
    }
  }

  static Future<Worksheet> _getWorksheet (Spreadsheet spreadsheet, String title) async {
    try {
      return await spreadsheet.addWorksheet(title);
    } catch (e) {
      return spreadsheet.worksheetByTitle(title)!;
    }
  }

  static Future<int> getRowCount() async {
    var lastRow = await _userProfilesWorksheet?.values.lastRow();
    return int.tryParse(lastRow?.first ?? "0") ?? 0;
  }

  static Future<AppUserProfile?> getAppUserProfile(String uid) async {
    final json = await _userProfilesWorksheet?.values.map.rowByKey(uid, fromColumn: USER_PROFILES_UID_COLUMN_NUMBER);
    return json != null ? fromGoogleSheetsJson(json) : null;
  }

  static Future<void> addOrUpdateAppUserProfile(AppUser? appUser, AppUserProfile appUserProfile) async {
    var uid = appUserProfile.uid;
    if (uid != null) {
      final index = await _userProfilesWorksheet?.values.rowIndexOf(uid, inColumn: USER_PROFILES_UID_COLUMN_NUMBER);

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

  static Future<void> addOrUpdateAppUserProfiles(List<AppUserProfile> appUserProfiles) async {
    for (var appUserProfile in appUserProfiles) {
      await addOrUpdateAppUserProfile(null, appUserProfile);
    }
  }

  static Future insertAppUserProfile(Map<String, dynamic> row) async {
    try {
      await _userProfilesWorksheet?.values.map.appendRow(row);
    } catch (e) {
      developer.log("Insert appUserProfile error:$e");
    }
  }

  static Future insertAppUserProfiles(List<Map<String, dynamic>> rowList) async {
    try {
      _userProfilesWorksheet?.values.map.appendRows(rowList);
    } catch(e) {
      developer.log("Insert appUserProfiles error:$e");
    }
  }

  static Future<List<AppUserProfile>> getAppUserProfiles() async {
    final appUserProfiles = await _userProfilesWorksheet?.values.map.allRows();
    return appUserProfiles == null ? <AppUserProfile>[] : appUserProfiles.map(fromGoogleSheetsJson).toList();
  }

  static Future<bool> updateAppUserProfile(String uid, Map<String, dynamic> appUserProfile) async {
    return await _userProfilesWorksheet?.values.map.insertRowByKey(uid, appUserProfile) ?? false;
  }

  static Future<bool> updateAppUserProfileCell(int id, String columnName, dynamic value) async {
    return await _userProfilesWorksheet?.values.insertValueByKeys(value, columnKey: columnName, rowKey: id) ?? false;
  }

  static Future<bool> deleteAppUserProfileById(int id) async {
    final index = await _userProfilesWorksheet?.values.rowIndexOf(id);
    if (index == null || index == -1) return false;
    return await _userProfilesWorksheet?.deleteRow(index) ?? false;
  }
}