import 'dart:convert';
import 'dart:ui';

// Donations go to Rocky Mountain Wild through Every.org, which charges nonprofits no platform fee.
// See docs/design/2026-10-10-supporters-plan.md.

// RMW's Every.org slug or EIN, set once RMW claims its profile. The donate button hides until then.
const String everyOrgNonprofit = "";
// From partners@every.org; Every.org calls our webhook for donations made with it
const String everyOrgWebhookToken = "";

bool get canTakeDonations => everyOrgNonprofit.isNotEmpty;

// Linking out to pay for app features is only allowed in the United States (court rulings against
// Apple and Google). Elsewhere the app may ask for support but shows no payment link.
bool canShowDonateLink(Locale locale) => canTakeDonations && locale.countryCode?.toUpperCase() == "US";

// The donate page, tagged with the account so the webhook can mark it as a supporter.
// A yearly gift renews the supporter status each year.
Uri donateUri({String? userId, DateTime? now}) {
  final parameters = <String, String>{
    "frequency": "YEARLY",
    "suggestedAmounts": "25,100,250",
    if (userId != null && userId.isNotEmpty) ...{
      "partner_donation_id": "$userId-${(now ?? DateTime.now()).millisecondsSinceEpoch}",
      "partner_metadata": base64Url.encode(utf8.encode(jsonEncode({"uid": userId}))),
    },
    if (everyOrgWebhookToken.isNotEmpty) "webhook_token": everyOrgWebhookToken,
  };
  return Uri.https("www.every.org", "/$everyOrgNonprofit", parameters).replace(fragment: "donate");
}
