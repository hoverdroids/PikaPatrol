// ignore_for_file: constant_identifier_names
import 'dart:convert';

import 'package:gsheets/gsheets.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:pika_patrol/services/google_sheets/google_sheets_value_exception_pair.dart';
import 'package:pika_patrol/services/google_sheets_worksheet.dart';
import 'dart:developer' as developer;

import '../observations/observation.dart';
import '../google_sheets_service.dart';

class GoogleSheetsObservationWorksheet extends GoogleSheetsWorksheet {

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

  GoogleSheetsObservationWorksheet(
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
  
  Future<GoogleSheetsValueExceptionPair<Observation>> getObservation(String uid) async {
    final returnValue = await getRowByUid(uid);

    if (returnValue.exception != null) {
      return GoogleSheetsValueExceptionPair(null, exception: returnValue.exception);
    }
    return GoogleSheetsValueExceptionPair(returnValue.value?.toObservationFromGoogleSheetsRow());
  }

  Future<GoogleSheetsValueExceptionPair<List<Observation>>> getAllObservations() async {
    final returnValue = await getAllRows();
    final value = returnValue.value ?? [];

    if (returnValue.exception != null) {
      return GoogleSheetsValueExceptionPair(null, exception: returnValue.exception);
    }

    final observations = value.map((row) => row.toObservationFromGoogleSheetsRow()).toList();
    return GoogleSheetsValueExceptionPair(observations);
  }

  Future<GoogleSheetsValueExceptionPair<bool>> addOrUpdateObservation(Observation observation) async {
    return await addOrUpdateRowByUid(observation.uid, observation.toGoogleSheetsRow());
  }

  Future<GoogleSheetsValueExceptionPair<bool>> addOrUpdateObservations(List<Observation> observations, String organization) async {
    for (var observation in observations) {
      //Null shared projects means there haven't been options added to the observation, so share with everybody
      //Empty would mean the user actively doesn't want the observation shared
      // var sharedWithProjects = observation.sharedWithProjects;
      // var doesntHaveSharedWithProjects = sharedWithProjects == null;
      var projectIncluded = observation.sharedWithProjects?.contains(organization) ?? false;
      var projectExcluded = observation.notSharedWithProjects?.contains(organization) ?? false;
      if (projectIncluded || !projectExcluded) {
        // If project was specifically included, then the observation has been updated since the latest models were updated to include sharedWithProject
        // If project was not specifically included, and it wasn't excluded, then either the project is new in Firebase or the observation is old and
        // wasn't tracking sharedWithProjects. So, include it until the observation is updated to exclude it.
        var returnValue = await addOrUpdateObservation(observation);

        if (returnValue.exception != null) {
          developer.log("Not updated ${observation.location} in $organization");
          return GoogleSheetsValueExceptionPair(false, exception: returnValue.exception);
        } else {
          showToast("Updated ${observation.location} in $organization");
        }

        await Future.delayed(const Duration(milliseconds: GoogleSheetsService.MORE_THAN_60_WRITES_DELAY_MS), () {});
      } else {
        developer.log("Not updated ${observation.location} in $organization");
      }
    }
    return GoogleSheetsValueExceptionPair(true);
  }

  Future<GoogleSheetsValueExceptionPair<bool>> deleteObservation(Observation observation) async => await deleteRowByUid(observation.uid);
}

extension GoogleSheetsObservationRow on Map<String, dynamic> {
  Observation toObservationFromGoogleSheetsRow() => Observation(
      uid: this[WorksheetService.UID_COLUMN_TITLE],
      observerUid: this[GoogleSheetsObservationWorksheet.OBSERVER_UID_COLUMN_TITLE],
      name: this[GoogleSheetsObservationWorksheet.NAME_COLUMN_TITLE],
      location: this[GoogleSheetsObservationWorksheet.LOCATION_COLUMN_TITLE],
      date: DateTime.parse(jsonDecode(this[GoogleSheetsObservationWorksheet.DATE_COLUMN_TITLE])),
      altitudeInMeters: jsonDecode(this[GoogleSheetsObservationWorksheet.ALTITUDE_IN_METERS_COLUMN_TITLE]),
      latitude: jsonDecode(this[GoogleSheetsObservationWorksheet.LATITUDE_COLUMN_TITLE]),
      longitude: jsonDecode(this[GoogleSheetsObservationWorksheet.LONGITUDE_COLUMN_TITLE]),
      species: this[GoogleSheetsObservationWorksheet.SPECIES_COLUMN_TITLE],
      signs: jsonDecode(this[GoogleSheetsObservationWorksheet.SIGNS_COLUMN_TITLE]),
      pikasDetected: this[GoogleSheetsObservationWorksheet.PIKAS_DETECTED_COLUMN_TITLE],
      distanceToClosestPika: this[GoogleSheetsObservationWorksheet.DISTANCE_TO_CLOSEST_PIKA_COLUMN_TITLE],
      searchDuration: this[GoogleSheetsObservationWorksheet.SEARCH_DURATION_COLUMN_TITLE],
      talusArea: this[GoogleSheetsObservationWorksheet.TALUS_AREA_COLUMN_TITLE],
      temperature: this[GoogleSheetsObservationWorksheet.TEMPERATURE_COLUMN_TITLE],
      skies: this[GoogleSheetsObservationWorksheet.SKIES_COLUMN_TITLE],
      wind: this[GoogleSheetsObservationWorksheet.WIND_COLUMN_TITLE],
      siteHistory: this[GoogleSheetsObservationWorksheet.SITE_HISTORY_COLUMN_TITLE],
      comments: this[GoogleSheetsObservationWorksheet.COMMENTS_COLUMN_TITLE],
      imageUrls: jsonDecode(this[GoogleSheetsObservationWorksheet.IMAGE_URLS_COLUMN_TITLE]),
      audioUrls: jsonDecode(this[GoogleSheetsObservationWorksheet.AUDIO_URLS_COLUMN_TITLE]),
      otherAnimalsPresent: jsonDecode(this[GoogleSheetsObservationWorksheet.OTHER_ANIMALS_PRESENT_COLUMN_TITLE]),
      sharedWithProjects: jsonDecode(this[GoogleSheetsObservationWorksheet.SHARED_WITH_PROJECTS_COLUMN_TITLE]),
      notSharedWithProjects: jsonDecode(this[GoogleSheetsObservationWorksheet.NOT_SHARED_WITH_PROJECTS_COLUMN_TITLE]),
      dateUpdatedInGoogleSheets: DateTime.parse(jsonDecode(this[GoogleSheetsObservationWorksheet.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE]))
  );
}

extension GoogleSheetsObservation on Observation {
  Map<String, dynamic> toGoogleSheetsRow() => {
    WorksheetService.UID_COLUMN_TITLE: uid,
    GoogleSheetsObservationWorksheet.OBSERVER_UID_COLUMN_TITLE: observerUid,
    GoogleSheetsObservationWorksheet.ALTITUDE_IN_METERS_COLUMN_TITLE: altitudeInMeters,
    GoogleSheetsObservationWorksheet.LONGITUDE_COLUMN_TITLE: longitude,
    GoogleSheetsObservationWorksheet.LATITUDE_COLUMN_TITLE: latitude,
    GoogleSheetsObservationWorksheet.NAME_COLUMN_TITLE: name,
    GoogleSheetsObservationWorksheet.LOCATION_COLUMN_TITLE: location,
    GoogleSheetsObservationWorksheet.DATE_COLUMN_TITLE: date?.toUtc().toString(),
    GoogleSheetsObservationWorksheet.SPECIES_COLUMN_TITLE: species,
    GoogleSheetsObservationWorksheet.SIGNS_COLUMN_TITLE: jsonEncode(signs),
    GoogleSheetsObservationWorksheet.PIKAS_DETECTED_COLUMN_TITLE: pikasDetected,
    GoogleSheetsObservationWorksheet.DISTANCE_TO_CLOSEST_PIKA_COLUMN_TITLE: distanceToClosestPika,
    GoogleSheetsObservationWorksheet.SEARCH_DURATION_COLUMN_TITLE: searchDuration,
    GoogleSheetsObservationWorksheet.TALUS_AREA_COLUMN_TITLE: talusArea,
    GoogleSheetsObservationWorksheet.TEMPERATURE_COLUMN_TITLE: temperature,
    GoogleSheetsObservationWorksheet.SKIES_COLUMN_TITLE: skies,
    GoogleSheetsObservationWorksheet.WIND_COLUMN_TITLE: wind,
    GoogleSheetsObservationWorksheet.SITE_HISTORY_COLUMN_TITLE: siteHistory,
    GoogleSheetsObservationWorksheet.COMMENTS_COLUMN_TITLE: comments,
    GoogleSheetsObservationWorksheet.IMAGE_URLS_COLUMN_TITLE: jsonEncode(imageUrls),
    GoogleSheetsObservationWorksheet.AUDIO_URLS_COLUMN_TITLE: jsonEncode(audioUrls),
    GoogleSheetsObservationWorksheet.OTHER_ANIMALS_PRESENT_COLUMN_TITLE: jsonEncode(otherAnimalsPresent),
    GoogleSheetsObservationWorksheet.SHARED_WITH_PROJECTS_COLUMN_TITLE: jsonEncode(sharedWithProjects),
    GoogleSheetsObservationWorksheet.NOT_SHARED_WITH_PROJECTS_COLUMN_TITLE: jsonEncode(notSharedWithProjects),
    GoogleSheetsObservationWorksheet.DATE_UPDATED_IN_GOOGLE_SHEETS_COLUMN_TITLE: dateUpdatedInGoogleSheets?.toUtc().toString()
  };
}