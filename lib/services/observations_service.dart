import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import '../l10n/translations.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import '../utils/observation_utils.dart';

class ObservationsService {

  late Translations translations;

  StreamController<List<Observation>>? _emptyObservationsStreamController;
  Stream<List<Observation>> get emptyObservationsStream {

    _emptyObservationsStreamController = StreamController<List<Observation>>.broadcast(
      onListen: () async {
        _emptyObservationsStreamController?.add([]);
      }, onCancel: () {
        _emptyObservationsStreamController?.close();
        _emptyObservationsStreamController = null;
      }
    );

    return _emptyObservationsStreamController!.stream;
  }

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
        for( var sharedObservation in _sharedObservations) {
          sharedObservation.buttonText = translations.viewObservation;
        }

        _sharedObservationsStreamController?.add(_sharedObservations);
      }
    }
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
            // Is the local observation more up to date?
            // Trigger remote update

            //Is the remote observation more up to date?
            //Don't trigger remote update
            //Trigger local update

            //Are the local and remote observations the same?
            //Don't do anything
          }

          userObservation.buttonText = translations.viewObservation;
        }
      }
    }
  }

  bool _isLocalObservation(Observation localObservation, Observation userObservation) {
    //this would be preferable for comparison, but it fails immediately after creating an observation
    if (userObservation.uid == localObservation.uid) {
      return true;
    }

    // IF the uid isn't available yet, e.g. right after adding to the local store and waiting for another update to the local store with the uid
    // then use a combo of info to determine if there is a local version of the observation already.
    // Note that it would e very hard to have the same user make observations at the exact same time, and then even harder to make them with the same exact name
    var isSameName = userObservation.name == localObservation.name;
    var isSameLocation = userObservation.location == localObservation.location;
    var userDate = userObservation.date;
    var localDate = localObservation.date;

    //Don't compare with equals as the microseconds are not exactly the same for whatever reason.
    //So, if the time is within a second, it's likely the same observation
    var isSameTime = false;
    if (userDate != null && localDate != null) {
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
     LocalObservation localObservation = element;

      //Only load observations for the current user or observations that don't have an ownerId because they were made when the user wasn't logged in
      if (localObservation.observerUid == userId || localObservation.observerUid.isEmpty) {

        var observation = toObservation(localObservation, buttonText: translations.viewObservation);
        localObservations.add(observation);
      }
    }

    for (var observation in localObservations) {
      observation.buttonText = translations.viewObservation;
    }

    _localObservations = localObservations;
    _localObservationsStreamController?.add(_localObservations);
  }

}