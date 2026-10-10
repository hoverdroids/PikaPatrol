// Pure supporter rules, kept apart from Firebase so they can be tested without it.
// See docs/design/2026-10-10-supporters-plan.md.

export const DAY_MS = 24 * 60 * 60 * 1000;

// The body Every.org posts to the partner webhook (docs.every.org/docs/webhooks/partner-webhook)
export interface EveryOrgDonation {
  chargeId?: string;
  partnerDonationId?: string;
  partnerMetadata?: { uid?: unknown } | null;
  toNonprofit?: { slug?: string; ein?: string; name?: string };
  amount?: string;
  netAmount?: string;
  currency?: string;
  frequency?: string;
  donationDate?: string;
  paymentMethod?: string;
}

export interface Gift {
  chargeId: string;
  uid: string;
  amount: number;
  currency: string;
  frequency: "Yearly" | "Monthly" | "One-time";
  donationDate: number;
}

// The gift in a webhook body, or why it can't unlock anything
export function parseDonation(body: EveryOrgDonation, nonprofitSlug: string): Gift | string {
  if (!body.chargeId) return "no chargeId";
  const slug = body.toNonprofit?.slug ?? "";
  if (nonprofitSlug && slug !== nonprofitSlug) return `gift to another nonprofit: ${slug}`;
  const uid = body.partnerMetadata?.uid;
  if (typeof uid !== "string" || uid.length === 0) return "no app account in partnerMetadata";
  const amount = Number(body.amount);
  if (!Number.isFinite(amount) || amount <= 0) return `bad amount: ${body.amount}`;
  const frequency = body.frequency === "Yearly" || body.frequency === "Monthly" ? body.frequency : "One-time";
  const date = Date.parse(body.donationDate ?? "");
  return {
    chargeId: body.chargeId,
    uid,
    amount,
    currency: (body.currency ?? "USD").toUpperCase(),
    frequency,
    donationDate: Number.isFinite(date) ? date : Date.now(),
  };
}

// How long a gift makes someone a supporter. A yearly or one-time gift counts for a year; a
// monthly gift for a month and a week, so a late charge doesn't lock anyone out.
// Gifts under the minimum (yearly, in US dollars) are thanked but unlock nothing.
export function supportDays(gift: Gift, minimumYearlyUsd: number): number {
  const yearly = gift.frequency === "Monthly" ? gift.amount * 12 : gift.amount;
  if (gift.currency === "USD" && yearly < minimumYearlyUsd) return 0;
  return gift.frequency === "Monthly" ? 38 : 365;
}

// A new gift adds to whatever time is left, so renewing early loses nothing
export function extendUntil(currentUntil: number | undefined, days: number, now: number): number {
  const start = Math.max(currentUntil ?? 0, now);
  return start + days * DAY_MS;
}
