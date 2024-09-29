// ignore_for_file: constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_patrol/services/firebase/firebase_firestore_service.dart';

import '../../../model/google_sheets_credential.dart';
import 'firebase_firestore_collection.dart';

class FirebaseGoogleSheetsCredentialCollection extends FirebaseFirestoreCollection {

  static const COLLECTION_NAME = "googleSheets";

  static const String CREDENTIAL = "credential";
  static const String SPREADSHEETS = "spreadsheets";

  var enabled = true;

  //region Constructor
  FirebaseGoogleSheetsCredentialCollection(
    FirebaseFirestore firestore,
    {
      String name = COLLECTION_NAME,
      super.limit = FirebaseFirestoreCollection.DEFAULT_LIMIT_NONE
    }
  ) : super(firestore, name);
  //endregion


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