// ignore_for_file: depend_on_referenced_packages
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:path/path.dart';
import 'package:pika_patrol/data/pika_species.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/model/app_user_profile.dart';
import 'dart:developer' as developer;

import '../l10n/translations.dart';
import '../utils/observation_utils.dart';


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

  //Don't use class uid because it will still be null immediately after registration.
  //Instead, pass the newly registered user's ID and add a user profile to simplify the streams
  //providing the AppUserProfile
  Future<FirebaseAuthException?> initializeUser(String newlyRegisteredUid) async {
    try {
      await userProfilesCollection.doc(newlyRegisteredUid).set(
          {
            'firstName': "",
            'lastName': "",
            'tagline': "",
            'pronouns': "",
            'organization': "",
            'address': "",
            'city': "",
            'state': "",
            'zip': "",
            'frppOptIn': false,
            'rmwOptIn': false,
            'dzOptIn': false,
          }
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e;
    }
  }

  bool areUserProfilesDifferent(AppUserProfile? profile1, AppUserProfile? profile2) {
    return profile1 == null && profile2 != null ||
           profile1 != null && profile2 == null ||
           profile1?.firstName != profile2?.firstName ||
           profile1?.lastName != profile2?.lastName ||
           profile1?.tagline != profile2?.tagline ||
           profile1?.pronouns != profile2?.pronouns ||
           profile1?.organization != profile2?.organization ||
           profile1?.address != profile2?.address ||
           profile1?.city != profile2?.city ||
           profile1?.state != profile2?.state ||
           profile1?.zip != profile2?.zip ||
           profile1?.frppOptIn != profile2?.frppOptIn ||
           profile1?.rmwOptIn != profile2?.rmwOptIn ||
           profile1?.dzOptIn != profile2?.dzOptIn;
  }

  Future addOrUpdateUserProfile(
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
      bool dzOptIn,
      Translations translations
  ) async {

    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();
    final trimmedTagline = tagline.trim();
    final trimmedPronouns = pronouns.trim();
    final trimmedOrganization = organization.trim();
    final trimmedAddress = address.trim();
    final trimmedCity = city.trim();
    final trimmedState = state.trim();
    final trimmedZip = zip.trim();

    var cachedUserProfile = await getCurrentUserProfileFromCache();
    var updatedUserProfile = AppUserProfile(
        trimmedFirstName,
        trimmedLastName,
        tagline: trimmedTagline,
        pronouns: trimmedPronouns,
        organization: trimmedOrganization,
        address: trimmedAddress,
        city: trimmedCity,
        state: trimmedState,
        zip: trimmedZip,
        frppOptIn: frppOptIn,
        rmwOptIn: rmwOptIn,
        dzOptIn: dzOptIn
    );
    
    var shouldUpdate = areUserProfilesDifferent(cachedUserProfile, updatedUserProfile);

    if (!shouldUpdate) {
      showToast(translations.profileIsAlreadyUpToDate);
      return;
    }

    await userProfilesCollection.doc(uid).set(
        {
          'firstName': trimmedFirstName,
          'lastName': trimmedLastName,
          'tagline' : trimmedTagline,
          'pronouns': trimmedPronouns,
          'organization': trimmedOrganization,
          'address': trimmedAddress,
          'city': trimmedCity,
          'state': trimmedState,
          'zip': trimmedZip,
          'frppOptIn': frppOptIn,
          'rmwOptIn': rmwOptIn,
          'dzOptIn': dzOptIn,
        }
    );

    showToast("Profile updated");
  }

  Future deleteUserProfile() async {
    return userProfilesCollection.doc(uid).delete();
  }
  
  AppUserProfile? _userProfileFromSnapshot(DocumentSnapshot snapshot) {
    var exists = snapshot.exists;
    if (uid == null || !exists) {
      return null;
    }

    try {

      final dataMap = snapshot.data() as Map<String, dynamic>;
      List<dynamic>? roles = dataMap['roles'];
      List<String> resolvedRoles = roles == null || roles.isEmpty ? <String>[] : roles.cast<String>().toList();

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
        roles: resolvedRoles
      );
    } catch(e){
      return null;
    }
  }

  List<AppUserProfile> _userProfilesFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {

      final dataMap = doc.data() as Map<String, dynamic>;
      List<dynamic>? roles = dataMap['roles'];
      List<String> resolvedRoles = roles == null || roles.isEmpty ? <String>[] : roles.cast<String>().toList();

      return AppUserProfile(
        dataMap['firstName']?.trim() ?? '',
        dataMap['lastName']?.trim() ?? '',
        uid: doc.id.trim(),
        tagline: dataMap['tagline']?.trim() ?? '',
        pronouns: dataMap['pronouns']?.trim() ?? '',
        organization: dataMap['organization']?.trim() ?? '',
        address: dataMap['address']?.trim() ?? '',
        city: dataMap['city']?.trim() ?? '',
        state: dataMap['state']?.trim() ?? '',
        zip: dataMap['zip']?.trim() ?? '',
        frppOptIn: dataMap['frppOptIn'] ?? false,
        rmwOptIn: dataMap['rmwOptIn'] ?? false,
        dzOptIn: dataMap['dzOptIn'] ?? false,
        roles: resolvedRoles
      );
    }).toList();
  }

  Stream<AppUserProfile?> get userProfile {
    return userProfilesCollection.doc(uid).snapshots().map(_userProfileFromSnapshot);
  }

  Future<List<AppUserProfile>> getUserProfiles({int? limit}) async {
    //https://stackoverflow.com/questions/50870652/flutter-firebase-basic-query-or-basic-search-code

    var userProfiles = <AppUserProfile>[];
    var query = userProfilesCollection
        .where('tagline', isGreaterThanOrEqualTo: "the bro")
        .where('tagline', isLessThan: "the bro" +'z');

    if (limit != null) {
      query = query.limit(limit);
    }

    await query
      .get()
      .then((QuerySnapshot snapshot){
        userProfiles = _userProfilesFromSnapshot(snapshot);
      })
      .catchError((e){
        developer.log("User profiles query error:$e");
      });

      return userProfiles;
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
          date: DateTime.fromMillisecondsSinceEpoch(dataMap['date']?.millisecondsSinceEpoch),
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