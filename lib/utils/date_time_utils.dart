import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseTime(dynamic date) {
  if (date == null) return null;
  if (date is Timestamp) return date.toDate();
  if (date is DateTime) return date;
  return null;
}