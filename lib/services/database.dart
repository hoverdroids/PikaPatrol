import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_joe/model/brew.dart';
import 'package:pika_joe/model/user.dart';

class DatabaseService {

  final String uid;
  DatabaseService({ this.uid });

  final CollectionReference brewCollection = Firestore.instance.collection('brews');

  Future updateUserData(String sugars, String name, int strength) async {
    return await brewCollection.document(uid).setData({
      'sugars' : sugars,
      'name' : name,
      'strength' : strength,
    });
  }

  List<Brew> _brewListFromSnapshot(QuerySnapshot snapshot) {
    print('BrewListFromSnapshot:');
    print(snapshot.documents[0].data);
    var list = snapshot.documents.map((doc){
      print("Snapshot:");
      print(doc.data['name']);
      return Brew(
        name: doc.data['name'] ?? '',
        strength: doc.data['strength'] ?? 0,
        sugars: doc.data['sugars'] ?? '0'
      );
    }).toList();

    print('List:');
    print(list);

    return list;
  }

  //userData from snapsho
  UserData _userDataFromSnapshot(DocumentSnapshot snapshot) {
    return UserData(
      uid: uid,
      name: snapshot.data['name'],
      sugars: snapshot.data['sugars'],
      strength: snapshot.data['strength']
    );
  }

  //Get brews stream
  Stream<List<Brew>> get brews {
      return brewCollection.snapshots().map(_brewListFromSnapshot);
  }

  //Get user doc stream
  Stream<UserData> get userData {
      return brewCollection.document(uid).snapshots().map(_userDataFromSnapshot);
  }
}