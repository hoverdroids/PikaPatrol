// ignore_for_file: constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

import '../data/pika_species.dart';
import '../model/observation.dart';
import '../utils/date_time_utils.dart';
import '../utils/observation_utils.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';

class FirebaseObservationsService {

  static const String STORAGE_BUCKET_NAME = "pikajoe-97c5c.appspot.com";
  static const String STORAGE_BUCKET_URL = "gs://$STORAGE_BUCKET_NAME";
  static const String IMAGES_FOLDER_NAME = "images";
  static const String AUDIO_FOLDER_NAME = "audio";

  static const String OBSERVATIONS_COLLECTION_NAME = "observations";

  static const String OBSERVER_UID = "observerUid";
  static const String NAME = "name";
  static const String LOCATION = "location";
  static const String DATE = "date";
  static const String ALTITUDE = "altitude";
  static const String LATITUDE = "latitude";
  static const String LONGITUDE = "longitude";
  static const String SPECIES = "species";
  static const String SIGNS = "signs";
  static const String PIKAS_DETECTED = "pikasDetected";
  static const String DISTANCE_TO_CLOSEST_PIKA = "distanceToClosestPika";
  static const String SEARCH_DURATION = "searchDuration";
  static const String TALUS_AREA = "talusArea";
  static const String TEMPERATURE = "temperature";
  static const String SKIES = "skies";
  static const String WIND = "wind";
  static const String SITE_HISTORY = "siteHistory";
  static const String COMMENTS = "comments";
  static const String IMAGE_URLS = "imageUrls";
  static const String AUDIO_URLS = "audioUrls";
  static const String OTHER_ANIMALS_PRESENT = "otherAnimalsPresent";
  static const String SHARED_WITH_PROJECTS = "sharedWithProjects";
  static const String NOT_SHARED_WITH_PROJECTS = "notSharedWithProjects";
  static const String DATE_UPDATED_IN_GOOGLE_SHEETS = "dateUpdatedInGoogleSheets";
  static const String IS_UPLOADED = "isUploaded";

  final FirebaseFirestore firebaseFirestore;
  late final CollectionReference observationsCollection;

  FirebaseObservationsService(this.firebaseFirestore) {
    observationsCollection = firebaseFirestore.collection(OBSERVATIONS_COLLECTION_NAME);
  }

  Future<FirebaseException?> updateObservation(Observation observation) async {
    //TODO - determine if there are any images that were uploaded and associated with this observation that are no longer associated; delete them from the database

    var observationObject = {
      OBSERVER_UID: observation.observerUid,
      NAME: observation.name,
      LOCATION: observation.location,
      DATE: observation.date,
      ALTITUDE: observation.altitudeInMeters,
      LATITUDE: observation.latitude,
      LONGITUDE: observation.longitude,
      SPECIES: observation.species,
      SIGNS: observation.signs,
      PIKAS_DETECTED: observation.pikasDetected,
      DISTANCE_TO_CLOSEST_PIKA: observation.distanceToClosestPika,
      SEARCH_DURATION: observation.searchDuration,
      TALUS_AREA: observation.talusArea,
      TEMPERATURE: observation.temperature,
      SKIES: observation.skies,
      WIND: observation.wind,
      SITE_HISTORY: observation.siteHistory,
      COMMENTS: observation.comments,
      IMAGE_URLS: observation.imageUrls,
      AUDIO_URLS: observation.audioUrls,
      OTHER_ANIMALS_PRESENT: observation.otherAnimalsPresent,
      SHARED_WITH_PROJECTS: observation.sharedWithProjects,
      NOT_SHARED_WITH_PROJECTS: observation.notSharedWithProjects,
      DATE_UPDATED_IN_GOOGLE_SHEETS: observation.dateUpdatedInGoogleSheets,
      IS_UPLOADED: observation.isUploaded
    };

    DocumentReference doc;
    var isUidNullOrEmpty = observation.uid == null || observation.uid?.isEmpty == true;
    if (isUidNullOrEmpty) {
      doc = observationsCollection.doc();
      observation.uid = doc.id;
    } else {
      doc = observationsCollection.doc(observation.uid);
    }

    try {
      // Calling set when a doc with the Id doesn't exist will create it.
      // If the doc exists, it will be updated
      await doc.set(observationObject);
    } on FirebaseException catch (e) {
      if (isUidNullOrEmpty) {
        // Need to reset or the local observation will appear to have been uploaded with a valid ID, that is actually non existent
        observation.uid = null;
      }

      return e;
    }
    return null;
  }

  Future<FirebaseException?> deleteObservation(Observation observation, bool deleteImages, bool deleteAudio) async {
    var exception = deleteImages ? await deleteFiles(IMAGES_FOLDER_NAME, observation.imageUrls) : null;
    if (exception != null) {
      return exception;
    }

    exception = deleteAudio ? await deleteFiles(AUDIO_FOLDER_NAME, observation.audioUrls) : null;
    if (exception != null) {
      return exception;
    }

    var docUid = observation.uid;
    if (docUid?.isNotEmpty == true) {
      try {
        await observationsCollection.doc(docUid).delete();
      } on FirebaseException catch (e) {
        return e;
      }
    }

    return null;
  }

