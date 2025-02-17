// ignore_for_file: constant_identifier_names
import 'dart:convert';

import 'package:gsheets/gsheets.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/services/worksheet_service.dart';

import '../model/app_user.dart';
import '../model/app_user_profile.dart';
import '../model/gsheets_value.dart';
import 'google_sheets_service.dart';

import 'dart:developer' as developer;

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

  Future<GSheetsValue<AppUserProfile>> getAppUserProfile(String uid) async {
    final returnValue = await getRowByUid(uid);

    if (returnValue.exception != null) {
      return GSheetsValue(null, exception: returnValue.exception);
    }
    return GSheetsValue(returnValue.value?.toAppUserProfileFromGoogleSheetsRow());
  }

  Future<GSheetsValue<List<AppUserProfile>>> getAppUserProfiles() async {
    final returnValue = await getAllRows();
    final value = returnValue.value ?? [];

    if (returnValue.exception != null) {
      return GSheetsValue(null, exception: returnValue.exception);
    }

    final appUserProfiles = value.map((row) => row.toAppUserProfileFromGoogleSheetsRow()).toList();
    return GSheetsValue(appUserProfiles);
  }

  Future<GSheetsValue<bool>> addOrUpdateAppUserProfile(AppUser? appUser, AppUserProfile appUserProfile) async {
    Map<String, dynamic> row;
    if (appUser == null) {
      row = appUserProfile.toGoogleSheetsRowForBulkProfileExport();
    } else {
      row = appUserProfile.toGoogleSheetsRowForLoggedInUser(appUser);
    }

    return await addOrUpdateRowByUid(appUserProfile.uid, row);
  }

  Future<GSheetsValue<bool>> addOrUpdateAppUserProfiles(List<AppUserProfile> appUserProfiles, String organization) async {
    for (var appUserProfile in appUserProfiles) {
      var returnValue = await addOrUpdateAppUserProfile(null, appUserProfile);

      if (returnValue.exception != null) {
        developer.log("Not updated ${appUserProfile.firstName} ${appUserProfile.lastName} in $organization");
        return GSheetsValue(false, exception: returnValue.exception);
      } else {
        showToast("Updated ${appUserProfile.firstName} ${appUserProfile.lastName} in $organization");
      }

      await Future.delayed(const Duration(milliseconds: GoogleSheetsService.MORE_THAN_60_WRITES_DELAY_MS), () {});
    }
    return GSheetsValue(true);
  }
}

extension GoogleSheetsAppUserProfileRow on Map<String, dynamic> {
  AppUserProfile toAppUserProfileFromGoogleSheetsRow() => AppUserProfile(
    this[UserProfilesWorksheetService.FIRST_NAME_COLUMN_TITLE],
    this[UserProfilesWorksheetService.LAST_NAME_COLUMN_TITLE],
    uid: this[WorksheetService.UID_COLUMN_TITLE],
    tagline: this[UserProfilesWorksheetService.TAGLINE_COLUMN_TITLE],
    pronouns: this[UserProfilesWorksheetService.PRONOUNS_COLUMN_TITLE],
    organization: this[UserProfilesWorksheetService.ORGANIZATION_COLUMN_TITLE],
    address: this[UserProfilesWorksheetService.ADDRESS_COLUMN_TITLE],
    city: this[UserProfilesWorksheetService.CITY_COLUMN_TITLE],
    state: this[UserProfilesWorksheetService.STATE_COLUMN_TITLE],
    zip: this[UserProfilesWorksheetService.ZIP_COLUMN_TITLE],
    dateUpdatedInGoogleSheets: DateTime.parse(jsonDecode(this[UserProfilesWorksheetService.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE])),
    // creationTimestamp: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_ACCOUNT_CREATED_TITLE])), //No need; info is in AppUser
    // lastSignInTime: DateTime.parse(jsonDecode(json[USER_PROFILES_DATE_LAST_SIGNED_IN_TITLE])),     //No need; info is in Appuser
  );
}

extension GoogleSheetsAppUserProfile on AppUserProfile {
  // There is no way to get all user emails and other credentials in bulk for Firebase Client SDK
  // Consequently, those fields must be ignored when bulk exporting user profiles from Firebase to Google Sheets
  // and then updated from a server with the Admin SDK
  Map<String, dynamic> toGoogleSheetsRowForBulkProfileExport() =>
  {
    WorksheetService.UID_COLUMN_TITLE: uid,
    UserProfilesWorksheetService.FIRST_NAME_COLUMN_TITLE: firstName,
    UserProfilesWorksheetService.LAST_NAME_COLUMN_TITLE: lastName,
    UserProfilesWorksheetService.TAGLINE_COLUMN_TITLE: tagline,
    UserProfilesWorksheetService.PRONOUNS_COLUMN_TITLE: pronouns,
    UserProfilesWorksheetService.ORGANIZATION_COLUMN_TITLE: organization,
    UserProfilesWorksheetService.ADDRESS_COLUMN_TITLE: address,
    UserProfilesWorksheetService.CITY_COLUMN_TITLE: city,
    UserProfilesWorksheetService.STATE_COLUMN_TITLE: state,
    UserProfilesWorksheetService.ZIP_COLUMN_TITLE: zip,
    UserProfilesWorksheetService.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: dateUpdatedInGoogleSheets?.toUtc().toString()
  };

  // Since the user is logged in, their individual information is available for update
  Map<String, dynamic> toGoogleSheetsRowForLoggedInUser(AppUser appUser) =>
  {
    WorksheetService.UID_COLUMN_TITLE: uid,
    UserProfilesWorksheetService.IS_ADMIN_COLUMN_TITLE: appUser.isAdmin,
    UserProfilesWorksheetService.FIRST_NAME_COLUMN_TITLE: firstName,
    UserProfilesWorksheetService.LAST_NAME_COLUMN_TITLE: lastName,
    UserProfilesWorksheetService.EMAIL_COLUMN_TITLE: appUser.email,
    UserProfilesWorksheetService.TAGLINE_COLUMN_TITLE: tagline,
    UserProfilesWorksheetService.PRONOUNS_COLUMN_TITLE: pronouns,
    UserProfilesWorksheetService.ORGANIZATION_COLUMN_TITLE: organization,
    UserProfilesWorksheetService.ADDRESS_COLUMN_TITLE: address,
    UserProfilesWorksheetService.CITY_COLUMN_TITLE: city,
    UserProfilesWorksheetService.STATE_COLUMN_TITLE: state,
    UserProfilesWorksheetService.ZIP_COLUMN_TITLE: zip,
    UserProfilesWorksheetService.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: dateUpdatedInGoogleSheets?.toUtc().toString(),
    UserProfilesWorksheetService.DATE_ACCOUNT_CREATED_TITLE: appUser.creationTimestamp?.toUtc().toString(),
    UserProfilesWorksheetService.DATE_LAST_SIGNED_IN_TITLE: appUser.lastSignInTime?.toUtc().toString()
  };
}