import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseTime(dynamic date) {
  if (date == null) return null;
  return Platform.isIOS ? (date as Timestamp).toDate() : (date as DateTime);
}