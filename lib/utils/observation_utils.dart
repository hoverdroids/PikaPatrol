import 'package:charcode/html_entity.dart';
import 'package:hive/hive.dart';
import 'package:material_themes_widgets/utils/collection_utils.dart';
import 'package:pika_patrol/data/pika_species.dart';

import '../l10n/translations.dart';
import '../model/app_user.dart';
import '../model/local_observation.dart';
import '../model/observation.dart';
import '../services/firebase_database_service.dart';

Future saveObservation(AppUser? user, Observation observation) async {
    //TODO - CHRIS - compare observation with its firebase counterpart and don't upload if unchanged

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

//region
/*List<String> getDefaults() => ;
List<String> getDefaultsKeys() => ;

String getLabel(int index, String value, Translations translations) {
  var defaultIndex = getDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getDefaultsKeys()[defaultIndex]);
}

extension  on Observation {
  List<String> getValues() {
    var selected =  ?? <String>[];
    var defaults = getDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}*/
//endregion

//region OtherAnimalsPresent
List<String> getOtherAnimalsPresentDefaults() => ["Marmots", "Weasels", "Woodrats", "Mountain Goats", "Cattle", "Ptarmigans", "Raptors", "Brown Capped Rosy Finch", "Bats", "Other"];
List<String> getOtherAnimalsPresentDefaultsKeys() => ["marmots", "weasels", "woodrats", "mountainGoats", "cattle", "ptarmigans", "raptors", "brownCappedRosyFinch", "bats", "other"];

String getOtherAnimalsPresentLabel(int index, String value, Translations translations) {
  var defaultIndex = getOtherAnimalsPresentDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getOtherAnimalsPresentDefaultsKeys()[defaultIndex]);
}

extension OtherAnimalsPresent on Observation {
  List<String> getOtherAnimalsPresentValues() {
    var selected = otherAnimalsPresent ?? <String>[];
    var defaults = getOtherAnimalsPresentDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Pikas Detected
List<String> getPikasDetectedDefaults() => ["0", "1", "2", "3", "4", "5", ">5", ">10", "Unsure. More than 1"];
List<String> getPikasDetectedDefaultsKeys() => ["0", "1", "2", "3", "4", "5", ">5", ">10", "unsureMoreThanOne"];

String getPikasDetectedLabel(int index, String value, Translations translations) {
  var defaultIndex = getPikasDetectedDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getPikasDetectedDefaultsKeys()[defaultIndex]);
}

extension PikasDetected on Observation {
  List<String> getPikasDetectedValues() {
    var detected = pikasDetected;
    var selected = detected != null && detected.isNotEmpty ? [detected] : <String>[];
    var defaults = getPikasDetectedDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Signs
List<String> getSignsDefaults() => ["Saw Pika", "Heard Pika Calls", "HayPile: Old", "HayPile: New", "HayPile: Other", "Scat: Old", "Scat: New", "Scat: Other"];
List<String> getSignsDefaultsKeys() => ["sawPika", "heardPikaCalls", "haypileOld", "haypileNew", "haypileOther", "scatOld", "scatNew", "scatOther"];

String getSignsLabel(int index, String value, Translations translations) {
  var defaultIndex = getSignsDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getSignsDefaultsKeys()[defaultIndex]);
}

extension Signs on Observation {
  List<String> getSignsValues() {
    var selected = signs ?? <String>[];
    var defaults = getSignsDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Skies
List<String> getSkiesDefaults() => ["Clear", "Partly Cloudy", "Overcast", "Rain/Drizzle", "Snow"];
List<String> getSkiesDefaultsKeys() => ["clear", "partlyCloudy", "overcast", "rainDrizzle", "snow"];

String getSkiesLabel(int index, String value, Translations translations) {
  var defaultIndex = getSkiesDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getSkiesDefaultsKeys()[defaultIndex]);
}

extension Skies on Observation {
  List<String> getSkiesValues() {
    var sky = skies;
    var selected = sky != null && sky.isNotEmpty ? [sky] : <String>[];
    var defaults = getSkiesDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Species
const String SPECIES_DEFAULT = "American Pika";
List<String> getSpeciesDefaults() => ["American Pika", "Collared Pika"];
List<String> getSpeciesDefaultsKeys() => ["americanPika", "collaredPika"];

String getSpeciesLabel(int index, String value, Translations translations) {
  var defaultIndex = getSpeciesDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getSpeciesDefaultsKeys()[defaultIndex]);
}

extension Species on Observation {
  List<String> getSpeciesValues() {
    var selected = species.isNotEmpty ? [species] : <String>[];
    var defaults = getSpeciesDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Talus Area
List<String> getTalusAreaDefaults() => ["<3,000 ft\u00B2", "3,000 - 10,000 ft\u00B2", "10,000 - 50,000 ft\u00B2", "> 1 acre"];
List<String> getTalusAreaDefaultsKeys() => ["lessThan3000Feet", "threeThousandToTenThousandFeet", "tenThousandToFiftyThousandFeet", "greaterThanOneAcre"];

List<String> getTalusAreaHintsDefaults() => ["Smaller than Tennis Court", "Tennis Court to Baseball Infield", "Baseball Infield to Football Field", "Larger than Football Field"];
List<String> getTalusAreaHintsDefaultsKeys() => ["smallerThanTennisCourt", "tennisCourtToBaseballInfield", "baseballInfieldToFootballField", "largerThanFootballField"];

String getTalusAreaLabel(int index, String value, Translations translations, bool showHints) {
  var defaultIndex = getTalusAreaDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  var keys = showHints ? getTalusAreaHintsDefaultsKeys() : getTalusAreaDefaultsKeys();
  return translations.get(keys[defaultIndex]);
}

extension TalusArea on Observation {
  List<String> getTalusAreaValues() {
    String? talus = talusArea;
    var selected = talus != null && talus.isNotEmpty ? [talus] : <String>[];
    var defaults = getTalusAreaDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Temperature
var degF = "${String.fromCharCode($deg)}F";
List<String> getTemperatureDefaults() => ["Cold: <45$degF" , "Cool: 45 - 60$degF", "Warm: 60 - 75$degF", "Hot: >75$degF"];
List<String> getTemperatureDefaultsKeys() => ["cold", "cool", "warm", "hot"];

String getTemperatureLabel(int index, String value, Translations translations) {
  var defaultIndex = getTemperatureDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getTemperatureDefaultsKeys()[defaultIndex]);
}

extension Temperature on Observation {
  List<String> getTemperatureValues() {
    var temp = temperature;
    var selected = temp != null && temp.isNotEmpty ? [temp] : <String>[];
    var defaults = getTemperatureDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion

//region Wind
List<String> getWindDefaults() => ["Low: Bends Grasses", "Medium: Bends Branches", "High: Bends Trees"];
List<String> getWindDefaultsKeys() => ["lowBendsGrasses", "mediumBendsBranches", "highBendsTrees"];

String getWindLabel(int index, String value, Translations translations) {
  var defaultIndex = getWindDefaults().indexOf(value);
  if (defaultIndex == -1) {
    //Can't find the animal in the defaults, so, can't translate it
    return value;
  }
  return translations.get(getWindDefaultsKeys()[defaultIndex]);
}

extension Wind on Observation {
  List<String> getWindValues() {
    var wind = this.wind;
    var selected = wind != null && wind.isNotEmpty ? [wind] : <String>[];
    var defaults = getWindDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
}
//endregion