import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:data_connection_checker_nulls/data_connection_checker_nulls.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:gsheets/gsheets.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/providers/filehost/file_host.dart';
import 'package:provider/provider.dart';

import '../../l10n/translations.dart';
import '../authentication/app_user.dart';
import '../google_sheets/google_sheets_value_exception_pair.dart';
import 'local_observation.dart';
import 'observation.dart';
import '../../model/value_message_pair.dart';
import '../firebase/buckets/firebase_audio_storage_bucket.dart';
import '../firebase/buckets/firebase_images_storage_bucket.dart';
import '../firebase/firebase_firestore_service.dart';
import '../google_sheets/google_sheets_service.dart';


//TODO - this probably needs to get merged into AnimalObservationsFirebaseFirestoreService
class ObservationsService {

  //TODO - this service should have list of observations services and loop through providers, and each service or provider should be able to be used for reading or writing

  //TODO - CHRIS - should this be a list of buckets?
  //there could be any number of image and audio buckets; they do not have to be one to one by file type

  //region File Hosts
  FileHost? imagesFileHost;
  FileHost? audioFileHost;
  //endregion

  //region Observation provider(s)
  //TODO - note if is a local or remote provider
  //endregion

  //region User profile provider(s)
  //TODO - note if is local or remote provider
  //endregion

  //region Authentication provider(s)
  //TODO - note if local or remote
  //endregion

  late Translations translations;
  late GoogleSheetsService googleSheetsService;
  late FirebaseFirestoreService firebaseFirestoreService;

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

