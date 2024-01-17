import 'package:hive/hive.dart';
import '../utils/observation_utils.dart';

@HiveType(typeId: 1)
class LocalObservation extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String observerUid;

  @HiveField(2)
  double altitudeInMeters;

  @HiveField(3)
  double longitude;

  @HiveField(4)
  double latitude;

  @HiveField(5)
  String name;

  @HiveField(6)
  String location;

  @HiveField(7)
  String date;

  @HiveField(8)
  List<String> signs;

  @HiveField(9)
  String pikasDetected;

  @HiveField(10)
  String distanceToClosestPika;

  @HiveField(11)
  String searchDuration;

  @HiveField(12)
  String talusArea;

  @HiveField(13)
  String temperature;

  @HiveField(14)
  String skies;

  @HiveField(15)
  String wind;

  @HiveField(16)
  List<String> otherAnimalsPresent;

  @HiveField(17)
  String siteHistory;

  @HiveField(18)
  String comments;

  @HiveField(19)
  List<String> imageUrls;

  @HiveField(20)
  List<String> audioUrls;

  @HiveField(21)
  String species;

  @HiveField(22)
  List<String> sharedWithProjects;

  @HiveField(23)
  List<String> notSharedWithProjects;

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
      this.species = SPECIES_DEFAULT,
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
      this.notSharedWithProjects = const <String>[]
    }
  );
}