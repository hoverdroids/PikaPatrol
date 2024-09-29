// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_patrol/services/firebase/google_sheets_credentials/firebase_google_sheets_database_service.dart';
import 'package:pika_patrol/services/firebase/observations/firebase_observations_service.dart';
import 'package:pika_patrol/services/firebase/user_profiles/firebase_user_profiles_database_service.dart';

class FirebaseDatabaseService {

  String? _uid;

  String? get uid => _uid;

  set uid(String? value){
    _uid = value;
    userProfilesService.uid = value;
  }

  late final FirebaseFirestore firebaseFirestore;

  CollectionReference get userProfilesCollection {
    return userProfilesService.userProfilesCollection;
  }

  CollectionReference get observationsCollection {
    return observationsService.observationsCollection;
  }

  CollectionReference get googleSheetsCredentialsCollection {
    return googleSheetsService.credentialsCollection;
  }

  late final FirebaseUserProfilesDatabaseService userProfilesService;
  late final FirebaseObservationsService observationsService;
  late final FirebaseGoogleSheetsDatabaseService googleSheetsService;

  bool useEmulators;
  late String host;

  FirebaseDatabaseService(this.useEmulators, {String? uid}){

    firebaseFirestore = FirebaseFirestore.instance;

    if (useEmulators) {
      host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      firebaseFirestore.useFirestoreEmulator(host, 8080);
      /*firebaseFirestore.settings = const Settings(
          persistenceEnabled: false
      );*/
    }
    _uid = uid;
    userProfilesService = FirebaseUserProfilesDatabaseService(firebaseFirestore, uid);
    observationsService = FirebaseObservationsService(firebaseFirestore);
    googleSheetsService = FirebaseGoogleSheetsDatabaseService(firebaseFirestore);
  }
}