import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:pika_patrol/utils/observation_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import 'firebase_database_service.dart';

class SharedObservationsService {

  late Translations translations;

  late FirebaseDatabaseService _firebaseDatabaseService;

/*  SharedObservationsService(Translations translations, Box<LocalObservation> box, String userId) {
    _translations = translations;
    setLocalObservations(box, userId);
  }*/

/*  SharedObservationsService(FirebaseDatabaseService firebaseDatabaseService) {
    _firebaseDatabaseService = firebaseDatabaseService;
  }*/

/*  Stream<List<Observation>> get sharedObservations {
    //return []; //observationsCollection.orderBy(DATE, descending: true).limit(5).snapshots().map(_observationsFromSnapshot);

    //return Provider.of<FirebaseDatabaseService>(context).observationsService.observations;
    return _firebaseDatabaseService.observationsService.observations;
  }*/

  List<Observation> sharedObservations = [];

  Key localObservationsScrollerKey = UniqueKey();
  final Key emptyLocalObservationsScrollerKey = UniqueKey();

  List<Observation> _localObservations = [];

  List<Observation> get localObservations {
    return _localObservations;
  }

  setLocalObservations(Box<LocalObservation> box, String userId) {
    Map<dynamic, dynamic> raw = box.toMap();
    List list = raw.values.toList();
    List<Observation> localObservations = <Observation>[];

    for (var element in list) {
      var observation = toObservation(element, buttonText: translations.viewObservation);
      localObservations.add(observation);
    }

    _localObservations = localObservations;

    localObservationsScrollerKey = Key(_localObservations.hashCode.toString());
  }

}