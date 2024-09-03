import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import 'firebase_database_service.dart';

class SharedObservationsService {

  late Translations translations;

  late FirebaseDatabaseService _firebaseDatabaseService;

  /*SharedObservationsService(Translations translations, Box<LocalObservation> box, String userId) {
    _translations = translations;
    setLocalObservations(box, userId);
  }*/

  /*SharedObservationsService(FirebaseDatabaseService firebaseDatabaseService) {
    _firebaseDatabaseService = firebaseDatabaseService;
  }*/

  /*Stream<List<Observation>> get sharedObservations {
      //return [];//observationsCollection.orderBy(DATE, descending: true).limit(5).snapshots().map(_observationsFromSnapshot);

      //return Provider.of<FirebaseDatabaseService>(context).observationsService.observations;
      return _firebaseDatabaseService.observationsService.observations;
    }*/

  /* Stream<List<Observation>> get localObservations {

    }*/


  List<Observation> sharedObservations = [];

  List<Observation> _localObservations = [];

  List<Observation> get localObservations {
    return _localObservations;
  }

  final _localObservationsStreamController = StreamController<List<Observation>>();

  Stream<List<Observation>> get localObservationsStream {
    return _localObservationsStreamController.stream;
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

    for (var observation in  localObservations) {
      observation.buttonText = translations.viewObservation;
    }

    _localObservations = localObservations;
    _localObservationsStreamController.add(_localObservations);
  }
}
