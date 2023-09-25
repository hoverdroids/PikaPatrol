

import 'package:hive/hive.dart';

import '../model/app_user.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import '../services/firebase_database_service.dart';

Future saveObservation(AppUser? user, Observation observation, bool dontSaveIfIsNotEmpty) async {
    //TODO - CHRIS - compare observation with its firebase counterpart and don't upload if unchanged
    var uid = observation.uid;
    if (uid == null || (uid.isNotEmpty && dontSaveIfIsNotEmpty)) {
      return;
    }

    var databaseService = FirebaseDatabaseService();//TODO - CHRIS - Provider.of<FirebaseDatabaseService>(context);

    var imageUrls = observation.imageUrls;
    if (imageUrls != null && imageUrls.isNotEmpty) {
      observation.imageUrls = await databaseService.uploadFiles(imageUrls, true);
    }
    //developer.log("ImageUrls: ${observation.imageUrls.toString()}");

    var audioUrls = observation.audioUrls;
    if (audioUrls != null && audioUrls.isNotEmpty) {
      observation.audioUrls = await databaseService.uploadFiles(audioUrls, false);
    }
    //developer.log("AudioUrls: ${observation.audioUrls.toString()}");

    await databaseService.updateObservation(observation);

    // Update local observation after successful upload because the uid will be non empty now
    saveLocalObservation(observation);
}

Future<void> saveLocalObservation(Observation observation) async {
  var box = Hive.box<LocalObservation>('observations');

  //The observation screen can be opened from an online observation, which means that the dbId can be null.
  //So, make sure we associate the dbId if there's a local copy so that we don't duplicate local copies
  Map<dynamic, dynamic> raw = box.toMap();
  List list = raw.values.toList();

  for (var element in list) {
    LocalObservation localObservation = element;
    if(localObservation.uid == observation.uid) {
      observation.dbId = localObservation.key;
    }
  }

  var localObservation = LocalObservation(
      uid: observation.uid ?? "",
      observerUid: observation.observerUid ?? "",
      altitude: observation.altitude ?? 0.0,
      longitude: observation.longitude ?? 0.0,
      latitude: observation.latitude ?? 0.0,
      name: observation.name ?? "",
      location: observation.location ?? "",
      date: observation.date?.toString() ?? "",
      signs: observation.signs ?? <String>[],
      pikasDetected: observation.pikasDetected ?? "",
      distanceToClosestPika: observation.distanceToClosestPika ?? "",
      searchDuration: observation.searchDuration ?? "",
      talusArea: observation.talusArea ?? "",
      temperature: observation.temperature ?? "",
      skies: observation.skies ?? "",
      wind: observation.wind ?? "",
      otherAnimalsPresent: observation.otherAnimalsPresent ?? <String>[],
      siteHistory: observation.siteHistory ?? "",
      comments: observation.comments ?? "",
      imageUrls: observation.imageUrls ?? <String>[],
      audioUrls: observation.audioUrls ?? <String>[]
  );

  if(observation.dbId == null) {
    await box.add(localObservation);

    //If the user remains on the observation page, they can edit/save again. In that case, they need
    //to use the same database ID instead of adding a new entry each time
    observation.dbId = localObservation.key;
  } else {
    await box.put(observation.dbId, localObservation);
  }
}