# Pika Patrol Supporters Plan (3.6.0 and later)

**Goal:** give people reasons to donate to Rocky Mountain Wild (RMW) through the app, without fees eating
the donations and without growing the Firebase bill.

**Status:** draft, 2026-10-10. 3.5.0 ships first from `doing/3.5.0-store-blockers`; this work lives on
`doing/3.6.0-supporters` and ships as later versions.

## What supporters get

| Who | What they get |
|---|---|
| Individual supporter (annual) | Every observation in "Shared Observations" (today only admins page back through them), a gallery of every photo, a map of every observation, and a dashboard of observation data. A supporter badge on their profile. |
| Adopt a pika (annual, add-on or higher tier) | Names a pika at a site they pick. The name shows in the app, and a "Track Pete the Pika" map shows sightings, a heat map and a timeline for that site. |
| Organization sponsor (annual) | Their name, logo and link listed under Sponsors and Support in the left menu, ordered by tier. |

Tiers and prices are RMW's call. A starting point, modeled on common nonprofit tiers:

- Individuals: Friend ($25/yr: map, dashboard, gallery, all observations), Steward ($100/yr: adds one adopted pika), Guardian ($250/yr: adds three adopted pikas and a name in a supporters list).
- Organizations: Bronze ($500/yr: name and link), Silver ($1,500/yr: adds logo), Gold ($5,000/yr: top placement, logo, and a short message).

### Adopting a pika, honestly

