import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:material_themes_widgets/utils/ui_utils.dart';
import 'package:provider/provider.dart';

import '../l10n/translations.dart';

// For admins: makes someone a supporter by email, for gifts made outside the app (a check, an
// event, a sponsorship), or ends their status. The setSupporter Cloud Function does the work,
// because only the server can change sign-in claims.
Future<void> showSetSupporterDialog(BuildContext context) async {
  final translations = Provider.of<Translations>(context, listen: false);
  final email = TextEditingController();
  // Days to add; 0 ends the status now
  var days = 365;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(translations.setSupporterStatus),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              decoration: InputDecoration(labelText: translations.email),
            ),
            const SizedBox(height: 16.0),
            Wrap(
              spacing: 8.0,
              children: [
                for (final (value, label) in [(365, translations.addOneYear), (30, translations.addOneMonth), (0, translations.endSupporterStatus)])
                  ChoiceChip(label: Text(label), selected: days == value, onSelected: (_) => setState(() => days = value)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(translations.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(translations.save)),
        ],
      ),
    ),
  );

  final address = email.text.trim();
  email.dispose();
  if (confirmed != true) return;
  if (address.isEmpty) {
    showToast(translations.emailCannotBeEmpty);
    return;
  }

  try {
    await FirebaseFunctions.instance.httpsCallable("setSupporter").call({"email": address, "days": days});
    showToast(translations.supporterStatusUpdated);
  } on FirebaseFunctionsException catch (e) {
    showToast(e.message ?? e.code);
  }
}
