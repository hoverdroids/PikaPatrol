import 'package:hive/hive.dart';
import 'local_google_sheets_credential.dart';

class GoogleSheetsCredentialAdapter extends TypeAdapter<LocalGoogleSheetsCredential> {

  @override
  int get typeId => 2;

  @override
  read(BinaryReader reader) => LocalGoogleSheetsCredential(
    credential: reader.readString(),
    spreadsheets: reader.readMap().cast()
  );

  @override
  void write(BinaryWriter writer, LocalGoogleSheetsCredential localGoogleSheetsCredential) {
    writer.writeString(localGoogleSheetsCredential.credential);
    writer.writeMap(localGoogleSheetsCredential.spreadsheets);
  }
}