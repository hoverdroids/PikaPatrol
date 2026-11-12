import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseTime(dynamic date) {
  if (date == null) return null;
  if (date is Timestamp) return date.toDate();
  if (date is DateTime) return date;
  if (date is String) return DateTime.tryParse(date);
  return null;
}
// A short time span that reads the same in English, Spanish and French: "45 s", "12 min",
// "3 h 5 min", "4 d 2 h"
String formatShortDuration(Duration duration) {
  if (duration.inMinutes < 1) return "${duration.inSeconds} s";
  if (duration.inHours < 1) return "${duration.inMinutes} min";
  if (duration.inDays < 1) return "${duration.inHours} h ${duration.inMinutes % 60} min";
  return "${duration.inDays} d ${duration.inHours % 24} h";
}
