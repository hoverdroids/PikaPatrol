import 'package:gsheets/gsheets.dart';
import 'dart:developer' as developer;
import '../model/google_sheets_user_profile.dart';

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
  static final _gsheets = GSheets(_credentials);
  static Worksheet? _userProfilesWorksheet;
  static Worksheet? _observationsWorksheet;

  static Future init() async {//TODO - CHRIS - do not init this when not an admin account; it will increase API usage without benefit
    try {
      final spreadsheet = await _gsheets.spreadsheet(_spreadsheetId);
      _userProfilesWorksheet = await _getWorksheet(spreadsheet, "User Profiles");
      final columnNamesRow = GoogleSheetsUserProfile.getColumnNames();
      _userProfilesWorksheet?.values.insertRow(1, columnNamesRow);

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
}