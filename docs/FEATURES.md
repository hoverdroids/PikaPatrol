# Pika Patrol Feature List

Every request made for Pika Patrol, collected from the project email history (2022 to October 2026) and the GitHub issues. We work from this list to finish the app and publish it to Google Play and the App Store.

## How to use this list

- `[x]` means done and confirmed in the code, or shipped in a store release.
- `[ ]` means not done, or only partly done. A note says what is missing.
- Each item names who asked, when, and the email thread or GitHub issue it came from.
- **Owner** marks items that are not code work: Rocky Mountain Wild (Megan), Jo, UBC (Mike, Leigh Anne), or Chris.
- Status was checked on 2026-10-09 against branch `done/doing/alluser-observations-in-one-place-4-manual-redo` (version 3.4.0+334). Much of the recent work is on this branch only and is not yet merged into `main`.

## People

- **Jo** — Johanna Varner, Colorado Mesa University. Lead scientist.
- **Megan** — Megan Mueller, Rocky Mountain Wild (RMW). Owns the store accounts and the contracts.
- **Mike** — Michael Russello, UBC Okanagan. Funds the Canadian work.
- **Leigh Anne** — Leigh Anne Isaac, BC government. Canadian co-lead and tester.
- **Denver Zoo** — Stefan, Julie and Alex. Co-owner of the app with RMW.
- **Turi** — French translation reviewer.
- **Volunteers** — bug reports come from the CPP and Cascades Pika Watch volunteers through the "report a bug" Google form.

---

## 1. Release blockers (must fix before the next store release)

