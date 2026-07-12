## Build the county-level single-race population parquet (narcan 0.5.0) from the
## Census PEP Vintage 2024 county file cc-est2024-alldata.csv. PARSE step
## (pull-from-parse): reads a cached raw file (the pull fetches it; see the
## download helper) and writes the Release-asset parquet + a small bundled
## fixture. DuckDB does the WIDE->long reshape (UNPIVOT) driven by the shipped
## 36-column allowlist/decode table; R only orchestrates. Quiet; run from root.
##
## No double-count: STORE only the 24 NH*/H* x {MALE,FEMALE} finest
## crossings (hispanic_origin non_hispanic/hispanic). The 12 all-origin race
## columns + TOT_POP are VALIDATION-ONLY (WA == NHWA + HWA; 6-race sum ==
## TOT_POP) then dropped. The 30 *C_ "alone-or-in-combination" columns are NEVER
## read. total/both/all are synthesized downstream.

library(duckdb)

## Stable R_user_dir defaults with env overrides -- never a session scratchpad
## path baked into the package.
raw_path <- Sys.getenv(
    "NARCAN_CC_EST2024",
    file.path(tools::R_user_dir("narcan", "cache"), "raw",
              "cc-est2024-alldata.csv"))
stopifnot(file.exists(raw_path))

out_dir <- Sys.getenv("NARCAN_P5_BUILD",
                      file.path(tools::R_user_dir("narcan", "cache"), "build"))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
out_parquet <- file.path(out_dir, "pop_singlerace_county.parquet")
fixture_parquet <- "inst/extdata/pop_singlerace_county_fixture.parquet"
decode_csv <- "inst/extdata/pop_county_columns.csv"

decode <- read.csv(decode_csv, stringsAsFactors = FALSE)
stopifnot(nrow(decode) == 36L,
          sum(decode$role == "store") == 24L,
          sum(decode$role == "validate") == 12L,
          !any(grepl("C_(MALE|FEMALE)$", decode$column)))
store_cols <- decode$column[decode$role == "store"]

con <- dbConnect(duckdb())
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
q <- function(sql) dbGetQuery(con, sql)
qraw <- shQuote(raw_path)
qcol <- function(x) paste0("\"", x, "\"")          # double-quote any identifier

## --- Header/allowlist integrity: every allowlisted column must exist, and no
## *C_ (alone-or-in-combination) column may be in the allowlist. ---
hdr <- names(q(sprintf("SELECT * FROM read_csv_auto(%s) LIMIT 0", qraw)))
stopifnot(all(decode$column %in% hdr))

## --- Validation identities, across ALL county x year x age rows before
## dropping the marginals: all-origin == NH + H (per race x sex), 6-race-alone
## sum == TOT_POP. ---
stems <- c("WA", "BA", "IA", "AA", "NA", "TOM")
alone_cols <- as.vector(t(outer(stems, c("MALE", "FEMALE"), paste, sep = "_")))
origin_break_sql <- paste(vapply(alone_cols, function(cc) sprintf(
    "SUM(CASE WHEN %s <> %s + %s THEN 1 ELSE 0 END)",
    qcol(cc), qcol(paste0("NH", cc)), qcol(paste0("H", cc))), character(1)),
    collapse = " + ")
val <- q(sprintf("
  SELECT (%s) AS origin_breaks,
         SUM(CASE WHEN TOT_POP <> (%s) THEN 1 ELSE 0 END) AS tot_breaks
  FROM read_csv_auto(%s)
  WHERE SUMLEV = '050' AND YEAR BETWEEN 2 AND 6 AND AGEGRP BETWEEN 1 AND 18",
    origin_break_sql, paste(qcol(alone_cols), collapse = " + "), qraw))
stopifnot(val$origin_breaks == 0L, val$tot_breaks == 0L)

## --- Reshape: filter to 7/1 estimates (YEAR 2-6) and real age bins (1-18),
## UNPIVOT the 24 stored crossings, decode to (race, hispanic_origin, sex). ---
invisible(dbExecute(con, sprintf(
    "CREATE TEMP TABLE decode AS SELECT * FROM read_csv_auto(%s)",
    shQuote(decode_csv))))
on_list <- paste(qcol(store_cols), collapse = ", ")

build_sql <- sprintf("
  WITH src AS (
    SELECT
      printf('%%02d', CAST(STATE AS INTEGER)) AS state_fips,
      printf('%%02d', CAST(STATE AS INTEGER)) ||
        printf('%%03d', CAST(COUNTY AS INTEGER)) AS county_fips,
      YEAR + 2018 AS year,
      (AGEGRP - 1) * 5 AS age,
      %s
    FROM read_csv_auto(%s)
    WHERE SUMLEV = '050' AND YEAR BETWEEN 2 AND 6 AND AGEGRP BETWEEN 1 AND 18
  ),
  long AS (UNPIVOT src ON %s INTO NAME col_name VALUE pop)
  SELECT
    l.state_fips, l.county_fips, l.year, l.age,
    d.sex, d.race, d.hispanic_origin,
    SUM(l.pop)::BIGINT AS pop,
    'single' AS scheme, 'census_pep_v2024' AS source, 'V2024' AS vintage
  FROM long l JOIN decode d ON l.col_name = d.\"column\"
  GROUP BY ALL",
    on_list, qraw, on_list)

## Full Release-asset parquet, sorted by (year, state, county, ...).
invisible(dbExecute(con, sprintf("
  COPY (SELECT * FROM (%s)
        ORDER BY year, state_fips, county_fips, race, hispanic_origin, sex, age)
  TO %s (FORMAT PARQUET, COMPRESSION 'zstd', ROW_GROUP_SIZE 122880)",
    build_sql, shQuote(out_parquet))))

## Small bundled fixture: one small state (Wyoming, 56), all years -- used by the
## accessor tests and the vignette (its sparse asian_only cells exercise pop==0).
invisible(dbExecute(con, sprintf("
  COPY (SELECT * FROM (%s) WHERE state_fips = '56'
        ORDER BY year, county_fips, race, hispanic_origin, sex, age)
  TO %s (FORMAT PARQUET, COMPRESSION 'zstd', ROW_GROUP_SIZE 122880)",
    build_sql, shQuote(fixture_parquet))))

## --- Value goldens: county->national reconciles to the person per year; finest
## key is unique (no stored marginals). ---
gold <- q(sprintf(
    "SELECT year, SUM(pop) AS pop FROM read_parquet(%s) GROUP BY year ORDER BY year",
    shQuote(out_parquet)))
stopifnot(identical(as.integer(gold$year), 2020:2024),
          gold$pop[gold$year == 2020] == 331577720)

n_all <- q(sprintf("SELECT COUNT(*) n FROM read_parquet(%s)",
                   shQuote(out_parquet)))$n
n_key <- q(sprintf("SELECT COUNT(*) n FROM (SELECT DISTINCT state_fips, county_fips,
  year, age, sex, race, hispanic_origin FROM read_parquet(%s))",
                   shQuote(out_parquet)))$n
stopifnot(n_all == n_key)
