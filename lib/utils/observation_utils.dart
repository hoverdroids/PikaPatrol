import 'package:material_themes_widgets/utils/collection_utils.dart';
import '../l10n/translations.dart';
import '../model/observation.dart';

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