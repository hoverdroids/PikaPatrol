import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pika_patrol/model/card.dart' as card;

class Observation extends card.Card {
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
  List<String>? signs;
  String? pikasDetected;
  String? distanceToClosestPika;
  String? searchDuration;
  String? talusArea;
  String? temperature;
  String? skies;
  String? wind;
  List<String>? otherAnimalsPresent;
  String? siteHistory;
  String? comments;
  List<String>? imageUrls;
  List<String>? audioUrls;

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
    super.buttonText = "View Observation",
    super.cardLayout,
    IconData? uploadedIcon = Icons.cloud_upload,
    IconData? notUploadedIcon = Icons.access_time_filled
  }){
    this.signs = signs ?? <String>[];
    this.otherAnimalsPresent = otherAnimalsPresent ?? <String>[];
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
}
