import 'package:hive/hive.dart';
import 'local_observation.dart';

class LocalObservationAdapter extends TypeAdapter<LocalObservation> {

  @override
  int get typeId => 0;

  @override
  read(BinaryReader reader) => LocalObservation(
      uid: reader.readString(),
      observerUid: reader.readString(),
      name: reader.readString(),
      location: reader.readString(),
      date: reader.readString(),
      altitudeInMeters: reader.readDouble(),
      latitude: reader.readDouble(),
      longitude: reader.readDouble(),
      species: reader.readString(),
      signs: reader.readStringList(),
      pikasDetected: reader.readString(),
      distanceToClosestPika: reader.readString(),
      searchDuration: reader.readString(),
      talusArea: reader.readString(),
      temperature: reader.readString(),
      skies: reader.readString(),
      wind: reader.readString(),
      siteHistory: reader.readString(),
      comments: reader.readString(),
      imageUrls: reader.readStringList(),
      audioUrls: reader.readStringList(),
      otherAnimalsPresent: reader.readStringList(),
      sharedWithProjects: reader.readStringList(),
      notSharedWithProjects: reader.readStringList(),
      dateUpdatedInGoogleSheets: reader.readString()
  );

  @override
  void write(BinaryWriter writer, LocalObservation observation) {
      writer.writeString(observation.uid);
      writer.writeString(observation.observerUid);
      writer.writeString(observation.name);
      writer.writeString(observation.location);
      writer.writeString(observation.date);
      writer.writeDouble(observation.altitudeInMeters);
      writer.writeDouble(observation.latitude);
      writer.writeDouble(observation.longitude);
      writer.writeString(observation.species);
      writer.writeStringList(observation.signs);
      writer.writeString(observation.pikasDetected);
      writer.writeString(observation.distanceToClosestPika);
      writer.writeString(observation.searchDuration);
      writer.writeString(observation.talusArea);
      writer.writeString(observation.temperature);
      writer.writeString(observation.skies);
      writer.writeString(observation.wind);
      writer.writeString(observation.siteHistory);
      writer.writeString(observation.comments);
      writer.writeStringList(observation.imageUrls);
      writer.writeStringList(observation.audioUrls);
      writer.writeStringList(observation.otherAnimalsPresent);
      writer.writeStringList(observation.sharedWithProjects);
      writer.writeStringList(observation.notSharedWithProjects);
      writer.writeString(observation.dateUpdatedInGoogleSheets);
  }

}