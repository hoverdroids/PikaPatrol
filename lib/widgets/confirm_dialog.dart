import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';

// Asks before an action that can't be undone. Returns true only when the user confirms.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String confirmLabel,
  required String cancelLabel,
  Color confirmColor = Colors.red,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(description),
      actions: [
        TextButton(
          child: Text(cancelLabel),
          onPressed: () => Navigator.pop(context, false),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            backgroundColor: confirmColor,
            shape: const StadiumBorder(),
          ),
          child: ThemedTitle(confirmLabel, type: ThemeGroupType.MOP),
        ),
      ],
    ),
  );
  return confirmed == true;
}
