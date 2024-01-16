import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:material_themes_widgets/utils/collection_utils.dart';
import 'package:pika_patrol/data/pika_species.dart';
import 'package:pika_patrol/main.dart';

import '../l10n/translations.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import '../services/firebase_database_service.dart';

Future saveObservation(Observation observation) async {
    //TODO - CHRIS - compare observation with its firebase counterpart and don't upload if unchanged
    var needToSaveLocalObservation = observation.uid == null;

    var databaseService = FirebaseDatabaseService(useEmulators);//TODO - CHRIS - Provider.of<FirebaseDatabaseService>(context);

    var imageUrls = observation.imageUrls;
    if (imageUrls != null && imageUrls.isNotEmpty) {
      observation.imageUrls = await databaseService.observationsService.uploadFiles(imageUrls, true);
    }
    //developer.log("ImageUrls: ${observation.imageUrls.toString()}");

    var audioUrls = observation.audioUrls;
    if (audioUrls != null && audioUrls.isNotEmpty) {
      observation.audioUrls = await databaseService.observationsService.uploadFiles(audioUrls, false);
    }
    //developer.log("AudioUrls: ${observation.audioUrls.toString()}");

    await databaseService.observationsService.updateObservation(observation);

    if (needToSaveLocalObservation) {
      // Update local observation after successful upload because the uid will be non empty now
      saveLocalObservation(observation);
    }
}

Future<LocalObservation?> saveLocalObservation(Observation observation) async {
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
      sharedWithProjects: observation.sharedWithProjects ?? PikaData.SHARED_WITH_PROJECTS_DEFAULT
  );

  if(observation.dbId == null) {
    int? key = await box.add(localObservation);

    //If the user remains on the observation page, they can edit/save again. In that case, they need
    //to use the same database ID instead of adding a new entry each time
    observation.dbId = key;
  } else {
    await box.put(observation.dbId, localObservation);
  }

  return box.get(observation.dbId);
}

Future<FirebaseException?> deleteObservation(Observation observation, bool deleteImages, bool deleteAudio) async {
  await deleteLocalObservation(observation);

  var databaseService = FirebaseDatabaseService(useEmulators);//TODO - CHRIS - Provider.of<FirebaseDatabaseService>(context);
  return await databaseService.observationsService.deleteObservation(observation, deleteImages, deleteAudio);
}

Future deleteLocalObservation(Observation observation) async {
  var box = Hive.box<LocalObservation>('observations');
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

//region OtherAnimalsPresent
List<String> getOtherAnimalsPresentDefaults(Translations translations) => translations.otherAnimalsPresentDefaultValues;

String getOtherAnimalsPresentLabel(int index, String value, Translations translations) {
  var defaultIndex = getOtherAnimalsPresentDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.otherAnimalsPresentKeys[defaultIndex]);
}

