// ignore_for_file: constant_identifier_names
import 'dart:io';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:pika_patrol/services/firebase/model/firebase_value_exception_pair.dart';
import 'package:pika_patrol/model/value_exception_pair.dart';
import 'package:pika_patrol/services/firebase/utils/firebase_utils.dart';

import '../../observations/observation.dart';
import '../../../utils/date_time_utils.dart';
import 'firebase_firestore_collection.dart';

class FirebaseObservationCollection extends FirebaseFirestoreCollection {

  //region Constructors
  FirebaseObservationCollection(
    FirebaseFirestore firestore,
    {
      String name = COLLECTION_NAME,
      int limit = FirebaseFirestoreCollection.DEFAULT_LIMIT_MEDIUM,
      this.orderBy = DATE,
      this.orderByDescending = true
    }
  ) : super(firestore, name, limit: limit);
  //endregion

  //region Collection: Fields in Firebase
  static const String COLLECTION_NAME = "observations";

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
  //endregion

  //region Order/Sort
  String orderBy;
  bool orderByDescending;
  //endregion

  //region Id: Generator
  //Doesn't need FirebaseValueExceptionPair; no exceptions can be thrown.
  FirebaseValueExceptionPair<String> getNewObservationUid() {
    try {
      final returnValue = collection.doc().id;
      return FirebaseValueExceptionPair(returnValue);
    } on FirebaseException catch (e) {
      return FirebaseValueExceptionPair("", exception: e);
    }
  }
  //endregion

  //region Get
  Future<FirebaseValueExceptionPair<List<Observation>>> getAllObservations({int? limit = FirebaseFirestoreCollection.DEFAULT_LIMIT_NONE}) async {
    Query query = collection;
    return await getObservations(query, limit: limit);
  }

  Future<FirebaseValueExceptionPair<List<Observation>>> getObservations(Query query, {int? limit = FirebaseFirestoreCollection.DEFAULT_LIMIT_NONE}) async {
    //https://stackoverflow.com/questions/50870652/flutter-firebase-basic-query-or-basic-search-code
    final returnValue = FirebaseValueExceptionPair(<Observation>[]);

    try {
      await query
          .nullableLimit(limit)
          .get()
          .then((QuerySnapshot snapshot) {
        returnValue.value = snapshot.toObservations();
      }).catchError((e) {
        returnValue.exception = e;
      });
    } on FirebaseException catch (e) {
      returnValue.exception = e;
    }

    return returnValue;
  }
  //endregion

  //region Get: Stream
  //TODO - should the stream be a FirebaseValueExceptionPair?
  Stream<List<Observation>> get observationsStream {
    return collection
        .nullableLimit(limit)
        .orderBy(orderBy, descending: orderByDescending)
        .snapshots()
        .map((querySnapshot) => querySnapshot.toObservations());
  }

  //TODO - should the stream be a FirebaseValueExceptionPair?
  Stream<List<Observation>> getUserObservationsStream(String userId) {
    return collection
        .where(OBSERVER_UID, whereIn: [userId])
        .nullableLimit(limit)
        .orderBy(orderBy, descending: orderByDescending)
        .snapshots()
        .map((querySnapshot) => querySnapshot.toObservations());
  }
  //endregion

  //region Create/Update
  Future<FirebaseValueExceptionPair<bool>> createObservation(Observation observation) async {
    return FirebaseValueExceptionPair(false);
    /*//Assume a successful upload unless an exception is thrown
    //This allows firebase to be up-to-date with only one write
    observation.isUploaded = true;

    var firebaseObservation = observation.toFirebaseObservation();

    DocumentReference doc = collection.doc();
    observation.uid = doc.id;

    try {
      // Calling set when a doc with the Id doesn't exist will create it.
      // If the doc exists, it will be updated
      await doc.set(firebaseObservation);
    } on FirebaseException catch (e) {
      if (isUidNullOrEmpty) {
        // Need to reset or the local observation will appear to have been uploaded with a valid ID, that is actually non existent
        observation.uid = null;
      }

      observation.isUploaded = false;

      return e;
    }
    return null;*/
  }

  Future<FirebaseValueExceptionPair<bool>> updateObservation(Observation observation) async {
    return FirebaseValueExceptionPair(false);
    /*//Assume a successful upload unless an exception is thrown
    //This allows firebase to be up-to-date with only one write
    observation.isUploaded = true;

    var firebaseObservation = observation.toFirebaseObservation();

    DocumentReference doc;
    var isUidNullOrEmpty = observation.uid == null || observation.uid?.isEmpty == true;
    if (isUidNullOrEmpty) {
      doc = collection.doc();
      observation.uid = doc.id;
    } else {
      doc = collection.doc(observation.uid);
    }

    try {
      // Calling set when a doc with the Id doesn't exist will create it.
      // If the doc exists, it will be updated
      await doc.set(firebaseObservation);
    } on FirebaseException catch (e) {
      if (isUidNullOrEmpty) {
        // Need to reset or the local observation will appear to have been uploaded with a valid ID, that is actually non existent
        observation.uid = null;
      }

      observation.isUploaded = false;

      return e;
    }
    return null;*/
  }
  //endregion

  //region Delete
  Future<FirebaseValueExceptionPair<bool>> deleteObservation(Observation observation) async {
    final returnValue = FirebaseValueExceptionPair(true);

    final docUid = observation.uid ?? "";
    if (docUid.isNotEmpty) {
      try {

        //Observations.doc.delete does not return when offline and doesn't throw an offline exception;
        //it just hangs until it goes back online, even though the doc delete is queued up and will take affect after going online
        //So, need to timeout so that the process can continue
        //https://stackoverflow.com/questions/52672137/await-future-for-a-specific-time
        await Future.value(collection.doc(docUid).delete())
            .timeout(const Duration(seconds: 3), onTimeout: () => throw createFirebaseNetworkException());

      } on FirebaseException catch (e) {
        //still return true since we know delete will eventually be applied based on Firebase's docs
        returnValue.exception = e;
      }
    }

    return returnValue;
  }
  //endregion
}

