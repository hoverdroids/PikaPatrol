import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

import '../data/pika_species.dart';
import '../model/observation.dart';
import '../utils/observation_utils.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart';

class FirebaseObservationsService {

  final FirebaseFirestore firebaseFirestore;
  late final CollectionReference observationsCollection;

  FirebaseObservationsService(this.firebaseFirestore) {
    observationsCollection = firebaseFirestore.collection("observations");
  }

  Future updateObservation(Observation observation) async {
    //TODO - determine if there are any images that were uploaded and associated with this observation that are no longer associated; delete them from the database

    var observationObject = {
      'observerUid': observation.observerUid,
      'name': observation.name,
      'location': observation.location,
      'date': observation.date,
      'altitude': observation.altitudeInMeters,
      'latitude': observation.latitude,
      'longitude': observation.longitude,
      'species': observation.species,
      'signs': observation.signs,
      'pikasDetected': observation.pikasDetected,
      'distanceToClosestPika': observation.distanceToClosestPika,
      'searchDuration': observation.searchDuration,
      'talusArea': observation.talusArea,
      'temperature': observation.temperature,
      'skies': observation.skies,
      'wind': observation.wind,
      'siteHistory': observation.siteHistory,
      'comments': observation.comments,
      'imageUrls': observation.imageUrls,
      'audioUrls': observation.audioUrls,
      'otherAnimalsPresent': observation.otherAnimalsPresent,
      'sharedWithProjects': observation.sharedWithProjects
    };
    DocumentReference doc;
    if (observation.uid == null || observation.uid?.isEmpty == true) {
      doc = observationsCollection.doc();
      observation.uid = doc.id;
      try {
        await doc.set(observationObject);
      } catch (e) {
        developer.log("Firebase doc.set error:$e");
      }
    } else {
      doc = observationsCollection.doc(observation.uid);
      try {
        await doc.update(observationObject);
      } catch(e) {
        developer.log("Firebase doc.update error:$e");
      }
    }

    developer.log("Update Observation id:${observation.uid}");
  }

  List<Observation> _observationsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {

      final dataMap = doc.data() as Map<String, dynamic>;

      List<dynamic>? data = dataMap['signs'];
      List<String> signs = data == null || data.isEmpty ? <String>[] : data.cast<String>().toList();

      data = dataMap['otherAnimalsPresent'];
      List<String> otherAnimalsPresent = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap['imageUrls'];
      List<String> imageUrls = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap['audioUrls'];
      List<String> audioUrls = data == null || data.isEmpty ? <String>[] :  data.cast<String>().toList();

      data = dataMap['sharedWithProjects'];
      List<String> sharedWithProjects = data == null || data.isEmpty ? PikaData.SHARED_WITH_PROJECTS_DEFAULT : data.cast<String>().toList();

      return Observation(
          uid: doc.id,
          observerUid: dataMap['observerUid'] ?? '',
          name: dataMap['name'] ?? '',
          location: dataMap['location'] ?? '',
          date: DateTime.fromMillisecondsSinceEpoch(dataMap['date']?.millisecondsSinceEpoch),//// parseTime(dataMap['dateUpdatedInGoogleSheets'])//TODO - CHRIS - verify this works in Android and then check other timestamps/dates
          altitudeInMeters: dataMap['altitude'],
          latitude: dataMap['latitude'],
          longitude: dataMap['longitude'],
          signs: signs,
          species: dataMap['species'] ?? SPECIES_DEFAULT,
          pikasDetected: dataMap['pikasDetected'] ?? '',
          distanceToClosestPika: dataMap['distanceToClosestPika'] ?? '',
          searchDuration: dataMap['searchDuration'] ?? '',
          talusArea: dataMap['talusArea'] ?? '',
          temperature: dataMap['temperature'] ?? '',
          skies: dataMap['skies'] ?? '',
          wind: dataMap['wind'] ?? '',
          siteHistory: dataMap['siteHistory'] ?? '',
          otherAnimalsPresent: otherAnimalsPresent,
          comments: dataMap['comments'] ?? '',
          imageUrls: imageUrls,
          audioUrls: audioUrls,
          sharedWithProjects: sharedWithProjects
      );
    }).toList();
  }

  Stream<List<Observation>> get observations {
    return observationsCollection.orderBy('date', descending: true).limit(5).snapshots().map(_observationsFromSnapshot);
  }

  Future<List<String>> uploadFiles(List<String> filepaths, bool areImages) async {
    List<String> uploadUrls = [];

    await Future.wait(filepaths.map((String filepath) async {
      //TODO - base on mime
      /*String mimeStr = lookupMimeType(filepath);
      var fileType = mimeStr.split('/');
      developer.log('file type ${fileType}');*/
      var folder = areImages ? "images" : "audio";
      if(filepath.contains('pikajoe-97c5c.appspot.com')) {
        //Do not try to upload an image that has already been uploaded
        uploadUrls.add(filepath);
      } else {
        FirebaseStorage storage = FirebaseStorage.instanceFor(bucket: 'gs://pikajoe-97c5c.appspot.com');
        UploadTask uploadTask = storage.ref().child("$folder/${basename(filepath)}").putFile(File(filepath));

        try {
          var snapshot = await uploadTask;

          var storageTaskSnapshot = snapshot;
          final String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
          uploadUrls.add(downloadUrl);

          developer.log('Upload success');
        } on FirebaseException catch (e) {
          developer.log('Error from image repo ${e.message}');
          throw ('This file is not an image');
        }
      }
    }), eagerError: true, cleanUp: (_) {
      developer.log('eager cleaned up');
    });

    return uploadUrls;
  }
}