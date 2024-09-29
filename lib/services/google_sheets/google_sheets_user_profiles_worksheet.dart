// ignore_for_file: constant_identifier_names
import 'dart:convert';

import 'package:gsheets/gsheets.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/services/google_sheets/google_sheets_worksheet.dart';

import '../authentication/app_user.dart';
import '../user_profiles/app_user_profile.dart';
import '../../model/gsheets_value.dart';
import '../google_sheets_service.dart';

import 'dart:developer' as developer;

class GoogleSheetsUserProfilesWorksheet extends GoogleSheetsWorksheet {
   
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

  GoogleSheetsUserProfilesWorksheet(
    Spreadsheet spreadsheet,
    bool doInitHeaderRow,
    {int columnHeadersRowNumber = GoogleSheetsWorksheet.DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) : super(
    spreadsheet,
    WORKSHEET_TITLE,
    [
      GoogleSheetsWorksheet.UID_COLUMN_TITLE,
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

  Future<GoogleSheetsValueExceptionPair<AppUserProfile>> getAppUserProfile(String uid) async {
    final returnValue = await getRowByUid(uid);
    
    if (returnValue.exception != null) {
      return GoogleSheetsValueExceptionPair(null, exception: returnValue.exception);
    }
    return GoogleSheetsValueExceptionPair(returnValue.value?.toAppUserProfileFromGoogleSheetsRow());
  }

  Future<GoogleSheetsValueExceptionPair<List<AppUserProfile>>> getAppUserProfiles() async {
    final returnValue = await getAllRows();
    final value = returnValue.value ?? [];
    
    if (returnValue.exception != null) {
      return GoogleSheetsValueExceptionPair(null, exception: returnValue.exception);
    }
    
    final appUserProfiles = value.map((row) => row.toAppUserProfileFromGoogleSheetsRow()).toList();
    return GoogleSheetsValueExceptionPair(appUserProfiles);
  }

  Future<GoogleSheetsValueExceptionPair<bool>> addOrUpdateAppUserProfile(AppUser? appUser, AppUserProfile appUserProfile) async {
    Map<String, dynamic> row;
    if (appUser == null) {
      row = appUserProfile.toGoogleSheetsRowForBulkProfileExport();
    } else {
      row = appUserProfile.toGoogleSheetsRowForLoggedInUser(appUser);
    }

    return await addOrUpdateRowByUid(appUserProfile.uid, row);
  }

  Future<GoogleSheetsValueExceptionPair<bool>> addOrUpdateAppUserProfiles(List<AppUserProfile> appUserProfiles, String organization) async {
    for (var appUserProfile in appUserProfiles) {
      var returnValue = await addOrUpdateAppUserProfile(null, appUserProfile);

      if (returnValue.exception != null) {
        developer.log("Not updated ${appUserProfile.firstName} ${appUserProfile.lastName} in $organization");
        return GoogleSheetsValueExceptionPair(false, exception: returnValue.exception);
      } else {
        showToast("Updated ${appUserProfile.firstName} ${appUserProfile.lastName} in $organization");
      }

      await Future.delayed(const Duration(milliseconds: GoogleSheetsService.MORE_THAN_60_WRITES_DELAY_MS), () {});
    }
    return GoogleSheetsValueExceptionPair(true);
  }
}

extension GoogleSheetsAppUserProfileRow on Map<String, dynamic> {
  AppUserProfile toAppUserProfileFromGoogleSheetsRow() => AppUserProfile(
    this[GoogleSheetsUserProfilesWorksheet.FIRST_NAME_COLUMN_TITLE],
    this[GoogleSheetsUserProfilesWorksheet.LAST_NAME_COLUMN_TITLE],
    uid: this[GoogleSheetsWorksheet.UID_COLUMN_TITLE],
    tagline: this[GoogleSheetsUserProfilesWorksheet.TAGLINE_COLUMN_TITLE],
    pronouns: this[GoogleSheetsUserProfilesWorksheet.PRONOUNS_COLUMN_TITLE],
    organization: this[GoogleSheetsUserProfilesWorksheet.ORGANIZATION_COLUMN_TITLE],
    address: this[GoogleSheetsUserProfilesWorksheet.ADDRESS_COLUMN_TITLE],
    city: this[GoogleSheetsUserProfilesWorksheet.CITY_COLUMN_TITLE],
    state: this[GoogleSheetsUserProfilesWorksheet.STATE_COLUMN_TITLE],
    zip: this[GoogleSheetsUserProfilesWorksheet.ZIP_COLUMN_TITLE],
    dateUpdatedInGoogleSheets: DateTime.parse(jsonDecode(this[GoogleSheetsUserProfilesWorksheet.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE])),
    // creationTimestamp: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_ACCOUNT_CREATED_TITLE])), //No need; info is in AppUser
    // lastSignInTime: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_LAST_SIGNED_IN_TITLE])),     //No need; info is in Appuser
  );
}

extension GoogleSheetsAppUserProfile on AppUserProfile {
  // There is no way to get all user emails and other credentials in bulk for Firebase Client SDK
  // Consequently, those fields must be ignored when bulk exporting user profiles from Firebase to Google Sheets
  // and then updated from a server with the Admin SDK
  Map<String, dynamic> toGoogleSheetsRowForBulkProfileExport() => {
    GoogleSheetsWorksheet.UID_COLUMN_TITLE: uid,
    GoogleSheetsUserProfilesWorksheet.FIRST_NAME_COLUMN_TITLE: firstName,
    GoogleSheetsUserProfilesWorksheet.LAST_NAME_COLUMN_TITLE: lastName,
    GoogleSheetsUserProfilesWorksheet.TAGLINE_COLUMN_TITLE: tagline,
    GoogleSheetsUserProfilesWorksheet.PRONOUNS_COLUMN_TITLE: pronouns,
    GoogleSheetsUserProfilesWorksheet.ORGANIZATION_COLUMN_TITLE: organization,
    GoogleSheetsUserProfilesWorksheet.ADDRESS_COLUMN_TITLE: address,
    GoogleSheetsUserProfilesWorksheet.CITY_COLUMN_TITLE: city,
    GoogleSheetsUserProfilesWorksheet.STATE_COLUMN_TITLE: state,
    GoogleSheetsUserProfilesWorksheet.ZIP_COLUMN_TITLE: zip,
    GoogleSheetsUserProfilesWorksheet.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: dateUpdatedInGoogleSheets?.toUtc().toString()
  };

  // Since the user is logged in, their individual information is available for update
  Map<String, dynamic> toGoogleSheetsRowForLoggedInUser(AppUser appUser) => {
    GoogleSheetsWorksheet.UID_COLUMN_TITLE: uid,
    GoogleSheetsUserProfilesWorksheet.IS_ADMIN_COLUMN_TITLE: appUser.isAdmin,
    GoogleSheetsUserProfilesWorksheet.FIRST_NAME_COLUMN_TITLE: firstName,
    GoogleSheetsUserProfilesWorksheet.LAST_NAME_COLUMN_TITLE: lastName,
    GoogleSheetsUserProfilesWorksheet.EMAIL_COLUMN_TITLE: appUser.email,
    GoogleSheetsUserProfilesWorksheet.TAGLINE_COLUMN_TITLE: tagline,
    GoogleSheetsUserProfilesWorksheet.PRONOUNS_COLUMN_TITLE: pronouns,
    GoogleSheetsUserProfilesWorksheet.ORGANIZATION_COLUMN_TITLE: organization,
    GoogleSheetsUserProfilesWorksheet.ADDRESS_COLUMN_TITLE: address,
    GoogleSheetsUserProfilesWorksheet.CITY_COLUMN_TITLE: city,
    GoogleSheetsUserProfilesWorksheet.STATE_COLUMN_TITLE: state,
    GoogleSheetsUserProfilesWorksheet.ZIP_COLUMN_TITLE: zip,
    GoogleSheetsUserProfilesWorksheet.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: dateUpdatedInGoogleSheets?.toUtc().toString(),
    GoogleSheetsUserProfilesWorksheet.DATE_ACCOUNT_CREATED_TITLE: appUser.creationTimestamp?.toUtc().toString(),
    GoogleSheetsUserProfilesWorksheet.DATE_LAST_SIGNED_IN_TITLE: appUser.lastSignInTime?.toUtc().toString()
  };
}