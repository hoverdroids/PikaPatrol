// ignore_for_file: constant_identifier_names
import 'dart:convert';

import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/services/worksheet_service.dart';

import '../model/observation.dart';

class ObservationsWorksheetService extends WorksheetService {

  static const String OBSERVATIONS_WORKSHEET_TITLE = "Observations";

  static const String OBSERVER_UID_COLUMN_TITLE = "observerUid";
  static const String ALTITUDE_IN_METERS_COLUMN_TITLE = "altitudeInMeters";
  static const String LONGITUDE_COLUMN_TITLE = "longitude";
  static const String LATITUDE_COLUMN_TITLE = "latitude";
  static const String NAME_COLUMN_TITLE = "name";
  static const String LOCATION_COLUMN_TITLE = "location";
  static const String DATE_COLUMN_TITLE = "date";
  static const String SPECIES_COLUMN_TITLE = "species";
  static const String SIGNS_COLUMN_TITLE = "signs";
  static const String PIKAS_DETECTED_COLUMN_TITLE = "pikasDetected";
  static const String DISTANCE_TO_CLOSEST_PIKA_COLUMN_TITLE = "distanceToClosestPika";
  static const String SEARCH_DURATION_COLUMN_TITLE = "searchDuration";
  static const String TALUS_AREA_COLUMN_TITLE = "talusArea";
  static const String TEMPERATURE_COLUMN_TITLE = "temperature";
  static const String SKIES_COLUMN_TITLE = "skies";
  static const String WIND_COLUMN_TITLE = "wind";
  static const String SITE_HISTORY_COLUMN_TITLE = "siteHistory";
  static const String COMMENTS_COLUMN_TITLE = "comments";
  static const String IMAGE_URLS_COLUMN_TITLE = "imageUrls";
  static const String AUDIO_URLS_COLUMN_TITLE = "audioUrls";
  static const String OTHER_ANIMALS_PRESENT_COLUMN_TITLE = "otherAnimalsPresent";
  static const String SHARED_WITH_PROJECTS_COLUMN_TITLE = "sharedWithProjects";
  static const String NOT_SHARED_WITH_PROJECTS_COLUMN_TITLE = "notSharedWithProjects";
  static const String DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE = "dateUpdatedInGoogleSheets";

  ObservationsWorksheetService(
    Spreadsheet spreadsheet,
    bool doInitHeaderRow,
    {int columnHeadersRowNumber = WorksheetService.DEFAULT_COLUMN_HEADER_ROW_NUMBER}
  ) : super(
    spreadsheet,
    OBSERVATIONS_WORKSHEET_TITLE,
    [
      WorksheetService.UID_COLUMN_TITLE,
      OBSERVER_UID_COLUMN_TITLE,
      ALTITUDE_IN_METERS_COLUMN_TITLE,
      LONGITUDE_COLUMN_TITLE,
      LATITUDE_COLUMN_TITLE,
      NAME_COLUMN_TITLE,
      LOCATION_COLUMN_TITLE,
      DATE_COLUMN_TITLE,
      SPECIES_COLUMN_TITLE,
      SIGNS_COLUMN_TITLE,
      PIKAS_DETECTED_COLUMN_TITLE,
      DISTANCE_TO_CLOSEST_PIKA_COLUMN_TITLE,
      SEARCH_DURATION_COLUMN_TITLE,
      TALUS_AREA_COLUMN_TITLE,
      TEMPERATURE_COLUMN_TITLE,
      SKIES_COLUMN_TITLE,
      WIND_COLUMN_TITLE,
      SITE_HISTORY_COLUMN_TITLE,
      COMMENTS_COLUMN_TITLE,
      IMAGE_URLS_COLUMN_TITLE,
      AUDIO_URLS_COLUMN_TITLE,
      OTHER_ANIMALS_PRESENT_COLUMN_TITLE,
      SHARED_WITH_PROJECTS_COLUMN_TITLE,
      NOT_SHARED_WITH_PROJECTS_COLUMN_TITLE,
      DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE
    ],
    doInitHeaderRow,
    columnHeadersRowNumber: columnHeadersRowNumber
  );

