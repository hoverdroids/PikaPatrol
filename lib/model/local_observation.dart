import 'package:hive/hive.dart';
import 'observation.dart';

@HiveType(typeId: 0)
class LocalObservation extends HiveObject {
  @HiveField(0, defaultValue: "")
  String uid;

  @HiveField(1, defaultValue: "")
  String observerUid;

  @HiveField(2, defaultValue: 0.0)
  double altitudeInMeters;

  @HiveField(3, defaultValue: 0.0)
  double longitude;

  @HiveField(4, defaultValue: 0.0)
  double latitude;

  @HiveField(5, defaultValue: "")
  String name;

  @HiveField(6, defaultValue: "")
  String location;

  @HiveField(7, defaultValue: "")
  String date;

  @HiveField(8, defaultValue: <String>[])
  List<String> signs;

  @HiveField(9, defaultValue: "")
  String pikasDetected;

  @HiveField(10, defaultValue: "")
  String distanceToClosestPika;

  @HiveField(11, defaultValue: "")
  String searchDuration;

  @HiveField(12, defaultValue: "")
  String talusArea;

  @HiveField(13, defaultValue: "")
  String temperature;

  @HiveField(14, defaultValue: "")
  String skies;

  @HiveField(15, defaultValue: "")
  String wind;

  @HiveField(16, defaultValue: <String>[])
  List<String> otherAnimalsPresent;

  @HiveField(17, defaultValue: "")
  String siteHistory;

  @HiveField(18, defaultValue: "")
  String comments;

  @HiveField(19, defaultValue: <String>[])
  List<String> imageUrls;

  @HiveField(20, defaultValue: <String>[])
  List<String> audioUrls;

  @HiveField(21, defaultValue: "")
  String species;

  @HiveField(22, defaultValue: <String>[])
  List<String> sharedWithProjects;

  @HiveField(23, defaultValue: <String>[])
  List<String> notSharedWithProjects;

  @HiveField(24, defaultValue: "")
  String dateUpdatedInGoogleSheets;

  @HiveField(25, defaultValue: false)
  bool isUploaded;

  LocalObservation(
    {
      this.uid = "",
      this.observerUid = "",
      this.name = "",
      this.location = "",
      this.date = "",
      this.altitudeInMeters = 0.0,
      this.latitude = 0.0,
      this.longitude = 0.0,
      this.species = Observation.SPECIES_DEFAULT,
      this.signs = const <String>[],
      this.pikasDetected = "",
      this.distanceToClosestPika = "",
      this.searchDuration = "",
      this.talusArea = "",
      this.temperature = "",
      this.skies = "",
      this.wind = "",
      this.siteHistory = "",
      this.comments = "",
      this.imageUrls = const <String>[],
      this.audioUrls = const <String>[],
      this.otherAnimalsPresent = const <String>[],
      this.sharedWithProjects = const <String>[],
      this.notSharedWithProjects = const <String>[],
      this.dateUpdatedInGoogleSheets = "",
      this.isUploaded = false
    }
  );
}