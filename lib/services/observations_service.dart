import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/utils/observation_utils.dart';
import 'package:pika_patrol/utils/primitive_utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pika_patrol/services/firebase_observations_service.dart';
import 'package:pika_patrol/services/google_sheets_service.dart';

import '../l10n/translations.dart';
import '../model/app_user.dart';
import '../model/gsheets_value.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import '../model/value_message_pair.dart';
import '../services/firebase_database_service.dart';

class ObservationsService {

  late Translations translations;
  late GoogleSheetsService googleSheetsService;
  late FirebaseDatabaseService _firebaseDatabaseService;//TODO - should this be firebase_observations_service?
  FirebaseDatabaseService get firebaseDatabaseService => _firebaseDatabaseService;
  set firebaseDatabaseService(FirebaseDatabaseService service) {
    _firebaseDatabaseService = service;
    service.observationsService.onFileDeletesFailed = _addPendingFileDeletes;
    _loadHasPendingRetries();
  }

  // True when a Sheets sync or a Storage delete still needs retrying, so the app retries when it
  // comes online even if every observation is already uploaded
  bool _hasPendingRetries = false;
  bool get hasPendingRetries => _hasPendingRetries;
  bool _hasLoadedPendingRetries = false;

  Future<void> _loadHasPendingRetries() async {
    if (_hasLoadedPendingRetries) return;
    _hasLoadedPendingRetries = true;
    await _refreshHasPendingRetries();
  }

  Future<void> _refreshHasPendingRetries() async {
    final prefs = await SharedPreferences.getInstance();
    _hasPendingRetries = (prefs.getStringList(_PENDING_GOOGLE_SHEETS_SYNC_KEY)?.isNotEmpty ?? false)
        || (prefs.getStringList(_PENDING_FILE_DELETES_KEY)?.isNotEmpty ?? false);
  }

  void refreshLocalizedCardText() {
    final localizedViewObservation = translations.viewObservation;
    var changed = false;

    for (final observation in _localObservations) {
      if (observation.buttonText != localizedViewObservation) {
        observation.buttonText = localizedViewObservation;
        changed = true;
      }
    }

    for (final observation in _sharedObservations) {
      if (observation.buttonText != localizedViewObservation) {
        observation.buttonText = localizedViewObservation;
        changed = true;
      }
    }

    for (final observation in _userObservations) {
      if (observation.buttonText != localizedViewObservation) {
        observation.buttonText = localizedViewObservation;
        changed = true;
      }
    }

    if (changed) {
      _localObservationsStreamController?.add(_localObservations);
      _sharedObservationsStreamController?.add(_sharedObservations);
    }
  }

  //region Empty Observations
  StreamController<List<Observation>>? _emptyObservationsStreamController;
  Stream<List<Observation>> get emptyObservationsStream {
    _emptyObservationsStreamController ??= StreamController<List<Observation>>.broadcast(
        onListen: () {
          _emptyObservationsStreamController?.add([]);
        }
    );

    return _emptyObservationsStreamController!.stream;
  }
  //endregion

  //region Local Observations
  List<Observation> _localObservations = [];

  List<Observation> get localObservations {
    return _localObservations;
  }

  // Memoized (created once, never recreated/closed) so the widget tree always pushes into the
  // same controller. Previously this getter created a *new* StreamController on every call - since
  // it's read fresh inside a StreamBuilder's `stream:` argument, any rebuild handed StreamBuilder a
  // different Stream instance and it would resubscribe. Meanwhile setLocalObservations() only ever
  // pushes into whatever controller this field *currently* points to, so a subscriber holding onto
  // an older controller (or a moment where the field was null after the last listener cancelled)
  // silently stopped receiving live updates until something else forced a fresh rebuild/resubscribe
  // (backgrounding/foregrounding the app, or saving a new observation, which happened to trigger one).
  StreamController<List<Observation>>? _localObservationsStreamController; // ignore: close_sinks

  Stream<List<Observation>> get localObservationsStream {
    _localObservationsStreamController ??= StreamController<List<Observation>>.broadcast(
        onListen: () {
          _localObservationsStreamController?.add(_localObservations);
        }
    );

    return _localObservationsStreamController!.stream;
  }

