-- ============================================================
-- Conflict-check analysis: manual (exact) vs automated (normalized)
-- ============================================================

WITH ix AS (
  SELECT i.*,
    TIMESTAMP_DIFF(manual_check_ts, received_ts, MINUTE)/60.0 AS manual_hours,
    -- manual reviewer = exact case-insensitive name match (misses variants)
    EXISTS(SELECT 1 FROM `project-face2a76-c92a-4842-858.legal_intake.known_parties` k
           WHERE LOWER(TRIM(k.raw_name)) = LOWER(TRIM(i.opp_raw_name))) AS manual_flag,
    -- automated = normalized match
    EXISTS(SELECT 1 FROM `project-face2a76-c92a-4842-858.legal_intake.known_parties` k
           WHERE k.norm_name = `project-face2a76-c92a-4842-858.legal_intake.normalize_name`(i.opp_raw_name)) AS auto_flag
  FROM `project-face2a76-c92a-4842-858.legal_intake.intakes` i
)
SELECT
  COUNT(*) AS total_intakes,
  COUNTIF(is_true) AS true_conflicts,
  -- speed
  ROUND(AVG(manual_hours),1) AS avg_manual_hours,
  ROUND(APPROX_QUANTILES(manual_hours,2)[OFFSET(1)],1) AS median_manual_hours,
  ROUND(100*COUNTIF(manual_hours>24)/COUNT(*),1) AS pct_over_24h,
  -- accuracy
  ROUND(100*COUNTIF(is_true AND manual_flag)/COUNTIF(is_true),1) AS manual_catch_rate,
  ROUND(100*COUNTIF(is_true AND auto_flag)/COUNTIF(is_true),1) AS auto_catch_rate,
  -- routing under automation
  COUNTIF(NOT auto_flag) AS cleared_instantly,
  ROUND(100*COUNTIF(NOT auto_flag)/COUNT(*),1) AS pct_cleared_instantly,
  COUNTIF(auto_flag) AS routed_to_human,
  COUNTIF(auto_flag AND NOT is_true) AS namesake_false_positives
FROM ix;

-- Example: the conflicts manual review MISSED but automation caught (the risk story)
-- SELECT intake_id, opp_raw_name,
--   `project-face2a76-c92a-4842-858.legal_intake.normalize_name`(opp_raw_name) AS opp_norm
-- FROM `project-face2a76-c92a-4842-858.legal_intake.intakes` i
-- WHERE is_true
--   AND NOT EXISTS(SELECT 1 FROM `project-face2a76-c92a-4842-858.legal_intake.known_parties` k
--                  WHERE LOWER(TRIM(k.raw_name)) = LOWER(TRIM(i.opp_raw_name)))
-- LIMIT 20;
