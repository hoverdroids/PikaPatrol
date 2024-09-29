import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class GoogleSheetsCredential extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String credential;

  @HiveField(2)
  Map<String, String> spreadsheets;

  GoogleSheetsCredential({
    this.uid = "",
    this.credential = "",
    this.spreadsheets = const {}
  });
}