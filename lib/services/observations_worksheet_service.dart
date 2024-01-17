// ignore_for_file: constant_identifier_names
import 'package:gsheets/gsheets.dart';
import 'package:pika_patrol/services/worksheet_service.dart';

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
      WIND_COLUMN_TITLE
    ],
    doInitHeaderRow,
    columnHeadersRowNumber: columnHeadersRowNumber
  );
}