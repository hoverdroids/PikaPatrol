import 'dart:io';

import 'package:provider/provider.dart';

import '../model/observation.dart';
import 'firebase_database_service.dart';

class SharedObservationsService {

  late FirebaseDatabaseService _firebaseDatabaseService;

  SharedObservationsService(FirebaseDatabaseService firebaseDatabaseService) {
    _firebaseDatabaseService = firebaseDatabaseService;
  }

  Stream<List<Observation>> get sharedObservations {
    //return [];//observationsCollection.orderBy(DATE, descending: true).limit(5).snapshots().map(_observationsFromSnapshot);

    //return Provider.of<FirebaseDatabaseService>(context).observationsService.observations;
    return _firebaseDatabaseService.observationsService.observations;
  }
}