-- ============================================================
-- LegalShield intake conflict-check - data generation (BigQuery)
-- Deterministic simulation (FARM_FINGERPRINT, no RAND). PII-safe.
-- ============================================================

CREATE SCHEMA IF NOT EXISTS `project-face2a76-c92a-4842-858.legal_intake`
OPTIONS(location='US', description='LegalShield intake conflict-of-interest check improvement - simulated');

-- Name normalization: lowercase, strip punctuation + company suffixes,
-- collapse spaces, canonicalize common nicknames.
CREATE OR REPLACE FUNCTION `project-face2a76-c92a-4842-858.legal_intake.normalize_name`(s STRING) AS ((
  WITH a AS (SELECT LOWER(TRIM(s)) AS x),
  b AS (SELECT REGEXP_REPLACE(x, r'[^a-z0-9 ]', '') AS x FROM a),
  c AS (SELECT REGEXP_REPLACE(x, r'\b(inc|llc|corp|corporation|co|ltd|company)\b', '') AS x FROM b),
  d AS (SELECT TRIM(REGEXP_REPLACE(x, r'\s+', ' ')) AS x FROM c),
  e AS (SELECT REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
       x, r'\bbob\b','robert'), r'\bbill\b','william'), r'\brick\b','richard'), r'\bjim\b','james'), r'\bmike\b','michael'),
       r'\bliz\b','elizabeth'), r'\bjen\b','jennifer'), r'\bpat\b','patricia'), r'\bjoe\b','joseph'), r'\btom\b','thomas') AS x FROM d)
  SELECT x FROM e
));

-- Known parties: existing clients + prior opposing parties
CREATE OR REPLACE TABLE `project-face2a76-c92a-4842-858.legal_intake.known_parties` AS
WITH n AS (SELECT i FROM UNNEST(GENERATE_ARRAY(1,800)) AS i),
firsts AS (SELECT ['James','Mary','Robert','Patricia','John','Jennifer','Michael','Linda','David','Elizabeth','William','Barbara','Richard','Susan','Joseph','Thomas','Sarah','Charles','Karen','Nancy'] AS a),
lasts AS (SELECT ['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Wilson','Anderson','Taylor','Moore','Jackson','Martin','Lee','Perez','Thompson','White'] AS a),
comps AS (SELECT ['Acme','Summit','Pioneer','Blue Ridge','Cedar','Metro','Northstar','Riverside','Vanguard','Keystone','Coastal','Granite','Harbor','Ironwood'] AS a),
sufs AS (SELECT ['Inc','LLC','Corp','Co','Ltd'] AS a)
SELECT
  1000 + i AS party_id,
  CASE WHEN MOD(i,2)=0
    THEN CONCAT((SELECT a FROM firsts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('f',i))),20))], ' ',
                (SELECT a FROM lasts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('l',i))),20))])
    ELSE CONCAT((SELECT a FROM comps)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('c',i))),14))], ' ',
                (SELECT a FROM sufs)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('s',i))),5))])
  END AS raw_name,
  IF(MOD(i,2)=0,'individual','company') AS party_type,
  IF(MOD(ABS(FARM_FINGERPRINT(CONCAT('role',i))),100)<70,'client','opposing') AS party_role
FROM n;

UPDATE `project-face2a76-c92a-4842-858.legal_intake.known_parties`
SET raw_name = raw_name WHERE TRUE;  -- no-op guard

-- add normalized name
CREATE OR REPLACE TABLE `project-face2a76-c92a-4842-858.legal_intake.known_parties` AS
SELECT *, `project-face2a76-c92a-4842-858.legal_intake.normalize_name`(raw_name) AS norm_name
FROM `project-face2a76-c92a-4842-858.legal_intake.known_parties`;

