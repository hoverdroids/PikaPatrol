import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:hive/hive.dart';

import '../l10n/translations.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import '../utils/observation_utils.dart';

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