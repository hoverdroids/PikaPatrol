# Firebase Runbook

How the Pika Patrol Firebase project (`pikajoe-97c5c`) is kept secure and free of surprise bills. Written for Chris, Megan and Jo.

## Security rules

The rules live in `firebase/`, so changes can be reviewed and tracked:

- `firebase/firestore.rules`: an exact copy of the live Firestore rules (published Feb 4, 2024).
- `firebase/storage.rules`: the live Storage rules (deployed 2026-10-10). Photos and audio stay publicly readable, but uploads only go into `images/` and `audio/`, each under 50 MB. The app checks sizes first and offers to shrink photos that are too large.

Deploy from the `firebase/` folder with the Firebase CLI (`npm install -g firebase-tools`, then `firebase login`):

```zsh
cd firebase
firebase deploy --only storage           # Storage rules
firebase deploy --only firestore:rules   # Firestore rules
```

## Never get a bill

Firebase requires the Blaze plan for Cloud Storage. Blaze keeps the free quotas, but anything over them is charged. Google's spend caps (Billing → Budgets & caps) only cover Cloud Run, Cloud Run functions, the Gemini API and Vertex AI, not Firestore or Cloud Storage, which are what Pika Patrol uses.

Protection, in layers:

1. **Kill switch:** the `firebase-billing-kill-switch` repo (sibling folder), in `lock-rules` mode. When the "Pika Patrol Alerts" budget is reached, a Cloud Function publishes Firestore and Storage rules that let only admins in. The app stops reading, downloading and uploading, so the charges stop; nothing is deleted. Setup below.
2. **Budget alerts:** email at 50%, 90% and 100% of the "Pika Patrol Alerts" budget.
3. **Upload limits:** the Storage rules (50 MB, two folders), the app's size check, and photo compression (2560 px, 85% quality).
4. **Caching:** photos and recordings download once and stay on the phone (`MediaCache`), and the shared observations feed is one long-lived listener on the newest five.
5. **App Check:** once most users have 3.5.0, enforce it for Firestore and Storage, so only the real app gets in.

### Kill switch setup (Chris)

From the `firebase-billing-kill-switch` folder:

