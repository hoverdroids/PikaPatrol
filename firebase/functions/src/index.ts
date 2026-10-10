// Pika Patrol Cloud Functions. Deploy from the firebase folder with: npm --prefix functions run deploy
// See docs/design/2026-10-10-supporters-plan.md.
import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { logger } from "firebase-functions";
import { defineInt, defineSecret, defineString } from "firebase-functions/params";
import { onDocumentDeleted, onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall, onRequest } from "firebase-functions/v2/https";
import { DAY_MS, EveryOrgDonation, extendUntil, parseDonation, supportDays } from "./supporters";

initializeApp();
const db = getFirestore();

const OBSERVATIONS = "observations";
const DELETED_OBSERVATIONS = "deletedObservations";
const SUPPORTERS = "supporters";
const UPDATED_AT = "updatedAt";
const SUPPORTER_CLAIM = "supporter";

// The webhook URL given to Every.org ends in ?key=<this secret>, so nobody else can post gifts.
// Set it with: firebase functions:secrets:set EVERYORG_WEBHOOK_KEY
const everyOrgWebhookKey = defineSecret("EVERYORG_WEBHOOK_KEY");
// Rocky Mountain Wild's Every.org page name, for example "rocky-mountain-wild"
const everyOrgNonprofit = defineString("EVERYORG_NONPROFIT", { default: "" });
const supporterMinimumUsd = defineInt("SUPPORTER_MINIMUM_USD", { default: 25 });

//region Observation changes, so devices can sync only what changed

// Stamps when an observation last changed, for app versions that don't stamp it themselves.
// Skips writes that already changed the stamp, which also stops this function from triggering itself.
export const stampObservationUpdatedAt = onDocumentWritten(`${OBSERVATIONS}/{observationId}`, async (event) => {
  const after = event.data?.after;
  if (!after?.exists) return;
  const before = event.data?.before;
  const newStamp = after.get(UPDATED_AT) as Timestamp | undefined;
  const oldStamp = before?.exists ? (before.get(UPDATED_AT) as Timestamp | undefined) : undefined;
  if (newStamp && !(oldStamp && newStamp.isEqual(oldStamp))) return;
  await after.ref.update({ [UPDATED_AT]: FieldValue.serverTimestamp() });
});

// Leaves a small marker, so devices holding a copy of every observation can drop deleted ones
export const markObservationDeleted = onDocumentDeleted(`${OBSERVATIONS}/{observationId}`, async (event) => {
  await db.collection(DELETED_OBSERVATIONS).doc(event.params.observationId).set({ deletedAt: FieldValue.serverTimestamp() });
});
//endregion

//region Supporters

async function extendSupporter(uid: string, days: number, gift: Record<string, unknown> | null): Promise<number> {
  const user = await getAuth().getUser(uid);
  const claims = { ...(user.customClaims ?? {}) };
  const current = typeof claims[SUPPORTER_CLAIM] === "number" ? (claims[SUPPORTER_CLAIM] as number) : undefined;
  const until = days > 0 ? extendUntil(current, days, Date.now()) : Date.now();

  if (days > 0) {
    claims[SUPPORTER_CLAIM] = until;
  } else {
    delete claims[SUPPORTER_CLAIM];
  }
  await getAuth().setCustomUserClaims(uid, claims);

  const supporter = db.collection(SUPPORTERS).doc(uid);
  await supporter.set({ supporterUntil: Timestamp.fromMillis(until), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  if (gift) {
    await supporter.collection("gifts").doc(String(gift.chargeId)).set({ ...gift, receivedAt: FieldValue.serverTimestamp() });
  }
  return until;
}

// Every.org calls this when someone gives through the app's donate link. The link carries the
// giver's account in partner_metadata. Names and emails in the body are not stored.
export const everyOrgWebhook = onRequest({ secrets: [everyOrgWebhookKey] }, async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("POST only");
    return;
  }
  if (req.query.key !== everyOrgWebhookKey.value()) {
    res.status(403).send("Forbidden");
    return;
  }

  const body = (typeof req.body === "string" ? JSON.parse(req.body) : req.body) as EveryOrgDonation;
  const gift = parseDonation(body, everyOrgNonprofit.value());
  if (typeof gift === "string") {
    // Answer 200 so Every.org doesn't retry a gift that can never unlock anything
    logger.warn(`Every.org gift skipped: ${gift}`, { chargeId: body.chargeId });
    res.status(200).send("Skipped");
    return;
  }

  // Each gift counts once, even if Every.org sends it again
  const giftRef = db.collection(SUPPORTERS).doc(gift.uid).collection("gifts").doc(gift.chargeId);
  if ((await giftRef.get()).exists) {
    res.status(200).send("Already counted");
    return;
  }

  const days = supportDays(gift, supporterMinimumUsd.value());
  const record = { ...gift, source: "every.org", paymentMethod: body.paymentMethod ?? null, days };
  try {
    if (days > 0) {
      const until = await extendSupporter(gift.uid, days, record);
      logger.info("Supporter extended", { uid: gift.uid, until: new Date(until).toISOString() });
    } else {
      await giftRef.set({ ...record, receivedAt: FieldValue.serverTimestamp() });
    }
    res.status(200).send("OK");
  } catch (e) {
    logger.error("Every.org gift failed", { chargeId: gift.chargeId, error: String(e) });
    res.status(500).send("Error");
  }
});

// Admins grant, extend or end supporter status by email, for gifts made by check, at events,
// or as part of a sponsorship. days = 0 ends it now.
export const setSupporter = onCall(async (request) => {
  if (request.auth?.token.admin !== true) {
    throw new HttpsError("permission-denied", "Admins only");
  }
  const email = String(request.data?.email ?? "").trim();
  const days = Number(request.data?.days ?? 365);
  if (!email || !Number.isInteger(days) || days < 0 || days > 3650) {
    throw new HttpsError("invalid-argument", "An email and a number of days from 0 to 3650");
  }

  let uid: string;
  try {
    uid = (await getAuth().getUserByEmail(email)).uid;
  } catch {
    throw new HttpsError("not-found", "No account with that email");
  }

  const gift = days > 0 ? { chargeId: `admin-${Date.now()}`, source: "admin", grantedBy: request.auth.uid, days } : null;
  const until = await extendSupporter(uid, days, gift);
  return { supporterUntil: days > 0 ? until : null, days: Math.round((until - Date.now()) / DAY_MS) };
});
//endregion
