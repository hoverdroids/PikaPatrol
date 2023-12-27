import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../utils/constants.dart';

/// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
class SettingsService with ChangeNotifier, DiagnosticableTreeMixin {

  SettingsService() {
    init();
  }

  Locale _locale = L10n.ENGLISH;
  Locale get locale => _locale;
  set locale(Locale locale) {
    _locale = locale;
    notifyListeners();
  }

  updateLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(Constants.PREFERENCE_LANGUAGE_CODE, locale.languageCode);
    this.locale = locale;
  }

  init() async {
    final prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString(Constants.PREFERENCE_LANGUAGE_CODE) ?? L10n.ENGLISH.languageCode;
    locale = Locale(languageCode);
  }
}