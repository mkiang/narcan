## Build the single-race BACKFILL denominators (narcan 0.5.1) covering 2000-2024
## at the STATE grain -> bundled national `pop_singlerace_full` .rda +
## `pop_singlerace_state_full.parquet` (Release asset). PARSE step
## (pull-from-parse): reads cached raw Census PEP files (the pull is
## `fetch_singlerace_backfill_raw.R`) and writes the outputs. DuckDB does the
## reshape + aggregation; R only orchestrates. Quiet; run from the package root.
##
## Three vintages, each owning a DISJOINT calendar-year range (verified layouts in
## verify_fwf/output/review/73_p3_verified_layouts.md):
##   2000-2010 intercensal state  st-est00int-alldata.csv       owns 2000-2009
##     PATH 3: 5-year AGEGRP (0=total drop; 1..18 -> (AGEGRP-1)*5).
##     STATE 0-56 INCLUDES 1,197 US rows at STATE=0 -> WHERE STATE > 0 or the
##     state-sum DOUBLE-COUNTS. Melt POPESTIMATE2000..2009 only (excludes
##     ESTIMATESBASE2000 / CENSUS2010POP / POPESTIMATE2010).
##   2010-2020 rebased intercensal sc-est2020int-alldata6.csv   owns 2010-2019
##     PATH 1: single-year AGE floor. SUMLEV 040 only. Melt POPESTIMATE2010..2019.
##   2020-2024 (V2024)             sc-est2024-alldata6.csv       owns 2020-2024
##     PATH 1: single-year AGE floor. Melt POPESTIMATE2020..2024. (0.5.0 source.)
##
## Census ORIGIN 0=total / 1=Not-Hispanic / 2=Hispanic (OPPOSITE SEER). RACE 1-6 =
## the six OMB single-race groups. Store only finest cells; total/both/all are
## synthesized downstream. Per-row `vintage` records provenance (int2000 /
## int2010 / V2024). National = sum of the STATE grain (so national == state-sum
## by construction; the county build is an independent parse for the G5 recon).

library(duckdb)

## Stable cache default (R_user_dir), env override -- never a session scratchpad
## path baked into the package.
cache <- Sys.getenv("NARCAN_SC_CACHE",
                    file.path(tools::R_user_dir("narcan", "cache"), "raw"))
out_dir <- Sys.getenv("NARCAN_P5_BUILD",
                      file.path(tools::R_user_dir("narcan", "cache"), "build"))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
state_parquet <- file.path(out_dir, "pop_singlerace_state_full.parquet")

f_st2000 <- file.path(cache, "st-est00int-alldata.csv")        # 2000-2010 state
f_st2010 <- file.path(cache, "sc-est2020int-alldata6.csv")     # 2010-2020 rebased
f_st2024 <- file.path(cache, "sc-est2024-alldata6.csv")        # V2024 (0.5.0)
stopifnot(file.exists(f_st2000), file.exists(f_st2010), file.exists(f_st2024))

## Retain the driver in a binding so R's GC cannot reclaim it and invalidate the
## connection mid-script (intermittent "Invalid connection" otherwise).
drv <- duckdb::duckdb()
con <- dbConnect(drv)
g <- function(s) dbGetQuery(con, s)
sqlq <- function(p) paste0("'", gsub("'", "''", p), "'")
## DuckDB's CSV sniffer can infer an all-numeric code column (observed: STATE) as
## VARCHAR, which then breaks numeric comparisons. Pin the integer columns per file
## via `types=` so parsing is deterministic, not sniff-dependent.
tmap <- function(intcols, popyears) sprintf("{%s}", paste(c(
  sprintf("'%s':'INTEGER'", intcols),
  sprintf("'POPESTIMATE%d':'BIGINT'", popyears)), collapse = ", "))
rd_typed <- function(path, intcols, popyears) sprintf(
  "read_csv_auto(%s, types = %s)", sqlq(path), tmap(intcols, popyears))
r_st2000 <- rd_typed(f_st2000, c("STATE","SEX","ORIGIN","RACE","AGEGRP"), 2000:2009)
r_st2010 <- rd_typed(f_st2010, c("SUMLEV","STATE","SEX","ORIGIN","RACE","AGE"), 2010:2019)
r_st2024 <- rd_typed(f_st2024, c("STATE","SEX","ORIGIN","RACE","AGE"), 2020:2024)

