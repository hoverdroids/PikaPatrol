import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_joe/model/user_profile.dart';

class FirebaseDatabaseService {

  final String uid;

  FirebaseDatabaseService({ this.uid });

  //TODO - we should never get all users' preference! We should just get the one set for the one user
  final CollectionReference userProfilesCollection = Firestore.instance.collection("userProfiles");

  //TODO - we should try to get the most recent ten or apply and pass a filter
  final CollectionReference observationsCollection = Firestore.instance
      .collection("observations");

  Future updateUserProfile(
    String firstName,
    String lastName,
    {
      String pronouns = "",
      String organization = "",
      String address = "",
      String city = "",
      String state = "",
      String zip = "",
      bool frppOptIn = false,
      bool rmwOptIn = false,
      bool dzOptIn = false
    }
  ) async {
    return await userProfilesCollection.document(uid).setData(
        {
          'firstName': firstName,
          'lastName': lastName,
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

  //TODO - this is a really bad way of getting a single user's perferences
  List<UserProfile> _userProfilesListFromSnapshot(QuerySnapshot snapshot) {
    print("UserProfilesListFromSnapShot:");
    print(snapshot.documents[0].data);

    var list = snapshot.documents.map((doc) {
      print("Snapshot:");
      print(doc.data['firstName']);

      return UserProfile(
        doc.data['firstName'] ?? '',
        doc.data['lastName'] ?? '',
        pronouns: doc.data['pronouns'] ?? '',
        organization: doc.data['organization'] ?? '',
        address: doc.data['address'] ?? '',
        city: doc.data['city'] ?? '',
        state: doc.data['state'] ?? '',
        zip: doc.data['zip'] ?? '',
        frppOptIn: doc.data['frppOptIn'] ?? false,
        rmwOptIn: doc.data['rmwOptIn'] ?? false,
        dzOptIn: doc.data['dzOptIn'] ?? false,
      );
    }).toList();

    print("List:");
    print(list);

    return list;
  }

  Stream<List<UserProfile>> get userProfiles {
    return userProfilesCollection.snapshots().map(_userProfilesListFromSnapshot);
  }

  Stream<UserProfile> get userProfile {
    return userProfilesCollection.document(uid).snapshots().map(_userProfileFromSnapshot);
  }

}