1. `cp .env.example .env.pikajoe-97c5c`, then set `ACTION=lock-rules`, `STORAGE_BUCKETS=pikajoe-97c5c.appspot.com`, `DRY_RUN=true`.
2. `npm install`, then `firebase deploy --only functions:kill-switch --project pikajoe-97c5c`.
3. Google Cloud console → Billing → Budgets & caps → Pika Patrol Alerts → Edit → Actions → Connect a Pub/Sub topic → `projects/pikajoe-97c5c/topics/billing-budget` → Save.
4. Google Cloud console → IAM & Admin → IAM → Default compute service account → Edit → add **Firebase Rules Admin**.
5. Test with a fake message (see the repo's README), check the log says `DRY_RUN: would lock-rules`, then set `DRY_RUN=false` and deploy again.

### If the kill switch trips

Everyone but admins is locked out of Firestore and Storage. Observations still save on the phone and upload later. To recover:

1. Look at Billing → Reports to see what used the money.
2. Fix the cause, for example a runaway upload loop, or raise the budget.
3. Reopen: from the `firebase/` folder, `firebase deploy --only firestore:rules,storage`. The switch won't trip again until next month.

## App Check

The app sends App Check tokens from 3.5.0 on. Register these two apps (Firebase console → App Check → Apps). Skip Pika Joe (`com.hoverdroids.pika_joe`): it's the old Android app and nothing uses it.

- **tCubed Studios Pika Patrol** (`com.tcubedstudios.pika_patrol`) → Play Integrity. Needs the **SHA-256 of the app signing key**: Play Console → Pika Patrol → Test and release → App integrity → App signing → App signing key certificate. In Play Console on that same page, link the Google Cloud project `pikajoe-97c5c` under Play Integrity API.
- **Pika Patrol (iOS)** (`com.tcubedstudios.pikaPatrol`) → App Attest, Team ID `ZNWSMB2USP`. Also register DeviceCheck for phones older than iOS 14: Apple Developer → Keys → new key with DeviceCheck → its Key ID and `.p8` file.

Leave the token time to live at its default (1 hour). Registering is free and changes nothing for users: it only starts the request charts.

**Don't enforce yet.** Enforcement is a separate **Enforce** button per service on the APIs tab (Cloud Firestore, Cloud Storage, Authentication). Leave each one Unenforced until the charts show nearly all requests verified, a few weeks after 3.5.0 ships; enforcing earlier blocks everyone still on 3.4.0. After enforcing, debug builds need a debug token added under the app's menu → Manage debug tokens.

## Console checklist (Chris)

These can only be done in the Google Cloud or Firebase consoles:

- [ ] Set up the kill switch (see Kill switch setup above).
- [ ] Check the Storage bucket region (step 4 above).
- [ ] Restrict the Android and iOS API keys to the app (Google Cloud → APIs & Services → Credentials: Android key → package `com.tcubedstudios.pika_patrol` plus SHA-1s; iOS key → bundle ID `com.tcubedstudios.pikaPatrol`).
- [ ] Register the apps in App Check now; enforce for Firestore and Storage once most users have 3.5.0 (see App Check above).
- [ ] Turn on email enumeration protection (Firebase → Authentication → Settings → User actions).
- [ ] Delete unused OAuth clients (Google Cloud → APIs & Services → Credentials).
- [ ] Turn on the Google and Apple sign-in providers, and add the debug and Play app-signing SHA-1s to the Android app (see FEATURES.md §9).

## 3.6.0: supporters, map, dashboard, gallery, sponsors

Do these before 3.6.0 goes to the stores, in this order. Nothing here costs money on the free tier.

1. **Rules and functions.** From `firebase/`: `npx -y firebase-tools@15 deploy --only firestore:rules,functions`.
   This adds the `sponsors`, `supporters` and `deletedObservations` rules and four functions:
   `stampObservationUpdatedAt`, `markObservationDeleted`, `everyOrgWebhook` and `setSupporter`.
   The kill switch is a separate codebase, so this deploy leaves it alone.
2. **Backfill change stamps (once).** From `firebase/functions/`:
   `gcloud auth application-default login`, then
   `npm run build && GOOGLE_CLOUD_PROJECT=pikajoe-97c5c node lib/scripts/backfill-updated-at.js`
   (add `--dry-run` first to see the count).
3. **Photo thumbnails.** Install the **Resize Images** extension (Firebase console → Extensions) with:
   sizes `400x400`, resized images path `thumbs`, delete original `No`, convert to `original`,
   paths to include `/images`, and **backfill existing images** on. The gallery reads
   `images/thumbs/<name>_400x400.<ext>` and shows the full photo until a thumbnail exists.
4. **Map tiles.** Make a free MapTiler account, create a key restricted to the app IDs, and set
   `MAP_TILE_URL` and `MAP_TILE_ATTRIBUTION` in `.env` (see `.env.example`). Without it the map falls
   back to OpenStreetMap's servers, which is fine for testing only.
5. **Every.org.** After Rocky Mountain Wild claims its page: set `EVERYORG_NONPROFIT` (and
   `EVERYORG_WEBHOOK_TOKEN` from partners@every.org) in `.env`; set the function's secret with
   `firebase functions:secrets:set EVERYORG_WEBHOOK_KEY` and its `EVERYORG_NONPROFIT` param; give
   Every.org the webhook URL `https://us-central1-pikajoe-97c5c.cloudfunctions.net/everyOrgWebhook?key=<the secret>`.
   Until `EVERYORG_NONPROFIT` is set the app thanks people but shows no donate link. The link only
   shows on US phones.
6. **Sponsors.** In Firestore, add documents to `sponsors` with `name`, `url`, `tier`
   (`gold`, `silver` or `bronze`), and optionally `message`, `logoUrl` and `expiresAt` (a timestamp).
   Phones pick up changes within a day.
7. **Supporters by hand.** Admins use the menu's **Supporter status** to add a year for gifts made
   by check or at events.
