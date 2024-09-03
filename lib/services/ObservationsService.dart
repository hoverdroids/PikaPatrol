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

  Stream<List<Observation>> get sharedObservationsStream {
    //Based on method_channel_query Stream<QuerySnapshotPlatform> snapshots

    // It's fine to let the StreamController be garbage collected once all the
    // subscribers have cancelled; this analyzer warning is safe to ignore.
    late StreamController<List<Observation>> controller; // ignore: close_sinks

    controller = StreamController<List<Observation>>.broadcast(
      onListen: () async {
        controller.add(_sharedObservations);
        controller.close();
      }
    );

    return controller.stream;
  }

  List<Observation> _localObservations = [];

  List<Observation> get localObservations {
    return _localObservations;
  }

  Stream<List<Observation>> get localObservationsStream {
    //Based on method_channel_query Stream<QuerySnapshotPlatform> snapshots

    // It's fine to let the StreamController be garbage collected once all the
    // subscribers have cancelled; this analyzer warning is safe to ignore.
    late StreamController<List<Observation>> controller; // ignore: close_sinks

    controller = StreamController<List<Observation>>.broadcast(
        onListen: () async {
          controller.add(_localObservations);
          controller.close();
        }
    );

    return controller.stream;
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

        //_sharedObservationsStreamController.add(_sharedObservations);
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
        localObservations.add(observation);
      }
    }

    _localObservations = localObservations;
    //_localObservationsStreamController.add(_localObservations);
  }
}
