import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../services/firebase_auth_service.dart';
import '../utils/donation_utils.dart';
import '../utils/network_utils.dart';
import 'confirm_dialog.dart';

// Shown each time someone who isn't a supporter opens the map or dashboard. It explains what
// supporters see and, where the stores allow it (see canShowDonateLink), links to the donate page.
Future<void> showSupporterDialog(BuildContext context, {String? userId}) async {
  final translations = Provider.of<Translations>(context, listen: false);
  // The phone's region, not the app's language: the app language has no country
  final showLink = canShowDonateLink(View.of(context).platformDispatcher.locale);

  // A gift unlocks the account that opened the link, so there has to be one
  final description = userId == null
      ? "${translations.supporterDescription}\n\n${translations.signInToBecomeSupporter}"
      : translations.supporterDescription;

  if (!showLink || userId == null) {
    await showInfoDialog(context, title: translations.supportPikaResearch, description: description, closeLabel: translations.ok);
    return;
  }

  final donate = await showConfirmDialog(
    context,
    title: translations.supportPikaResearch,
    description: translations.supporterDescription,
    confirmLabel: translations.donate,
    cancelLabel: translations.notNow,
    confirmColor: context.read<MaterialThemesManager>().colorPalette().primary,
  );
  if (!donate || !context.mounted) return;

  final authService = Provider.of<FirebaseAuthService>(context, listen: false);
  launchInBrowser(donateUri(userId: userId).toString());
  _refreshClaimsWhenBack(authService);
}

// Every.org tells our webhook about the gift within moments, so when the person comes back to the
// app, ask for their supporter status again rather than waiting up to an hour for it
void _refreshClaimsWhenBack(FirebaseAuthService authService) {
  late final AppLifecycleListener listener;
  listener = AppLifecycleListener(onResume: () async {
    listener.dispose();
    await Future.delayed(const Duration(seconds: 5));
    await authService.refreshClaims();
  });
}
