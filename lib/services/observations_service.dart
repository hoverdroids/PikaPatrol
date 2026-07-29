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
  late FirebaseDatabaseService firebaseDatabaseService;//TODO - should this be firebase_observations_service?

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

  setSharedObservations(AsyncSnapshot<List<Observation>> sharedObservationsOnFirebase) {
    if (sharedObservationsOnFirebase.hasData) {
      var data = sharedObservationsOnFirebase.data;
      if (data != null) {
        _sharedObservations = data;

        _sharedObservations = _sharedObservations.reversed.toList();
        for (var sharedObservation in  _sharedObservations) {
          sharedObservation.buttonText = translations.viewObservation;
        }

        _sharedObservationsStreamController?.add(_sharedObservations);
      }
    }
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
          final List<GSheetsValue> googleSheetsReturnValue = await saveObservationToGoogleSheets(observation);
          final googleSheetsException = googleSheetsReturnValue.first.exception;

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

    //TODO - determine if there are any images that were uploaded and associated with this observation that are no longer associated; delete them from the database

    //TODO - modify files in the file host now, based on the updated observation files list

    return await firebaseDatabaseService.observationsService.addOrUpdateObservation(observation);
  }

  Future<List<GSheetsValue>> saveObservationToGoogleSheets(Observation observation) async {

    //Try to update to googleSheets first so that we have a real date that actually reflects when sheet updates succeeded
    final lastDateUpdatedInGoogleSheets = observation.dateUpdatedInGoogleSheets;
    observation.dateUpdatedInGoogleSheets = DateTime.now();

    List<GSheetsValue> returnValues = [];

    var sharedWithProjects = observation.sharedWithProjects;
    sharedWithProjects?.add("Pika Patrol");

    GSheetsException? firstException;

    //Update all organization's spreadsheets even if an exception is thrown for one of them, since a single sheet can have an error while others are don't
    for (var service in googleSheetsService.pikaPatrolSpreadsheetServices) {
      GSheetsValue<bool>? returnValue;
      if (sharedWithProjects?.contains(service.organization) == true) {
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

    //TODO -  this is where we need to delete the observation images and audio, not in the collection

    FirebaseException? firebaseException;
    if (context.mounted && deleteFromFirebase) {
      var databaseService = Provider.of<FirebaseDatabaseService>(context, listen: false); //TODO - CHRIS - allow use with emulators
      firebaseException = await databaseService.observationsService.deleteObservation(observation, deleteImages, deleteAudio);
    }

    /*
    TODO - figure out where I was going with the following
      if (bool deleteImages, bool deleteAudio) {
        //delete files here instead of in the observationCollection in order to separate concerns
        //if for example, we change the file host, then there will not be a need to change the code other than swapping out the file host implementation

        //for this to work, need a list of urls for the files

        var exception = deleteImages ? await deleteFiles(FOLDER_NAME, observation.imageUrls) : null;
        if (exception != null) {
          return exception;
        }

        exception = deleteAudio ? await deleteFiles(FOLDER_NAME, observation.audioUrls) : null;
        if (exception != null) {
          return exception;
        }
      }


     */

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
