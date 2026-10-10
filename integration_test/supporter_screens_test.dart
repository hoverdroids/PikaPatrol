import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:pika_patrol/main.dart' as app;
import 'package:pika_patrol/model/local_observation.dart';
import 'package:pika_patrol/model/observation.dart';
import 'package:pika_patrol/services/observations_service.dart';
import 'package:provider/provider.dart';
import 'package:pika_patrol/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Opens the map and dashboard from the bottom bar and screenshots them. Run like the store
// screenshots (see store_screenshots_test.dart), with SCREENSHOT_DIR set to a scratch folder.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> wait(WidgetTester tester, [int seconds = 2]) async {
    for (var i = 0; i < seconds * 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('map and dashboard', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsService.PREFERENCE_SHOW_SPLASH_SCREEN, false);
    await prefs.setBool(SettingsService.PREFERENCE_USER_ACK_GEO, true);

    await app.main();
    await wait(tester, 8);

    // A few sample observations on this device, removed again at the end
    final service = Provider.of<ObservationsService>(tester.element(find.byType(Scaffold).first), listen: false);
    final samples = <LocalObservation>[];
    final sites = [('Loveland Pass', 39.663, -105.879, '2'), ('Mount Evans', 39.588, -105.643, '0'),
        ('Rocky Mountain NP', 40.383, -105.693, '>5'), ('Independence Pass', 39.108, -106.564, '1')];
    for (final (index, (location, latitude, longitude, pikas)) in sites.indexed) {
      final saved = await service.saveLocalObservation(Observation(
        observerUid: '', location: location, latitude: latitude, longitude: longitude, pikasDetected: pikas,
        date: DateTime(2026, 6 + index, 10), altitudeInMeters: 3300.0 + index * 150,
        signs: ['Saw Pika', if (index.isEven) 'Heard Pika Calls'], species: index == 3 ? 'Collared Pika' : Observation.SPECIES_DEFAULT,
        sharedWithProjects: ['Rocky Mountain Wild'],
      ));
      if (saved != null) samples.add(saved);
    }
    await wait(tester, 2);

    await tester.tap(find.byIcon(Icons.map).first);
    await wait(tester, 3);
    await binding.takeScreenshot('map-supporter-prompt');
    await tester.tap(find.text('OK').last);
    await wait(tester, 6);
    await binding.takeScreenshot('map');

    await tester.tap(find.byType(BackButton).first);
    await wait(tester, 3);

    await tester.tap(find.byIcon(Icons.show_chart).first);
    await wait(tester, 3);
    await tester.tap(find.text('OK').last);
    await wait(tester, 3);
    await binding.takeScreenshot('dashboard');
    await tester.drag(find.byType(ListView).last, const Offset(0, -900));
    await wait(tester, 2);
    await binding.takeScreenshot('dashboard-2');

    for (final sample in samples) {
      await sample.delete();
    }
  });
}