Volunteers almost never tell one pika from another; observations are of sites, not marked animals. So an
adoption names the pika living at a site (a point and radius the supporter picks from existing
observations). "Track Pete the Pika" shows every observation within that radius: sightings, a heat map,
a timeline of detections, and photos and calls recorded there. The app says so in one line ("Pete lives
in this talus patch; sightings near here are likely Pete or Pete's neighbors"). Names are reviewed by an
admin before they show, since the app is used by kids.

## Store rules and payments

Findings, 2026-10-10 (sources at the end):

- Selling digital features is a digital purchase in both stores, even when the seller is a nonprofit.
  Neither store has a nonprofit exemption for that. Apple's nonprofit carve-out (3.2.1(vi)) covers plain
  donations in the app with Apple Pay, not donations that unlock features. Apple's nonprofit program
  waives the yearly developer fee, not the commission.
- United States: court rulings now let apps link to a web page to pay. Apple currently charges no
  commission on those link-outs while the court sets a fee; Apple proposed 15%, or 5% for Small Business
  Program apps, and 0% for plain web links, in August 2026. Google's US external-links program is
  open, with fees capped at 9% or 20% under the settlement and possibly starting October 1, 2026.
- Canada: no such rulings. Linking out to pay for features is not allowed there.
- Either store's own billing costs 15% under the small business programs.

**Recommendation:** donations happen on RMW's Every.org page. A supporter's account unlocks
automatically. On US devices the app shows a "Become a supporter" button that opens that page; on
other devices the app shows what supporters get and a thank-you, with no payment link, and unlocks
for supporters who donated elsewhere. Check the fee status in both stores before 3.6.0 ships, and
confirm the plan with Apple App Review through the App Review contact form.

### Why Every.org

- No platform fee. Bank (ACH), stock and donor-advised-fund gifts have no fees at all; card and PayPal
  gifts carry processor fees (about 2.2% + $0.30 for cards), and Every.org asks donors to cover them, so
  most gifts arrive whole.
- RMW already has a page: Every.org lists every US 501(c)(3). RMW only claims it and connects a bank
  account (which avoids the 1.5% fee for mailed or third-party disbursement).
- It can tell the app who donated. The donate link carries our own donation ID and metadata (the
  supporter's account and tier), and Every.org calls our webhook when the gift is made. PayPal Giving
  Fund has zero fees but no way to tie a gift to an app account and pays out in 15–45 days, so it
  can't unlock anything.
- Every.org supports one-time and monthly gifts, not yearly. An annual membership is a one-time gift
  that lasts 12 months; the app reminds supporters a few weeks before it lapses.

### RMW setup ("go set this up real quick")

1. Claim RMW's profile at every.org (search Rocky Mountain Wild, choose Claim this nonprofit).
2. In the admin settings, connect RMW's bank account directly (no disbursement fee).
3. Add a logo, a short description, and "Pika Patrol" as a fundraiser if they want a dedicated page.
4. Tell Chris the page link. Chris asks Every.org (partners@every.org) for a partner webhook token.

## How it works

### Supporter status

- A `supporters/{uid}` document: tier, expiry date, adopted pikas, source (Every.org, manual).
- Written only by a Cloud Function or an admin, never by the app user. Firestore rules: the owner can
  read their own document; nobody can write from the app.
- The Every.org webhook (a Cloud Function) checks the partner token, reads the account and tier from
  the metadata, and writes or extends the supporter document. Bank and PayPal gifts can fail after the
  first notice, so access starts at once and is pulled if a later notice says the gift failed.
- Admins can grant or extend supporter status in the app, for gifts by check, event or sponsor deals.

### Sponsors in the left menu

A `sponsors` collection (name, link, logo, tier, expiry), readable by everyone, written by admins. The
left menu lists unexpired sponsors by tier, replacing the hard-coded list. It's cached on the device
and refreshed at most once a day.

### Map

- A new bottom-bar button to the right of the new-observation button.
- Syncfusion Maps (`syncfusion_flutter_maps`) with an OpenStreetMap-based tile layer, markers for
  observations, and a heat map layer when zoomed out. Tapping a marker opens the observation.
- Syncfusion Maps has no marker clustering. If thousands of markers are slow, cluster them ourselves
  in a small shared block rather than switching map packages.
- The public OpenStreetMap tile servers don't allow app-scale use; use a free tile plan with a key
  (for example MapTiler or Stadia Maps) and show the attribution.

### Dashboard

- A second new bottom-bar button.
- Syncfusion Charts (`syncfusion_flutter_charts`): totals (observations, sites, observers), observations
  per month, species, pikas detected, signs, search duration, elevation, and projects shared with.
- Filters: date range, species, project, state or province.
- No observer names, only counts.

### Gallery

- Every observation photo in a scrolling grid, newest first, tapping opens the observation.
- Thumbnails only in the grid. The Firebase "Resize Images" extension makes small copies of new
  uploads; a one-time job makes them for existing photos. Full photos load only when opened.
- `cached_network_image` keeps thumbnails on the device, so scrolling back costs nothing.

### Caching, so supporters don't drive up the bill

The plan reads each observation once per device, then only what changed.

- Every observation is mirrored on the device (Hive), with the time of the last sync.
- Observations get an `updatedAt` server timestamp. A Cloud Function sets it on every write, so edits
  from older app versions are covered too. A one-time script backfills existing observations.
- Deletes leave a small marker in `deletedObservations`, also written by a Cloud Function.
- On open (at most every 15 minutes, and on pull-to-refresh), the app asks only for observations and
  delete markers newer than the last sync. No live listener on the whole collection.
- The map, dashboard, gallery and Shared Observations all read the same device mirror; none of them
  read Firestore directly.
- Cost: the first sync on a device reads every observation once (a few thousand reads, well under one
  cent). After that, a sync reads only new or edited observations. The heavier cost is photo downloads,
  which thumbnails and the device cache keep small.

Observations are already readable by anyone (Firestore rules `allow read: if true`), so the supporter
gate is a feature gate in the app, not a security boundary. That's fine for public data, and the rules
don't need to change for it.

## Phases

| Phase | What | Version |
|---|---|---|
| 1 | Device mirror and incremental sync, Cloud Functions for `updatedAt` and delete markers, backfill script | 3.6.0 |
| 2 | Supporter status, admin grant, supporter badge, gating | 3.6.0 |
| 3 | Map | 3.6.0 |
| 4 | Dashboard | 3.6.0 |
| 5 | Gallery and thumbnails | 3.6.0 |
| 6 | Every.org link and webhook, US-only donate button | 3.6.0 |
| 7 | Sponsors collection and organization tiers in the left menu | 3.6.0 |
| 8 | Adopt a pika, name review, Track a Pika map | 3.7.0 |

Console and deploy steps (Chris): Cloud Functions deploy, Firestore rules for `supporters`, `sponsors`
and `deletedObservations`, the Resize Images extension, a map tile key, and the Every.org webhook token.

## Open questions

1. Which unlock model (recommendation above), and does RMW agree?
2. Tier names and prices, individual and organization.
3. Should adopt a pika be its own purchase or part of a tier?
4. Who reviews adopted pika names and sponsor logos?
5. Map tile provider and who holds the key.

## Sources

- [Every.org partner webhook](https://docs.every.org/docs/webhooks/partner-webhook), [donate link](https://docs.every.org/docs/donate-link), [fees](https://every.org/3pfees), [pricing questions](https://blog.every.org/how-does-every-org-work-your-top-10-pricing-questions-answered/)
- [PayPal Giving Fund vs PayPal donations](https://pep.paypal.com/us/cshelp/article/what-is-the-difference-between-paypal-donations-and-paypal-giving-fund-donations-help222)
- [Apple 3.2.2 donation rejection thread](https://developer.apple.com/forums/thread/799549), [charitable donations thread](https://developer.apple.com/forums/thread/101502)
- [Ninth Circuit largely upholds Epic v. Apple](https://www.fenwick.com/insights/publications/ninth-circuit-largely-upholds-ruling-in-epic-v-apple), [Apple proposes a 15% link-out fee (TechCrunch, Aug 2026)](https://techcrunch.com/2026/08/14/apple-proposes-to-take-a-15-cut-of-purchases-made-outside-the-app-store/), [AppleInsider on the proposed rates](https://appleinsider.com/articles/26/08/13/apples-latest-commission-rates-for-external-app-store-purchases-havent-satisfied-epic)
- [Google Play policies for US developers](https://support.google.com/googleplay/android-developer/answer/15582165?hl=en), [Epic v. Google settlement update, April 2026](https://www.stash.gg/blog/blog-epic-v-google-settlement-update-april-2026)
