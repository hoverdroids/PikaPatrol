import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pika_joe/model/brew.dart';

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

  //Get brews stream
  Stream<List<Brew>> get brews {
      return brewCollection.snapshots().map(_brewListFromSnapshot);
  }

}