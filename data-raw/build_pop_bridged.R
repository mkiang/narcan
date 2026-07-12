## Build the SEER-uniform bridged population denominators (narcan 0.5.1) from the
## two SEER U.S. Population Data files. PARSE step (pull-from-parse): reads the
## cached raw .txt.gz (the pull fetches them via download_pop_data(raw = TRUE) /
## the URLs below) and writes the bundled national `pop_bridged` .rda plus the
## state + county Release-asset parquets. DuckDB does the fixed-width parse
## (whole-line VARCHAR + substr) and the aggregation; R only orchestrates. Quiet;
## run from the package root.
##
## Sources (SEER U.S. Population Data, Vintage 2024; PUBLIC aggregates). The exact
## download URLs are registered in inst/extdata/pop_manifest.csv (`source_url`) at
## delivery (the bridged rows land with the Release assets) and are fetched by
## download_pop_data(raw = TRUE) -- NEVER fetched here (pull-from-parse; no URL
## literal in a builder):
##   1969-2024 file us.1969_2024.20ages.adjusted (race 3-group White/Black/Other,
##     NO Hispanic)
##   1990-2024 file us.1990_2024.20ages.adjusted (race 4-group White/Black/AIAN/
##     API + Hispanic origin 0/1)
##
## Stitch (no double-count): years < 1990 come ONLY from the 1969 file, years
## >= 1990 ONLY from the 1990 file (each calendar year from exactly one series).
## The two series are byte-identical for White/Black across 1990-2024, so the
## 1990 seam has no artificial level step -- only the genuine availability change
## (AIAN/API split + Hispanic origin appear at 1990).
##
## 26-byte record: Year 1-4, state postal 5-6, state FIPS 7-8, county FIPS 9-11,
## registry 12-13, Race 14, Origin 15, Sex 16, Age 17-18, Population 19-26.
## SEER Origin (0 = Non-Hispanic, 1 = Hispanic, 9 = N/A) has the OPPOSITE
## polarity to Census PEP -- it gets its OWN decode here. Age 20-code ->
## narcan 18 bins: {00,01}->0; codes 02..17 -> (code-1)*5; {18,19}->85.
## Drop the KR (Katrina/Rita) pseudo-state from both files.
##
## No double-count: STORE only the finest cells (year x age x sex x race x
## hispanic_origin, plus geography); total/both/all are synthesized downstream.

library(duckdb)

## Stable cache default (R_user_dir), env override -- never a session scratchpad
## path baked into the package (matches build_pop_singlerace_full.R).
cache <- Sys.getenv("NARCAN_SEER_CACHE",
                    file.path(tools::R_user_dir("narcan", "cache"), "raw"))
raw_1969 <- file.path(cache, "us.1969_2024.20ages.adjusted.txt.gz")
raw_1990 <- file.path(cache, "us.1990_2024.20ages.adjusted.txt.gz")
stopifnot(file.exists(raw_1969), file.exists(raw_1990))

out_dir <- Sys.getenv("NARCAN_P5_BUILD",
                      file.path(tools::R_user_dir("narcan", "cache"), "build"))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
state_parquet  <- file.path(out_dir, "pop_bridged_state.parquet")
county_parquet <- file.path(out_dir, "pop_bridged_county.parquet")

con <- dbConnect(duckdb())
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
q <- function(sql) dbGetQuery(con, sql)
qf <- function(p) paste0("'", p, "'")

## One whole-line-VARCHAR reader per file; \x07 never occurs so each line is one
## field. quote/escape disabled so the fixed-width bytes pass through verbatim.
reader <- function(path) sprintf(
    "read_csv(%s, header = false, delim = '\\x07', quote = '', escape = '', columns = {'line': 'VARCHAR'})",
    qf(path))

