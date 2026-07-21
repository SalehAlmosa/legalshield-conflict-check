# Recommendation: Automated Conflict-of-Interest Check at Intake

**To:** Intake Operations & Supervising Attorneys
**From:** Saleh Almosa
**Re:** Cutting member wait time and closing the conflict-check accuracy gap

## The situation

Today, every new member matter waits on a manual conflict-of-interest check before it can proceed. Analysis of 2,000 simulated intakes shows this costs the firm on two fronts at once:

- **Speed:** conflict checks average 14.8 hours to complete, and 15% take more than a full day. That is time the member spends waiting before anyone can help them.
- **Accuracy:** manual review catches only 51% of true conflicts. The misses aren't carelessness — they're name variations a human scanning a list won't reconcile: "Bob" vs "Robert," "ABC Corp" vs "ABC Corporation," different casing and punctuation. Every missed conflict is a compliance and malpractice exposure.

## The recommendation

Run an automated, normalized-name conflict check the moment intake data is entered. Normalization lowercases names, strips punctuation and company suffixes, and canonicalizes common nicknames before matching against the existing-client list. In testing this catches 99% of true conflicts instantly.

Route each intake into one of three tiers:

1. **No match → clear immediately.** 83% of members get an instant answer instead of waiting ~15 hours. This is the single biggest client-experience win.
2. **Match with a confirming secondary identifier (DOB or matter) → flag as a likely conflict** for attorney review.
3. **Match but mismatched secondary identifier → likely namesake**, queued as low priority.

## Why the secondary identifier matters

Name matching alone over-flags: about 5% of intakes share a normalized name with an unrelated person. Confirming against a second field keeps the firm from wrongly telling a member "we can't help you" — and keeps reviewer attention on real conflicts.

## Impact

- Member wait for clearance: ~15 hours → instant for 83% of intakes.
- Conflict catch rate: 51% → 99% (compliance risk sharply reduced).
- Staff conflict-check workload: 100% of intakes → the 17% that genuinely need human judgment.

## Next steps

Pilot the normalized check as a read-only advisory alongside the current process for 30 days, measure catch rate and reviewer agreement, then move it into the intake workflow as the system of record with attorney sign-off on flagged matters.
