# Improving the Client Experience: Automated Conflict-of-Interest Check at Intake

A self-directed analytics case study (Google Data Analytics Case Study 3) grounded in real experience doing member intake at a LegalShield provider law firm — where every new matter required a **manual** conflict-of-interest check against existing clients before the case could move forward.

**Business task:** Members calling in for legal help had to wait while staff manually checked whether the opposing party conflicted with an existing client. This project quantifies the cost of that manual process and designs a data-driven fix that improves the client experience.

## Ask

**Problem:** Manual conflict checks are slow and error-prone. A member's matter can't proceed until the check clears, and name variations make eyeball matching unreliable.

**Metrics:** conflict-check turnaround time, share of intakes delayed, conflict catch rate (accuracy), and share of members who could be cleared instantly.

**Stakeholders:** intake team, supervising attorneys (compliance/malpractice risk owners), and members (the client experience).

## Prepare & Process

Simulated, reproducible data generated in BigQuery (no real client data — PII-safe):

- `known_parties` (800): existing clients and prior opposing parties, with a normalized name.
- `intakes` (2,000): incoming matters with the opposing-party name as typed at intake, a received timestamp, and a manual-check completion timestamp. 247 are seeded true conflicts, expressed as realistic **name variants** (Bob/Robert, "Corp"/"Corporation", casing and punctuation).
- `normalize_name()` UDF: lowercases, strips punctuation and company suffixes, collapses spaces, and canonicalizes common nicknames.

## Analyze — findings

| Metric | Manual (today) | Automated (proposed) |
|---|---|---|
| Avg conflict-check turnaround | 14.8 hours | Instant (< 1 min) |
| Intakes taking > 24 hours | 14.8% | 0% |
| True-conflict catch rate | 50.6% (125 / 247) | 98.8% (244 / 247) |
| Members cleared instantly | 0% | 82.9% (1,658 / 2,000) |
| Intakes needing a human | 100% | 17.1% (342 / 2,000) |

The headline: manual checking misses **~half** of real conflicts because it can't reconcile name variations — a compliance and malpractice exposure, not just a delay. Automated normalized matching at intake catches **99%**, clears **83% of members instantly**, and hands humans only the **17%** that actually need judgment.

**Honest caveat:** ~5% of intakes are namesake false positives (different people, same normalized name). Name matching alone over-flags, so the design adds a **secondary identifier** (date of birth or matter type) to confirm before a member is told there's a conflict.

## Share

`dashboard/conflict_check_dashboard.html` — manual-vs-automated dashboard (open in any browser).
`docs/solution_recommendation.md` — one-page recommendation memo.

## Act — recommended solution

Run a normalized-name conflict check **at the moment of intake**, in three tiers:

1. **No match → clear instantly.** 83% of members get an immediate answer instead of waiting ~15 hours.
2. **Match + matching secondary identifier → flag as likely conflict** for attorney review.
3. **Match but mismatched secondary identifier → likely namesake**, low-priority review.

This protects the firm from missed conflicts, removes the member wait for the large majority, and focuses staff time on the small set of genuine judgment calls.

## Repo layout

```
sql/generate_data.sql   Known parties, intakes, and normalize_name() UDF (BigQuery)
sql/analysis.sql        Manual-vs-automated comparison queries
dashboard/conflict_check_dashboard.html
docs/solution_recommendation.md
```
