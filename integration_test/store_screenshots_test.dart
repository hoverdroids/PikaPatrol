import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pika_patrol/main.dart' as app;
import 'package:pika_patrol/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Store screenshots. Run on a simulator or device, signed out, with location allowed:
//   fvm flutter drive --driver=test_driver/screenshots_driver.dart \
//     --target=integration_test/store_screenshots_test.dart -d <device>
// The driver saves each shot under the folder in SCREENSHOT_DIR (default build/screenshots).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // The app has endless animations (shimmer, loading cards), so pump for a while instead of
  // waiting for it to settle
  Future<void> wait(WidgetTester tester, [int seconds = 2]) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('store screenshots', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsService.PREFERENCE_SHOW_SPLASH_SCREEN, false);
    await prefs.setBool(SettingsService.PREFERENCE_USER_ACK_GEO, true);

    await app.main();
    await wait(tester, 8);
    await binding.takeScreenshot('01-observations');

    await tester.tap(find.byIcon(Icons.menu));
    await wait(tester);
    await binding.takeScreenshot('02-menu');

    await tester.tap(find.text('Identifying Pikas and Their Signs'));
    await wait(tester, 3);
    // Past the title page, to a page with a pika photo
    await tester.drag(find.byType(Scaffold).last, const Offset(-600, 0));
    await wait(tester, 3);
    await binding.takeScreenshot('03-training');

    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await wait(tester, 3);

    await tester.tap(find.byIcon(Icons.loupe).first);
    await wait(tester, 6);
    await binding.takeScreenshot('04-new-observation');
  });
}
