import { test } from "node:test";
import assert from "node:assert/strict";
import { DAY_MS, extendUntil, parseDonation, supportDays, Gift } from "./supporters";

const body = {
  chargeId: "ch_1",
  partnerMetadata: { uid: "user1" },
  toNonprofit: { slug: "rocky-mountain-wild" },
  amount: "25.00",
  currency: "USD",
  frequency: "Yearly",
  donationDate: "2026-10-10T12:00:00.000Z",
};

test("parses a gift to our nonprofit", () => {
  const gift = parseDonation(body, "rocky-mountain-wild") as Gift;
  assert.equal(gift.uid, "user1");
  assert.equal(gift.amount, 25);
  assert.equal(gift.frequency, "Yearly");
  assert.equal(gift.donationDate, Date.parse("2026-10-10T12:00:00.000Z"));
});

test("rejects gifts that can't be tied to an account or are for someone else", () => {
  assert.equal(typeof parseDonation({ ...body, partnerMetadata: undefined }, "rocky-mountain-wild"), "string");
  assert.equal(typeof parseDonation({ ...body, toNonprofit: { slug: "other" } }, "rocky-mountain-wild"), "string");
  assert.equal(typeof parseDonation({ ...body, chargeId: undefined }, "rocky-mountain-wild"), "string");
  assert.equal(typeof parseDonation({ ...body, amount: "abc" }, "rocky-mountain-wild"), "string");
});

test("treats unknown frequencies as one-time", () => {
  const gift = parseDonation({ ...body, frequency: "Once" }, "") as Gift;
  assert.equal(gift.frequency, "One-time");
});

test("a year for yearly and one-time gifts, a month and a week for monthly", () => {
  const gift = parseDonation(body, "") as Gift;
  assert.equal(supportDays(gift, 25), 365);
  assert.equal(supportDays({ ...gift, frequency: "One-time" }, 25), 365);
  assert.equal(supportDays({ ...gift, frequency: "Monthly", amount: 5 }, 25), 38);
});

test("gifts under the minimum unlock nothing", () => {
  const gift = parseDonation(body, "") as Gift;
  assert.equal(supportDays({ ...gift, amount: 10 }, 25), 0);
  assert.equal(supportDays({ ...gift, frequency: "Monthly", amount: 2 }, 25), 0);
});

test("extends from the current end, or from now if it has passed", () => {
  const now = 1_000 * DAY_MS;
  assert.equal(extendUntil(undefined, 365, now), now + 365 * DAY_MS);
  assert.equal(extendUntil(now - DAY_MS, 365, now), now + 365 * DAY_MS);
  assert.equal(extendUntil(now + 10 * DAY_MS, 365, now), now + 375 * DAY_MS);
});
