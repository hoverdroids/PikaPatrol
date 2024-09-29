// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_google_sheets_credentials_collection.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_observation_collection.dart';
import 'package:pika_patrol/services/firebase/collections/firebase_user_profiles_collection.dart';

import '../../utils/constants.dart';
import 'buckets/firebase_audio_storage_bucket.dart';
import 'buckets/firebase_images_storage_bucket.dart';
import 'firebase_constants.dart';
import 'firebase_firestore_service.dart';

class AnimalObservationsFirebaseFirestoreService extends FirebaseFirestoreService {


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
  late final FirebaseUserProfilesCollection userProfilesCollection;//TODO - should this be a generic database with the specific implementation set in init?
  late final FirebaseObservationCollection observationsCollection;
  late final FirebaseGoogleSheetsCredentialCollection googleSheetsCredentialsCollection;

  late final FirebaseAudioStorageBucket audioStorageBucket;//TODO - should this be a FileHost with the specific implementation set in init?
  late final FirebaseImagesStorageBucket imagesStorageBucket;

  AnimalObservationsFirebaseFirestoreService(
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
      audioStorageBucket = FirebaseAudioStorageBucket(bucket);
      buckets[audioStorageBucket.folderName] = audioStorageBucket;

      imagesStorageBucket = FirebaseImagesStorageBucket(bucket);
      buckets[imagesStorageBucket.folderName] = imagesStorageBucket;
    }
  }
}