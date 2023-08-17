import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/model/app_user_profile.dart';

class FirebaseDatabaseService {

  final String? uid;

  FirebaseDatabaseService({ this.uid });

  final CollectionReference userProfilesCollection = FirebaseFirestore.instance.collection("userProfiles");

  final CollectionReference observationsCollection = FirebaseFirestore.instance.collection("observations");

  Future updateUserProfile(
      String firstName,
      String lastName,
      String tagline,
      String pronouns,
      String organization,
      String address,
      String city,
      String state,
      String zip,
      bool frppOptIn,
      bool rmwOptIn,
      bool dzOptIn
      ) async {
    return await userProfilesCollection.doc(uid).set(
        {
          'firstName': firstName,
          'lastName': lastName,
          'tagline' : tagline,
          'pronouns': pronouns,
          'organization': organization,
          'address': address,
          'city': city,
          'state': state,
          'zip': zip,
          'frppOptIn': frppOptIn,
          'rmwOptIn': rmwOptIn,
          'dzOptIn': dzOptIn,
        }
    );
  }
  
  AppUserProfile _userProfileFromSnapshot(DocumentSnapshot snapshot) {
    return AppUserProfile(
      snapshot.get('firstName') ?? '',
      snapshot.get('lastName') ?? '',
      uid: uid,
      tagline: snapshot.get('tagline') ?? '',
      pronouns: snapshot.get('pronouns') ?? '',
      organization: snapshot.get('organization') ?? '',
      address: snapshot.get('address') ?? '',
      city: snapshot.get('city') ?? '',
      state: snapshot.get('state') ?? '',
      zip: snapshot.get('zip') ?? '',
      frppOptIn: snapshot.get('frppOptIn') ?? false,
      rmwOptIn: snapshot.get('rmwOptIn') ?? false,
      dzOptIn: snapshot.get('dzOptIn') ?? false,
    );
  }

  Stream<AppUserProfile>? get userProfile {
    return uid == null ? null : userProfilesCollection.doc(uid).snapshots().map(_userProfileFromSnapshot);
  }

  Future updateObservation(Observation observation) async {
    //TODO - determine if there are any images that were uploaded and associated with this observation that are no longer associated; delete them from the database
    DocumentReference doc;
    if(observation.uid == null || observation.uid?.isEmpty == true) {
      doc = observationsCollection.doc();
      observation.uid = doc.id;
    } else {
      doc = observationsCollection.doc(observation.uid);
    }

    print("Update Observation id:${observation.uid}");

    return await doc.update(
        {
          'observerUid': observation.observerUid,
          'name': observation.name,
          'location': observation.location,
          'date': observation.date,
          'altitude': observation.altitude,
          'latitude': observation.latitude,
          'longitude': observation.longitude,
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
          'audioUrls': observation.audioUrls
        }
    );
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

      return Observation(
          uid: doc.id,
          observerUid: dataMap['observerUid'] ?? '',
          name: dataMap['name'] ?? '',
          location: dataMap['location'] ?? '',
          altitude: dataMap['altitude'],
          latitude: dataMap['latitude'],
          longitude: dataMap['longitude'],
          date: DateTime.fromMillisecondsSinceEpoch(dataMap['date']?.millisecondsSinceEpoch),
          signs: signs,
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
          audioUrls: audioUrls
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
      print('file type ${fileType}');*/
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

          print('Upload success');
        } on FirebaseException catch (e) {
          print('Error from image repo ${e.message}');
          throw ('This file is not an image');
        }
      }
    }), eagerError: true, cleanUp: (_) {
      print('eager cleaned up');
    });

    return uploadUrls;
  }
}