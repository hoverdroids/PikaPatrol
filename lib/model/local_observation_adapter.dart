import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pika_joe/model/local_observation.dart';

class LocalObservationAdapter extends TypeAdapter<LocalObservation> {

  @override
  int get typeId => 0;

  @override
  LocalObservation read(BinaryReader reader) {
    return LocalObservation(
      uid: reader.readString(),
      observerUid: reader.readString(),
      altitude: reader.readDouble(),
      longitude: reader.readDouble(),
      latitude: reader.readDouble()
    );
  }

  @override
  void write(BinaryWriter writer, LocalObservation observation) {
    writer.writeString(observation.uid);
    writer.writeString(observation.observerUid);
    writer.writeDouble(observation.altitude);
    writer.writeDouble(observation.longitude);
    writer.writeDouble(observation.latitude);
  }
}