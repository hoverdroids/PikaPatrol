import 'package:material_themes_widgets/utils/collection_utils.dart';
import '../l10n/translations.dart';
import '../model/app_user.dart';
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

extension ObservationState on Observation {
  bool isUserObservation(AppUser? user) {
    return user != null && user.uid == observerUid;
  }

  bool isNewObservation() {
    // We know this is a new observations since uid isn't set until the observation is saved, and dbId isn't set until the local observation is saved
    return uid == null && dbId == null;
  }

  bool isLocalObservation() {
    return dbId != null;
  }

  bool isOnlyLocalObservation() {
    return isLocalObservation() && !isRemoteObservation();
  }

  bool isRemoteObservation() {
    return uid != null;
  }

  bool isOnlyRemoteObservation() {
    return isRemoteObservation() && !isLocalObservation();
  }

  bool canUserEdit(AppUser? user) {
    //When can an observation be edited?

    // Observation is new
    //    user == null or user != null <- since there is no requirement to be logged in to make local observations
    //    dbId == null
    //    uid == null
    final isNew = isNewObservation();

    //  Observation is local, for a user that is not signed in            <-edit local
    //    user == null
    //    dbId != null
    //    uid == null
    final isLocalWithoutObserver = user == null && observerUid == null && isOnlyLocalObservation();

    //  Observation is our own local, and a remote version doesn't exist  <-edit local
    //    user != null
    //    user.id == observer.id
    //    dbId != null
    //    uid == null
    //  Observation is our own local, and a remote version exists         <-edit local and remote
    //    user != null
    //    user.id == observer.id
    //    dbId != null
    //    uid != null
    //  Observation is our own remote, and a local version doesn't exist  <-edit remote
    //    user != null
    //    user.id == observer.id
    //    dbId == null
    //    uid != null
    final isUsers = isUserObservation(user);

    //  We are a logged in admin                   <-edit remote for any user
    //    user != null
    //    admin == true
    final isAdmin = user?.isAdmin ?? false;

    //When can't an observation be deleted?
    //  Observation is new                                                <-already editing
    //  Observation is not our own remote, we are not admin               <-no permissions to edit

    return isNew || isLocalWithoutObserver || isUsers || isAdmin;
  }
}
