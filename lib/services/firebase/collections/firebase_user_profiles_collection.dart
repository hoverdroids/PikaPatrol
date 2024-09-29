// ignore_for_file: constant_identifier_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pika_patrol/model/firebase_value_exception_pair.dart';

import '../../../l10n/translations.dart';
import '../../../model/app_user_profile.dart';
import '../../../utils/date_time_utils.dart';
import 'firebase_firestore_collection.dart';

class FirebaseUserProfilesCollection extends FirebaseFirestoreCollection {

  //region Constructor
  FirebaseUserProfilesCollection(
    FirebaseFirestore firestore,
    this._currentUserId,
    {
      String name = COLLECTION_NAME,
      super.limit = FirebaseFirestoreCollection.DEFAULT_LIMIT_SMALL
    }
  ) : super(firestore, name);
  //endregion

  //region Collection: Fields in Firebase
  static const String COLLECTION_NAME = "userProfiles";

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
  //endregion

  //region UserId
  static const String RANDOM_CURRENT_USER_ID = "A9x4ikJ7h6MvaJiYAHx7v9o7zRx5";

  //Any random Id to start with so that it doesn't match until a real ID is provided,
  //because we don't want to match against null or empty as those are valid but undesirable
  String _currentUserId = RANDOM_CURRENT_USER_ID;

  set currentUserId(String? userId) {
    _currentUserId = userId ?? RANDOM_CURRENT_USER_ID;
  }

  String get currentUserId => _currentUserId;
  //endregion

