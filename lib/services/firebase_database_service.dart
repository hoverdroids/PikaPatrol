// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/services/firebase_user_profiles_database_service.dart';

import '../model/observation.dart';

class FirebaseDatabaseService {

  String? uid;

  late final FirebaseFirestore firebaseFirestore;



  CollectionReference get userProfilesCollection {
    return userProfilesService.userProfilesCollection;
  }

  CollectionReference get observationsCollection {
    return observationsService.observationsCollection;
  }

  late final FirebaseUserProfilesDatabaseService userProfilesService;
  late final FirebaseObservationsService observationsService;

  bool useEmulators;
  late String host;

  FirebaseDatabaseService(this.useEmulators, { this.uid }){

    firebaseFirestore = FirebaseFirestore.instance;

    if (useEmulators) {
      host = Platform.isAndroid ? '10.0.2.2' : 'localhost';
      firebaseFirestore.useFirestoreEmulator(host, 8080);
      /*firebaseFirestore.settings = const Settings(
          persistenceEnabled: false
      );*/
    }

    userProfilesService = FirebaseUserProfilesDatabaseService(firebaseFirestore, uid);
    observationsService = FirebaseObservationsService(firebaseFirestore);
  }
}