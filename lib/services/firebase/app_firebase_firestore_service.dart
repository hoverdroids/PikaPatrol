// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_google_sheets_credentials_collection.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_observation_collection.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_user_profiles_collection.dart';

import '../../providers/filehost/file_host.dart';
import '../../utils/constants.dart';
import 'buckets/firebase_audio_storage_bucket.dart';
import 'buckets/firebase_images_storage_bucket.dart';
import 'firebase_constants.dart';
import 'firebase_firestore_service.dart';

//TODO - this should aggregate all the filehosts and dbs in one place for the app
// It should be useful regardless of choice of db or file host
class AppFirebaseFirestoreService extends FirebaseFirestoreService {


  /*
  TODO - does this just belong in UserProfileService?
  String? _currentUserId;
  String? get currentUserId => _currentUserId;

  set currentUserId(String? value){
    _currentUserId = value;
    userProfilesCollection.currentUserId = value;
  }*/



  /*CollectionReference get userProfilesCollection {
    return userProfilesService.userProfilesCollection;
  }

  CollectionReference get observationsCollection {
    return observationsService.observationsCollection;
  }

  CollectionReference get googleSheetsCredentialsCollection {
    return googleSheetsService.credentialsCollection;
  }*/


  //TODO - CHRIS - should these be available to caller or should there be an interface that abstracts how the service is doing it?
  //TODO - this collection is providing Profiles
  late final FirebaseUserProfilesCollection userProfilesCollection;//TODO - should this be a generic database with the specific implementation set in init?
  //TODO - this collection is providing Observations
  late final FirebaseObservationCollection observationsCollection;
  //TODO - this collection is providing GoogleSheetsCredentials
  late final FirebaseGoogleSheetsCredentialCollection googleSheetsCredentialsCollection;


  late final FileHost audioFileHost;
  late final FileHost imagesFileHost;

  AppFirebaseFirestoreService(
    {
      super.firebaseFirestore,
      String? bucket,
      super.useEmulator = false,
      super.emulatorHostnameOrIpAddress = Constants.LOCALHOST,
      super.emulatorPort = FirebaseConstants.EMULATOR_PORT_FIRESTORE,
      super.persistenceEnabled = true,
      super.sslEnabled = false,
      String? currentUserId
    }
  ) {
    _currentUserId = currentUserId;

    userProfilesCollection = FirebaseUserProfilesCollection(super.firebaseFirestore, currentUserId);
    collections[userProfilesCollection.name] = userProfilesCollection;

    observationsCollection = FirebaseObservationCollection(super.firebaseFirestore);
    collections[observationsCollection.name] = observationsCollection;

    googleSheetsCredentialsCollection = FirebaseGoogleSheetsCredentialCollection(super.firebaseFirestore);
    collections[googleSheetsCredentialsCollection.name] = googleSheetsCredentialsCollection;

    if (bucket != null) {
      final audioStorageBucket = FirebaseAudioStorageBucket(bucket);
      audioFileHost = audioStorageBucket;
      buckets[audioFileHost.name] = audioStorageBucket;

      final imagesStorageBucket = FirebaseImagesStorageBucket(bucket);
      imagesFileHost = imagesFileHost;
      buckets[imagesFileHost.name] = imagesStorageBucket;
    }
  }
}