  //region Initialize
  //Don't use class uid because it will still be null immediately after registration.
  //Instead, pass the newly registered user's ID and add a user profile to simplify the streams
  //providing the AppUserProfile
  Future<FirebaseValueExceptionPair<bool>> initializeUser(String newlyRegisteredUid) async {
    try {
      await collection.doc(newlyRegisteredUid).set(
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
      return FirebaseValueExceptionPair(true);
    } on FirebaseAuthException catch (e) {
      return FirebaseValueExceptionPair(false, exception: e);
    }
  }
  //endregion

  //region Get
  Future<FirebaseValueExceptionPair<List<AppUserProfile>>> getAllUserProfiles({int? limit}) async {
    Query query = collection;
    return await getUserProfiles(query, limit: limit);
  }

  //Doesn't need FirebaseValueExceptionPair; no exceptions can be thrown.
  Future<AppUserProfile?> getUserProfile(String? userId, GetOptions options) async {
    if (userId == null) {
      return null;
    }
    final userProfileSnapshot = await collection.doc(userId).get(options);
    return userProfileSnapshot.toUserProfile(currentUserId);
  }

  Future<FirebaseValueExceptionPair<List<AppUserProfile>>> getUserProfiles(Query query, {int? limit}) async {
    //https://stackoverflow.com/questions/50870652/flutter-firebase-basic-query-or-basic-search-code

    if (limit != null) {
      query = query.limit(limit);
    }

    return await query
        .get()
        .then((QuerySnapshot querySnapshot){
      return FirebaseValueExceptionPair<List<AppUserProfile>>(querySnapshot.toUserProfiles());
    })
        .catchError((e){
      return FirebaseValueExceptionPair<List<AppUserProfile>>([], exception: e);
    });
  }
  //endregion

  //region Get: Stream
  Stream<AppUserProfile?> get userProfileStream {
    return collection.doc(currentUserId).snapshots().map((snapshot) => snapshot.toUserProfile(currentUserId));
  }
  //endregion

  //region Get: Not in Google Sheets
  // Firestore doesn't allow queries based on fields that don't yet exist in the document, so the following query doesn't do anything
  // until all user profiles have the field
  // https://stackoverflow.com/questions/49579693/how-do-i-get-documents-where-a-specific-field-exists-does-not-exists-in-firebase
  Future<FirebaseValueExceptionPair<List<AppUserProfile>>> getUserProfilesNotInGoogleSheets({int? limit}) async {
    Query query = collection.where(DATE_UPDATED_IN_GOOGLE_SHEETS, isEqualTo: null);
    return await getUserProfiles(query, limit: limit);
  }
  //endregion
  
  //region Get: from Cache
  //Doesn't need FirebaseValueExceptionPair; no exceptions can be thrown.
  Future<AppUserProfile?> getCurrentUserProfileFromCache() async {
    return await getUserProfileFromCache(currentUserId);
  }

  //Doesn't need FirebaseValueExceptionPair; no exceptions can be thrown.
  Future<AppUserProfile?> getUserProfileFromCache(String? userId) async {
    return await getUserProfile(userId, const GetOptions(source: Source.cache));
  }
  //endregion
  
  //region Get: from Server
  //Doesn't need FirebaseValueExceptionPair; no exceptions can be thrown.
  Future<AppUserProfile?> getUserProfileFromServer(String? userId) async {
    return await getUserProfile(userId, const GetOptions(source: Source.server));
  }

  //Doesn't need FirebaseValueExceptionPair; no exceptions can be thrown.
  Future<AppUserProfile?> getUserProfileFromServerWithCacheFallback(String? userId) async {
    return await getUserProfile(userId, const GetOptions(source: Source.serverAndCache));
  }
  //endregion

  //region Create/Update
  Future<FirebaseValueExceptionPair<AppUserProfile>> createOrUpdateUserProfile(
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
    var isCurrentUser = updatedUserProfile.uid == currentUserId;
    if (isCurrentUser) {
      var cachedUserProfile = await getCurrentUserProfileFromCache();
      shouldUpdate = cachedUserProfile.isDifferent(updatedUserProfile);
    }

    if (!shouldUpdate) {
      return FirebaseValueExceptionPair(null);
    }

    try {
      await collection.doc(updatedUserProfile.uid).set(
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
      return FirebaseValueExceptionPair(updatedUserProfile);
    } on FirebaseException catch(e) {
      return FirebaseValueExceptionPair(null, exception: e);
    }
  }
  //endregion
  
  //region Delete
  Future deleteUserProfile() async {
    return collection.doc(currentUserId).delete();
  }
  //endregion
}

extension FirebaseAppUserProfilesCollectionDocumentSnapshotExtensions on DocumentSnapshot {
  AppUserProfile? toUserProfile(String? currentUserId) {
    if (currentUserId == null || !exists) {
      return null;
    }

    try {

      final dataMap = data() as Map<String, dynamic>;

      return AppUserProfile(
          get(FirebaseUserProfilesCollection.FIRST_NAME)?.trim() ?? '',
          get(FirebaseUserProfilesCollection.LAST_NAME)?.trim() ?? '',
          uid: currentUserId.trim(),
          tagline: get(FirebaseUserProfilesCollection.TAGLINE)?.trim() ?? '',
          pronouns: get(FirebaseUserProfilesCollection.PRONOUNS)?.trim() ?? '',
          organization: get(FirebaseUserProfilesCollection.ORGANIZATION)?.trim() ?? '',
          address: get(FirebaseUserProfilesCollection.ADDRESS)?.trim() ?? '',
          city: get(FirebaseUserProfilesCollection.CITY)?.trim() ?? '',
          state: get(FirebaseUserProfilesCollection.STATE)?.trim() ?? '',
          zip: get(FirebaseUserProfilesCollection.ZIP)?.trim() ?? '',
          frppOptIn: get(FirebaseUserProfilesCollection.FRPP_OPT_IN) ?? false,
          rmwOptIn: get(FirebaseUserProfilesCollection.RMW_OPT_IN) ?? false,
          dzOptIn: get(FirebaseUserProfilesCollection.DZ_OPT_IN) ?? false,
          dateUpdatedInGoogleSheets: parseTime(dataMap[FirebaseUserProfilesCollection.DATE_UPDATED_IN_GOOGLE_SHEETS])
      );
    } catch(e){
      return null;
    }
  }
}

extension FirebaseAppUserProfilesCollectionQuerySnapshotExtensions on QuerySnapshot {
  List<AppUserProfile> toUserProfiles() {
    return docs.map((doc) {

      final dataMap = doc.data() as Map<String, dynamic>;

      return AppUserProfile(
          dataMap[FirebaseUserProfilesCollection.FIRST_NAME]?.trim() ?? '',
          dataMap[FirebaseUserProfilesCollection.LAST_NAME]?.trim() ?? '',
          uid: doc.id.trim(),
          tagline: dataMap[FirebaseUserProfilesCollection.TAGLINE]?.trim() ?? '',
          pronouns: dataMap[FirebaseUserProfilesCollection.PRONOUNS]?.trim() ?? '',
          organization: dataMap[FirebaseUserProfilesCollection.ORGANIZATION]?.trim() ?? '',
          address: dataMap[FirebaseUserProfilesCollection.ADDRESS]?.trim() ?? '',
          city: dataMap[FirebaseUserProfilesCollection.CITY]?.trim() ?? '',
          state: dataMap[FirebaseUserProfilesCollection.STATE]?.trim() ?? '',
          zip: dataMap[FirebaseUserProfilesCollection.ZIP]?.trim() ?? '',
          frppOptIn: dataMap[FirebaseUserProfilesCollection.FRPP_OPT_IN] ?? false,
          rmwOptIn: dataMap[FirebaseUserProfilesCollection.RMW_OPT_IN] ?? false,
          dzOptIn: dataMap[FirebaseUserProfilesCollection.DZ_OPT_IN] ?? false,
          dateUpdatedInGoogleSheets: parseTime(dataMap[FirebaseUserProfilesCollection.DATE_UPDATED_IN_GOOGLE_SHEETS])
      );
    }).toList();
  }
}

extension FirebaseAppUserProfilesCollectionAppUserProfileExtension on AppUserProfile? {
  bool isDifferent(AppUserProfile? profile2) =>
      this == null && profile2 != null ||
          this != null && profile2 == null ||
          this?.firstName != profile2?.firstName ||
          this?.lastName != profile2?.lastName ||
          this?.tagline != profile2?.tagline ||
          this?.pronouns != profile2?.pronouns ||
          this?.organization != profile2?.organization ||
          this?.address != profile2?.address ||
          this?.city != profile2?.city ||
          this?.state != profile2?.state ||
          this?.zip != profile2?.zip ||
          this?.frppOptIn != profile2?.frppOptIn ||
          this?.rmwOptIn != profile2?.rmwOptIn ||
          this?.dzOptIn != profile2?.dzOptIn ||
          this?.dateUpdatedInGoogleSheets?.millisecondsSinceEpoch != profile2?.dateUpdatedInGoogleSheets?.millisecondsSinceEpoch;
}