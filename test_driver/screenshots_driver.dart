import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

// Saves the screenshots taken by integration_test/store_screenshots_test.dart
Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final dir = Platform.environment['SCREENSHOT_DIR'] ?? 'build/screenshots';
    final file = File('$dir/$name.png');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
);
