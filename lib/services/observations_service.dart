import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:gsheets/gsheets.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/utils/observation_utils.dart';
import 'package:provider/provider.dart';

import 'package:pika_patrol/main.dart';
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

  //region Empty Observations
  StreamController<List<Observation>>? _emptyObservationsStreamController;
  Stream<List<Observation>> get emptyObservationsStream {

    _emptyObservationsStreamController = StreamController<List<Observation>>.broadcast(
        onListen: () async {
          _emptyObservationsStreamController?.add([]);
        },
        onCancel: () {
          _emptyObservationsStreamController?.close();
          _emptyObservationsStreamController = null;
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

  //Based on method_channel_query Stream<QuerySnapshotPlatform> snapshots
  // It's fine to let the StreamController be garbage collected once all the
  // subscribers have cancelled; this analyzer warning is safe to ignore.
  StreamController<List<Observation>>? _localObservationsStreamController; // ignore: close_sinks

  Stream<List<Observation>> get localObservationsStream {

    _localObservationsStreamController = StreamController<List<Observation>>.broadcast(
        onListen: () async {
          _localObservationsStreamController?.add(_localObservations);
        },
        onCancel: () {
          _localObservationsStreamController?.close();
          _localObservationsStreamController = null;
        }
    );

    return _localObservationsStreamController!.stream;
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

  setLocalObservations(Box<LocalObservation> box, String userId) {
    Map<dynamic, dynamic> raw = box.toMap();
    List list = raw.values.toList();
    List<Observation> localObservations = <Observation>[];

    localObservations = localObservations.reversed.toList();

    for (var element in list) {
      //TODO - CHRIS - this conversion from LocalObservation to Observation should not happen here
      LocalObservation localObservation = element;

      //Only load observations for the current user or observations that don't have an ownerId because they were made when the user wasn't logged in
      if (localObservation.observerUid == userId || localObservation.observerUid.isEmpty) {
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

  //Based on method_channel_query Stream<QuerySnapshotPlatform> snapshots
  // It's fine to let the StreamController be garbage collected once all the
  // subscribers have cancelled; this analyzer warning is safe to ignore.
  StreamController<List<Observation>>? _sharedObservationsStreamController; // ignore: close_sinks

  Stream<List<Observation>> get sharedObservationsStream {

    _sharedObservationsStreamController = StreamController<List<Observation>>.broadcast(
        onListen: () async {
          _sharedObservationsStreamController?.add(_localObservations);
        },
        onCancel: () {
          _sharedObservationsStreamController?.close();
          _sharedObservationsStreamController = null;
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
  List<Observation> _userObservations = [];

  List<Observation> get userObservations {
    return _userObservations;
  }

  setUserObservations(AsyncSnapshot<List<Observation>> userObservationsOnFirebase) async {
    /*if (userObservationsOnFirebase.hasData) {
      var data = userObservationsOnFirebase.data;
      if (data != null) {
        _userObservations = data;

        _userObservations = _userObservations.reversed.toList();
        for (var userObservation in _userObservations) {

          var localVersionsOfObservation = _localObservations.where((localObservation) => _isLocallySavedObservation(localObservation, userObservation)).toList();

          // There are no local observations matching the remote observations.
          // So, add the remote observation to the local cache to allow the user to restore their observations from another device,
          // or after an uninstall and reinstall.
          if (localVersionsOfObservation.isEmpty) {
            await saveLocalObservation(userObservation);
          }


          //TODO
          for (var localObservationWithSameUid in localVersionsOfObservation) {
            //Is the local observation more up to date?
            // Trigger remote update

            //Is the remote observation more up to date?
            //  Don't trigger remote update
            //  Trigger local update


            //Are the local and remote observations the same?
            //  don't do anything
          }


          userObservation.buttonText = translations.viewObservation;
        }
      }
    }*/
  }
  //endregion

  //region Observation CRUD
  Future<ValueMessagePair?> saveObservation(Observation observation, AppUser? user) async {

    var returnValue = ValueMessagePair<bool>(true, null);

    // TODO: we need an online/offline widget that triggers updates so that we don't have to ask this question every time
    // Or, given that the online/offline service will poll, maybe request an update at given time or at least request the current state which is then
    // saved for others to register sooner
    var hasConnection = await DataConnectionChecker().hasConnection;

    // TODO - ensure that this doesn't hang and prevent local observation from being saved
    if (hasConnection) {
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
        }
      } else {
        //If the uid is null then a new observation was not uploaded to Firebase, so don't update Google Sheets
        //Or, if the uid is not null, but there was an exception, then don't update Google Sheets because the observation wasn't updated in Firebase
        observation.dateUpdatedInGoogleSheets = originalDateUpdatedInGoogleSheets;

        if (firebaseException != null) {
          returnValue = ValueMessagePair(false, firebaseException);
        }
      }
    } else {
      //No need to modify dateUpdatedInGoogleSheets since it is only modified when there is a connection and both Firebase and Google Sheets are updated
      //No need to modify isUploaded since that is only set to false when the observation is saved by the user and an attempt is made to save to Firebase

      returnValue = ValueMessagePair(false, translations.noConnectionFoundObservationSavedLocally);
    }

    //Only save the current user's observations locally, not other observations the current user modified as admin
    if (observation.isUserObservation(user)) {
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
