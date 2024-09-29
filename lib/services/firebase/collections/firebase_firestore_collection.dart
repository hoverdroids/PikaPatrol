import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseFirestoreCollection {

  //region Firebase
  final FirebaseFirestore firestore;
  //endregion

  //region Collection
  late final CollectionReference collection;
  String name;
  //endregion

  //region Limit
  static const int? DEFAULT_LIMIT_NONE = null;
  static const int DEFAULT_LIMIT_SMALL = 5;
  static const int DEFAULT_LIMIT_MEDIUM = 15;
  static const int DEFAULT_LIMIT_LARGE = 30;

  int? limit;
  //endregion

  //region Timeout
  static const int FUTURE_TIMEOUT_SECONDS = 3;
  static const bool FUTURE_TIMEDOUT = true;
  //endregion

  //region Constructors
  FirebaseFirestoreCollection(
    this.firestore,
    this.name,
    {this.limit = DEFAULT_LIMIT_SMALL}
  ){
    collection = firestore.collection(name);
  }
  //endregion
}