// One-time: gives every observation without an updatedAt stamp one, so phones that keep a copy of
// every observation can sync only what changed. Safe to run more than once; stamped ones are
// skipped. Each stamped observation is one Firestore write (the free tier allows 20,000 a day).
//
// Run from the firebase/functions folder, signed in as a project Owner:
//   gcloud auth application-default login
//   npm run build && GOOGLE_CLOUD_PROJECT=pikajoe-97c5c node lib/scripts/backfill-updated-at.js
// Add --dry-run to only count them.
import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";

const dryRun = process.argv.includes("--dry-run");

async function main() {
  initializeApp();
  const db = getFirestore();
  const snapshot = await db.collection("observations").select("updatedAt").get();
  const missing = snapshot.docs.filter((doc) => doc.get("updatedAt") == null);
  console.log(`${snapshot.size} observations, ${missing.length} without updatedAt`);
  if (dryRun || missing.length === 0) return;

  const writer = db.bulkWriter();
  for (const doc of missing) {
    writer.update(doc.ref, { updatedAt: FieldValue.serverTimestamp() });
  }
  await writer.close();
  console.log(`Stamped ${missing.length}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
