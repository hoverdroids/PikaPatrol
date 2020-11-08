import 'package:hive/hive.dart';

//part 'local_observation.g.dart';

@HiveType(typeId: 0)
class LocalObservation extends HiveObject {
  @HiveField(0)
  String uid;

  @HiveField(1)
  String observerUid;

  @HiveField(2)
  double altitude;

  @HiveField(3)
  double longitude;

  @HiveField(4)
  double latitude;

  LocalObservation({this.uid = "", this.observerUid = "", this.altitude = 0.0, this.longitude = 0.0, this.latitude = 0.0});
}