race_case <- "CASE RACE WHEN 1 THEN 'white_only' WHEN 2 THEN 'black_only'
  WHEN 3 THEN 'american_indian_only' WHEN 4 THEN 'asian_only'
  WHEN 5 THEN 'nhopi_only' WHEN 6 THEN 'multiracial' END"
orig_case <- "CASE ORIGIN WHEN 1 THEN 'non_hispanic' WHEN 2 THEN 'hispanic' END"
sex_case  <- "CASE SEX WHEN 1 THEN 'male' WHEN 2 THEN 'female' END"

## --- Raw-file DOMAIN checks + per-stratum MARGINAL reconciliation ------------
## Build-time only: the SEX=0 / ORIGIN=0 / RACE=0 provided marginals are dropped
## before aggregation, so a race/origin/sex mislabel that PRESERVES the grand
## total (which the national tot() anchors below cannot catch) is caught HERE or
## nowhere (CP-1, both state reviewers). For each vintage + owned year, assert the
## provided marginal equals the finest-cell sum, per stratum of the other dims.
validate_state <- function(reader, agecol, years, has_race0, filt) {
  wf <- function(extra) if (nzchar(filt))
    sprintf("WHERE %s AND %s", filt, extra) else sprintf("WHERE %s", extra)
  ## Domain: RACE (excluding a 0 marginal) is exactly 1..6 (rejects a bridged
  ## file); AGEGRP path exactly 0..18; single-year AGE spans 0..85.
  stopifnot(setequal(
    g(sprintf("SELECT DISTINCT RACE r FROM %s %s", reader, wf("RACE <> 0")))$r, 1:6))
  if (identical(agecol, "AGEGRP")) {
    stopifnot(setequal(
      g(sprintf("SELECT DISTINCT AGEGRP a FROM %s %s", reader, wf("TRUE")))$a, 0:18))
  } else {
    ar <- range(g(sprintf("SELECT MIN(AGE) lo, MAX(AGE) hi FROM %s %s",
                          reader, wf("TRUE")))[1, ])
    stopifnot(ar[1] == 0, ar[2] == 85)
  }
  bad <- 0L
  for (yc in years) {
    bad <- bad + g(sprintf(
      "SELECT COUNT(*) n FROM (SELECT ORIGIN, RACE, %1$s ak,
         SUM(CASE WHEN SEX=0 THEN %2$s END) m0,
         SUM(CASE WHEN SEX IN (1,2) THEN %2$s END) m12
       FROM %3$s %4$s GROUP BY ORIGIN, RACE, %1$s)
       WHERE m0 IS DISTINCT FROM m12",
      agecol, yc, reader, wf("ORIGIN IN (1,2) AND RACE BETWEEN 1 AND 6")))$n
    bad <- bad + g(sprintf(
      "SELECT COUNT(*) n FROM (SELECT SEX, RACE, %1$s ak,
         SUM(CASE WHEN ORIGIN=0 THEN %2$s END) m0,
         SUM(CASE WHEN ORIGIN IN (1,2) THEN %2$s END) m12
       FROM %3$s %4$s GROUP BY SEX, RACE, %1$s)
       WHERE m0 IS DISTINCT FROM m12",
      agecol, yc, reader, wf("SEX IN (1,2) AND RACE BETWEEN 1 AND 6")))$n
    if (has_race0) bad <- bad + g(sprintf(
      "SELECT COUNT(*) n FROM (SELECT SEX, ORIGIN, %1$s ak,
         SUM(CASE WHEN RACE=0 THEN %2$s END) m0,
         SUM(CASE WHEN RACE BETWEEN 1 AND 6 THEN %2$s END) m12
       FROM %3$s %4$s GROUP BY SEX, ORIGIN, %1$s)
       WHERE m0 IS DISTINCT FROM m12",
      agecol, yc, reader, wf("SEX IN (1,2) AND ORIGIN IN (1,2)")))$n
  }
  stopifnot(bad == 0L)
}
validate_state(r_st2000, "AGEGRP", sprintf("POPESTIMATE%d", 2000:2009),
               has_race0 = TRUE,  filt = "STATE > 0")
validate_state(r_st2010, "AGE",    sprintf("POPESTIMATE%d", 2010:2019),
               has_race0 = FALSE, filt = "CAST(SUMLEV AS INTEGER) = 40")
validate_state(r_st2024, "AGE",    sprintf("POPESTIMATE%d", 2020:2024),
               has_race0 = FALSE, filt = "")

