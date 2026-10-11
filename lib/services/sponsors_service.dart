import 'dart:convert';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// An organization that sponsors Pika Patrol, listed under "Sponsors and Support" in the left menu.
// Admins add them in the Firestore console (collection "sponsors"; see docs/firebase-runbook.md).
class Sponsor {
  // Higher tiers list first; unknown tiers list last
  static const List<String> tiers = ["gold", "silver", "bronze"];

  final String name;
  final String? url;
  final String? logoUrl;
  final String tier;
  final String? message;
  final DateTime? expiresAt;

  const Sponsor({required this.name, this.url, this.logoUrl, this.tier = "bronze", this.message, this.expiresAt});

  int get tierRank {
    final index = tiers.indexOf(tier);
    return index < 0 ? tiers.length : index;
  }

  bool isShownAt(DateTime now) => name.isNotEmpty && (expiresAt == null || expiresAt!.isAfter(now));

  static Sponsor fromMap(Map<String, dynamic> map) {
    String? text(String key) {
      final value = map[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }
    final expires = map["expiresAt"];
    return Sponsor(
      name: text("name") ?? "",
      url: text("url"),
      logoUrl: text("logoUrl"),
      tier: text("tier")?.toLowerCase() ?? "bronze",
      message: text("message"),
      expiresAt: expires is Timestamp ? expires.toDate() : expires is String ? DateTime.tryParse(expires) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    "name": name,
    "url": url,
    "logoUrl": logoUrl,
    "tier": tier,
    "message": message,
    "expiresAt": expiresAt?.toIso8601String(),
  };

  // Unexpired sponsors, highest tier first, then by name
  static List<Sponsor> shown(Iterable<Sponsor> sponsors, DateTime now) =>
      sponsors.where((sponsor) => sponsor.isShownAt(now)).toList()
        ..sort((a, b) => a.tierRank != b.tierRank ? a.tierRank.compareTo(b.tierRank) : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

// Keeps the sponsor list on the phone and asks Firestore for it at most once a day, so the menu
// costs a handful of reads per phone per day at most.
class SponsorsService with ChangeNotifier {
  static const String collection = "sponsors";
  static const Duration refreshInterval = Duration(days: 1);
  static const String _cacheKey = "sponsorsCache";
  static const String _cachedAtKey = "sponsorsCachedAt";

  List<Sponsor> _all = [];
  List<Sponsor> get sponsors => Sponsor.shown(_all, DateTime.now());

  SponsorsService() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    DateTime? cachedAt;
    try {
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        _all = [for (final map in jsonDecode(cached) as List) Sponsor.fromMap(map as Map<String, dynamic>)];
        notifyListeners();
      }
      cachedAt = DateTime.tryParse(prefs.getString(_cachedAtKey) ?? "");
    } catch (e) {
      developer.log('Could not read the saved sponsors: $e', name: 'SponsorsService');
    }
    if (cachedAt == null || DateTime.now().difference(cachedAt) >= refreshInterval) {
      await _refresh(prefs);
    }
  }

  Future<void> _refresh(SharedPreferences prefs) async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection(collection).get();
      _all = [for (final doc in snapshot.docs) Sponsor.fromMap(doc.data())];
      await prefs.setString(_cacheKey, jsonEncode([for (final sponsor in _all) sponsor.toJson()]));
      await prefs.setString(_cachedAtKey, DateTime.now().toIso8601String());
      notifyListeners();
    } catch (e) {
      // Offline or denied: keep the saved list and try again next launch
      developer.log('Could not load sponsors: $e', name: 'SponsorsService');
    }
  }
}
