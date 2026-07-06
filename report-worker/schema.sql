-- Knockoff report worker — D1 schema.
-- Apply with: wrangler d1 execute knockoff-reports --file=schema.sql --remote

CREATE TABLE IF NOT EXISTS reports (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand TEXT NOT NULL,            -- brand as displayed ("SZHLUX")
  brand_key TEXT NOT NULL,        -- normalized key ("szhlux")
  suggestion TEXT NOT NULL,       -- "is_junk" | "not_junk"
  verdict TEXT,                   -- what the extension decided at report time
  asin TEXT,                      -- product the report came from, if any
  marketplace TEXT,               -- "www.amazon.com" etc.
  ext_version TEXT,               -- extension version, for triage
  ip_hash TEXT NOT NULL,          -- salted SHA-256 of reporter IP (rate limiting only)
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_reports_brand_key ON reports (brand_key);
CREATE INDEX IF NOT EXISTS idx_reports_created ON reports (created_at);
CREATE INDEX IF NOT EXISTS idx_reports_ip ON reports (ip_hash, created_at);

-- Curated verdicts, maintained from the /review dashboard. Served to every
-- extension install via GET /flagged and GET /brands, so a curation decision
-- reaches users within their next daily refresh — no extension release.
CREATE TABLE IF NOT EXISTS curated (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  brand TEXT NOT NULL,
  brand_key TEXT NOT NULL UNIQUE,
  list TEXT NOT NULL CHECK (list IN ('flagged', 'known')),
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

-- Handy triage view: which brands are reported most, and which way?
CREATE VIEW IF NOT EXISTS brand_tallies AS
SELECT
  brand_key,
  MAX(brand) AS brand,
  SUM(CASE WHEN suggestion = 'is_junk' THEN 1 ELSE 0 END) AS junk_votes,
  SUM(CASE WHEN suggestion = 'not_junk' THEN 1 ELSE 0 END) AS real_votes,
  COUNT(*) AS total,
  MAX(created_at) AS last_report
FROM reports
GROUP BY brand_key;
