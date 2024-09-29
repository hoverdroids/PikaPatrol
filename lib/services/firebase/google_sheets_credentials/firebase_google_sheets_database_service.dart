// ignore_for_file: constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../provider_services/credentials/google_sheets/google_sheets_credential.dart';

class FirebaseGoogleSheetsDatabaseService {

  static const GOOGLE_SHEETS_COLLECTION_NAME = "googleSheets";

  static const String CREDENTIAL = "credential";
  static const String SPREADSHEETS = "spreadsheets";

  final FirebaseFirestore firebaseFirestore;
  late final CollectionReference credentialsCollection;

  var enabled = true;

  FirebaseGoogleSheetsDatabaseService(this.firebaseFirestore) {
    credentialsCollection = firebaseFirestore.collection(GOOGLE_SHEETS_COLLECTION_NAME);
  }

  List<GoogleSheetsCredential> _credentialsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {
      final dataMap = doc.data() as Map<String, dynamic>;

      var credential = dataMap[CREDENTIAL] ?? '';
      Map<dynamic, dynamic> spreadsheets = dataMap[SPREADSHEETS] ?? {};

      return GoogleSheetsCredential(
        credential: credential,
        spreadsheets: spreadsheets.cast()
      );
    }).toList();
  }

  Stream<List<GoogleSheetsCredential>> get credentials {
    return credentialsCollection.snapshots().map(_credentialsFromSnapshot);
  }
}