# Firebase Runbook

How the Pika Patrol Firebase project (`pikajoe-97c5c`) is kept secure and free of surprise bills. Written for Chris, Megan and Jo.

## Security rules

The rules live in `firebase/`, so changes can be reviewed and tracked:

- `firebase/firestore.rules`: an exact copy of the live Firestore rules (published Feb 4, 2024).
- `firebase/storage.rules`: **proposed** Storage rules, not deployed yet. They keep photos and audio publicly readable, but only allow uploads into `images/` and `audio/`, each under 15 MB. Today any signed-in user can write any file of any size anywhere.

Deploy from the `firebase/` folder with the Firebase CLI (`npm install -g firebase-tools`, then `firebase login`):

```zsh
cd firebase
firebase deploy --only storage           # proposed Storage rules
firebase deploy --only firestore:rules   # Firestore rules (unchanged copy)
```

## Never get a bill

Firebase now requires the Blaze plan for Cloud Storage. Blaze keeps the free quotas, but anything over them is charged. On 2026-10-09 Storage held 6.45 GB, which is over the 5 GB free tier, so a few cents a month are already accruing.

Protection, in layers:

1. **Kill switch:** the `firebase-billing-kill-switch` repo (sibling folder). A $1 monthly budget publishes to Pub/Sub, and a Cloud Function turns off billing when the budget is reached. Setup steps are in its README. Once it's pushed to GitHub, add it to this repo as a git submodule.
2. **Budget alerts:** part of the same setup: email at 50%, 90% and 100% of $1.
3. **Upload limits:** the proposed Storage rules (15 MB, two folders) plus in-app photo compression (2560 px, 85% quality).
4. **Free-tier region:** check that the bucket `pikajoe-97c5c.appspot.com` is in `us-central1`, `us-east1` or `us-west1` (Firebase console → Storage). Free Storage quota applies only there.
5. **Request caps (optional):** in Google Cloud console → IAM & Admin → Quotas, set daily limits on the Cloud Firestore API and Cloud Storage just above normal use.

### If the kill switch trips

Paid features stop: photo and audio uploads fail, and Sheets syncing may stop. Observations still save on the phone and upload later. To recover:

1. Look at Billing → Reports to see what used the money.
2. Fix the cause, for example a runaway upload loop.
3. Re-link the billing account: Google Cloud console → Billing → Account management → My projects → the project → Change billing.

## Console checklist (Chris)

These can only be done in the Google Cloud or Firebase consoles:

- [ ] Set up the kill switch and budget (see the kill switch README).
- [ ] Check the Storage bucket region (step 4 above).
- [ ] Restrict the Android and iOS API keys to the app (Google Cloud → APIs & Services → Credentials: Android key → package `com.tcubedstudios.pika_patrol` plus SHA-1s; iOS key → bundle ID `com.tcubedstudios.pikaPatrol`).
- [ ] Turn on Firebase App Check for Firestore and Storage (Play Integrity on Android, App Attest on iOS). Turning it on also needs an app update, so it's listed separately in FEATURES.md.
- [ ] Turn on email enumeration protection (Firebase → Authentication → Settings → User actions).
- [ ] Delete unused OAuth clients (Google Cloud → APIs & Services → Credentials).
- [ ] Turn on the Google and Apple sign-in providers, and add the debug and Play app-signing SHA-1s to the Android app (see FEATURES.md §9).
