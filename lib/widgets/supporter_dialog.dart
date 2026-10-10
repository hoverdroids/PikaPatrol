import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';
import '../utils/donation_utils.dart';
import '../utils/network_utils.dart';
import 'confirm_dialog.dart';

// Shown each time someone who isn't a supporter opens the map or dashboard. It explains what
// supporters see and, where the stores allow it (see canShowDonateLink), links to the donate page.
Future<void> showSupporterDialog(BuildContext context, {String? userId}) async {
  final translations = Provider.of<Translations>(context, listen: false);
  // The phone's region, not the app's language: the app language has no country
  final showLink = canShowDonateLink(View.of(context).platformDispatcher.locale);

  if (!showLink) {
    await showInfoDialog(context, title: translations.supportPikaResearch, description: translations.supporterDescription, closeLabel: translations.ok);
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
  if (donate) launchInBrowser(donateUri(userId: userId).toString());
}
