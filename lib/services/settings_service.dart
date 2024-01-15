import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
class SettingsService with ChangeNotifier, DiagnosticableTreeMixin {

  static const String PREFERENCE_USER_ACK_GEO = "userAckGeo";
  static const String PREFERENCE_LANGUAGE_CODE = "languageCode";
  static const String PREFERENCE_IS_ADMIN = "isAdmin";
  
  SettingsService() {
    init();
  }

  Locale _locale = L10n.ENGLISH;
  Locale get locale => _locale;
  set locale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  Future<bool?> getUserAcknowledgedGeo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREFERENCE_USER_ACK_GEO);
  }

  Future setUserAcknowledgedGeo({bool userAcknowledged = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFERENCE_USER_ACK_GEO, userAcknowledged);
  }

  Future<bool?> getIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREFERENCE_USER_ACK_GEO);
  }

  Future setIsAdmin(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFERENCE_IS_ADMIN, isAdmin);
  }

  updateLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREFERENCE_LANGUAGE_CODE, locale.languageCode);
    this.locale = locale;
  }

  init() async {
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString(PREFERENCE_LANGUAGE_CODE) ?? L10n.ENGLISH.languageCode;
    locale = Locale(languageCode);
  }
}