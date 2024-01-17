import 'package:flutter/material.dart';
import 'package:material_themes_widgets/utils/collection_utils.dart';
import 'package:pika_patrol/model/card.dart' as card;
import '../primitives/card_layout.dart';
import '../utils/observation_utils.dart';

class Observation extends card.CardModel {

  int? dbId;
  String? uid;
  String? observerUid;
  //TODO - position: https://fireship.io/lessons/flutter-realtime-geolocation-firebase/
  //TODO was position manually entered?
  double? altitudeInMeters;
  double? longitude;
  double? latitude;
  String? name;
  String? location;
  DateTime? date;
  String species;
  List<String>? signs;
  String? pikasDetected;
  String? distanceToClosestPika;
  String? searchDuration;
  String? talusArea;
  String? temperature;
  String? skies;
  String? wind;

  List<String>? _otherAnimalsPresent;
  List<String>? get otherAnimalsPresent => _otherAnimalsPresent;
  set otherAnimalsPresent(List<String>? list) {
    _otherAnimalsPresent = list?.toTrimmedUniqueList().sortList();
  }

  String? siteHistory;
  String? comments;
  List<String>? imageUrls;
  List<String>? audioUrls;

  List<String>? _sharedWithProjects;
  List<String>? get sharedWithProjects => _sharedWithProjects;
  set sharedWithProjects(List<String>? list) {
    _sharedWithProjects = list?.toTrimmedUniqueList().sortList();
  }

  List<String>? notSharedWithProjects;

  DateTime? dateUpdatedInGoogleSheets;

  //TODO - image descriptions including isHayPile, isHayPile fresh/old/not sure, is scat...is fresh/old/not sure
  Observation({
    this.dbId,
    this.uid,
    this.observerUid,
    this.name = "",
    this.location = "",
    this.date,
    this.altitudeInMeters,
    this.latitude,
    this.longitude,
    this.species = SPECIES_DEFAULT,
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
    otherAnimalsPresent,
    sharedWithProjects,
    this.notSharedWithProjects,
    this.dateUpdatedInGoogleSheets,
    super.buttonText,
    super.cardLayout,
    IconData? uploadedIcon = Icons.cloud_upload,
    IconData? notUploadedIcon = Icons.access_time_filled
  }){
    this.signs = signs ?? <String>[];
    this.otherAnimalsPresent = otherAnimalsPresent ?? <String>[];
    _sharedWithProjects = sharedWithProjects;
    this.imageUrls = imageUrls ?? <String>[];
    this.audioUrls = audioUrls ?? <String>[];
    super.icon = uid?.isNotEmpty == true ? uploadedIcon : notUploadedIcon;
  }

  @override
  String get title => location?.toUpperCase() ?? "";

  @override
  String get imageUrl {
    var imgUrls = imageUrls ?? [];
    if (imgUrls.isEmpty == true) return "";
    return imgUrls.elementAt(0);
  }

  Observation copy(
    {
      int? dbId,
      String? uid,
      String? observerUid,
      String? name,
      String? location,
      DateTime? date,
      double? altitudeInMeters,
      double? latitude,
      double? longitude,
      String? species,
      List<String>? signs,
      String? pikasDetected,
      String? distanceToClosestPika,
      String? searchDuration,
      String? talusArea,
      String? temperature,
      String? skies,
      String? wind,
      String? siteHistory,
      String? comments,
      List<String>? imageUrls,
      List<String>? audioUrls,
      List<String>? otherAnimalsPresent,
      List<String>? sharedWithProjects,
      List<String>? notSharedWithProjects,
      DateTime? dateUpdatedInGoogleSheets,
      String? buttonText,
      CardLayout? cardLayout,
      IconData? uploadedIcon,
      IconData? notUploadedIcon
    }
  ) => Observation(
    dbId: dbId ?? this.dbId,
    uid: uid ?? this.uid,
    observerUid: observerUid ?? this.observerUid,
    name: name ?? this.name,
    location: location ?? this.location,
    date: date ?? this.date,
    altitudeInMeters: altitudeInMeters ?? this.altitudeInMeters,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    species: species ?? this.species,
    signs: signs ?? this.signs,
    pikasDetected: pikasDetected ?? this.pikasDetected,
    distanceToClosestPika: distanceToClosestPika ?? this.distanceToClosestPika,
    searchDuration: searchDuration ?? this.searchDuration,
    talusArea: talusArea ?? this.talusArea,
    temperature: temperature ?? this.temperature,
    skies: skies ?? this.skies,
    wind: wind ?? this.wind,
    siteHistory: siteHistory ?? this.siteHistory,
    comments: comments ?? this.comments,
    imageUrls: imageUrls ?? this.imageUrls,
    audioUrls: audioUrls ?? this.audioUrls,
    otherAnimalsPresent: otherAnimalsPresent ?? this.otherAnimalsPresent,
    sharedWithProjects: sharedWithProjects ?? this.sharedWithProjects,
    notSharedWithProjects: notSharedWithProjects ?? this.notSharedWithProjects,
    dateUpdatedInGoogleSheets: dateUpdatedInGoogleSheets ?? this.dateUpdatedInGoogleSheets,
    buttonText: buttonText ?? this.buttonText,
    cardLayout: cardLayout ?? this.cardLayout,
    uploadedIcon: uploadedIcon ?? Icons.cloud_upload,
    notUploadedIcon: notUploadedIcon ?? Icons.access_time_filled
  );
}