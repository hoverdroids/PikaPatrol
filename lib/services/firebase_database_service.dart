// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_patrol/services/firebase_google_sheets_database_service.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/services/firebase_user_profiles_database_service.dart';

class FirebaseDatabaseService {

  String? _currentUserId;

  String? get currentUserId => _currentUserId;

  set currentUserId(String? value){
    _currentUserId = value;
    userProfilesService.currentUserId = value;
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

  FirebaseDatabaseService(this.useEmulators, {String? currentUserId}){

    firebaseFirestore = FirebaseFirestore.instance;

    if (useEmulators) {
      host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      firebaseFirestore.useFirestoreEmulator(host, 8080);
      /*firebaseFirestore.settings = const Settings(
          persistenceEnabled: false
      );*/
    }
    _currentUserId = currentUserId;
    userProfilesService = FirebaseUserProfilesDatabaseService(firebaseFirestore, currentUserId);
    observationsService = FirebaseObservationsService(firebaseFirestore);
    googleSheetsService = FirebaseGoogleSheetsDatabaseService(firebaseFirestore);
  }
}