  // Reads the Hive box directly rather than _localObservations, because _localObservations is
  // filtered by LocalObservation.canUserEdit(user) - once a user is logged in, an observation with
  // no observerUid no longer passes that check (it's neither "this user's" nor "no one's, while no
  // one's logged in"), so it silently drops out of _localObservations and "My Observations" even
  // though it's still sitting in the box. This is exactly what needs surfacing at login time.
  List<LocalObservation> getUnassociatedLocalObservations() {
    var box = Hive.box<LocalObservation>(FirebaseObservationsService.OBSERVATIONS_COLLECTION_NAME);
    return box.values.where((localObservation) => localObservation.observerUid.isEmpty).toList();
  }

  Future<void> associateLocalObservationsWithUser(String userId) async {
    for (var localObservation in getUnassociatedLocalObservations()) {
      localObservation.observerUid = userId;
      await localObservation.save();
    }
  }

  // Shared by the reconnect-polling listener, the app-resume check, and the post-association
  // flow - anywhere that just learned "there's a logged-in user and a network, so anything
  // pending should go up now" rather than waiting for the next unrelated trigger to happen to
  // fire. In particular: logging in (and therefore associating local observations with the
  // account) only ever happens while already online, so a connectivity-*change* listener never
  // fires for it - nothing else was prompting an upload attempt at that moment.
  //
  // These triggers can overlap in time (e.g. a connectivity-change fires around the same moment
  // the associate-with-account dialog is accepted). Each call to saveObservation() mints a brand
  // new Firestore doc for any observation whose uid is still empty, so two overlapping runs over
  // the same not-yet-uploaded local observation raced to upload it twice under two different
  // Firestore doc IDs before either run's result made it back into Hive. Caching the in-flight
  // Future means a second caller just awaits the first run instead of starting its own.
  Future<void>? _pendingUploadFuture;

  Future<void> uploadPendingLocalObservations(AppUser user) {
    return _pendingUploadFuture ??= _uploadPendingLocalObservations(user).whenComplete(() {
      _pendingUploadFuture = null;
    });
  }

  Future<void> _uploadPendingLocalObservations(AppUser user) async {
    // Refresh from the Hive box first: _localObservations is filtered by canUserEdit(user), so an
    // observation that was just associated with this user (e.g. via associateLocalObservationsWithUser)
    // may not have made it into that cache yet - nothing else forces a rebuild before this runs.
    // Without this, the observation is invisible to the loop below and never gets uploaded.
    setLocalObservations(Hive.box<LocalObservation>(FirebaseObservationsService.OBSERVATIONS_COLLECTION_NAME), user);

    for (var localObservation in localObservations) {
      if (!localObservation.isUploaded) {
        await saveObservation(localObservation, user);
      }
    }

    await _retryPendingGoogleSheetsSyncs();
    await _retryPendingFileDeletes();
  }

  // Storage files that could not be deleted (for example while offline) are remembered on the
  // device and retried the next time the app is online, so removed photos and recordings never
  // stay in Storage, where they would keep costing money.
  static const String _PENDING_FILE_DELETES_KEY = "pendingFileDeletes";

