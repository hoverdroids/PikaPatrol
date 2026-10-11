import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/services/sponsors_service.dart';

void main() {
  final now = DateTime(2026, 10, 11);

  test('Sponsors list by tier, then name, without expired ones', () {
    final sponsors = [
      Sponsor.fromMap({"name": "zeta", "tier": "Bronze"}),
      Sponsor.fromMap({"name": "Alpha", "tier": "bronze"}),
      Sponsor.fromMap({"name": "Gone", "tier": "gold", "expiresAt": "2026-01-01T00:00:00Z"}),
      Sponsor.fromMap({"name": "Big", "tier": "gold", "expiresAt": "2027-01-01T00:00:00Z"}),
      Sponsor.fromMap({"name": "Odd", "tier": "platinum"}),
      Sponsor.fromMap({"name": " ", "tier": "gold"}),
    ];
    expect(Sponsor.shown(sponsors, now).map((s) => s.name), ["Big", "Alpha", "zeta", "Odd"]);
  });

  test('A sponsor survives the round trip through the phone cache', () {
    final sponsor = Sponsor.fromMap({"name": "Big", "url": "https://example.org", "tier": "silver", "expiresAt": "2027-01-01T00:00:00.000Z"});
    final copy = Sponsor.fromMap(sponsor.toJson());
    expect(copy.name, "Big");
    expect(copy.url, "https://example.org");
    expect(copy.tier, "silver");
    expect(copy.expiresAt, sponsor.expiresAt);
  });
}