//region Extensions
extension FirebaseObservationCollectionObservationExtensions on Observation {
  Map<String, dynamic> toFirebaseObservation() => {
    FirebaseObservationCollection.OBSERVER_UID: observerUid,
    FirebaseObservationCollection.NAME: name,
    FirebaseObservationCollection.LOCATION: location,
    FirebaseObservationCollection.DATE: date,
    FirebaseObservationCollection.ALTITUDE: altitudeInMeters,
    FirebaseObservationCollection.LATITUDE: latitude,
    FirebaseObservationCollection.LONGITUDE: longitude,
    FirebaseObservationCollection.SPECIES: species,
    FirebaseObservationCollection.SIGNS: signs,
    FirebaseObservationCollection.PIKAS_DETECTED: pikasDetected,
    FirebaseObservationCollection.DISTANCE_TO_CLOSEST_PIKA: distanceToClosestPika,
    FirebaseObservationCollection.SEARCH_DURATION: searchDuration,
    FirebaseObservationCollection.TALUS_AREA: talusArea,
    FirebaseObservationCollection.TEMPERATURE: temperature,
    FirebaseObservationCollection.SKIES: skies,
    FirebaseObservationCollection.WIND: wind,
    FirebaseObservationCollection.SITE_HISTORY: siteHistory,
    FirebaseObservationCollection.COMMENTS: comments,
    FirebaseObservationCollection.IMAGE_URLS: imageUrls,
    FirebaseObservationCollection.AUDIO_URLS: audioUrls,
    FirebaseObservationCollection.OTHER_ANIMALS_PRESENT: otherAnimalsPresent,
    FirebaseObservationCollection.SHARED_WITH_PROJECTS: sharedWithProjects,
    FirebaseObservationCollection.NOT_SHARED_WITH_PROJECTS: notSharedWithProjects,
    FirebaseObservationCollection.DATE_UPDATED_IN_GOOGLE_SHEETS: dateUpdatedInGoogleSheets,
    FirebaseObservationCollection.IS_UPLOADED: isUploaded
  };
}

extension FirebaseObservationCollectionQuerySnapshotExtensions on QuerySnapshot {
  List<Observation> toObservations() {
    return docs.map((doc) {

      final dataMap = doc.data() as Map<String, dynamic>;

      List<dynamic>? data = dataMap[FirebaseObservationCollection.SIGNS];
      List<String> signs = data == null || data.isEmpty ? <String>[] : data.cast<String>().toList();
      
      data = dataMap[FirebaseObservationCollection.OTHER_ANIMALS_PRESENT];
      List<String> otherAnimalsPresent = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap[FirebaseObservationCollection.IMAGE_URLS];
      List<String> imageUrls = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap[FirebaseObservationCollection.AUDIO_URLS];
      List<String> audioUrls = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap[FirebaseObservationCollection.SHARED_WITH_PROJECTS];
      List<String> sharedWithProjects = data == null || data.isEmpty ? <String>[]: data.cast<String>().toList();

      data = dataMap[FirebaseObservationCollection.NOT_SHARED_WITH_PROJECTS];
      List<String> notSharedWithProjects = data == null || data.isEmpty ? <String>[]: data.cast<String>().toList();

      return Observation(
          uid: doc.id,
          observerUid: dataMap[FirebaseObservationCollection.OBSERVER_UID] ?? '',
          name: dataMap[FirebaseObservationCollection.NAME] ?? '',
          location: dataMap[FirebaseObservationCollection.LOCATION] ?? '',
          date: parseTime(dataMap[FirebaseObservationCollection.DATE]),
          altitudeInMeters: dataMap[FirebaseObservationCollection.ALTITUDE],
          latitude: dataMap[FirebaseObservationCollection.LATITUDE],
          longitude: dataMap[FirebaseObservationCollection.LONGITUDE],
          signs: signs,
          species: dataMap[FirebaseObservationCollection.SPECIES] ?? Observation.SPECIES_DEFAULT,
          pikasDetected: dataMap[FirebaseObservationCollection.PIKAS_DETECTED] ?? '',
          distanceToClosestPika: dataMap[FirebaseObservationCollection.DISTANCE_TO_CLOSEST_PIKA] ?? '',
          searchDuration: dataMap[FirebaseObservationCollection.SEARCH_DURATION] ?? '',
          talusArea: dataMap[FirebaseObservationCollection.TALUS_AREA] ?? '',
          temperature: dataMap[FirebaseObservationCollection.TEMPERATURE] ?? '',
          skies: dataMap[FirebaseObservationCollection.SKIES] ?? '',
          wind: dataMap[FirebaseObservationCollection.WIND] ?? '',
          siteHistory: dataMap[FirebaseObservationCollection.SITE_HISTORY] ?? '',
          otherAnimalsPresent: otherAnimalsPresent,
          comments: dataMap[FirebaseObservationCollection.COMMENTS] ?? '',
          imageUrls: imageUrls,
          audioUrls: audioUrls,
          sharedWithProjects: sharedWithProjects,
          notSharedWithProjects: notSharedWithProjects,
          dateUpdatedInGoogleSheets: parseTime(dataMap[FirebaseObservationCollection.DATE_UPDATED_IN_GOOGLE_SHEETS]),
          isUploaded: dataMap[FirebaseObservationCollection.IS_UPLOADED] ?? true
      );
    }).toList();
  }
}
//endregion