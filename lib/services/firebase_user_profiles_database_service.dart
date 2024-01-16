import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'dart:developer' as developer;

import '../l10n/translations.dart';
import '../model/app_user_profile.dart';
import '../utils/date_time_utils.dart';

class FirebaseUserProfilesDatabaseService {

  String? uid;

  final FirebaseFirestore firebaseFirestore;
  late final CollectionReference userProfilesCollection;

  FirebaseUserProfilesDatabaseService(this.firebaseFirestore, this.uid) {
    userProfilesCollection = firebaseFirestore.collection("userProfiles");
  }

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
            'dateUpdatedInGoogleSheets': null
          }
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e;
    }
  }

  bool areUserProfilesDifferent(AppUserProfile? profile1, AppUserProfile? profile2) =>
      profile1 == null && profile2 != null ||
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
          profile1?.dzOptIn != profile2?.dzOptIn ||
          profile1?.dateUpdatedInGoogleSheets?.millisecondsSinceEpoch != profile2?.dateUpdatedInGoogleSheets?.millisecondsSinceEpoch;

  Future<AppUserProfile?> addOrUpdateUserProfile(
      String firstName,
      String lastName,
      String? uid,
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
      DateTime? dateUpdatedInGoogleSheets,
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

    var updatedUserProfile = AppUserProfile(
        trimmedFirstName,
        trimmedLastName,
        uid: uid,
        tagline: trimmedTagline,
        pronouns: trimmedPronouns,
        organization: trimmedOrganization,
        address: trimmedAddress,
        city: trimmedCity,
        state: trimmedState,
        zip: trimmedZip,
        frppOptIn: frppOptIn,
        rmwOptIn: rmwOptIn,
        dzOptIn: dzOptIn,
        dateUpdatedInGoogleSheets: dateUpdatedInGoogleSheets
    );

    var shouldUpdate = true;
    var isCurrentUser = updatedUserProfile.uid == this.uid;
    if (isCurrentUser) {
      var cachedUserProfile = await getCurrentUserProfileFromCache();
      shouldUpdate = areUserProfilesDifferent(cachedUserProfile, updatedUserProfile);
    }

    if (!shouldUpdate) {
      return null;
    }

    try {
      await userProfilesCollection.doc(updatedUserProfile.uid).set(
          {
            'firstName': trimmedFirstName,
            'lastName': trimmedLastName,
            'tagline': trimmedTagline,
            'pronouns': trimmedPronouns,
            'organization': trimmedOrganization,
            'address': trimmedAddress,
            'city': trimmedCity,
            'state': trimmedState,
            'zip': trimmedZip,
            'frppOptIn': frppOptIn,
            'rmwOptIn': rmwOptIn,
            'dzOptIn': dzOptIn,
            'dateUpdatedInGoogleSheets': DateTime.now()
          }
      );
    } catch(e) {
      showToast("App profile update error:$e");
    }

    return updatedUserProfile;
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
          dateUpdatedInGoogleSheets: parseTime(dataMap['dateUpdatedInGoogleSheets'])//TODO - CHRIS - verify this works in Android and then check other timestamps/dates
      );
    } catch(e){
      return null;
    }
  }

  List<AppUserProfile> _userProfilesFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {

      final dataMap = doc.data() as Map<String, dynamic>;

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
          dateUpdatedInGoogleSheets: parseTime(dataMap['dateUpdatedInGoogleSheets'])//TODO - CHRIS - verify this works in Android and then check other timestamps/dates
      );
    }).toList();
  }

  Stream<AppUserProfile?> get userProfile {
    return userProfilesCollection.doc(uid).snapshots().map(_userProfileFromSnapshot);
  }

  Future<List<AppUserProfile>> getAllUserProfiles({int? limit}) async {
    Query query = userProfilesCollection;
    return await getUserProfiles(query, limit: limit);
  }

  // Firestore doesn't allow queries based on fields that don't yet exist in the document, so the following query doesn't do anything
  // until all user profiles have the field
  // https://stackoverflow.com/questions/49579693/how-do-i-get-documents-where-a-specific-field-exists-does-not-exists-in-firebase
  Future<List<AppUserProfile>> getUserProfilesNotInGoogleSheets({int? limit}) async {
    Query query = userProfilesCollection
        .where('dateUpdatedInGoogleSheets', isEqualTo: null);
    return await getUserProfiles(query, limit: limit);
  }

  Future<List<AppUserProfile>> getUserProfiles(Query query, {int? limit}) async {
    //https://stackoverflow.com/questions/50870652/flutter-firebase-basic-query-or-basic-search-code

    if (limit != null) {
      query = query.limit(limit);
    }

    var userProfiles = <AppUserProfile>[];
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
}