  Map<String, dynamic> toGoogleSheetsJson(Observation observation) => {
    WorksheetService.UID_COLUMN_TITLE: observation.uid,
    OBSERVER_UID_COLUMN_TITLE: observation.observerUid,
    ALTITUDE_IN_METERS_COLUMN_TITLE: observation.altitudeInMeters,
    LONGITUDE_COLUMN_TITLE: observation.longitude,
    LATITUDE_COLUMN_TITLE: observation.latitude,
    NAME_COLUMN_TITLE: observation.name,
    LOCATION_COLUMN_TITLE: observation.location,
    DATE_COLUMN_TITLE: observation.date?.toUtc().toString(),
    SPECIES_COLUMN_TITLE: observation.species,
    SIGNS_COLUMN_TITLE: jsonEncode(observation.signs),
    PIKAS_DETECTED_COLUMN_TITLE: observation.pikasDetected,
    DISTANCE_TO_CLOSEST_PIKA_COLUMN_TITLE: observation.distanceToClosestPika,
    SEARCH_DURATION_COLUMN_TITLE: observation.searchDuration,
    TALUS_AREA_COLUMN_TITLE: observation.talusArea,
    TEMPERATURE_COLUMN_TITLE: observation.temperature,
    SKIES_COLUMN_TITLE: observation.skies,
    WIND_COLUMN_TITLE: observation.wind,
    SITE_HISTORY_COLUMN_TITLE: observation.siteHistory,
    COMMENTS_COLUMN_TITLE: observation.comments,
    IMAGE_URLS_COLUMN_TITLE: jsonEncode(observation.imageUrls),
    AUDIO_URLS_COLUMN_TITLE: jsonEncode(observation.audioUrls),
    OTHER_ANIMALS_PRESENT_COLUMN_TITLE: jsonEncode(observation.otherAnimalsPresent),
    SHARED_WITH_PROJECTS_COLUMN_TITLE: jsonEncode(observation.sharedWithProjects),
    NOT_SHARED_WITH_PROJECTS_COLUMN_TITLE: jsonEncode(observation.notSharedWithProjects),
    DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: observation.dateUpdatedInGoogleSheets?.toUtc().toString()
  };

  Observation fromGoogleSheetsJson(Map<String, dynamic> json) => Observation(
    uid: json[WorksheetService.UID_COLUMN_TITLE],
    observerUid: json[OBSERVER_UID_COLUMN_TITLE],
    name: json[NAME_COLUMN_TITLE],
    location: json[LOCATION_COLUMN_TITLE],
    date: DateTime.parse(jsonDecode(json[DATE_COLUMN_TITLE])),
    altitudeInMeters: jsonDecode(json[ALTITUDE_IN_METERS_COLUMN_TITLE]),
    latitude: jsonDecode(json[LATITUDE_COLUMN_TITLE]),
    longitude: jsonDecode(json[LONGITUDE_COLUMN_TITLE]),
    species: json[SPECIES_COLUMN_TITLE],
    signs: jsonDecode(json[SIGNS_COLUMN_TITLE]),
    pikasDetected: json[PIKAS_DETECTED_COLUMN_TITLE],
    distanceToClosestPika: json[DISTANCE_TO_CLOSEST_PIKA_COLUMN_TITLE],
    searchDuration: json[SEARCH_DURATION_COLUMN_TITLE],
    talusArea: json[TALUS_AREA_COLUMN_TITLE],
    temperature: json[TEMPERATURE_COLUMN_TITLE],
    skies: json[SKIES_COLUMN_TITLE],
    wind: json[WIND_COLUMN_TITLE],
    siteHistory: json[SITE_HISTORY_COLUMN_TITLE],
    comments: json[COMMENTS_COLUMN_TITLE],
    imageUrls: jsonDecode(json[IMAGE_URLS_COLUMN_TITLE]),
    audioUrls: jsonDecode(json[AUDIO_URLS_COLUMN_TITLE]),
    otherAnimalsPresent: jsonDecode(json[OTHER_ANIMALS_PRESENT_COLUMN_TITLE]),
    sharedWithProjects: jsonDecode(json[SHARED_WITH_PROJECTS_COLUMN_TITLE]),
    notSharedWithProjects: jsonDecode(json[NOT_SHARED_WITH_PROJECTS_COLUMN_TITLE]),
    dateUpdatedInGoogleSheets: DateTime.parse(jsonDecode(json[DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE]))
  );

  Future<Observation?> getObservation(String uid) async {
    final json = await worksheet?.values.map.rowByKey(uid, fromColumn: WorksheetService.UID_COLUMN_NUMBER);
    return json != null ? fromGoogleSheetsJson(json) : null;
  }

  Future<List<Observation>> getObservations() async {
    final observations = await worksheet?.values.map.allRows();
    return observations == null ? <Observation>[] : observations.map(fromGoogleSheetsJson).toList();
  }

  Future<void> addOrUpdateObservation(Observation observation) async {
    var uid = observation.uid;
    if (uid != null) {
      final index = await worksheet?.values.rowIndexOf(uid, inColumn: WorksheetService.UID_COLUMN_NUMBER);

      Map<String, dynamic> json;
      json = toGoogleSheetsJson(observation);

      if (index == null || index == -1) {
        await insertRow(json);
      } else {
        await updateRow(uid, json);
      }
    }
  }

  Future<void> addOrUpdateObservations(List<Observation> observations) async {
    for (var observation in observations) {
      await addOrUpdateObservation(observation);
    }
  }

  Future<bool> deleteObservation(Observation observation) async {
    return deleteRowByUid(observation.uid);
  }
}