extension OtherAnimalsPresent on Observation {
  List<String> getOtherAnimalsPresentValues(Translations translations) {
    var selected = otherAnimalsPresent ?? <String>[];
    var defaults = getOtherAnimalsPresentDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Distance to closest pika
List<String> getDistanceToClosestPikaDefaults(Translations translations) => translations.distanceToClosestPikaDefaultValues;

String getDistanceToClosestPikaLabel(int index, String value, Translations translations) {
  var defaultIndex = getDistanceToClosestPikaDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.distanceToClosestPikaKeys[defaultIndex]);
}

extension DistanceToClosestPika on Observation {
  List<String> getDistanceToClosestPikaValues(Translations translations) {
    var distanceToClosestPika = this.distanceToClosestPika;
    var selected = distanceToClosestPika != null && distanceToClosestPika.isNotEmpty ? [distanceToClosestPika] : <String>[];
    var defaults = getDistanceToClosestPikaDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Pikas Detected
List<String> getPikasDetectedDefaults(Translations translations) => translations.pikasDetectedDefaultValues;

String getPikasDetectedLabel(int index, String value, Translations translations) {
  var defaultIndex = getPikasDetectedDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.pikasDetectedKeys[defaultIndex]);
}

extension PikasDetected on Observation {
  List<String> getPikasDetectedValues(Translations translations) {
    var pikasDetected = this.pikasDetected;
    var selected = pikasDetected != null && pikasDetected.isNotEmpty ? [pikasDetected] : <String>[];
    var defaults = getPikasDetectedDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Search Duration
List<String> getSearchDurationDefaults(Translations translations) => translations.searchDurationDefaultValues;

String getSearchDurationLabel(int index, String value, Translations translations) {
  var defaultIndex = getSearchDurationDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.searchDurationKeys[defaultIndex]);
}

extension SearchDuration on Observation {
  List<String> getSearchDurationValues(Translations translations) {
    var searchDuration = this.searchDuration;
    var selected = searchDuration != null && searchDuration.isNotEmpty ? [searchDuration] : <String>[];
    var defaults = getSearchDurationDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Signs
List<String> getSignsDefaults(Translations translations) => translations.signsDefaultValues;

String getSignsLabel(int index, String value, Translations translations) {
  var defaultIndex = getSignsDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.signsKeys[defaultIndex]);
}

extension Signs on Observation {
  List<String> getSignsValues(Translations translations) {
    var selected = signs ?? <String>[];
    var defaults = getSignsDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Skies
List<String> getSkiesDefaults(Translations translations) => translations.skiesDefaultValues;

String getSkiesLabel(int index, String value, Translations translations) {
  var defaultIndex = getSkiesDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.skiesKeys[defaultIndex]);
}

extension Skies on Observation {
  List<String> getSkiesValues(Translations translations) {
    var sky = skies;
    var selected = sky != null && sky.isNotEmpty ? [sky] : <String>[];
    var defaults = getSkiesDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Species
const String SPECIES_DEFAULT = "American Pika";
List<String> getSpeciesDefaults(Translations translations) => translations.speciesDefaultValues;

String getSpeciesLabel(int index, String value, Translations translations) {
  var defaultIndex = getSpeciesDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.speciesKeys[defaultIndex]);
}

extension Species on Observation {
  List<String> getSpeciesValues(Translations translations) {
    var selected = species.isNotEmpty ? [species] : <String>[];
    var defaults = getSpeciesDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Talus Area
List<String> getTalusAreaDefaults(Translations translations) => translations.talusAreaDefaultValues;

List<String> getTalusAreaHintsDefaults(Translations translations) => translations.talusAreaHintsDefaultValues;

String getTalusAreaLabel(int index, String value, Translations translations, bool showHints) {
  var defaultIndex = getTalusAreaDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  var keys = showHints ? translations.talusAreaHintsKeys : translations.talusAreaKeys;
  return translations.get(keys[defaultIndex]);
}

extension TalusArea on Observation {
  List<String> getTalusAreaValues(Translations translations) {
    String? talus = talusArea;
    var selected = talus != null && talus.isNotEmpty ? [talus] : <String>[];
    var defaults = getTalusAreaDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Temperature
List<String> getTemperatureDefaults(Translations translations) => translations.temperatureDefaultValues;

String getTemperatureLabel(int index, String value, Translations translations) {
  var defaultIndex = getTemperatureDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.temperatureKeys[defaultIndex]);
}

extension Temperature on Observation {
  List<String> getTemperatureValues(Translations translations) {
    var temp = temperature;
    var selected = temp != null && temp.isNotEmpty ? [temp] : <String>[];
    var defaults = getTemperatureDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Wind
List<String> getWindDefaults(Translations translations) => translations.windDefaultValues;

String getWindLabel(int index, String value, Translations translations) {
  var defaultIndex = getWindDefaults(translations).indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(translations.windKeys[defaultIndex]);
}

extension Wind on Observation {
  List<String> getWindValues(Translations translations) {
    var wind = this.wind;
    var selected = wind != null && wind.isNotEmpty ? [wind] : <String>[];
    var defaults = getWindDefaults(translations);
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion