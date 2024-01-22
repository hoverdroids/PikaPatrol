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
    
    var localObservation = LocalObservation();
    
    if (reader.availableBytes > 0) {
      try {
        // Retrieve the observation data consistent across all versions of LocalObservation
        localObservation.uid = reader.readString();
        localObservation.observerUid = reader.readString();
        localObservation.altitudeInMeters = reader.readDouble();
        localObservation.longitude = reader.readDouble();
        localObservation.latitude = reader.readDouble();
        localObservation.name = reader.readString();
        localObservation.location = reader.readString();
        localObservation.date = reader.readString();
        localObservation.signs = reader.readStringList();
        localObservation.pikasDetected = reader.readString();
        localObservation.distanceToClosestPika = reader.readString();
        localObservation.searchDuration = reader.readString();
        localObservation.talusArea = reader.readString();
        localObservation.temperature = reader.readString();
        localObservation.skies = reader.readString();
        localObservation.wind = reader.readString();
        localObservation.otherAnimalsPresent = reader.readStringList();
        localObservation.siteHistory = reader.readString();
        localObservation.comments = reader.readString();
        localObservation.imageUrls = reader.readStringList();
        localObservation.audioUrls = reader.readStringList();

        // If the observation is older, there won't be any more bytes to read.
        // Trying to do so will throw the error "Not enough bytes available"


        // There are more bytes, so we know this is a newer observation with more bytes
        localObservation.species = reader.readString();
        localObservation.sharedWithProjects = reader.readStringList();
        localObservation.notSharedWithProjects = reader.readStringList();
        localObservation.dateUpdatedInGoogleSheets = reader.readString();
      } catch(e) {
        developer.log("Reader error: $e");
      }
    }


    return localObservation;
  }

  @override
  void write(BinaryWriter writer, LocalObservation observation) {
      writer.writeString(observation.uid);
      writer.writeString(observation.observerUid);
      writer.writeDouble(observation.altitudeInMeters);
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
      writer.writeString(observation.species);
      writer.writeStringList(observation.sharedWithProjects);
      writer.writeStringList(observation.notSharedWithProjects);
      writer.writeString(observation.dateUpdatedInGoogleSheets);
  }
}