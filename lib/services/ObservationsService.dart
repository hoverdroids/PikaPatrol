import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import '../l10n/translations.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';

class ObservationsService {

  late Translations translations;

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

  List<Observation> _userObservations = [];

  List<Observation> get userObservations {
    return _userObservations;
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

  setUserObservations(AsyncSnapshot<List<Observation>> userObservationsOnFirebase) {
    if (userObservationsOnFirebase.hasData) {
      var data = userObservationsOnFirebase.data;
      if (data != null) {
        _userObservations = data;

        _userObservations = _userObservations.reversed.toList();
        for (var userObservation in _userObservations) {
          userObservation.buttonText = translations.viewObservation;
        }

        //Now, how to handle ...
        //We've tracked the observations as is, but need to merge with local observations
        //we could start by comparing and ensuring uniqueness, to prove the concept
        //Then, the observations should all be local because we want to save observations that are online and not on our phone
        //Saving the observations that are online and not on the phone will cause the localobservations observable to trigger and update the list
        //with the same mechanism
        //This could also determine if the online observations are in sync with local observations, and determine if the user should be notified
        //that the observations need to be uploaded
        //We can and should also just upload them without notifying the users
        //This means we need to get the user's online observations first so that we can compare and save them

        _localObservations = _userObservations;
        _localObservationsStreamController?.add(_localObservations);
      }
    }
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
        //localObservations.add(observation);
      }
    }

    /*_localObservations = localObservations;
    _localObservationsStreamController?.add(_localObservations);*/
  }
}
