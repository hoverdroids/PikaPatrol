// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:path/path.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/model/app_user_profile.dart';
import 'dart:developer' as developer;

class FirebaseDatabaseService {

  String? uid;

  FirebaseDatabaseService({ this.uid });

  final CollectionReference userProfilesCollection = FirebaseFirestore.instance.collection("userProfiles");

  final CollectionReference observationsCollection = FirebaseFirestore.instance.collection("observations");

  Future<AppUserProfile?> getCurrentUserProfileFromCache() async {
    var options = const GetOptions(source: Source.cache);
    var userProfileSnapshot = await userProfilesCollection.doc(uid).get(options);
    return _userProfileFromSnapshot(userProfileSnapshot);
  }

  Future<bool> isCachedUserProfileDifferent(
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
    var cachedUserProfile = await getCurrentUserProfileFromCache();
    return cachedUserProfile == null ||
      cachedUserProfile.firstName != firstName ||
      cachedUserProfile.lastName != lastName ||
      cachedUserProfile.tagline != tagline ||
      cachedUserProfile.pronouns != pronouns ||
      cachedUserProfile.organization != organization ||
      cachedUserProfile.address != address ||
      cachedUserProfile.city != city ||
      cachedUserProfile.state != state ||
      cachedUserProfile.zip != zip ||
      cachedUserProfile.frppOptIn != frppOptIn ||
      cachedUserProfile.rmwOptIn != rmwOptIn ||
      cachedUserProfile.dzOptIn != dzOptIn;
  }

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

    var shouldUpdate = await isCachedUserProfileDifferent(
      firstName,
      lastName,
      tagline,
      pronouns,
      organization,
      address,
      city,
      state,
      zip,
      frppOptIn,
      rmwOptIn,
      dzOptIn
    );

    if (!shouldUpdate) {
      showToast("Profile is already up-to-date");
      return;
    }

    await userProfilesCollection.doc(uid).set(
        {
          'firstName': firstName.trim(),
          'lastName': lastName.trim(),
          'tagline' : tagline.trim(),
          'pronouns': pronouns.trim(),
          'organization': organization.trim(),
          'address': address.trim(),
          'city': city.trim(),
          'state': state.trim(),
          'zip': zip.trim(),
          'frppOptIn': frppOptIn,
          'rmwOptIn': rmwOptIn,
          'dzOptIn': dzOptIn,
        }
    );

    showToast("Profile updated");
  }
  
  AppUserProfile? _userProfileFromSnapshot(DocumentSnapshot snapshot) {
    if (uid == null) {
      return null;
    }
    return AppUserProfile(
      snapshot.get('firstName')?.trim() ?? '',
      snapshot.get('lastName')?.trim() ?? '',
      uid: uid?.trim(),
      tagline: snapshot.get('tagline')?.trim() ?? '',
      pronouns: snapshot.get('pronouns')?.trim() ?? '',
      organization: snapshot.get('organization')?.trim() ?? '',
      address: snapshot.get('address')?.trim() ?? '',
      city: snapshot.get('city')?.trim() ?? '',
      state: snapshot.get('state')?.trim() ?? '',
      zip: snapshot.get('zip')?.trim() ?? '',
      frppOptIn: snapshot.get('frppOptIn') ?? false,
      rmwOptIn: snapshot.get('rmwOptIn') ?? false,
      dzOptIn: snapshot.get('dzOptIn') ?? false,
    );
  }

  Stream<AppUserProfile?> get userProfile {
    return userProfilesCollection.doc(uid).snapshots().map(_userProfileFromSnapshot);
  }

  Future updateObservation(Observation observation) async {
    //TODO - determine if there are any images that were uploaded and associated with this observation that are no longer associated; delete them from the database

    var observationObject = {
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
    };

    DocumentReference doc;
    if(observation.uid == null || observation.uid?.isEmpty == true) {
      doc = observationsCollection.doc();
      observation.uid = doc.id;
      await doc.set(observationObject);
    } else {
      doc = observationsCollection.doc(observation.uid);
      await doc.update(observationObject);
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