## --- Per-vintage finest-cell SELECTs (state grain) --------------------------
## 2000-2010: AGEGRP path, STATE>0, owned POPESTIMATE2000..2009 melted explicitly.
yrs_2000 <- 2000:2009
melt_2000 <- paste(sprintf(
  "SELECT printf('%%02d', STATE) AS state_fips, %d AS year,
     (AGEGRP-1)*5 AS age, %s AS sex, %s AS hispanic_origin, %s AS race,
     CAST(POPESTIMATE%d AS BIGINT) AS pop, 'int2000' AS vintage
   FROM %s
   WHERE STATE > 0 AND SEX IN (1,2) AND ORIGIN IN (1,2) AND RACE BETWEEN 1 AND 6
     AND AGEGRP BETWEEN 1 AND 18",
  yrs_2000, sex_case, orig_case, race_case, yrs_2000, r_st2000),
  collapse = " UNION ALL ")

## 2010-2020 rebased: single-year AGE, SUMLEV 040, owned POPESTIMATE2010..2019.
yrs_2010 <- 2010:2019
melt_2010 <- paste(sprintf(
  "SELECT printf('%%02d', STATE) AS state_fips, %d AS year,
     LEAST((AGE//5)*5, 85) AS age, %s AS sex, %s AS hispanic_origin, %s AS race,
     CAST(POPESTIMATE%d AS BIGINT) AS pop, 'int2010' AS vintage
   FROM %s
   WHERE CAST(SUMLEV AS INTEGER) = 40 AND SEX IN (1,2) AND ORIGIN IN (1,2)
     AND RACE BETWEEN 1 AND 6",
  yrs_2010, sex_case, orig_case, race_case, yrs_2010, r_st2010),
  collapse = " UNION ALL ")

## 2020-2024 V2024: single-year AGE, owned POPESTIMATE2020..2024 (0.5.0 logic).
yrs_2024 <- 2020:2024
melt_2024 <- paste(sprintf(
  "SELECT printf('%%02d', STATE) AS state_fips, %d AS year,
     LEAST((AGE//5)*5, 85) AS age, %s AS sex, %s AS hispanic_origin, %s AS race,
     CAST(POPESTIMATE%d AS BIGINT) AS pop, 'V2024' AS vintage
   FROM %s
   WHERE SEX IN (1,2) AND ORIGIN IN (1,2) AND RACE BETWEEN 1 AND 6",
  yrs_2024, sex_case, orig_case, race_case, yrs_2024, r_st2024),
  collapse = " UNION ALL ")

invisible(dbExecute(con, sprintf(
  "CREATE TEMP TABLE finest_state AS
   SELECT state_fips, year, age, sex, race, hispanic_origin, vintage,
          SUM(pop)::BIGINT AS pop
   FROM (%s UNION ALL %s UNION ALL %s)
   GROUP BY ALL", melt_2000, melt_2010, melt_2024)))

## --- Boundary-dedup + structural checks ------------------------------------
chk <- g("SELECT
    COUNT(*) n,
    COUNT(*) FILTER (WHERE pop IS NULL OR age IS NULL OR race IS NULL
                     OR sex IS NULL OR hispanic_origin IS NULL) n_bad,
    MIN(pop) minpop,
    COUNT(DISTINCT (year)) n_years
  FROM finest_state")
yr_set <- sort(g("SELECT DISTINCT year y FROM finest_state")$y)
key_n  <- g("SELECT COUNT(*) n FROM (SELECT DISTINCT state_fips, year, age, sex,
             race, hispanic_origin FROM finest_state)")$n
n_states <- g("SELECT COUNT(DISTINCT state_fips) n FROM finest_state")$n
stopifnot(chk$n_bad == 0L, chk$minpop >= 0,
          identical(as.integer(yr_set), 2000:2024),
          chk$n == key_n,                       # one row per finest key
          n_states == 51L,                      # 50 states + DC, all present
          chk$n == 51L * 10800L)                # exact state grid (G8, state grain)
## 2010 owned exclusively by int2010 (per-row provenance assert).
stopifnot(g("SELECT COUNT(*) n FROM finest_state
             WHERE year = 2010 AND vintage <> 'int2010'")$n == 0L)

## --- National grain (sum of states) ----------------------------------------
national <- g("SELECT year, age, sex, race, hispanic_origin,
                 SUM(pop)::BIGINT AS pop,
                 CASE WHEN year < 2010 THEN 'int2000'
                      WHEN year < 2020 THEN 'int2010' ELSE 'V2024' END AS vintage
               FROM finest_state GROUP BY ALL
               ORDER BY year, race, hispanic_origin, sex, age")

## --- Goldens (committed literals; anchors from independent sources are checked
## in test-singlerace-full-data.R -- here we assert the build-internal ones) ---
tot <- function(y) sum(national$pop[national$year == y])
stopifnot(
  tot(2000) == 282162411, tot(2005) == 295516599, tot(2009) == 306771529,
  tot(2015) == 321815121,               # int2010 anchor: proves the REBASED file
  tot(2020) == 331577720,                                    # solid anchors
  nrow(national) == 10800L,                                  # G8 full grid
  nrow(national) == nrow(dplyr::distinct(national, year, age, sex, race,
                                         hispanic_origin)))
## 2020 by-race (V2024, solid) -- catches a race transposition.
b20 <- national[national$year == 2020, ]
byr <- tapply(b20$pop, b20$race, sum)
stopifnot(
  byr["white_only"] == 251705938, byr["black_only"] == 44911745,
  byr["american_indian_only"] == 4302125, byr["asian_only"] == 20224610,
  byr["nhopi_only"] == 851893, byr["multiracial"] == 9581409)
## Directional SEX/ORIGIN label-swap guards (CP-1 round 2): US female pop > male
## and non-Hispanic > Hispanic. A male<->female or NH<->Hispanic swap in sex_case/
## orig_case flips these. Non-circular -- from external demographic fact, not the
## build's own numbers (the marginal reconciliation is invariant to such a swap).
by_sex <- tapply(b20$pop, b20$sex, sum)
by_org <- tapply(b20$pop, b20$hispanic_origin, sum)
stopifnot(by_sex["female"] > by_sex["male"],
          by_org["non_hispanic"] > by_org["hispanic"])

## --- G12 freeze bijection (national + state): the 2020-2024 slice must reproduce
## the FROZEN 0.5.0 data value-for-value on the full key -- 1:1, no cell on one
## side only, equal pop (D-FREEZE). Runs BEFORE the writes so a failed gate leaves
## no artifact. County G12 runs in the county build. (CP-2/Sonnet: state+national
## G12 were unimplemented; the staged fixtures are the frozen 0.5.0 snapshots.) ---
.bijection <- function(new, frozen, keys) {
  n <- new[new$year %in% 2020:2024, c(keys, "pop")]
  f <- as.data.frame(frozen)[, c(keys, "pop")]
  m <- merge(n, f, by = keys, all = TRUE, suffixes = c(".n", ".f"))
  stopifnot(nrow(m) == nrow(n), nrow(n) == nrow(f),
            !anyNA(m$pop.n), !anyNA(m$pop.f), all(m$pop.n == m$pop.f))
}
.bijection(as.data.frame(national),
           readRDS("tests/testthat/fixtures/pop_singlerace_v0.5.0.rds"),
           c("year", "age", "sex", "race", "hispanic_origin"))
.bijection(g("SELECT state_fips, year, age, sex, race, hispanic_origin, pop
              FROM finest_state WHERE year BETWEEN 2020 AND 2024"),
           readRDS("tests/testthat/fixtures/pop_singlerace_state_v0.5.0.rds"),
           c("state_fips", "year", "age", "sex", "race", "hispanic_origin"))

## --- Write outputs ----------------------------------------------------------
pop_singlerace_full <- tibble::as_tibble(national)
pop_singlerace_full$scheme <- "single"
pop_singlerace_full$source <- "census_pep"
usethis::use_data(pop_singlerace_full, overwrite = TRUE)

invisible(dbExecute(con, sprintf("
  COPY (SELECT state_fips, year, age, sex, race, hispanic_origin, pop,
               'single' AS scheme, 'census_pep' AS source, vintage
        FROM finest_state
        ORDER BY year, state_fips, race, hispanic_origin, sex, age)
  TO %s (FORMAT PARQUET, COMPRESSION 'zstd', ROW_GROUP_SIZE 122880)",
  sqlq(state_parquet))))

## --- Emit interior-year national by-race, for CP-2 to CROSS-CHECK against the
## INDEPENDENT us-est00int national file ONLY. These are the build's OWN output;
## do NOT commit them as G1 test anchors (that would be circular -- the committed
## literals must be transcribed from us-est00int, per the §3.6b independence rule).
for (y in c(2005, 2015)) {
  by <- aggregate(pop ~ race, national[national$year == y, ], sum)
  cat(sprintf("== [CP-2 cross-check only, NOT a test anchor] national by race %d ==\n", y))
  print(by)
}
cat("state parquet:", state_parquet, "\n")
