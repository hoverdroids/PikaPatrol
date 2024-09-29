import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class LocalGoogleSheetsCredential extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String credential;

  @HiveField(2)
  Map<String, String> spreadsheets;

  LocalGoogleSheetsCredential({
    this.uid = "",
    this.credential = "",
    this.spreadsheets = const {}
  });
}