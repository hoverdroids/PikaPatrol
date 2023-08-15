class Observation {
  int dbId;
  String? uid;
  String observerUid;
  //TODO - position: https://fireship.io/lessons/flutter-realtime-geolocation-firebase/
  //TODO was position manually entered?
  double altitude;
  double longitude;
  double latitude;
  String name;
  String location;
  DateTime date;
  late List<String> signs;
  String pikasDetected;
  String distanceToClosestPika;
  String searchDuration;
  String talusArea;
  String temperature;
  String skies;
  String wind;
  late List<String> otherAnimalsPresent;
  String siteHistory;
  String comments;
  late List<String> imageUrls;
  late List<String> audioUrls;

  //TODO - image descriptions including isHayPile, isHayPile fresh/old/not sure, is scat...is fresh/old/not sure
  Observation({
    required this.dbId,
    required this.uid,
    required this.observerUid,
    this.name = "",
    this.location = "",
    required this.date,
    required this.altitude,
    required this.latitude,
    required this.longitude,
    signs,
    this.pikasDetected = "",
    this.distanceToClosestPika = "",
    this.searchDuration = "",
    this.talusArea = "",
    this.temperature = "",
    this.skies = "",
    this.wind = "",
    this.siteHistory = "",
    this.comments = "",
    imageUrls,
    audioUrls,
    otherAnimalsPresent
  }){
    this.signs = signs ?? <String>[];
    this.otherAnimalsPresent = otherAnimalsPresent ?? <String>[];
    this.imageUrls = imageUrls ?? <String>[];
    this.audioUrls = audioUrls ?? <String>[];
  }
}