  bool _isLocalObservation(Observation localObservation, Observation userObservation) {
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

    var bla = isSameLocation && isSameTime && isSameObserver;
    return bla;
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
    var box = Hive.box<LocalObservation>(FirebaseObservationProvider.COLLECTION_NAME);

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
    var box = Hive.box<LocalObservation>(FirebaseObservationProvider.COLLECTION_NAME);
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
    if (userObservationsOnFirebase.hasData) {
      var data = userObservationsOnFirebase.data;
      if (data != null) {
        _userObservations = data;

        _userObservations = _userObservations.reversed.toList();
        for (var userObservation in _userObservations) {

          var localVersionsOfObservation = _localObservations.where((localObservation) => _isLocalObservation(localObservation, userObservation)).toList();

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
    }
  }
  //endregion

  //region Observation CRUD
  Future<ValueMessagePair?> trySaveObservation(Observation observation, AppUser? user) async {

    /*
      TODO:
      all of this needs to go in the service
      and all of this needs  to start with a uid that is generated with observationsCollection.doc().id
      then, we can use that id to save once locally, save to sheets with and get a real date, and then update firebase so that all is in sync
      one foreseeable issue is going to be isUploaded will not be correct in sheets as firebase call comes after sheets call now
    */


    final originalObservationUid = observation.uid;
    final resolvedObservationUid = originalObservationUid ?? firebaseFirestoreService.observationsCollection.getNewObservationUid();
    observation.uid = resolvedObservationUid;



    //var isInitialObservation = observation.uid == null;//always save a new observation locally




    //"Date" can be set manually by the user for any date they indicate the observation was made.
    // So, do not set the date using DateTime.now!
    final dateUpdated = DateTime.now();
    final originalDateUpdatedInGoogleSheets = observation.dateUpdatedInGoogleSheets;
    observation.dateUpdatedInGoogleSheets = DateTime.now();



    //TODO - CHRIS - probably worth moving to the saveObservationon method
    // TODO: we need an online/offline widget that triggers updates so that we con't have to ask the isOnline question every time
    // Or, given that the online/offline service will poll, maybe request an update at given time or at least request the current state which is then
    // saved for others to register sooner
    var hasConnection = await DataConnectionChecker().hasConnection;
    if (!hasConnection) {
      return ValueMessagePair(null, translations.noConnectionFoundObservationSavedLocally);
    }

    if (user == null) {
      //TODO - should this indicate the user is null so the user can be notified?
      return null;
    }

    //If the observation was made when the user was not logged in, then edited after logging in, the user
    //id can be null. So update it now. This allows local observations to be uploaded when online.
    // However, if it's not null, then an admin could be editing it; so, don't override the original owner's ID
    observation.observerUid ??= user.uid;

    probably need some stuff here
    await saveObservation(observation);

    // Save local observation last to ensure correct information and status for Firebase and Google Sheets,
    // and to avoid having to call multiple times
    var isUsersObservation = user != null && user.uid == observation.observerUid;//don't save another user's observations locally; can happen when admin edits
    if (isUsersObservation) {
      observation.isUploaded = false; how to handle this
      //The observation was updated and not yet uploaded; ensure that's reflected in case !hasConnection
      await saveLocalObservation(observation);//TODO - CHRIS - I don't like the save local, save, save local approach
    }


    //TODO -  should this return a message indicating successful update?
    return null;
  }

  Future saveObservation(Observation observation, {bool saveLocal = true}) async {
    //TODO - CHRIS - compare observation with its firebase counterpart and don't upload if unchanged
    we now have all of our own observations and should compare what we have to the update and only try to update when different

    await saveObservationToFirebase();
    await saveObservationToGoogleSheets();


    var imageUrls = observation.imageUrls;
    if (imageUrls != null && imageUrls.isNotEmpty) {
      observation.imageUrls = await firebaseFirestoreService.observationsCollection.uploadFiles(imageUrls, true);do not upload if no change
    }

    var audioUrls = observation.audioUrls;
    if (audioUrls != null && audioUrls.isNotEmpty) {
      observation.audioUrls = await firebaseFirestoreService.observationsCollection.uploadFiles(audioUrls, false);do not upload if no change
    }

    //Try to update to googleSheets first so that we have a real date that the date actually reflects when sheet updates succeeded
    final lastDateUpdatedInGoogleSheets = observation.dateUpdatedInGoogleSheets;
    final resolvedDateUpdatedInGoogleSheets = DateTime.now();
    observation.dateUpdatedInGoogleSheets = resolvedDateUpdatedInGoogleSheets;

    try {
      var sharedWithProjects = observation.sharedWithProjects;
      sharedWithProjects?.add("Pika Patrol");

      for (var service in googleSheetsService.pikaPatrolSpreadsheetServices) {
        GoogleSheetsValueExceptionPair<bool>? returnValue;
        if (sharedWithProjects?.contains(service.organization) == true) {
          returnValue = await service.observationWorksheetService?.addOrUpdateObservation(observation);
        } else {
          returnValue = await service.observationWorksheetService?.deleteObservation(observation);
        }

        final exception = returnValue?.exception;
        if (exception != null) {
          throw GSheetsException(exception.cause);
        }
      }
    } on GSheetsException catch (e) {
      observation.dateUpdatedInGoogleSheets = lastDateUpdatedInGoogleSheets;
      showToast("Exception: ${e.cause}");//TODO - toast should not be here
    }

    this is where we probably need to use buckets, instead of the observation collection

    //TODO - determine if there are any images that were uploaded and associated with this observation that are no longer associated; delete them from the database
    modify files in the file host now, based on the updated observation files list



      var exception = await firebaseFirestoreService.observationsCollection.updateObservation(observation);
    if (exception != null) {
      showToast("Exception: ${exception.message}");//TODO - toast should not be here
    }

    // Update local observation after successful upload because the uid will be non empty now.
    // Also, if the user was offline and editing an already created observation, isUploaded will be false
    // because firebase will throw an exception of being offline.
    // In that case, track that the updates are no longer uploaded and will need to be the next time internet
    // is available
    if (saveLocal) {
      await saveLocalObservation(observation);
    }
  }

  Future<FirebaseException?> deleteObservation(BuildContext context, Observation observation, bool deleteImages, bool deleteAudio, bool deleteLocal, bool deleteFromFirebase, bool deleteFromGoogleSheets) async {
    if (deleteLocal) {
      await deleteLocalObservation(observation);
    }

    this is where we need to delete the observation images and audio, not in the collection

    FirebaseException? firebaseException;
    if (context.mounted && deleteFromFirebase) {
      var databaseService = Provider.of<FirebaseDatabaseService>(context, listen: false); //TODO - CHRIS - allow use with emulators
      firebaseException = await databaseService.observationsCollection.deleteObservation(observation, deleteImages, deleteAudio);


      if (, bool deleteImages, bool deleteAudio) {
    delete files here instead of in the observationCollection in order to separate concerns
    if for example, we change the file host, then there will not be a need to change the code other than swapping out the file host implementation

    for this to work, need a list of urls for the files
    }
    var exception = deleteImages ? await deleteFiles(NAME, observation.imageUrls) : null;
    if (exception != null) {
    return exception;
    }

    exception = deleteAudio ? await deleteFiles(NAME, observation.audioUrls) : null;
    if (exception != null) {
    return exception;
    }


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