  List<Observation> _observationsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {

      final dataMap = doc.data() as Map<String, dynamic>;

      List<dynamic>? data = dataMap[SIGNS];
      List<String> signs = data == null || data.isEmpty ? <String>[] : data.cast<String>().toList();

      data = dataMap[OTHER_ANIMALS_PRESENT];
      List<String> otherAnimalsPresent = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap[IMAGE_URLS];
      List<String> imageUrls = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap[AUDIO_URLS];
      List<String> audioUrls = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap[SHARED_WITH_PROJECTS];
      List<String> sharedWithProjects = data == null || data.isEmpty ? <String>[]: data.cast<String>().toList();

      data = dataMap[NOT_SHARED_WITH_PROJECTS];
      List<String> notSharedWithProjects = data == null || data.isEmpty ? <String>[]: data.cast<String>().toList();

      return Observation(
          uid: doc.id,
          observerUid: dataMap[OBSERVER_UID] ?? '',
          name: dataMap[NAME] ?? '',
          location: dataMap[LOCATION] ?? '',
          date: parseTime(dataMap[DATE]),
          altitudeInMeters: dataMap[ALTITUDE],
          latitude: dataMap[LATITUDE],
          longitude: dataMap[LONGITUDE],
          signs: signs,
          species: dataMap[SPECIES] ?? SPECIES_DEFAULT,
          pikasDetected: dataMap[PIKAS_DETECTED] ?? '',
          distanceToClosestPika: dataMap[DISTANCE_TO_CLOSEST_PIKA] ?? '',
          searchDuration: dataMap[SEARCH_DURATION] ?? '',
          talusArea: dataMap[TALUS_AREA] ?? '',
          temperature: dataMap[TEMPERATURE] ?? '',
          skies: dataMap[SKIES] ?? '',
          wind: dataMap[WIND] ?? '',
          siteHistory: dataMap[SITE_HISTORY] ?? '',
          otherAnimalsPresent: otherAnimalsPresent,
          comments: dataMap[COMMENTS] ?? '',
          imageUrls: imageUrls,
          audioUrls: audioUrls,
          sharedWithProjects: sharedWithProjects,
          notSharedWithProjects: notSharedWithProjects,
          dateUpdatedInGoogleSheets: parseTime(dataMap[DATE_UPDATED_IN_GOOGLE_SHEETS]),
          isUploaded: dataMap[IS_UPLOADED] ?? true

      );
    }).toList();
  }

  Stream<List<Observation>> get observations {
    return observationsCollection.orderBy(DATE, descending: true).limit(5).snapshots().map(_observationsFromSnapshot);
  }

  Future<List<String>> uploadFiles(List<String> filepaths, bool areImages) async {
    List<String> uploadUrls = [];

    await Future.wait(filepaths.map((String filepath) async {
      //TODO - base on mime
      /*String mimeStr = lookupMimeType(filepath);
      var fileType = mimeStr.split('/');
      developer.log('file type ${fileType}');*/
      var folder = areImages ? IMAGES_FOLDER_NAME : AUDIO_FOLDER_NAME;
      if(filepath.contains(STORAGE_BUCKET_NAME)) {
        //Do not try to upload an image that has already been uploaded
        uploadUrls.add(filepath);
      } else {
        try {
          FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: STORAGE_BUCKET_URL);
          UploadTask uploadTask = storage.ref().child("$folder/${basename(filepath)}").putFile(File(filepath));

          var snapshot = await uploadTask;

          var storageTaskSnapshot = snapshot;
          final String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
          uploadUrls.add(downloadUrl);
        } on FirebaseException catch (e) {
          throw ('This file is not an image');
        }
      }
    }), eagerError: true, cleanUp: (_) {});

    return uploadUrls;
  }

  Future<FirebaseException?> deleteFiles(String folderName, List<String>? fileUrls) async {
    if (fileUrls == null || fileUrls.isEmpty) return null;

    try {
      FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: STORAGE_BUCKET_URL);
      for (var fileUrl in fileUrls) {
          await storage.refFromURL(fileUrl).delete();// .ref().child("$folderName/${basename(fileUrl)}").delete();
      }
    } on FirebaseException catch(e) {
      return e;
    }

    return null;
  }

  Future<List<Observation>> getAllObservations({int? limit}) async {
    Query query = observationsCollection;
    return await getObservations(query, limit: limit);
  }

  Future<List<Observation>> getObservations(Query query, {int? limit}) async {
    //https://stackoverflow.com/questions/50870652/flutter-firebase-basic-query-or-basic-search-code

    if (limit != null) {
      query = query.limit(limit);
    }

    var observations = <Observation>[];
    await query
        .get()
        .then((QuerySnapshot snapshot){
      observations = _observationsFromSnapshot(snapshot);
    }).catchError((e){
      developer.log("Observations query error:$e");
    });

    return observations;
  }
}