## county-grain finest cells, both eras, disjoint by year.
build_sql <- sprintf("
  WITH p69 AS (
    SELECT
      CAST(substr(line,1,4) AS INTEGER) AS year,
      substr(line,7,2) AS state_fips,
      substr(line,7,2) || substr(line,9,3) AS county_fips,
      CASE CAST(substr(line,14,1) AS INTEGER)
        WHEN 1 THEN 'white' WHEN 2 THEN 'black' WHEN 3 THEN 'other' END AS race,
      'all' AS hispanic_origin,
      CASE substr(line,16,1) WHEN '1' THEN 'male' WHEN '2' THEN 'female' END AS sex,
      CAST(substr(line,17,2) AS INTEGER) AS age_code,
      CAST(substr(line,19,8) AS BIGINT) AS pop
    FROM %s
    WHERE substr(line,5,2) <> 'KR' AND CAST(substr(line,1,4) AS INTEGER) < 1990
  ),
  p90 AS (
    SELECT
      CAST(substr(line,1,4) AS INTEGER) AS year,
      substr(line,7,2) AS state_fips,
      substr(line,7,2) || substr(line,9,3) AS county_fips,
      CASE CAST(substr(line,14,1) AS INTEGER)
        WHEN 1 THEN 'white' WHEN 2 THEN 'black'
        WHEN 3 THEN 'american_indian' WHEN 4 THEN 'api' END AS race,
      CASE substr(line,15,1) WHEN '0' THEN 'non_hispanic' WHEN '1' THEN 'hispanic' END AS hispanic_origin,
      CASE substr(line,16,1) WHEN '1' THEN 'male' WHEN '2' THEN 'female' END AS sex,
      CAST(substr(line,17,2) AS INTEGER) AS age_code,
      CAST(substr(line,19,8) AS BIGINT) AS pop
    FROM %s
    WHERE substr(line,5,2) <> 'KR'
  ),
  u AS (SELECT * FROM p69 UNION ALL SELECT * FROM p90)
  SELECT
    state_fips, county_fips, year,
    CASE WHEN age_code IN (0,1) THEN 0
         WHEN age_code BETWEEN 2 AND 17 THEN (age_code - 1) * 5
         WHEN age_code IN (18,19) THEN 85 END AS age,
    sex, race, hispanic_origin,
    SUM(pop)::BIGINT AS pop
  FROM u
  GROUP BY ALL", reader(raw_1969), reader(raw_1990))

invisible(dbExecute(con, sprintf(
    "CREATE TEMP TABLE finest_county AS %s", build_sql)))

## Sanity on the parse before writing anything.
chk <- q("SELECT
    SUM(pop) FILTER (WHERE year = 1990) AS t1990,
    SUM(pop) FILTER (WHERE year = 2020) AS t2020,
    COUNT(*) FILTER (WHERE pop IS NULL OR age IS NULL OR race IS NULL
                     OR sex IS NULL OR hispanic_origin IS NULL) AS n_bad,
    MIN(pop) AS minpop
  FROM finest_county")
stopifnot(chk$t1990 == 249622814, chk$t2020 == 331577720,
          chk$n_bad == 0L, chk$minpop >= 0)

meta <- "'bridged' AS scheme, 'seer_uspop' AS source, 'SEER2024' AS vintage"

## National grain -> bundled .rda (metadata added in R).
national <- q(sprintf("
  SELECT year, age, sex, race, hispanic_origin, SUM(pop)::BIGINT AS pop
  FROM finest_county GROUP BY ALL
  ORDER BY year, race, hispanic_origin, sex, age"))

## State + county grain -> Release-asset parquets (value-identical; sorted).
invisible(dbExecute(con, sprintf("
  COPY (SELECT state_fips, year, age, sex, race, hispanic_origin,
               SUM(pop)::BIGINT AS pop, %s
        FROM finest_county GROUP BY ALL
        ORDER BY year, state_fips, race, hispanic_origin, sex, age)
  TO %s (FORMAT PARQUET, COMPRESSION 'zstd', ROW_GROUP_SIZE 122880)",
    meta, qf(state_parquet))))
invisible(dbExecute(con, sprintf("
  COPY (SELECT state_fips, county_fips, year, age, sex, race, hispanic_origin,
               pop, %s
        FROM finest_county
        ORDER BY year, state_fips, county_fips, race, hispanic_origin, sex, age)
  TO %s (FORMAT PARQUET, COMPRESSION 'zstd', ROW_GROUP_SIZE 122880)",
    meta, qf(county_parquet))))

## --- Post-build goldens (era-ragged race + origin; reconciliation) ---
pre  <- national[national$year < 1990, ]
post <- national[national$year >= 1990, ]
stopifnot(
    setequal(pre$race, c("white", "black", "other")),
    setequal(post$race, c("white", "black", "american_indian", "api")),
    setequal(pre$hispanic_origin, "all"),
    setequal(post$hispanic_origin, c("non_hispanic", "hispanic")),
    setequal(national$year, 1969:2024),
    setequal(national$sex, c("male", "female")),
    setequal(national$age, seq(0, 85, 5)),
    !anyNA(national$pop), all(national$pop >= 0),
    nrow(national) == nrow(dplyr::distinct(national, year, age, sex, race,
                                           hispanic_origin)))
## National row count reconciles exactly: pre-1990 (21 yr x 18 age x 2 sex x
## 3 race x 1 origin = 2268) + 1990+ (35 x 18 x 2 x 4 x 2 = 10080) = 12348.
stopifnot(nrow(national) == 12348L)

## state -> national and county -> state reconcile to the person.
st_nat <- q("SELECT year, SUM(pop) AS pop FROM (
    SELECT year, SUM(pop) AS pop FROM finest_county GROUP BY ALL) GROUP BY year")
stopifnot(sum(national$pop) == sum(st_nat$pop))

pop_bridged <- national
pop_bridged$scheme <- "bridged"
pop_bridged$source <- "seer_uspop"
pop_bridged$vintage <- "SEER2024"
pop_bridged <- tibble::as_tibble(pop_bridged)

usethis::use_data(pop_bridged, overwrite = TRUE)

## Emit the by-race / race x origin / by-sex 2020 national anchors that the
## reconciliation goldens pin (totals alone cannot catch a race or origin
## mislabel -- see the 0.5.1 review). Printed for capture into the tests.
b2020 <- national[national$year == 2020, ]
cat("== bridged 2020 by race ==\n")
print(aggregate(pop ~ race, b2020, sum))
cat("== bridged 2020 non_hispanic white ==\n")
print(sum(b2020$pop[b2020$race == "white" &
                    b2020$hispanic_origin == "non_hispanic"]))
cat("== bridged 2020 by sex ==\n")
print(aggregate(pop ~ sex, b2020, sum))
cat("state parquet:", state_parquet, "\ncounty parquet:", county_parquet, "\n")
