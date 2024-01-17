import 'package:hive/hive.dart';
import 'google_sheets_credential.dart';

class GoogleSheetsCredentialAdapter extends TypeAdapter<GoogleSheetsCredential> {

  @override
  int get typeId => 2;

  @override
  read(BinaryReader reader) => GoogleSheetsCredential(
    credential: reader.readString(),
    spreadsheets: reader.readMap().cast()
  );

  @override
  void write(BinaryWriter writer, GoogleSheetsCredential googleSheetsCredential) {
    writer.writeString(googleSheetsCredential.credential);
    writer.writeMap(googleSheetsCredential.spreadsheets);
  }
}