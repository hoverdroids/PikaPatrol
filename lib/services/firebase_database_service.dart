import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart';
import 'package:pika_joe/model/observation2.dart';
import 'package:pika_joe/model/user_profile.dart';

class FirebaseDatabaseService {

  final String uid;

  FirebaseDatabaseService({ this.uid });

  final CollectionReference userProfilesCollection = Firestore.instance.collection("userProfiles");

  final CollectionReference observationsCollection = Firestore.instance.collection("observations");

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
    return await userProfilesCollection.document(uid).setData(
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
  
  /*Future updateUserProfile(UserProfile data) async {
    return await userProfilesCollection.document(uid).setData(
        {
          'firstName': data.firstName,
          'lastName': data.lastName,
          'pronouns': data.pronouns,
          'organization': data.organization,
          'address': data.address,
          'city': data.city,
          'state': data.state,
          'zip': data.zip,
          'frppOptIn': data.frppOptIn,
          'rmwOptIn': data.rmwOptIn,
          'dzOptIn': data.dzOptIn,
        }
    );
  }*/

  UserProfile _userProfileFromSnapshot(DocumentSnapshot snapshot) {
    return UserProfile(
      snapshot.data['firstName'] ?? '',
      snapshot.data['lastName'] ?? '',
      uid: uid,
      tagline: snapshot.data['tagline'] ?? '',
      pronouns: snapshot.data['pronouns'] ?? '',
      organization: snapshot.data['organization'] ?? '',
      address: snapshot.data['address'] ?? '',
      city: snapshot.data['city'] ?? '',
      state: snapshot.data['state'] ?? '',
      zip: snapshot.data['zip'] ?? '',
      frppOptIn: snapshot.data['frppOptIn'] ?? false,
      rmwOptIn: snapshot.data['rmwOptIn'] ?? false,
      dzOptIn: snapshot.data['dzOptIn'] ?? false,
    );
  }

  Stream<UserProfile> get userProfile {
    return uid == null ? null : userProfilesCollection.document(uid).snapshots().map(_userProfileFromSnapshot);
  }

  Future updateObservation(Observation2 observation) async {

    DocumentReference doc;
    if(observation.uid == null || observation.uid.isEmpty) {
      doc = observationsCollection.document();
      observation.uid = doc.documentID;
    } else {
      doc = observationsCollection.document(observation.uid);
    }

    print("Update Observation id:${observation.uid}");

    return await doc.setData(
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

  List<Observation2> _observationsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.documents.map((doc) {

      List<dynamic> vals = doc.data['signs'];
      List<String> signs = vals == null || vals.isEmpty ? <String>[] : vals.cast<String>().toList();

      vals = doc.data['otherAnimalsPresent'];
      List<String> otherAnimalsPresent = vals == null || vals.isEmpty ? <String>[] :  vals.cast<String>().toList();

      vals = doc.data['imageUrls'];
      List<String> imageUrls = vals == null || vals.isEmpty ? <String>[] :  vals.cast<String>().toList();

      vals = doc.data['audioUrls'];
      List<String> audioUrls = vals == null || vals.isEmpty ? <String>[] :  vals.cast<String>().toList();

      return Observation2(
        uid: doc.documentID ?? '',
        observerUid: doc.data['observerUid'] ?? '',
        name: doc.data['name'] ?? '',
        location: doc.data['location'] ?? '',
        altitude: doc.data['altitude'],
        latitude: doc.data['latitude'],
        longitude: doc.data['longitude'],
        date: DateTime.fromMicrosecondsSinceEpoch(doc.data['date'].millisecondsSinceEpoch),
        signs: signs,
        pikasDetected: doc.data['pikasDetected'] ?? '',
        distanceToClosestPika: doc.data['distanceToClosestPika'] ?? '',
        searchDuration: doc.data['searchDuration'] ?? '',
        talusArea: doc.data['talusArea'] ?? '',
        temperature: doc.data['temperature'] ?? '',
        skies: doc.data['skies'] ?? '',
        wind: doc.data['wind'] ?? '',
        siteHistory: doc.data['siteHistory'] ?? '',
        otherAnimalsPresent: otherAnimalsPresent,
        comments: doc.data['comments'] ?? '',
        imageUrls: imageUrls,
        audioUrls: audioUrls
      );
    }).toList();
  }

  Stream<List<Observation2>> get observations {
    return observationsCollection.snapshots().map(_observationsFromSnapshot);
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
        FirebaseStorage storage = FirebaseStorage(storageBucket: 'gs://pikajoe-97c5c.appspot.com');
        StorageUploadTask uploadTask = storage.ref().child("$folder/${basename(filepath)}").putFile(File(filepath));
        StorageTaskSnapshot storageTaskSnapshot;

        StorageTaskSnapshot snapshot = await uploadTask.onComplete;
        if (snapshot.error == null) {
          storageTaskSnapshot = snapshot;
          final String downloadUrl = await storageTaskSnapshot.ref.getDownloadURL();
          uploadUrls.add(downloadUrl);

          print('Upload success');
        } else {
          print('Error from image repo ${snapshot.error.toString()}');
          throw ('This file is not an image');
        }
      }
    }), eagerError: true, cleanUp: (_) {
      print('eager cleaned up');
    });

    return uploadUrls;
  }
}