  Future<void> _addPendingFileDeletes(List<String> fileUrls) async {
    if (fileUrls.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = (prefs.getStringList(_PENDING_FILE_DELETES_KEY) ?? <String>[]).toSet()..addAll(fileUrls);
    await prefs.setStringList(_PENDING_FILE_DELETES_KEY, pending.toList());
    await _refreshHasPendingRetries();
  }

  Future<void> _retryPendingFileDeletes() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_PENDING_FILE_DELETES_KEY) ?? <String>[];
    if (pending.isEmpty) return;
    final failed = await firebaseDatabaseService.observationsService.deleteFiles(pending);
    await prefs.setStringList(_PENDING_FILE_DELETES_KEY, failed);
    await _refreshHasPendingRetries();
  }

  // Google Sheets can be unreachable when an observation is saved, after Firebase already has it.
  // Remember those observations on the device and retry them the next time the app is online,
  // instead of re-checking every observation (which would cost far more reads).
  static const String _PENDING_GOOGLE_SHEETS_SYNC_KEY = "pendingGoogleSheetsSync";

  Future<void> _setPendingGoogleSheetsSync(String? observationUid, bool isPending) async {
    if (observationUid == null || observationUid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final pending = (prefs.getStringList(_PENDING_GOOGLE_SHEETS_SYNC_KEY) ?? <String>[]).toSet();
    final changed = isPending ? pending.add(observationUid) : pending.remove(observationUid);
    if (changed) {
      await prefs.setStringList(_PENDING_GOOGLE_SHEETS_SYNC_KEY, pending.toList());
      await _refreshHasPendingRetries();
    }
  }

  Future<void> _retryPendingGoogleSheetsSyncs() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList(_PENDING_GOOGLE_SHEETS_SYNC_KEY) ?? <String>[];
    for (var uid in pending) {
      final matches = localObservations.where((observation) => observation.uid == uid && observation.isUploaded == true);
      if (matches.isEmpty) {
        // Deleted, or belongs to another account on this device; nothing to retry here
        continue;
      }
      final results = await saveObservationToGoogleSheets(matches.first);
      final failed = results.any((result) => result.exception != null);
      await _setPendingGoogleSheetsSync(uid, failed);
    }
  }

  //TODO - why is this here vs utils?
  bool _isLocallySavedObservation(Observation localObservation, Observation userObservation) {

    //this would be preferable for comparison, but it fails immediately after creating an observation
    if (userObservation.uid == localObservation.uid) {
      return true;
    }

    // If the uid isn't available yet, e.g. right after adding to the local store and waiting for another update to the local store with the uid
    // Then use a combo of info to determine if there is a local version of the observation already.
    // Note that it would be very hard to have the same user make observations at the exact same time, and then even harder to make them with the same exact name
    var isSameName = userObservation.name == localObservation.name;
    var isSameLocation = userObservation.location == localObservation.location;
    var userDate = userObservation.date;
    var localDate = localObservation.date;

    //Don't compare with equals as the microseconds are not exactly the same for whatever reason.
    //So, if the time is within a second, it's likely the same observation
    var isSameTime = false;
    if (userDate != null && localDate !=null) {
      isSameTime = userDate.difference(localDate) < const Duration(minutes: 1);
    }

    var isSameObserver = userObservation.observerUid == localObservation.observerUid;

    return isSameLocation && isSameTime && isSameObserver;
  }

  setLocalObservations(Box<LocalObservation> box, AppUser? user) {
    Map<dynamic, dynamic> raw = box.toMap();
    List list = raw.values.toList();
    List<Observation> localObservations = <Observation>[];

    localObservations = localObservations.reversed.toList();

    for (var element in list) {
      //TODO - CHRIS - this conversion from LocalObservation to Observation should not happen here
      LocalObservation localObservation = element;

      //Only load observations for the current user or observations that don't have an ownerId because they were made when the user wasn't logged in
      final canUserEdit = localObservation.canUserEdit(user);

      //Given that admin can edit any observation, we need to avoid allowing an admin on the device to edit local observations on the device that were made by a non-logged in user
      //because this would result in the observation being uploaded to Firebase with an empty observer uid.
      //To make the logic easier, only show local observations for the logged in user or observations for a non-logged-in user made by a non-logged-in user (as though non-logged-in is a user itself)
      final isAdmin = user?.isAdmin == true;
      final isAdminAndNonLoggedInUserObservation = isAdmin && localObservation.observerUid.isNullOrEmpty;

      if (canUserEdit && !isAdminAndNonLoggedInUserObservation) {
        var observation = Observation(
            dbId: localObservation.key,
            uid: localObservation.uid,
            observerUid: localObservation.observerUid,
            name: localObservation.name,
            location: localObservation.location,
            date: localObservation.date.isEmpty ? null : DateTime.parse(localObservation.date),
            altitudeInMeters: localObservation.altitudeInMeters,
            latitude: localObservation.latitude,
            longitude: localObservation.longitude,
            species: localObservation.species,
            signs: localObservation.signs,
            pikasDetected: localObservation.pikasDetected,
            distanceToClosestPika: localObservation.distanceToClosestPika,
            searchDuration: localObservation.searchDuration,
            talusArea: localObservation.talusArea,
            temperature: localObservation.temperature,
            skies: localObservation.skies,
            wind: localObservation.wind,
            siteHistory: localObservation.siteHistory,
            comments: localObservation.comments,
            imageUrls: localObservation.imageUrls,
            audioUrls: localObservation.audioUrls,
            otherAnimalsPresent: localObservation.otherAnimalsPresent,
            sharedWithProjects: localObservation.sharedWithProjects,
            notSharedWithProjects: localObservation.notSharedWithProjects,
            dateUpdatedInGoogleSheets: localObservation.dateUpdatedInGoogleSheets.isEmpty ? null : DateTime.parse(localObservation.dateUpdatedInGoogleSheets),
            isUploaded: localObservation.isUploaded,
            buttonText: translations.viewObservation
        );
        localObservations.add(observation);
      }
    }

    _localObservations = localObservations;
    _localObservationsStreamController?.add(_localObservations);
  }

  Future<LocalObservation?> saveLocalObservation(Observation observation) async {
    var box = Hive.box<LocalObservation>(FirebaseObservationsService.OBSERVATIONS_COLLECTION_NAME);

    LocalObservation? currentLocalObservation = box.get(observation.dbId);
    if (currentLocalObservation == null) {
      //The observation screen can be opened from an online observation, which means that the dbId can be null.
      //So, make sure we associate the dbId if there's a local copy so that we don't duplicate local copies
      Map<dynamic, dynamic> raw = box.toMap();
      List list = raw.values.toList();

      for (var element in list) {
        LocalObservation localObservation = element;
        if (localObservation.uid == observation.uid) {
          currentLocalObservation = localObservation;
          break;
        }
      }
    }

    var localObservation = LocalObservation(
        uid: observation.uid ?? "",
        observerUid: observation.observerUid ?? "",
        name: observation.name ?? "",
        location: observation.location ?? "",
        date: observation.date?.toString() ?? "",
        altitudeInMeters: observation.altitudeInMeters ?? 0.0,
        latitude: observation.latitude ?? 0.0,
        longitude: observation.longitude ?? 0.0,
        species: observation.species,
        signs: observation.signs ?? <String>[],
        pikasDetected: observation.pikasDetected ?? "",
        distanceToClosestPika: observation.distanceToClosestPika ?? "",
        searchDuration: observation.searchDuration ?? "",
        talusArea: observation.talusArea ?? "",
        temperature: observation.temperature ?? "",
        skies: observation.skies ?? "",
        wind: observation.wind ?? "",
        siteHistory: observation.siteHistory ?? "",
        comments: observation.comments ?? "",
        imageUrls: observation.imageUrls ?? <String>[],
        audioUrls: observation.audioUrls ?? <String>[],
        otherAnimalsPresent: observation.otherAnimalsPresent ?? <String>[],
        sharedWithProjects: observation.sharedWithProjects ?? <String>[],
        notSharedWithProjects: observation.notSharedWithProjects ?? <String>[],
        dateUpdatedInGoogleSheets: observation.dateUpdatedInGoogleSheets?.toString() ?? "",
        isUploaded: observation.isUploaded ?? false
    );

    if(currentLocalObservation == null) {
      int? key = await box.add(localObservation);

      //If the user remains on the observation page, they can edit/save again. In that case, they need
      //to use the same database ID instead of adding a new entry each time
      observation.dbId = key;
    } else {
      observation.dbId = currentLocalObservation.key;
      await box.put(observation.dbId, localObservation);
    }

    return box.get(observation.dbId);
  }

  Future deleteLocalObservation(Observation observation) async {
    var box = Hive.box<LocalObservation>(FirebaseObservationsService.OBSERVATIONS_COLLECTION_NAME);
    if (observation.dbId != null) {
      // Deleting from cached observations, the observation will have a dbId, but might not have a uid
      await box.delete(observation.dbId);
    } else {
      // Deleting from shared observations, the observation will hava uid but not a dbId
      for (var localObservation in box.values) {
        if (localObservation.uid == observation.uid) {
          await box.delete(localObservation.key);
          return;
        }
      }
    }
  }
  //endregion

  //region Shared Observations
  List<Observation> _sharedObservations = [];

  List<Observation> get sharedObservations {
    return _sharedObservations;
  }

  // Memoized for the same reason as _localObservationsStreamController above.
  StreamController<List<Observation>>? _sharedObservationsStreamController; // ignore: close_sinks

  Stream<List<Observation>> get sharedObservationsStream {
    _sharedObservationsStreamController ??= StreamController<List<Observation>>.broadcast(
        onListen: () {
          _sharedObservationsStreamController?.add(_sharedObservations);
        }
    );

    return _sharedObservationsStreamController!.stream;
  }

  // Everyone gets a live view of the newest observations. Admins can also scroll back through
  // every observation: older ones load one small page at a time as they near the end, and pages
  // already loaded stay in memory, so nothing is read twice in a session.
  static const int SHARED_OBSERVATIONS_PAGE_SIZE = 10;

  List<Observation> _liveSharedObservations = [];
  final List<Observation> _olderSharedObservations = [];
  DocumentSnapshot? _lastSharedObservationsPageDocument;
  bool _hasMoreSharedObservations = true;
  bool _isLoadingSharedObservations = false;

  setSharedObservations(AsyncSnapshot<List<Observation>> sharedObservationsOnFirebase) {
    if (sharedObservationsOnFirebase.hasData) {
      var data = sharedObservationsOnFirebase.data;
      if (data != null) {
        _liveSharedObservations = data;
        _publishSharedObservations();
      }
    }
  }

  Future<void> loadMoreSharedObservations() async {
    if (_isLoadingSharedObservations || !_hasMoreSharedObservations) return;
    _isLoadingSharedObservations = true;
    try {
      final page = await firebaseDatabaseService.observationsService.getObservationsPage(
        startAfter: _lastSharedObservationsPageDocument,
        pageSize: SHARED_OBSERVATIONS_PAGE_SIZE,
      );
      _lastSharedObservationsPageDocument = page.lastDocument;
      _hasMoreSharedObservations = page.observations.length == SHARED_OBSERVATIONS_PAGE_SIZE;
      _olderSharedObservations.addAll(page.observations);
      _publishSharedObservations();
    } on FirebaseException catch (e) {
      developer.log('Could not load more shared observations: $e', name: 'ObservationsService');
    } finally {
      _isLoadingSharedObservations = false;
    }
  }

  // Keeps loaded pages in step with this device's saves and deletes, without reading them again
  void _updateOlderSharedObservation(Observation observation, {bool deleted = false}) {
    final index = _olderSharedObservations.indexWhere((older) => older.uid != null && older.uid == observation.uid);
    if (index < 0) return;
    if (deleted) {
      _olderSharedObservations.removeAt(index);
    } else {
      _olderSharedObservations[index] = observation.copy();
    }
    _publishSharedObservations();
  }

  void _publishSharedObservations() {
    // Newest first: the live observations, then older pages without the ones already shown
    final liveUids = _liveSharedObservations.map((observation) => observation.uid).toSet();
    final newestFirst = [
      ..._liveSharedObservations,
      ..._olderSharedObservations.where((observation) => !liveUids.contains(observation.uid)),
    ];

    // The card stack shows the last card on top, so the newest goes last
    _sharedObservations = newestFirst.reversed.toList();
    for (var sharedObservation in  _sharedObservations) {
      sharedObservation.buttonText = translations.viewObservation;
    }

    _sharedObservationsStreamController?.add(_sharedObservations);
  }
  //endregion

  //region User Observations
  final List<Observation> _userObservations = [];

  List<Observation> get userObservations {
    return _userObservations;
  }

  setUserObservations(AsyncSnapshot<List<Observation>> userObservationsOnFirebase) async {
    if (userObservationsOnFirebase.hasError) {
      // e.g. a missing Firestore composite index or a security rules rejection - this fails
      // silently otherwise, so log it to make that class of regression visible.
      developer.log(
        'Failed to fetch user observations from Firestore: ${userObservationsOnFirebase.error}',
        name: 'ObservationsService',
      );
      return;
    }

    if (!userObservationsOnFirebase.hasData) return;

    var remoteObservations = userObservationsOnFirebase.data;
    if (remoteObservations == null) return;

    for (var remoteObservation in remoteObservations) {
      var localVersionsOfObservation = _localObservations.where((localObservation) => _isLocallySavedObservation(localObservation, remoteObservation)).toList();

      // There's no local copy of this remote observation yet - e.g. it was created on another
      // device, or this is a fresh install. Cache it locally so "My Observations" (which only
      // reads the local cache, not Firestore directly) can show it without another server call.
      if (localVersionsOfObservation.isEmpty) {
        remoteObservation.buttonText = translations.viewObservation;
        await saveLocalObservation(remoteObservation);
      }
    }

    // Prune the other direction too: a local observation that was previously synced to Firestore
    // but is no longer in this fetch is one that got deleted - by this device before this listener
    // caught up, or by another device entirely. Without this, deleting an uploaded observation on
    // one device would never be reflected in another device's local cache. Purely local,
    // never-uploaded observations are left untouched - they're not ours to prune based on what
    // Firestore has. No extra network calls: this reuses the already-open userObservations
    // listener's data instead of asking the server anything new.
    //
    // Must check isUploaded here, not isRemoteObservation()/uid != null: LocalObservation.uid is a
    // non-nullable String defaulting to "" (never actually null), so an Observation built from one
    // via setLocalObservations always has uid != null - isRemoteObservation() was true even for a
    // brand-new, never-uploaded local observation. That made every local observation look like it
    // had already been synced and was now "deleted remotely" the moment nothing matched it in the
    // current fetch, which for a logged-out user (whose fetch is always an empty list) meant any
    // observation just saved locally got immediately pruned again.
    var deletedRemotely = _localObservations.where((localObservation) {
      if (!localObservation.isUploaded) return false;
      return !remoteObservations.any((remoteObservation) => _isLocallySavedObservation(localObservation, remoteObservation));
    }).toList();

    for (var staleObservation in deletedRemotely) {
      await deleteLocalObservation(staleObservation);
    }
  }
  //endregion

  //region Observation CRUD
  Future<ValueMessagePair?> saveObservation(Observation observation, AppUser? user) async {

    var returnValue = ValueMessagePair<bool>(true, null);

    if (user == null) {
      // Not logged in: this is always a local-only save, so skip the connectivity probe below -
      // DataConnectionChecker pings real hosts and can take several seconds (much longer when
      // actually offline), and its result was never used on this branch anyway. Awaiting it here
      // just delayed the local save (further down) for no reason.
      returnValue = ValueMessagePair(false, translations.youMustLoginToUploadAnObservationObservationSavedLocally);
    } else {
      // TODO: we need an online/offline widget that triggers updates so that we don't have to ask this question every time
      // Or, given that the online/offline service will poll, maybe request an update at given time or at least request the current state which is then
      // saved for others to register sooner
      var hasConnection = await DataConnectionChecker().hasConnection;

      if (!hasConnection) {
        //No need to modify dateUpdatedInGoogleSheets since it is only modified when there is a connection and both Firebase and Google Sheets are updated
        //No need to modify isUploaded since that is only set to false when the observation is saved by the user and an attempt is made to save to Firebase

        returnValue = ValueMessagePair(false, translations.noConnectionFoundObservationSavedLocally);
      } else {
        // "Date" can be set manually by the user to indicate the date the observation was made.
        // So, do not set the date using DateTime.now!
        // Instead, track the date updated to google sheets in order to determine the last time an observation was updated and successfully synced
        // Also, if there is no connection, then all remote updates will fail, so don't worry about trying to update the dateUpdatedInGoogleSheets as it will just be reset to the original value

        //dateUpdatedInGoogleSheets is updated here so that Firebase is up-to-date without having to write twice (second write would occur after Google Sheets is updated)
        final originalDateUpdatedInGoogleSheets = observation.dateUpdatedInGoogleSheets;
        observation.dateUpdatedInGoogleSheets = DateTime.now();

        final firebaseReturnValue = await saveObservationToFirebase(observation);
        final firebaseException = firebaseReturnValue?.message;
        final firebaseUpdated = firebaseException == null && observation.uid != null;

        if (firebaseUpdated) {
          // Persist the Firebase result (isUploaded + real uid) to Hive right away, before the
          // slower/less reliable Google Sheets sync runs. Otherwise, if the app is interrupted
          // during that sync, Hive is left showing isUploaded: false with an empty uid even though
          // Firebase already has the doc - so any later retry re-uploads it and, because uid is
          // still empty, mints a second Firebase doc for the same local observation.
          if (observation.isUserObservation(user) || observation.isNonLoggedInUserObservation(user)) {
            await saveLocalObservation(observation);
          }
          _updateOlderSharedObservation(observation);

          final List<GSheetsValue> googleSheetsReturnValue = await saveObservationToGoogleSheets(observation);
          final googleSheetsException = googleSheetsReturnValue.where((value) => value.exception != null).firstOrNull?.exception;
          await _setPendingGoogleSheetsSync(observation.uid, googleSheetsException != null);

          if (googleSheetsException != null) {
            returnValue = ValueMessagePair(false, googleSheetsException.cause);
          } else {
            returnValue = ValueMessagePair(true, translations.observationSavedSuccessfully);
          }
        } else {
          //If the uid is null then a new observation was not uploaded to Firebase, so don't update Google Sheets
          //Or, if the uid is not null, but there was an exception, then don't update Google Sheets because the observation wasn't updated in Firebase
          observation.dateUpdatedInGoogleSheets = originalDateUpdatedInGoogleSheets;

          if (firebaseException != null) {
            returnValue = ValueMessagePair(false, firebaseException);
          } else {
            returnValue = ValueMessagePair(false, translations.unknownErrorUploadingToServerObservationSavedLocally);
          }
        }
      }
    }

    //Only save the current user's observations locally, not other observations the current user modified as admin
    if (observation.isUserObservation(user) || observation.isNonLoggedInUserObservation(user)) {
      // Save local observation last to ensure correct information and status for Firebase and Google Sheets
      await saveLocalObservation(observation);
    }

    return returnValue;
  }

  Future<FirebaseException?> saveObservationToFirebase(Observation observation) async {

    //TODO - CHRIS - compare observation with its firebase counterpart and don't upload if unchanged

    //TODO - we now have all of our own observations nad should compare what we have to the update and only try to update when different

    var imageUrls = observation.imageUrls;
    if (imageUrls != null && imageUrls.isNotEmpty) {
      observation.imageUrls = await firebaseDatabaseService.observationsService.uploadFiles(imageUrls, true);//TODO - do not upload if no change
    }

    var audioUrls = observation.audioUrls;
    if (audioUrls != null && audioUrls.isNotEmpty) {
      observation.audioUrls = await firebaseDatabaseService.observationsService.uploadFiles(audioUrls, false);//TODO - do not upload if no chane
    }

    // addOrUpdateObservation also deletes Storage files the user removed from the observation
    return await firebaseDatabaseService.observationsService.addOrUpdateObservation(observation);
  }

  Future<List<GSheetsValue>> saveObservationToGoogleSheets(Observation observation) async {

    //Try to update to googleSheets first so that we have a real date that actually reflects when sheet updates succeeded
    final lastDateUpdatedInGoogleSheets = observation.dateUpdatedInGoogleSheets;
    observation.dateUpdatedInGoogleSheets = DateTime.now();

    List<GSheetsValue> returnValues = [];

    // Every observation goes to the master sheet, even when it isn't shared with any project.
    // Copy the list so the observation itself never gets the hidden master project added to it.
    var sharedWithProjects = {...?observation.sharedWithProjects, GoogleSheetsService.MASTER_PROJECT};

    GSheetsException? firstException;

    //Update all organization's spreadsheets even if an exception is thrown for one of them, since a single sheet can have an error while others are don't
    for (var service in googleSheetsService.pikaPatrolSpreadsheetServices) {
      GSheetsValue<bool>? returnValue;
      if (sharedWithProjects.contains(service.organization)) {
        returnValue = await service.observationWorksheetService?.addOrUpdateObservation(observation);
      } else {
        //TODO - it would be nice if we could know if the observation was previously shared with the organization, but now isn't
        //in order to reduce the number of calls being made to google sheets
        //Just in case the observation was previously shared with the organization, but now isn't
        returnValue = await service.observationWorksheetService?.deleteObservation(observation);
      }

      if (returnValue != null) {
        returnValues.add(returnValue);
      }

      firstException = firstException ?? returnValue?.exception;
    }

    if (firstException != null) {
      //Indicate that one or more sheets did not update successfully
      observation.dateUpdatedInGoogleSheets = lastDateUpdatedInGoogleSheets;
    }

    return returnValues;
  }

  Future<FirebaseException?> deleteObservation(BuildContext context, Observation observation, bool deleteImages, bool deleteAudio, bool deleteLocal, bool deleteFromFirebase, bool deleteFromGoogleSheets) async {
    if (deleteLocal) {
      await deleteLocalObservation(observation);
    }

    // Deleting from Firebase also deletes the observation's photos and recordings from Storage
    FirebaseException? firebaseException;
    if (context.mounted && deleteFromFirebase) {
      var databaseService = Provider.of<FirebaseDatabaseService>(context, listen: false); //TODO - CHRIS - allow use with emulators
      firebaseException = await databaseService.observationsService.deleteObservation(observation, deleteImages, deleteAudio);
      _updateOlderSharedObservation(observation, deleted: true);
    }

    if (context.mounted && deleteFromGoogleSheets) {
      var sheetsService = Provider.of<GoogleSheetsService>(context, listen: false);
      for (var service in sheetsService.pikaPatrolSpreadsheetServices) {
        service.observationWorksheetService?.deleteObservation(observation);
        await Future.delayed(const Duration(milliseconds: GoogleSheetsService.LESS_THAN_60_WRITES_DELAY_MS), () {});
      }
    }

    return firebaseException;
  }
//endregion
}