- [ ] **Security: stop shipping the Google service-account private key to every app user.** The Firestore `googleSheets` collection holds a full service-account key (`pika-patrol@pikajoe-97c5c.iam.gserviceaccount.com`), and the rules let *any signed-in user* read it. Anyone can register, so anyone can take the key. Fix: move the Sheets sync to a server-side Cloud Function triggered by Firestore writes (this also closes GitHub #68), make `googleSheets` admin-only or delete it, then delete that key in Google Cloud and check the service account's roles. Found 2026-10-09 while checking the Firebase console.
- [x] **Target Android 15 (API 35).** Now targets API 36, which Play requires from Aug 31 2026 (branch `doing/3.5.0-store-blockers`). Google Play blocks every update until this is done. The repo is on 34 because a July 2026 commit lowered it. Megan, Jun 2026, "FW: Update on Pika Patrol APP"; GitHub #73.
- [x] **Support 16 KB memory page sizes.** All native libraries checked at 16 KB alignment after the toolchain upgrade. Play Console shows this as an error on the 3.3.8 build. The toolchain needs upgrading: Flutter 3.19.6, AGP 7.4.2, Kotlin 1.7.10. Megan, Aug 6 2026, "Please accept Apple policy updates".
- [ ] **Find out why 3.3.8 drops 915 previously supported devices.** Megan asked to hold the release until this is checked. Same thread, Aug 6 2026.
- [x] **Upgrade reCAPTCHA to 18.4.0 or newer.** Resolves to 18.6.1. Version 18.1.2 has a critical security bug and is deprecated. The repo is on firebase_auth 4.12.0, which likely pulls 18.1.x, so upgrade the Firebase packages. Google Play Console, Apr 2024 and Apr/Jun 2026.
- [ ] **Remove READ_MEDIA_IMAGES / READ_MEDIA_VIDEO from every track and use the Android Photo Picker.** Code done: the Photo Picker is on and the merged manifest has neither permission. Still to do: replace the old builds on the Play testing tracks. Google rejected the app over this in Jun 2026. Removing them makes the app available in Canada again. The manifest no longer has them, but `useAndroidPhotoPicker` is not turned on, and old builds on the testing tracks still need replacing. Megan, Jan 2025 and Jun 2026, "Action Required: Your app is not compliant…".
- [x] **Add an iOS privacy manifest.** Added `ios/Runner/PrivacyInfo.xcprivacy`. `PrivacyInfo.xcprivacy` is missing. It needs `NSPrivacyAccessedAPITypes` for FileTimestamp and UserDefaults, and Apple has required it since May 2024 (ITMS-91053). App Store Connect, Mar 2024.
- [ ] **Merge the release branch into `main`** once it has been tested, and update the README version (it still says 3.3.9 / 333).
- [ ] **Publish to Google Play and the App Store** with release notes. **Owner:** Megan (Play), Jo or Chris (Apple).

## 2. Offline and cached observations, and sync

- [ ] **Cached observations keep asking to upload after they have already uploaded.** Reported on iOS and Android by Jo, Julie, Megan and several volunteers. The 2026 commits fix several causes, but volunteers still reported it in Jul and Oct 2026 (possibly on old builds). Confirm the fix on the newest build. GitHub #64; "Pika patrol issues/questions" (May 2024); "FW: Pika patrol bug feedback - still not seeing a fix…" (Oct 2026).
- [ ] **Editing cached observations offline must save.** A volunteer records in airplane mode and proofreads at home before uploading. Edits made offline are lost, so typos get uploaded. Edits must stick, and uploading should send everything at once. Volunteer report, Aug 2025, "Where are we with app updates?"; Oct 2026 follow-up.
- [ ] **Make edits to an already-uploaded observation reach the server, and show which version is on the server.** Volunteer, Oct 2024, "FW: Pika Patrol app problems and questions".
- [ ] **Show a clear status on each card: uploaded, waiting to upload, or failed.** A volunteer could not tell what the cloud icon meant. Oct 2024 (same thread); Chris, Aug 2025.
- [x] Users see all of their own observations on every device, including after a reinstall. Chris, Sep 2024; done 2026-07-28.
- [x] With two accounts on one phone, only the logged-in account's observations show, and the other account's local observations are never deleted. Chris, Sep 2024, "Fwd: Correction on recent bug report…".
- [x] Logged-out observations are no longer deleted, and offline duplicates are fixed (3.3.4 to 3.3.9, Jul 2026).
- [x] Deletions sync across devices (3.3.2).
- [x] "Cached Observations" renamed to "My observations", with an info button. Jo and Megan, Oct 2023; renamed again Jul 2026.
- [x] Users can delete their own observations; admins can edit or delete any (3.0.0).
- [ ] **Old data model:** observations saved before 3.0 have no "uploaded" flag. Confirm the migration covers them. Chris, Jul 2024.
- [ ] **Check that broken image links are fixed for older observations.** Images broke when Firebase gave a re-uploaded image a new access token, and saved local copies kept the broken URL. Chris, Jun–Sep 2024.

## 3. Observation form

- [x] Species limited to American pika (first and default) and Collared pika. Other Asian species stay hidden. Jo and Megan, Jan and Feb 2024, "More Pika species!" and "iOS build submitted".
- [ ] **Remove the leftover TODO about American pika showing twice** (observation_screen.dart:1550), after checking it no longer happens.
- [x] "Other" option for other animals, with free text. Jo, Sep 2023.
- [ ] **Latitude and longitude at 5 decimal places everywhere.** Editing and the map header show 5, but the read-only view shows 3, and typed input is not limited. Jo, Aug 2022 and Jun 2024, "List of projects to include in the app"; GitHub #50 and #58.
- [x] Altitude in feet, plus an imperial/metric preference. Jo, Sep 2023; Leigh Anne, Aug 2026. Done in 3.4.0.
- [ ] **Show Celsius next to Fahrenheit for temperature** (for example "45°F (7°C)"), or have the units setting cover temperature. Leigh Anne, Aug 2026.
- [ ] **Units in Google Sheets stay imperial.** The display setting must not change stored data. Jo, Aug 2026. Check this holds.
- [x] Altitude no longer shows 0 offline on Android 13. Jo, Sep 2023 (2.0.0 rework). Retest.
- [x] Date can be changed with the calendar button. GitHub #23.
- [x] Default observation template, with default species and default projects. Chris, Aug 2026; agreed by Jo, Mike, Megan and Leigh Anne. Done in 3.4.0.
- [ ] **Add a search duration option for incidental sightings that were not a standard search.** Leigh Anne, Aug 2026. Jo deferred to Megan, since the field comes from CPP. **Decision:** Megan.
- [x] Talus area hints in sports-field sizes ("Show hints").
- [ ] **Make the selected state of choice chips visible in sunlight, and not by color alone.** Chips now swap color (teal with white text versus grey). The request was a dark background with light text, **and** a thicker or darker border or a check icon, so that color is not the only cue. Test this outdoors. Volunteer via Jo, Aug 2025; GitHub #72 (still open).
- [ ] **Show a "Thank you for submitting your observation" message** after upload. Today there is only a "saved successfully" toast. GitHub #71 (low priority, needs funding).
- [ ] **Minor form changes from the Canadian partner meetings** (to be decided). Jo, Oct 2025, "Canadian pika project updates to Pika Patrol app". **Owner:** Jo and Mike, to send the list.

## 4. Projects and data sharing (Google Sheets)

- [x] Projects list: Colorado Pika Project, Cascades Pika Watch, PikaNET, Glacier NP, Mt. Rainier NP, Cascades Forest Conservancy, Montana Pika Project, Nevada Pika Atlas, Canadian Pika Project, Utah Pika Watch. Jo, Apr–Jun 2024, Nov 2024 and Jul 2026.
- [x] Denver Zoo, RMW and IF/THEN removed from the projects list. Jo, Feb 2024.
- [x] New observations start with no projects selected. Jo, Jul 2024 (3.0.3).
- [ ] **Hidden "Pika Patrol" project always on, so every observation reaches the master sheet.** Today it is added only while syncing to Sheets, and it is skipped when the project list is empty (observations_service.dart:527). It also changes the observation's own list. Jo, Feb and Jul 2024.
- [x] Each project gets its own sheet, updated on add, edit and delete, and an observation is removed from a project's sheet when that project is unticked (3.0.0).
- [ ] **Remove observer names and emails from the sheets shared with partners.** Today the User Profiles tab is written to every project's sheet. Megan wants partner sheets to have no personal data. Chris proposed one master sheet that feeds the others. Megan, Feb 2026, "a couple of questions about app data use agreement".
- [ ] **Add a sheet (or filter) of all Collared pika observations** for provincial governments and land managers. Yukon partner via Jo, Oct 2025. Chris: a filtered sheet or a simple API, depending on how they read data.
- [ ] **Send observations made in Canada to the Canadian Pika Project automatically**, even if the observer picks another project or none. Megan says the privacy policy likely allows it. Leigh Anne and Jo, Aug 2026. **Decision:** confirm the approach, then build it.
- [ ] **Firebase-to-Sheets gaps.** If Sheets is down, the sheet never gets the update. Options: (a) the user re-saves, (b) a manual fix, (c) admin full sync (expensive), or (d) check unsynced items when the app opens. Jo and Megan need to choose. GitHub #68 (Should Discuss).
- [x] Admin-only "export all" and "initialize sheets" (3.0.0).
- [ ] **Backfill older Canadian observations into the Canadian sheet** if Mike or Leigh Anne want them. Chris, Jul 2026.
- [ ] **Remove stale rows from the master sheet.** Rows for observations already deleted from Firebase remain. For example, four 2024 test observations under spragucm@gmail.com are in the sheet but not in Firestore (checked 2026-10-09).
- [ ] **Clean up the partner sheets** made before the default changed to "none". Each one received every observation. Also decide whether the IF/THEN, Denver Zoo and RMW sheets should still exist. **Owner:** Jo and Megan. Chris, Jul 2024.

## 5. Indigenous content (UBC grant)

- [x] Look up Native Land Digital territories and languages from the GPS location. Jo, Mike and Lizzy, Feb–Apr 2026, "Indigenous content in app".
- [x] Look up territories for manually typed coordinates too. Mike, Jul 2026.
- [x] Clickable territory links, and an in-app Native Land map (an extra, beyond the request).
- [x] The map's auto-open can be turned off on the map screen itself, as well as in User Settings. Mike found the auto-open distracting. Jul 2026.
- [ ] **Use the agreed wording, "Traditional territory of the XX, YY, ZZ people".** The app now shows "Indigenous Territories" and "Indigenous Languages" headings. Jo, Apr 30 2026, "Pika Patrol Indigenous Content".
- [ ] **Show the Native Land Digital source with a link to how they map territories.** Leigh Anne asked for the reference, and Jo thought it was shown, but the code has no attribution. Aug 2026.
- [ ] **Year 2 extra: Indigenous names for American and Collared pikas**, if funding and content come in. Mike, Jan 2025; Jo, Apr 2026.

## 6. Languages

- [x] Spanish across the whole app, with a language switcher (3.0.0). Megan and Jo, 2022–2024.
- [ ] **Have a professional check the Spanish** and fix it based on user feedback. The first pass was Google Translate plus Annika's sheet. Review was planned through QHM or Patagonia Catchfire. Jo and Megan, Jan 2024; IF/THEN report, Sep 2024.
- [x] French translation (3.3.8/3.4.0), with proofreader fixes. Mike, Dec 2024 to Jul 2026.
- [ ] **Apply Turi's French suggestions** (Jul 30 2026, "French Translation Suggestions.docx"), if the 2026-07-30 proofreader commit did not already cover them.
- [ ] **Translate new text into French and Spanish**, for example the "Traditional territory" wording and the call pro-tip. Jo offered to do these. Oct 2025.
- [ ] **Make it easier to add new languages**, using one translation sheet with a column per language. Chris, Dec 2024.

## 7. Training materials

- [x] Collared pika page, with an image and text that tells it apart from the American pika. Jo, Nov 2023.
- [ ] **Add the Collared pika call audio to its page.** Jo sent a call recording, but species pages have no audio. Jo, Nov 2023.
- [ ] **Credit the Collared pika photo to Katie Christie (optional).** Jo, Nov 2023.
- [ ] **Add the "Hear them roar" pro-tip:** "Pikas often respond to recorded calls, so if you don't see any, try playing this call with your speaker sound up!" Add it in English, Spanish (Annika's version) and French. Jo, Jan 2024; Megan approved.
- [ ] **Add a link to the on-demand trip leader training in the main menu.** IF/THEN report, Sep 2024.

## 8. Menu, branding and links

- [x] App Help and Info link. GitHub #39.
- [x] Map of Pika Observations link (https://pikapartners.org/pikapatrolmap/).
- [x] Take Climate Action link (formerly "Carbon"). GitHub #13.
- [x] Sponsors and Support: Colorado Pika Project, RMW, Denver Zoo, IF/THEN, Canadian Pika Project (https://blogs.ubc.ca/russellolab/canadian-pika-project/).
- [ ] **Change the IF/THEN link to https.** The app uses `http://www.ifthenshecan.org/`; Jo asked for `https://www.ifthenshecan.org`. Mar 2022.
- [ ] **Replace the "Front Range Pika Project" splash with the Colorado Pika Project name and logo.** The project was renamed in 2022, but the splash still shows the old name. Megan, Feb 2022.
- [x] IF/THEN logo (orange on white) on the splash. Jo, Mar 2022.
- [x] Splash screen can be turned off in User Settings (2026).
- [x] App version shown in the menu (3.2.1).
- [ ] **Remove the leftover `developer.log('Play Video')` stub,** or link the Kristi Odom tutorial video (https://vimeo.com/1011836237) from App Help if wanted. Sep 2024.
- [ ] **Possible future: Oregon Zoo on the splash.** Jo, May 2024 (only if they join).

## 9. Accounts and login

- [x] Forgot password, through a Firebase email. Jo, Feb 2023 (2.0.0).
- [x] Change email and password in the profile (3.0.0).
- [x] Profile no longer asks for the password again right after registering (3.0.2).
- [x] Required profile fields are enforced after login (2.0.0).
- [ ] **Account deletion must remove the login as well as the profile.** Today the profile is deleted first. If Firebase needs a recent sign-in, the login stays, so the user can still sign in but can't edit a profile. Reported by a volunteer, Sep 2024. Apple 5.1.1(v).
- [ ] **Sign in with Google and with Apple.** Chris listed both in Sep 2024, and Jo listed them in the UBC "misc" items. `google_sign_in` is in pubspec but unused. If Google sign-in ships, Apple sign-in is required on iOS. **Decision:** build both or remove the unused package.
- [ ] **Turn on email enumeration protection in Firebase Auth.** Firebase notice, Feb 2024 (no reply in the thread).

## 10. Photos and media

- [ ] **Save photos taken in the app to the phone's camera roll.** A volunteer lost photos because of this. Jul 2026, "FW: New ideas about Pika Patrol app bug on iPhone…".
- [ ] **Cache images** (for example cached_network_image) so cards don't stay blank while loading. Chris, Jun 2024.
- [ ] **Resize or compress photos before upload.** Large phone photos are slow, and Firebase Storage was at 89 percent of the free limit. Chris and Megan, Jun 2024 and Jun 2025.
- [ ] **Recheck GitHub #31** ("Audio recording won't save") **and #30** ("Can't take a picture after choosing to upload a photo"). Both are still open, marked "can't repro", and the file picker and audio were reworked in Jul 2026. Close or fix them.
- [x] Camera crash and image cropper fixed. GitHub #1.
- [x] Unused media permissions removed (Jul 2026).

## 11. Apple App Store compliance

- [x] Purpose strings for camera, photos, microphone and location, with examples (Apple 5.1.1). GitHub #49 and #51.
- [x] Background audio mode removed (Apple 2.5.4, Oct 2023).
- [x] Camera and microphone buttons work on iOS 17 (Apple 2.1, Oct 2023).
- [ ] **Privacy manifest** (see section 1).
- [x] **Check whether the `NSLocationAlways*` strings and the `remote-notification` background mode are needed.** Not needed; removed. The app uses no push notifications, which is also why every upload warns about ITMS-90078. Remove them if unused.
- [ ] **Keep iPad support** with real iPad screenshots (Apple 2.3.3). **Owner:** Jo.
- [ ] **No Android mentions in the App Store "What's New" text** (Apple 2.3.10). **Owner:** Jo and Megan.

## 12. Google Play compliance

- [ ] Target API 35, 16 KB pages, Photo Picker and reCAPTCHA (see section 1).
- [x] Prominent location disclosure before the location permission. GitHub #15 and #41.
- [x] Android App Bundle (.aab) is built.
- [ ] **Upload the deobfuscation mapping file and native debug symbols with each release** to clear the Play warnings. Optional.
- [ ] **Make the app available in Canada.** Megan added Canada under Countries/regions in Jun 2026, but the update is stuck behind the permission rejection. Send BC partners the APK download link until it's fixed. **Owner:** Megan and Chris. Aug 2026.
- [ ] **Keep the Data safety form accurate:** location, photos, audio, user content, account info, encrypted in transit, and account deletion link. **Owner:** Megan. Updated Apr 2024.
- [ ] **Developer account verification** (D-U-N-S), if still pending. **Owner:** Megan. Dec 2023 to Jun 2024.

## 13. Firebase, security and billing

- [ ] **Keep Firestore and Storage security rules in the repo.** There are no `firestore.rules`, `storage.rules` or `firebase.json` files, so the rules can't be reviewed or versioned. Chris said they were fixed in Dec 2024. IF/THEN report, Sep 2024.
- [ ] **Review Storage rules.** Unauthenticated read was turned on in Sep 2024 to work around broken image tokens. Decide whether that is acceptable, or switch to unique file names and authenticated reads.
- [ ] **Restrict Google API keys** (Android and iOS app restrictions). Google flagged a "Publicly accessible API key" in Feb 2025. Native Land key moved to `.env` in Jul 2026.
- [ ] **Blaze plan safeguards:** a $1 budget alert, a check that the Storage bucket is in a free-tier region, and an optional automatic cap. Megan added RMW's card on Aug 6 2026, and RMW can't afford surprise bills. Chris, Jul–Aug 2026.
- [ ] **Decide a storage strategy** (image size limits and compression, retention). Chris, Jun 2025. As of 2026-10-09 Storage holds 6.45 GB, which is over the 5 GB free tier, so the project is already paying a little for storage on the Blaze plan.
- [ ] **Clean up unused OAuth clients.** Google notices, Jun 2025 and Aug 2026.
- [ ] **Look into Google for Nonprofits / Cloud credits.** **Owner:** Megan. Aug 2023 and Oct 2024.

## 14. Store, legal and admin tasks (not code)

- [ ] **Data use agreement for partners**, covering credit wording ("built by tCubed Studios…", or "built and updated by"), personal data and imperial units. **Owner:** Megan and Jo. Feb and Aug 2026.
- [ ] **Privacy policy update** now with pro-bono attorneys. Add sharing with universities and any iNaturalist sharing if it goes ahead. **Owner:** Megan. Aug 2026.
- [ ] **Accept Apple agreements when they appear.** Chris is now an Apple admin (Aug 2026). **Owner:** Megan.
- [ ] **Close out the UBC contract** after Mike signs off on the pushed fixes. **Owner:** Megan, Jo and Mike. Aug 2026.
- [ ] **Keep TestFlight testers current** (Mike and Leigh Anne added Jul 2026). **Owner:** Jo and Chris.
- [ ] **Give Chris developer credit, and link the GitHub source,** on the CPP app page and in the store listings. Megan, Sep 2022 (never answered).

## 15. Decisions needed

- [x] **Sheets sync gaps:** option (d), re-sync unconfirmed observations on app open. Chris, 2026-10-09. GitHub #68.
- [x] **Auto-share Canadian observations:** no; Canadian users use the default observation template. Chris, 2026-10-09.
- [x] **Incidental search duration option:** yes, labeled "Incidental". Chris, 2026-10-09.
- [x] **Google and Apple sign-in:** build both in 3.5.0. Chris, 2026-10-09.
- [ ] **Default card image:** keep the pika placeholder or switch to a plain one. Chris and Jo, Jun 2024.

## 16. Future ideas (out of current scope)

- [ ] Share observations to iNaturalist, either automatically or by batch CSV. Needs a privacy policy update. Mike, Aug 2026.
- [ ] Thank-you message after submitting. GitHub #71.
- [ ] More pika species (the Asian species are coded but hidden). Kept to North American species for now. Jo and Megan, Jan 2024.
- [ ] Two-way sync, where edits in Sheets flow back to Firebase. Chris, Feb 2024.

## 17. Done earlier (history)

These shipped in versions 1.x to 3.0 and are kept here for the record.

- [x] Drawer menu freeze in release builds fixed (1.1.0). GitHub #3.
- [x] Colorado Pika Project name and logo in the menu (1.1.1). GitHub #7 and #8.
- [x] Version code goes up with every release. GitHub #47.
- [x] In-app account deletion (1.4.0). GitHub #48.
- [x] Clearer save and upload flow for offline observations (1.5.0). GitHub #32 and #46.
- [x] Firebase observations paginated. GitHub #4.
- [x] Target API 30, then 33 (2.0.0). GitHub #6 and #52.
- [x] Android 13 fixes. GitHub #56.
- [x] More obvious submit button. GitHub #57.
- [x] Password reset. GitHub #55.
- [x] Release APK no longer flagged as malware on Google Drive. GitHub #14.
- [x] Native Land Digital key moved to `.env`, with setup docs (Jul 2026).
- [x] Cross-device sync and Firestore listener fix (3.3.0).
