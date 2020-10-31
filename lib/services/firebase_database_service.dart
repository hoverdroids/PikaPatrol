import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_joe/model/observation2.dart';
import 'package:pika_joe/model/user_profile.dart';

class FirebaseDatabaseService {

  final String uid;

  FirebaseDatabaseService({ this.uid });

  final CollectionReference userProfilesCollection = Firestore.instance.collection("userProfiles");

  final CollectionReference observationsCollection = Firestore.instance.collection("observations");

  Future updateUserProfile(
    String firstName,
    String lastName,
    String tagline,
    String pronouns,
    String organization,
    String address,
    String city,
    String state,
    String zip,
    bool frppOptIn,
    bool rmwOptIn,
    bool dzOptIn
  ) async {
    return await userProfilesCollection.document(uid).setData(
        {
          'firstName': firstName,
          'lastName': lastName,
          'tagline' : tagline,
          'pronouns': pronouns,
          'organization': organization,
          'address': address,
          'city': city,
          'state': state,
          'zip': zip,
          'frppOptIn': frppOptIn,
          'rmwOptIn': rmwOptIn,
          'dzOptIn': dzOptIn,
        }
    );
  }
  
  /*Future updateUserProfile(UserProfile data) async {
    return await userProfilesCollection.document(uid).setData(
        {
          'firstName': data.firstName,
          'lastName': data.lastName,
          'pronouns': data.pronouns,
          'organization': data.organization,
          'address': data.address,
          'city': data.city,
          'state': data.state,
          'zip': data.zip,
          'frppOptIn': data.frppOptIn,
          'rmwOptIn': data.rmwOptIn,
          'dzOptIn': data.dzOptIn,
        }
    );
  }*/

  UserProfile _userProfileFromSnapshot(DocumentSnapshot snapshot) {
    return UserProfile(
      snapshot.data['firstName'] ?? '',
      snapshot.data['lastName'] ?? '',
      uid: uid,
      tagline: snapshot.data['tagline'] ?? '',
      pronouns: snapshot.data['pronouns'] ?? '',
      organization: snapshot.data['organization'] ?? '',
      address: snapshot.data['address'] ?? '',
      city: snapshot.data['city'] ?? '',
      state: snapshot.data['state'] ?? '',
      zip: snapshot.data['zip'] ?? '',
      frppOptIn: snapshot.data['frppOptIn'] ?? false,
      rmwOptIn: snapshot.data['rmwOptIn'] ?? false,
      dzOptIn: snapshot.data['dzOptIn'] ?? false,
    );
  }

  Stream<UserProfile> get userProfile {
    return uid == null ? null : userProfilesCollection.document(uid).snapshots().map(_userProfileFromSnapshot);
  }

  Future updateObservation(Observation2 observation) async {
    //if no ID, the id and timestamp are auto gen; not sure it's what we want
    var doc = observation.uid == null ? observationsCollection.document() : observationsCollection.document(observation.uid);
    observation.uid = doc.documentID;
    return await doc.setData(
        {
          'observerUid': observation.observerUid,
          'date': observation.date,
          //'geo' : null,
          'signs': observation.signs,
          'pikasDetected': observation.pikasDetected,
          'distanceToClosestPika': observation.distanceToClosestPika,
          'searchDuration': observation.searchDuration,
          'skies': observation.skies,
          'wind': observation.wind,
          'siteHistory': observation.siteHistory,
          'comments': observation.comments
        }
    );
  }

  /*Future updateObservation(
      String observationUid,
      String observerUid,
      String date,
      //TODO - geo data
      List<String> signs,
      String pikasDetected,
      String distanceToClosestPika,
      String searchDuration,
      String skies,
      String wind,
      String siteHistory,
      String comments,
      List<String> imageUrls,
      List<String> audioUrls,
      List<String> otherAnimalsPresent
      ) async {
    return await userProfilesCollection.document().setData(//if no ID, the id and timestamp are auto gen; not sure it's what we want
        {
          'observerUid': observerUid,
          'date': date,
          'geo' : null,
          'signs': signs,
          'pikasDetected': pikasDetected,
          'distanceToClosestPika': distanceToClosestPika,
          'searchDuration': searchDuration,
          'skies': skies,
          'wind': wind,
          'siteHistory': siteHistory,
          'comments': comments
        }
    );
  }*/

  List<Observation2> _observationsFromSnapshot(QuerySnapshot snapshot) {
    return snapshot.documents.map((doc) {
      return Observation2(
        uid: doc.documentID ?? '',
        observerUid: doc.data['observerUid'] ?? '',
        date: doc.data['date'] ?? '',
        signs: doc.data['signs'] ?? '',
        pikasDetected: doc.data['pikasDetected'] ?? '',
        distanceToClosestPika: doc.data['distanceToClosestPika'] ?? '',
        searchDuration: doc.data['searchDuration'] ?? '',
        skies: doc.data['skies'] ?? '',
        wind: doc.data['wind'] ?? '',
        siteHistory: doc.data['siteHistory'] ?? '',
        comments: doc.data['comments'] ?? ''
      );
    }).toList();
  }

  Stream<List<Observation2>> get observations {
    return observationsCollection.snapshots().map(_observationsFromSnapshot);
  }
}