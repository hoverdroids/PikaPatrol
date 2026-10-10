import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:pika_patrol/utils/donation_utils.dart';

void main() {
  test('the donate link asks for a yearly gift and carries the account for the webhook', () {
    final uri = donateUri(userId: 'abc', now: DateTime.fromMillisecondsSinceEpoch(42));

    expect(uri.host, 'www.every.org');
    expect(uri.fragment, 'donate');
    expect(uri.queryParameters['frequency'], 'YEARLY');
    expect(uri.queryParameters['partner_donation_id'], 'abc-42');
    expect(jsonDecode(utf8.decode(base64Url.decode(uri.queryParameters['partner_metadata']!))), {'uid': 'abc'});
  });

  test('a signed-out donor gets a plain link', () {
    final uri = donateUri();
    expect(uri.queryParameters.containsKey('partner_donation_id'), isFalse);
    expect(uri.queryParameters.containsKey('partner_metadata'), isFalse);
  });

  test('the donate link only shows in the United States, once Every.org is set up', () {
    expect(canShowDonateLink(const Locale('en', 'US')), canTakeDonations);
    expect(canShowDonateLink(const Locale('en', 'CA')), isFalse);
    expect(canShowDonateLink(const Locale('fr')), isFalse);
  });
}
