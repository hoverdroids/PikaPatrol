import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
class SettingsService with ChangeNotifier, DiagnosticableTreeMixin {

  static const String PREFERENCE_USER_ACK_GEO = "userAckGeo";
  static const String PREFERENCE_LANGUAGE_CODE = "languageCode";
  static const String PREFERENCE_IS_ADMIN = "isAdmin";
  static const String PREFERENCE_SHOW_INDIGENOUS_MAP = "showIndigenousMap";
  static const String PREFERENCE_SHOW_SPLASH_SCREEN = "showSplashScreen";
  static const String PREFERENCE_UNITS = "units";
  static const String PREFERENCE_DEFAULT_OBSERVATION_TEMPLATE = "defaultObservationTemplate";
  static const String PREFERENCE_SHOW_HINTS = "showHints";

  static const String UNITS_IMPERIAL = "imperial";
  static const String UNITS_METRIC = "metric";

  SettingsService() {
    init();
  }

  Locale _locale = L10n.ENGLISH;
  Locale get locale => _locale;
  set locale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  bool _showSplashScreen = true;
  bool get showSplashScreen => _showSplashScreen;

  Future<void> setShowSplashScreen(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFERENCE_SHOW_SPLASH_SCREEN, enabled);
    _showSplashScreen = enabled;
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
    return prefs.getBool(PREFERENCE_IS_ADMIN);
  }

  Future setIsAdmin(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFERENCE_IS_ADMIN, isAdmin);
  }

  bool _showIndigenousMap = true;
  bool get showIndigenousMap => _showIndigenousMap;

  Future<bool> getShowIndigenousMap() async => _showIndigenousMap;

  Future<void> setShowIndigenousMap(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFERENCE_SHOW_INDIGENOUS_MAP, enabled);
    _showIndigenousMap = enabled;
    notifyListeners();
  }

  //Whether choice fields that offer hints (e.g. talus area sizes as tennis court/football field
  //comparisons) show them; persisted so the user's choice sticks across observations and sessions.
  bool _showHints = false;
  bool get showHints => _showHints;

  Future<void> setShowHints(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREFERENCE_SHOW_HINTS, enabled);
    _showHints = enabled;
    notifyListeners();
  }

  String _units = UNITS_IMPERIAL;
  String get units => _units;
  bool get isMetric => _units == UNITS_METRIC;

  Future<void> setUnits(String units) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREFERENCE_UNITS, units);
    _units = units;
    notifyListeners();
  }

  // The default observation template, stored as JSON; see observation_utils.dart for the
  // Observation encode/decode helpers.
  String? _defaultObservationTemplateJson;
  String? get defaultObservationTemplateJson => _defaultObservationTemplateJson;

  Future<void> setDefaultObservationTemplateJson(String json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(PREFERENCE_DEFAULT_OBSERVATION_TEMPLATE, json);
    _defaultObservationTemplateJson = json;
    notifyListeners();
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
    _showSplashScreen = prefs.getBool(PREFERENCE_SHOW_SPLASH_SCREEN) ?? true;
    _showIndigenousMap = prefs.getBool(PREFERENCE_SHOW_INDIGENOUS_MAP) ?? true;
    _units = prefs.getString(PREFERENCE_UNITS) ?? UNITS_IMPERIAL;
    _showHints = prefs.getBool(PREFERENCE_SHOW_HINTS) ?? false;
    _defaultObservationTemplateJson = prefs.getString(PREFERENCE_DEFAULT_OBSERVATION_TEMPLATE);
    notifyListeners();
  }
}