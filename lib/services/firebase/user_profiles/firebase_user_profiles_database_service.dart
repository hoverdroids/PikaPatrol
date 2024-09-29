// ignore_for_file: constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'dart:developer' as developer;

import '../../../l10n/translations.dart';
import '../../../provider_services/user_profiles/app_user_profile.dart';
import '../../../utils/date_time_utils.dart';

class FirebaseUserProfilesDatabaseService {

  static const String USER_PROFILES_COLLECTION_NAME = "userProfiles";

  static const String FIRST_NAME = "firstName";
  static const String LAST_NAME = "lastName";
  static const String TAGLINE = "tagline";
  static const String PRONOUNS = "pronouns";
  static const String ORGANIZATION = "organization";
  static const String ADDRESS = "address";
  static const String CITY = "city";
  static const String STATE = "state";
  static const String ZIP = "zip";
  static const String FRPP_OPT_IN = "frppOptIn";
  static const String RMW_OPT_IN = "rmwOptIn";
  static const String DZ_OPT_IN = "dzOptIn";
  static const String DATE_UPDATED_IN_GOOGLE_SHEETS = "dateUpdatedInGoogleSheets";

  static const int? NO_LIMIT = null;

  String? uid;

  final FirebaseFirestore firebaseFirestore;
  late final CollectionReference userProfilesCollection;

  FirebaseUserProfilesDatabaseService(this.firebaseFirestore, this.uid) {
    userProfilesCollection = firebaseFirestore.collection(USER_PROFILES_COLLECTION_NAME);
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
            FIRST_NAME: "",
            LAST_NAME: "",
            TAGLINE: "",
            PRONOUNS: "",
            ORGANIZATION: "",
            ADDRESS: "",
            CITY: "",
            STATE: "",
            ZIP: "",
            FRPP_OPT_IN: false,
            RMW_OPT_IN: false,
            DZ_OPT_IN: false,
            DATE_UPDATED_IN_GOOGLE_SHEETS: null
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
            FIRST_NAME: trimmedFirstName,
            LAST_NAME: trimmedLastName,
            TAGLINE: trimmedTagline,
            PRONOUNS: trimmedPronouns,
            ORGANIZATION: trimmedOrganization,
            ADDRESS: trimmedAddress,
            CITY: trimmedCity,
            STATE: trimmedState,
            ZIP: trimmedZip,
            FRPP_OPT_IN: frppOptIn,
            RMW_OPT_IN: rmwOptIn,
            DZ_OPT_IN: dzOptIn,
            DATE_UPDATED_IN_GOOGLE_SHEETS: DateTime.now()
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
          snapshot.get(FIRST_NAME)?.trim() ?? '',
          snapshot.get(LAST_NAME)?.trim() ?? '',
          uid: uid?.trim(),
          tagline: snapshot.get(TAGLINE)?.trim() ?? '',
          pronouns: snapshot.get(PRONOUNS)?.trim() ?? '',
          organization: snapshot.get(ORGANIZATION)?.trim() ?? '',
          address: snapshot.get(ADDRESS)?.trim() ?? '',
          city: snapshot.get(CITY)?.trim() ?? '',
          state: snapshot.get(STATE)?.trim() ?? '',
          zip: snapshot.get(ZIP)?.trim() ?? '',
          frppOptIn: snapshot.get(FRPP_OPT_IN) ?? false,
          rmwOptIn: snapshot.get(RMW_OPT_IN) ?? false,
          dzOptIn: snapshot.get(DZ_OPT_IN) ?? false,
          dateUpdatedInGoogleSheets: parseTime(dataMap[DATE_UPDATED_IN_GOOGLE_SHEETS])
      );
    } catch(e){
      return null;
    }
  }

  List<AppUserProfile> _userProfilesFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.docs.map((doc) {

      final dataMap = doc.data() as Map<String, dynamic>;

      return AppUserProfile(
          dataMap[FIRST_NAME]?.trim() ?? '',
          dataMap[LAST_NAME]?.trim() ?? '',
          uid: doc.id.trim(),
          tagline: dataMap[TAGLINE]?.trim() ?? '',
          pronouns: dataMap[PRONOUNS]?.trim() ?? '',
          organization: dataMap[ORGANIZATION]?.trim() ?? '',
          address: dataMap[ADDRESS]?.trim() ?? '',
          city: dataMap[CITY]?.trim() ?? '',
          state: dataMap[STATE]?.trim() ?? '',
          zip: dataMap[ZIP]?.trim() ?? '',
          frppOptIn: dataMap[FRPP_OPT_IN] ?? false,
          rmwOptIn: dataMap[RMW_OPT_IN] ?? false,
          dzOptIn: dataMap[DZ_OPT_IN] ?? false,
          dateUpdatedInGoogleSheets: parseTime(dataMap[DATE_UPDATED_IN_GOOGLE_SHEETS])
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
        .where(DATE_UPDATED_IN_GOOGLE_SHEETS, isEqualTo: null);
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