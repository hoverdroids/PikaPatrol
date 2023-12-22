import 'package:flutter/material.dart';
import 'package:material_themes_widgets/utils/collection_utils.dart';
import 'package:pika_patrol/model/card.dart' as card;
import '../data/pika_species.dart';

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
    this.species = PikaData.PIKA_SPECIES_DEFAULT,
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
    super.buttonText,
    super.cardLayout,
    IconData? uploadedIcon = Icons.cloud_upload,
    IconData? notUploadedIcon = Icons.access_time_filled
  }){
    this.signs = signs ?? <String>[];
    this.otherAnimalsPresent = otherAnimalsPresent ?? <String>[];
    this.sharedWithProjects = sharedWithProjects ?? PikaData.SHARED_WITH_PROJECTS_DEFAULT;
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

  List<String> getSpeciesOptions() => ([species] + PikaData.PIKA_SPECIES).toTrimmedUniqueList();

  List<String> getOtherAnimalsPresentOptions() {
    var selectedAnimals = otherAnimalsPresent ?? <String>[];
    var defaultAnimals = PikaData.OTHER_ANIMALS_PRESENT;
    return (selectedAnimals + defaultAnimals).toTrimmedUniqueList();
  }

  List<String> getSharedWithProjectsOptions() {
    var selectedProjects = sharedWithProjects ?? PikaData.SHARED_WITH_PROJECTS_DEFAULT;
    var defaultProjects = PikaData.SHARED_WITH_PROJECTS;
    return (selectedProjects + defaultProjects).toTrimmedUniqueList();
  }
}
