// ignore_for_file: constant_identifier_names
import 'dart:io';
import 'dart:math';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:pika_patrol/utils/firebase_utils.dart';

import '../model/observation.dart';
import '../model/storage_file.dart';
import 'storage_file_correlator.dart';
import '../utils/date_time_utils.dart';
import 'package:path/path.dart';

class StorageScan {
  final List<FileFix> fixes;
  final List<StorageFile> unused;
  final int observationCount;
  final int totalFileCount;

  const StorageScan({required this.fixes, required this.unused, required this.observationCount, required this.totalFileCount});
}

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
  static const String RANDOM_CURRENT_USER_ID = "A9x4ikJ7h6MvaJiYAHx7v9o7zRx5";

  static const int FUTURE_TIMEOUT_SECONDS = 3;
  static const bool FUTURE_TIMEOUT = true;

  //Any random Id to start with so that it doesn't match until a real ID is provided,
  //because we don't want to match against null or empty as those are valid but undesirable
  String _currentUserId = RANDOM_CURRENT_USER_ID;
  set currentUesrId(String? userId) {
    _currentUserId = userId ?? RANDOM_CURRENT_USER_ID;
  }

  final FirebaseFirestore firebaseFirestore;
  late final CollectionReference observationsCollection;

  FirebaseObservationsService(this.firebaseFirestore) {
    observationsCollection = firebaseFirestore.collection(OBSERVATIONS_COLLECTION_NAME);
  }

  //region Id: Generator
  // Get a new and unique auto-generated document ID prefixed with a client-generated timestamp
  //Doesn't need FirebaseValueExceptionPair; no exceptions can be thrown.
  String generateNewObservationUid() {
    return observationsCollection.doc().id;
  }
  //endregion

  Future<FirebaseException?> addOrUpdateObservation(Observation observation) async {

    //Assume a successful upload unless an exception is thrown
    //This allows firebase to be up-to-date with only one write
    final originalIsUploaded = observation.isUploaded;
    observation.isUploaded = true;

    final originalUid = observation.uid;
    observation.uid = originalUid == null || originalUid.isEmpty ? generateNewObservationUid() : originalUid;
    DocumentReference doc = observationsCollection.doc(observation.uid);

    // The files this observation pointed to before this save, so the ones the user removed can be
    // deleted from Storage after the save works. One read per save.
    final previousFileUrls = originalUid == null || originalUid.isEmpty ? <String>[] : await _getFileUrls(doc);

    try {
      // Calling "set" when a doc with the Id doesn't exist will create it.
      // If a doc exists with the given uid, it will be updated
      await doc.set(observation.toFirebaseObservation());
    } on FirebaseException catch (e) {

      // Need to reset or the local observation will appear to have been uploaded with a valid ID, that is actually non existent
      observation.uid = originalUid;

      observation.isUploaded = originalIsUploaded;

      return e;
    }

    // Compare Storage paths, not URLs: the same file can have a new URL (a refreshed access
    // token), and comparing URLs would delete a file the observation still uses
    final currentFilePaths = {
      for (var url in [...?observation.imageUrls, ...?observation.audioUrls])
        storagePathFromUrl(url) ?? url
    };
    final removedFileUrls = previousFileUrls.where((url) => !currentFilePaths.contains(storagePathFromUrl(url) ?? url)).toList();
    final failedDeletes = await deleteFiles(removedFileUrls);
    await onFileDeletesFailed?.call(failedDeletes);

    return null;
  }

  Future<List<String>> _getFileUrls(DocumentReference doc) async {
    try {
      final snapshot = await doc.get();
      final data = snapshot.data() as Map<String, dynamic>?;
      if (data == null) return <String>[];
      return [
        ...(data[IMAGE_URLS] as List<dynamic>? ?? []).cast<String>(),
        ...(data[AUDIO_URLS] as List<dynamic>? ?? []).cast<String>(),
      ];
    } on FirebaseException catch (e) {
      developer.log('Could not read the previous files for ${doc.id}: $e', name: 'FirebaseObservationsService');
      return <String>[];
    }
  }

  // Called with Storage files that could not be deleted (for example while offline), so the
  // caller can retry later instead of leaving files that are still billed for.
  Future<void> Function(List<String> fileUrls)? onFileDeletesFailed;

  Future<FirebaseException?> deleteObservation(Observation observation, bool deleteImages, bool deleteAudio) async {
    final fileUrls = [
      if (deleteImages) ...?observation.imageUrls,
      if (deleteAudio) ...?observation.audioUrls,
    ];
    final failedDeletes = await deleteFiles(fileUrls);
    await onFileDeletesFailed?.call(failedDeletes);

    var docUid = observation.uid ?? "";
    if (docUid.isNotEmpty) {
      try {
        //Observations.doc.delete does not return when offline and doesn't throw an offline exception;
        //It just hangs until it goes back online, even though the doc delete is queued up and will take affect after going online
        //So, need to timeout so that the process can continue
        //https://stackoverflow.com/questions/52672137/await-future-for-a-specific-time
        await Future.value(observationsCollection.doc(docUid).delete())
            .timeout(const Duration(seconds: 3), onTimeout: () => throw getFirebaseNetworkException());
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
          species: dataMap[SPECIES] ?? Observation.SPECIES_DEFAULT,
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

  List<Observation> _observationsFromSnapshot2(QuerySnapshot snapshot) {
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
          species: dataMap[SPECIES] ?? Observation.SPECIES_DEFAULT,
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

  // Cached so repeated calls return the same Stream instance rather than creating a new
  // Firestore listener each time. This widget tree rebuilds this stream's callers via several
  // nested StreamBuilders (see main.dart), and StreamBuilder tears down and resubscribes
  // whenever it's handed a *different* Stream object - which, for a fresh .snapshots() listener,
  // means re-reading every matching document from the server instead of resuming from Firestore's
  // local cache. Memoizing keeps one long-lived listener per login session so only the initial
  // hydrate and genuine changes are billed as reads.
  Stream<List<Observation>>? _sharedObservationsStream;
  Stream<List<Observation>> get observations {
    return _sharedObservationsStream ??= observationsCollection.orderBy(DATE, descending: true).limit(5).snapshots().map(_observationsFromSnapshot);
  }

  String? _cachedUserObservationsUserId;
  Stream<List<Observation>>? _cachedUserObservationsStream;
  Stream<List<Observation>> userObservations(String userId) {
    if (_cachedUserObservationsStream == null || _cachedUserObservationsUserId != userId) {
      _cachedUserObservationsUserId = userId;
      _cachedUserObservationsStream = observationsCollection.where(OBSERVER_UID, whereIn: [userId])
          .orderBy(DATE, descending: true)
          .snapshots()
          .map(_observationsFromSnapshot2);
    }
    return _cachedUserObservationsStream!;
  }

  // Returns the download URLs in the same order as filepaths, so the first image stays the cover.
  // (Adding URLs as each upload finished put them in finish order, which moved the cover.)
  Future<List<String>> uploadFiles(List<String> filepaths, bool areImages) async {
    var folder = areImages ? IMAGES_FOLDER_NAME : AUDIO_FOLDER_NAME;

    return await Future.wait(filepaths.map((String filepath) async {
      if (filepath.contains(STORAGE_BUCKET_NAME)) {
        //Do not try to upload an image that has already been uploaded
        return filepath;
      }

      try {
        // A random prefix keeps two observations from sharing one Storage file (for example the
        // same gallery photo added to both), so deleting one never breaks the other
        final name = "${generateNewObservationUid()}_${basename(filepath)}";
        var snapshot = await _storage.ref().child("$folder/$name").putFile(File(filepath));
        return await snapshot.ref.getDownloadURL();
      } on FirebaseException {
        throw ('This file is not an image');
      }
    }), eagerError: true);
  }

  FirebaseStorage get _storage {
    final storage = FirebaseStorage.instanceFor(bucket: STORAGE_BUCKET_URL);
    // Fail fast when offline instead of retrying for two minutes; failed deletes are retried later
    storage.setMaxOperationRetryTime(const Duration(seconds: 10));
    return storage;
  }

  // Best-effort: deleting an observation should not get stuck because a Storage file is
  // already gone (e.g. a previous delete attempt partially succeeded, or a race with another
  // delete of the same observation) or was never uploaded in the first place (a local-only
  // file path, not a Storage URL). Each file is attempted independently so one failure doesn't
  // block cleanup of the rest. Returns the files that could not be deleted, to retry later.
  Future<List<String>> deleteFiles(List<String>? fileUrls) async {
    final failed = <String>[];
    if (fileUrls == null || fileUrls.isEmpty) return failed;

    for (var fileUrl in fileUrls) {
      if (!fileUrl.contains(STORAGE_BUCKET_NAME)) {
        //Not a Storage URL (e.g. still a local file path because it was never uploaded) - nothing to delete remotely.
        continue;
      }

      try {
        await _storage.refFromURL(fileUrl).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          developer.log('Failed to delete storage file $fileUrl: $e', name: 'FirebaseObservationsService');
          failed.add(fileUrl);
        }
      }
    }
    return failed;
  }

  // Everything the admin file tools need: every observation and every Storage file, with
  // proposed link repairs and the files nothing uses. Reads every observation once (one read
  // each), lists both folders, and makes one small Storage request per file, so it only runs
  // when an admin opens one of those screens.
  //
  // Observations come straight from the server and any error stops the scan: a partial or
  // cached list would make files that are in use look unused.
  Future<StorageScan> scanStorage({void Function(int done, int total)? onProgress}) async {
    final snapshot = await observationsCollection.get(const GetOptions(source: Source.server));
    final observations = _observationsFromSnapshot(snapshot);

    final refs = <Reference>[
      for (var folder in [IMAGES_FOLDER_NAME, AUDIO_FOLDER_NAME]) ...await _listAll(_storage.ref(folder)),
    ];
    final listedPaths = {for (var ref in refs) ref.fullPath};
    final usedPaths = <String>{
      for (var observation in observations)
        for (var url in [...?observation.imageUrls, ...?observation.audioUrls])
          if (storagePathFromUrl(url) case final path?) path,
    };

    // Files outside images/ and audio/ that observations point to: check they exist
    for (var path in usedPaths.difference(listedPaths)) {
      try {
        await _storage.ref(path).getMetadata();
        refs.add(_storage.ref(path));
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') rethrow;
      }
    }

    // Used files: a current download URL, to find links whose token changed.
    // Unused files: size and upload time, to match them to observations.
    final filesByPath = <String, StorageFile>{};
    final currentUrlsByPath = <String, String>{};
    var done = 0;
    const batchSize = 25;
    for (var i = 0; i < refs.length; i += batchSize) {
      await Future.wait(refs.skip(i).take(batchSize).map((ref) async {
        final isImage = !ref.fullPath.startsWith("$AUDIO_FOLDER_NAME/");
        if (usedPaths.contains(ref.fullPath)) {
          currentUrlsByPath[ref.fullPath] = await ref.getDownloadURL();
          filesByPath[ref.fullPath] = StorageFile(path: ref.fullPath, isImage: isImage, sizeBytes: 0);
        } else {
          final metadata = await ref.getMetadata();
          filesByPath[ref.fullPath] = StorageFile(path: ref.fullPath, isImage: isImage, sizeBytes: metadata.size ?? 0, created: metadata.timeCreated);
        }
      }));
      done = min(i + batchSize, refs.length);
      onProgress?.call(done, refs.length);
    }

    final result = StorageFileCorrelator(
      observations: observations,
      filesByPath: filesByPath,
      currentUrlsByPath: currentUrlsByPath,
      storagePathFromUrl: storagePathFromUrl,
    ).correlate();

    // Files from the last day are left out of the unused list, because an upload in progress
    // has its file in Storage before its observation is saved
    final cutoff = DateTime.now().subtract(const Duration(days: 1));
    final unused = result.unmatched.where((file) => file.created == null || file.created!.isBefore(cutoff)).toList()
      ..sort((a, b) => (b.created ?? DateTime(0)).compareTo(a.created ?? DateTime(0)));

    return StorageScan(
      fixes: result.fixes,
      unused: unused,
      observationCount: observations.length,
      totalFileCount: refs.length,
    );
  }

  Future<String> downloadUrl(String path) => _storage.ref(path).getDownloadURL();

  // Writes only the photo and recording lists, so nothing else on the observation changes
  Future<void> updateMediaUrls(String observationUid, List<String> imageUrls, List<String> audioUrls) =>
      observationsCollection.doc(observationUid).update({IMAGE_URLS: imageUrls, AUDIO_URLS: audioUrls});

  Future<List<Reference>> _listAll(Reference folder) async {
    final refs = <Reference>[];
    String? pageToken;
    do {
      final page = await folder.list(ListOptions(maxResults: 1000, pageToken: pageToken));
      refs.addAll(page.items);
      pageToken = page.nextPageToken;
    } while (pageToken != null);
    return refs;
  }

  // "images/abc.jpg" from a download URL such as
  // https://firebasestorage.googleapis.com/v0/b/<bucket>/o/images%2Fabc.jpg?alt=media&token=...
  static String? storagePathFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !url.contains(STORAGE_BUCKET_NAME)) return null;
    final index = uri.pathSegments.indexOf("o");
    if (index < 0 || index + 1 >= uri.pathSegments.length) return null;
    return uri.pathSegments.sublist(index + 1).join("/");
  }

  Future<List<StorageFile>> deleteStorageFiles(List<StorageFile> files) async {
    final failed = <StorageFile>[];
    for (var file in files) {
      try {
        await _storage.ref(file.path).delete();
      } on FirebaseException catch (e) {
        if (e.code != 'object-not-found') {
          developer.log('Failed to delete storage file ${file.path}: $e', name: 'FirebaseObservationsService');
          failed.add(file);
        }
      }
    }
    return failed;
  }

  // One page of all observations, newest first, for admins scrolling back through every
  // observation. Pass the previous page's lastDocument to get the next one.
  Future<({List<Observation> observations, DocumentSnapshot? lastDocument})> getObservationsPage({
    DocumentSnapshot? startAfter,
    required int pageSize,
  }) async {
    Query query = observationsCollection.orderBy(DATE, descending: true);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.limit(pageSize).get();
    return (
      observations: _observationsFromSnapshot(snapshot),
      lastDocument: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
    );
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


extension FirebaseObservation on Observation {
  Map<String, dynamic> toFirebaseObservation() => {
    FirebaseObservationsService.OBSERVER_UID: observerUid,
    FirebaseObservationsService.NAME: name,
    FirebaseObservationsService.LOCATION: location,
    FirebaseObservationsService.DATE: date,
    FirebaseObservationsService.ALTITUDE: altitudeInMeters,
    FirebaseObservationsService.LATITUDE: latitude,
    FirebaseObservationsService.LONGITUDE: longitude,
    FirebaseObservationsService.SPECIES: species,
    FirebaseObservationsService.SIGNS: signs,
    FirebaseObservationsService.PIKAS_DETECTED: pikasDetected,
    FirebaseObservationsService.DISTANCE_TO_CLOSEST_PIKA: distanceToClosestPika,
    FirebaseObservationsService.SEARCH_DURATION: searchDuration,
    FirebaseObservationsService.TALUS_AREA: talusArea,
    FirebaseObservationsService.TEMPERATURE: temperature,
    FirebaseObservationsService.SKIES: skies,
    FirebaseObservationsService.WIND: wind,
    FirebaseObservationsService.SITE_HISTORY: siteHistory,
    FirebaseObservationsService.COMMENTS: comments,
    FirebaseObservationsService.IMAGE_URLS: imageUrls,
    FirebaseObservationsService.AUDIO_URLS: audioUrls,
    FirebaseObservationsService.OTHER_ANIMALS_PRESENT: otherAnimalsPresent,
    FirebaseObservationsService.SHARED_WITH_PROJECTS: sharedWithProjects,
    FirebaseObservationsService.NOT_SHARED_WITH_PROJECTS: notSharedWithProjects,
    FirebaseObservationsService.DATE_UPDATED_IN_GOOGLE_SHEETS: dateUpdatedInGoogleSheets,
    FirebaseObservationsService.IS_UPLOADED: isUploaded
  };
}