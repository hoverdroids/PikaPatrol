import 'package:hive/hive.dart';
import 'local_observation.dart';
import 'dart:developer' as developer;

// DO NOT CHANGE THE READ OR WRITE ORDER BETWEEN ADAPTER VERSIONS!
// Calling "write" will save data in one block, in the
// linear order in which it is called. Calling "read" pulls the data
// from that one block until there are no more bytes available.

// So, if you called writeString(someString) and then
// writeString(someOtherString), you'll be storing "someStringSomeOtherString".
// Then, if you call someOtherString = readString, someString = readString,
// it will return someString then someOtherString since that's the
// the order of strings saved to the block.

// In short, the adapter's write/read order needs to remain consistent between
// adapter versions, and need to have same read order as write order.
// When additional fields are added to the hive model, add the writes/reads
// for each new field after the old writes/reads.

// Additionally, when the number of bytes written with a previous adapter are less
// than bytes written with a new adapter, because you added fields to the
// hive model, then the new adapter will try to continue reading bytes
// on the old model stored in db, and that model doesn't have any more.
// Consequently, hive will throw "not enough bytes" error because there are no more bytes to read.
class LocalObservationAdapter extends TypeAdapter<LocalObservation> {

  @override
  int get typeId => 0;

  @override
  read(BinaryReader reader) {
    // Retrieve the observation data consistent across all versions of LocalObservation
    var localObservation = LocalObservation(
        uid: reader.readString(),
        observerUid: reader.readString(),
        altitudeInMeters: reader.readDouble(),
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
        audioUrls: reader.readStringList(),
    );

    // If the observation is older, there won't be any more bytes to read.
    // Trying to do so will throw the error "Not enough bytes available"
    if (reader.availableBytes > 0) {
      // There are more bytes, so we know this is a newer observation with more bytes
      localObservation.species = reader.readString();
      localObservation.sharedWithProjects = reader.readStringList();
      localObservation.notSharedWithProjects = reader.readStringList();
      localObservation.dateUpdatedInGoogleSheets = reader.readString();
    }


    return localObservation;
  }

  @override
  void write(BinaryWriter writer, LocalObservation observation) {
      writer.write(observation.uid);
      writer.write(observation.observerUid);
      writer.write(observation.altitudeInMeters);
      writer.write(observation.longitude);
      writer.write(observation.latitude);
      writer.write(observation.name);
      writer.write(observation.location);
      writer.write(observation.date);
      writer.write(observation.signs);
      writer.write(observation.pikasDetected);
      writer.write(observation.distanceToClosestPika);
      writer.write(observation.searchDuration);
      writer.write(observation.talusArea);
      writer.write(observation.temperature);
      writer.write(observation.skies);
      writer.write(observation.wind);
      writer.write(observation.otherAnimalsPresent);
      writer.write(observation.siteHistory);
      writer.write(observation.comments);
      writer.write(observation.imageUrls);
      writer.write(observation.audioUrls);
      writer.write(observation.species);
      writer.write(observation.sharedWithProjects);
      writer.write(observation.notSharedWithProjects);
      writer.write(observation.dateUpdatedInGoogleSheets);
  }
}