-- Intakes: 2,000 matters. 12% seeded true conflicts expressed as name variants.
CREATE OR REPLACE TABLE `project-face2a76-c92a-4842-858.legal_intake.intakes` AS
WITH n AS (SELECT i FROM UNNEST(GENERATE_ARRAY(1,2000)) AS i),
firsts AS (SELECT ['James','Mary','Robert','Patricia','John','Jennifer','Michael','Linda','David','Elizabeth','William','Barbara','Richard','Susan','Joseph','Thomas','Sarah','Charles','Karen','Nancy','Kevin','Amy','Brian','Emily'] AS a),
lasts AS (SELECT ['Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Wilson','Anderson','Taylor','Moore','Jackson','Martin','Lee','Perez','Thompson','White','Harris','Clark','Lewis','Walker'] AS a),
inits AS (SELECT ['A','B','C','D','E','F','G','H','J','K','L','M','N','P','R','S','T'] AS a),
matters AS (SELECT ['Family','Consumer','Traffic','Estate','Employment','Real Estate','Debt','Small Claims'] AS a)
SELECT
  20000 + i AS intake_id,
  CONCAT((SELECT a FROM firsts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('mf',i))),24))],' ',
         (SELECT a FROM lasts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('ml',i))),24))]) AS member_name,
  (SELECT a FROM matters)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('mt',i))),8))] AS matter_type,
  is_true,
  CASE
    WHEN is_true THEN variant_name
    WHEN MOD(ABS(FARM_FINGERPRINT(CONCAT('mi',i))),100) < 85
      THEN CONCAT((SELECT a FROM firsts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('of',i))),24))],' ',
                  (SELECT a FROM inits)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('oi',i))),17))],'. ',
                  (SELECT a FROM lasts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('ol',i))),24))])
    ELSE CONCAT((SELECT a FROM firsts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('of',i))),24))],' ',
                (SELECT a FROM lasts)[OFFSET(MOD(ABS(FARM_FINGERPRINT(CONCAT('ol',i))),24))])
  END AS opp_raw_name,
  ts AS received_ts,
  TIMESTAMP_ADD(ts, INTERVAL manual_min MINUTE) AS manual_check_ts
FROM n,
UNNEST([STRUCT(MOD(ABS(FARM_FINGERPRINT(CONCAT('true',i))),100) < 12 AS is_true)]) t,
UNNEST([STRUCT(
  TIMESTAMP_SUB(TIMESTAMP '2026-07-20 09:00:00', INTERVAL MOD(ABS(FARM_FINGERPRINT(CONCAT('rc',i))), 90*24*60) MINUTE) AS ts,
  CASE
    WHEN MOD(ABS(FARM_FINGERPRINT(CONCAT('tat',i))),100) < 55 THEN 120 + MOD(ABS(FARM_FINGERPRINT(CONCAT('t1',i))),360)
    WHEN MOD(ABS(FARM_FINGERPRINT(CONCAT('tat',i))),100) < 85 THEN 480 + MOD(ABS(FARM_FINGERPRINT(CONCAT('t2',i))),960)
    ELSE 1440 + MOD(ABS(FARM_FINGERPRINT(CONCAT('t3',i))),2880)
  END AS manual_min
)]) m,
UNNEST([STRUCT((
  SELECT raw_name FROM `project-face2a76-c92a-4842-858.legal_intake.known_parties`
  WHERE party_id = 1000 + 1 + MOD(ABS(FARM_FINGERPRINT(CONCAT('pick',i))),800)
) AS picked_name)]) p,
UNNEST([STRUCT(
  CASE MOD(ABS(FARM_FINGERPRINT(CONCAT('var',i))),3)
    WHEN 0 THEN picked_name                                     -- exact
    WHEN 1 THEN CONCAT(UPPER(picked_name), '.')                 -- case + punctuation
    ELSE REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(
         picked_name, r'Robert','Bob'), r'William','Bill'), r'Richard','Rick'), r'Michael','Mike'), r'\b(Inc|LLC|Corp|Co|Ltd)\b','')  -- nickname/suffix
  END AS variant_name
)]) v;
