import 'package:hive/hive.dart';
import 'local_observation.dart';

class LocalObservationAdapter extends TypeAdapter<LocalObservation> {

  @override
  int get typeId => 0;

  @override
  read(BinaryReader reader) {
    return LocalObservation(
        uid: reader.readString(),
        observerUid: reader.readString(),
        altitude: reader.readDouble(),
        longitude: reader.readDouble(),
        latitude: reader.readDouble(),
        name: reader.readString(),
        location: reader.readString(),
        date: reader.readString(),
        signs: reader.readStringList(),
        pikasDetected: reader.readString(),
        distanceToClosestPika: reader.readString(),
        searchDuration: reader.readString(),
        talusArea: reader.readString(),
        temperature: reader.readString(),
        skies: reader.readString(),
        wind: reader.readString(),
        otherAnimalsPresent: reader.readStringList(),
        siteHistory: reader.readString(),
        comments: reader.readString(),
        imageUrls: reader.readStringList(),
        audioUrls: reader.readStringList()
    );
  }

  @override
  void write(BinaryWriter writer, LocalObservation observation) {
    writer.writeString(observation.uid);
    writer.writeString(observation.observerUid);
    writer.writeDouble(observation.altitude);
    writer.writeDouble(observation.longitude);
    writer.writeDouble(observation.latitude);
    writer.writeString(observation.name);
    writer.writeString(observation.location);
    writer.writeString(observation.date);
    writer.writeStringList(observation.signs);
    writer.writeString(observation.pikasDetected);
    writer.writeString(observation.distanceToClosestPika);
    writer.writeString(observation.searchDuration);
    writer.writeString(observation.talusArea);
    writer.writeString(observation.temperature);
    writer.writeString(observation.skies);
    writer.writeString(observation.wind);
    writer.writeStringList(observation.otherAnimalsPresent);
    writer.writeString(observation.siteHistory);
    writer.writeString(observation.comments);
    writer.writeStringList(observation.imageUrls);
    writer.writeStringList(observation.audioUrls);
  }

}