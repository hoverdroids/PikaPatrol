import 'package:material_themes_widgets/utils/collection_utils.dart';
import '../l10n/translations.dart';
import 'app_user.dart';
import 'observation.dart';

class ObservationViewModel {

  final Observation observation;
  final Translations translations;

  //region Constructors
  ObservationViewModel(this.observation, this.translations);
  //endregion

  //region OtherAnimalsPresent
  List<String> getOtherAnimalsPresentDefaults() => translations.otherAnimalsPresentDefaultValues;

  String getOtherAnimalsPresentLabel(int index, String value) {
    var defaultIndex = getOtherAnimalsPresentDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.otherAnimalsPresentKeys[defaultIndex]);
  }

  List<String> getOtherAnimalsPresentValues() {
    var selected = observation.otherAnimalsPresent ?? <String>[];
    var defaults = getOtherAnimalsPresentDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Distance to closest pika
  List<String> getDistanceToClosestPikaDefaults() => translations.distanceToClosestPikaDefaultValues;

  String getDistanceToClosestPikaLabel(int index, String value) {
    var defaultIndex = getDistanceToClosestPikaDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.distanceToClosestPikaKeys[defaultIndex]);
  }

  List<String> getDistanceToClosestPikaValues() {
    var distanceToClosestPika = observation.distanceToClosestPika;
    var selected = distanceToClosestPika != null && distanceToClosestPika.isNotEmpty ? [distanceToClosestPika] : <String>[];
    var defaults = getDistanceToClosestPikaDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Pikas Detected
  List<String> getPikasDetectedDefaults() => translations.pikasDetectedDefaultValues;

  String getPikasDetectedLabel(int index, String value) {
    var defaultIndex = getPikasDetectedDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.pikasDetectedKeys[defaultIndex]);
  }

  List<String> getPikasDetectedValues() {
    var pikasDetected = observation.pikasDetected;
    var selected = pikasDetected != null && pikasDetected.isNotEmpty ? [pikasDetected] : <String>[];
    var defaults = getPikasDetectedDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Search Duration
  List<String> getSearchDurationDefaults() => translations.searchDurationDefaultValues;

  String getSearchDurationLabel(int index, String value) {
    var defaultIndex = getSearchDurationDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.searchDurationKeys[defaultIndex]);
  }

  List<String> getSearchDurationValues() {
    var searchDuration = observation.searchDuration;
    var selected = searchDuration != null && searchDuration.isNotEmpty ? [searchDuration] : <String>[];
    var defaults = getSearchDurationDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Signs
  List<String> getSignsDefaults() => translations.signsDefaultValues;

  String getSignsLabel(int index, String value) {
    var defaultIndex = getSignsDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.signsKeys[defaultIndex]);
  }

  List<String> getSignsValues() {
    var selected = observation.signs ?? <String>[];
    var defaults = getSignsDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Skies
  List<String> getSkiesDefaults() => translations.skiesDefaultValues;

  String getSkiesLabel(int index, String value) {
    var defaultIndex = getSkiesDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.skiesKeys[defaultIndex]);
  }

  List<String> getSkiesValues() {
    var sky = observation.skies;
    var selected = sky != null && sky.isNotEmpty ? [sky] : <String>[];
    var defaults = getSkiesDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Species
  List<String> getSpeciesDefaults() => translations.speciesDefaultValues;

  String getSpeciesLabel(int index, String value) {
    var defaultIndex = getSpeciesDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.speciesKeys[defaultIndex]);
  }

  List<String> getSpeciesValues() {
    var selected = observation.species.isNotEmpty ? [observation.species] : <String>[];
    var defaults = getSpeciesDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Talus Area
  List<String> getTalusAreaDefaults() => translations.talusAreaDefaultValues;

  List<String> getTalusAreaHintsDefaults() => translations.talusAreaHintsDefaultValues;

  String getTalusAreaLabel(int index, String value, bool showHints) {
    var defaultIndex = getTalusAreaDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    var keys = showHints ? translations.talusAreaHintsKeys : translations.talusAreaKeys;
    return translations.get(keys[defaultIndex]);
  }

  List<String> getTalusAreaValues() {
    String? talus = observation.talusArea;
    var selected = talus != null && talus.isNotEmpty ? [talus] : <String>[];
    var defaults = getTalusAreaDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Temperature
  List<String> getTemperatureDefaults() => translations.temperatureDefaultValues;

  String getTemperatureLabel(int index, String value) {
    var defaultIndex = getTemperatureDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.temperatureKeys[defaultIndex]);
  }

  List<String> getTemperatureValues() {
    var temp = observation.temperature;
    var selected = temp != null && temp.isNotEmpty ? [temp] : <String>[];
    var defaults = getTemperatureDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion

  //region Wind
  List<String> getWindDefaults() => translations.windDefaultValues;

  String getWindLabel(int index, String value) {
    var defaultIndex = getWindDefaults().indexOf(value);
    if (defaultIndex == -1) {
      //Can't find the animal in the defaults, so, can't translate it
      return value;
    }
    return translations.get(translations.windKeys[defaultIndex]);
  }

  List<String> getWindValues() {
    var wind = observation.wind;
    var selected = wind != null && wind.isNotEmpty ? [wind] : <String>[];
    var defaults = getWindDefaults();
    return (defaults + selected).toTrimmedUniqueList();
  }
  //endregion
}