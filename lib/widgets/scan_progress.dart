import 'package:flutter/material.dart';
import 'package:material_themes_manager/material_themes_manager.dart';
import 'package:material_themes_widgets/fundamental/texts.dart';

// Progress for the admin Storage scan, which can take a minute with thousands of files
class ScanProgress extends StatelessWidget {
  final String message;
  final double? value;

  const ScanProgress(this.message, {super.key, this.value});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(value: value),
          const SizedBox(height: 16.0),
          ThemedSubTitle(message, type: ThemeGroupType.MOM),
        ],
      ),
    ),
  );
}
