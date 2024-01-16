// ignore_for_file: constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseGoogleSheetsDatabaseService {

  static const GOOGLE_SHEETS_COLLECTION_NAME = "googleSheets";

  final FirebaseFirestore firebaseFirestore;
  late final CollectionReference credentialsCollection;

  FirebaseGoogleSheetsDatabaseService(this.firebaseFirestore) {
    firebaseFirestore.collection("googleSheets");
  }
}