## Build the single-race BACKFILL county denominators (narcan 0.5.1), 2000-2024
## -> `pop_singlerace_county_full.parquet` (Release asset, supersedes the 0.5.0
## county asset) + a refreshed bundled Wyoming fixture spanning 2000-2024. PARSE
## step (pull-from-parse): reads cached raw Census PEP county files (the pull is
## `fetch_singlerace_backfill_raw.R`) and writes the parquet. DuckDB does the
## WIDE->long UNPIVOT (driven by the shipped 36-col decode table) + aggregation.
## Quiet; run from the package root. Reads cached paths ONLY (network-free; no URL
## ever passed to a DuckDB reader).
##
## Three vintages, DISJOINT owned years (verified layouts in
## verify_fwf/output/review/73_p3_verified_layouts.md):
##   2000-2010 co-est00int-alldata-NN.csv (51 per-state; glob) owns 2000-2009
##     PATH 4: AGEGRP 0=age0, 1=ages1-4, 2..18 -> (AGEGRP-1)*5, 99=total(drop).
##       0-4 bin = AGEGRP 0 + 1. YEAR 2..11 -> 2000..2009 (1=census, 12/13 skip).
##   2010-2020 cc-est2020int-alldata.csv (combined)             owns 2010-2019
##     PATH 2: AGEGRP 0=total(drop), 1..18 -> (AGEGRP-1)*5. YEAR 2..11 -> 2010..2019.
##   2020-2024 cc-est2024-alldata.csv (V2024, 0.5.0)            owns 2020-2024
##     PATH 2: AGEGRP 1..18. YEAR 2..6 -> 2020..2024. (0.5.0 source.)
##
## Store only the 24 NH*/H* x {MALE,FEMALE} finest crossings; the 12 all-origin +
## TOT_POP are validation-only then dropped. `*C_` combination columns never read.

library(duckdb)

cache <- Sys.getenv("NARCAN_SC_CACHE",
                    file.path(tools::R_user_dir("narcan", "cache"), "raw"))
out_dir <- Sys.getenv("NARCAN_P5_BUILD",
                      file.path(tools::R_user_dir("narcan", "cache"), "build"))
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
county_parquet  <- file.path(out_dir, "pop_singlerace_county_full.parquet")
fixture_parquet <- "inst/extdata/pop_singlerace_county_fixture.parquet"
decode_csv <- "inst/extdata/pop_county_columns.csv"

decode <- read.csv(decode_csv, stringsAsFactors = FALSE)
stopifnot(nrow(decode) == 36L, sum(decode$role == "store") == 24L,
          sum(decode$role == "validate") == 12L,
          !any(grepl("C_(MALE|FEMALE)$", decode$column)))
store_cols <- decode$column[decode$role == "store"]

## Explicit per-vintage YEAR code->calendar CASE (NOT an arithmetic offset -- the
## intercensal maps are not a simple offset; §3.2 / CP-1). Owned codes only.
year_case <- function(codes, years) sprintf("CASE YEAR %s END",
  paste(sprintf("WHEN %d THEN %d", codes, years), collapse = " "))
yc_co <- year_case(2:11, 2000:2009)      # co-est00int: 1=census, 12/13 excluded
yc_10 <- year_case(2:11, 2010:2019)      # cc-est2020int: 1=base, 12 excluded
yc_24 <- year_case(2:6,  2020:2024)      # cc-est2024 (V2024)

f_co2000 <- file.path(cache, "co-est00int-alldata-*.csv")      # 51-file glob
f_cc2010 <- file.path(cache, "cc-est2020int-alldata.csv")
f_cc2024 <- file.path(cache, "cc-est2024-alldata.csv")
stopifnot(length(Sys.glob(f_co2000)) == 51L,
          file.exists(f_cc2010), file.exists(f_cc2024))

## Retain the driver in a binding so R's GC cannot reclaim it and invalidate the
## connection mid-script (intermittent "Invalid connection" otherwise).
drv <- duckdb::duckdb()
con <- dbConnect(drv)
g <- function(s) dbGetQuery(con, s)
sqlq <- function(p) paste0("'", gsub("'", "''", p), "'")
qcol <- function(x) paste0("\"", x, "\"")
## Pin types (DuckDB's sniffer can mis-infer an all-numeric code column as VARCHAR):
## code columns INTEGER, TOT_POP + the 36 decode crossings BIGINT. union_by_name
## aligns the 51-file 2000-2010 glob by header name.
tmap_county <- sprintf("{%s}", paste(c(
  sprintf("'%s':'INTEGER'", c("SUMLEV","STATE","COUNTY","YEAR","AGEGRP")),
  sprintf("'%s':'BIGINT'", c("TOT_POP", decode$column))), collapse = ", "))
## encoding='latin-1': some county files carry non-UTF-8 county names (e.g. New
## Mexico's "Dona Ana County" with an n-tilde in Latin-1/Windows-1252). CTYNAME is
## never used, but DuckDB must still decode the whole line.
rd   <- function(path) sprintf(
  "read_csv_auto(%s, union_by_name = true, encoding = 'latin-1', types = %s)",
  sqlq(path), tmap_county)
on_list <- paste(qcol(store_cols), collapse = ", ")

## --- Header-integrity + trap-band validation identities, per vintage --------
stems <- c("WA", "BA", "IA", "AA", "NA", "TOM")
alone_cols <- as.vector(t(outer(stems, c("MALE", "FEMALE"), paste, sep = "_")))
val_sql <- function(reader, agegrp_lo) {
  breaks <- paste(vapply(alone_cols, function(cc) sprintf(
    "SUM(CASE WHEN %s <> %s + %s THEN 1 ELSE 0 END)",
    qcol(cc), qcol(paste0("NH", cc)), qcol(paste0("H", cc))), character(1)),
    collapse = " + ")
  sprintf("SELECT (%s) origin_breaks,
             SUM(CASE WHEN TOT_POP <> (%s) THEN 1 ELSE 0 END) tot_breaks
           FROM %s
           WHERE CAST(SUMLEV AS INTEGER) = 50 AND AGEGRP BETWEEN %d AND 18",
          breaks, paste(qcol(alone_cols), collapse = " + "), reader, agegrp_lo)
}
## co-est00int: include the path-4 age-0 trap band (AGEGRP 0..18); cc: 1..18.
hdr_ok <- function(reader) all(decode$column %in%
                               names(g(sprintf("SELECT * FROM %s LIMIT 0", reader))))
stopifnot(hdr_ok(rd(f_co2000)), hdr_ok(rd(f_cc2010)), hdr_ok(rd(f_cc2024)))
v_co <- g(val_sql(rd(f_co2000), 0L))
v_10 <- g(val_sql(rd(f_cc2010), 1L))
v_24 <- g(val_sql(rd(f_cc2024), 1L))
stopifnot(v_co$origin_breaks == 0L, v_co$tot_breaks == 0L,
          v_10$origin_breaks == 0L, v_10$tot_breaks == 0L,
          v_24$origin_breaks == 0L, v_24$tot_breaks == 0L)

## YEAR/AGEGRP code-set domain guards per file (explicit, not an assumed range --
## catches an R4-#1 code renumber). co has YEAR 1..13 + AGEGRP 0..18,99; the cc
## files have YEAR 1..N + AGEGRP 0..18 (0=total).
dom <- function(reader) list(
  y = sort(g(sprintf("SELECT DISTINCT YEAR y FROM %s", reader))$y),
  a = sort(g(sprintf("SELECT DISTINCT AGEGRP a FROM %s", reader))$a))
d_co <- dom(rd(f_co2000)); d_10 <- dom(rd(f_cc2010)); d_24 <- dom(rd(f_cc2024))
stopifnot(setequal(d_co$y, 1:13), setequal(d_co$a, c(0:18, 99)),
          setequal(d_10$y, 1:12), setequal(d_10$a, 0:18),
          setequal(d_24$y, 1:6),  setequal(d_24$a, 0:18))

## Trap-band proof is a check on the PARSED output (below, after finest_county is
## built): the int2000 age=0 bin must equal the raw store-col sum over AGEGRP 0+1
## and strictly exceed AGEGRP 1 alone -- so a revert of src_co to `1..18` (dropping
## true age 0) fails. Sum of the 24 stored crossings = the per-row finest total.
store_sum <- paste(qcol(store_cols), collapse = " + ")

## --- Per-vintage src (state_fips, county_fips, year, age, 24 store cols) -----
## age-CASE co-located with the AGEGRP filter (prevents an AGEGRP-0 -> age -5 bin).
fips_sel <- "printf('%02d', CAST(STATE AS INTEGER)) AS state_fips,
     printf('%02d', CAST(STATE AS INTEGER)) ||
       printf('%03d', CAST(COUNTY AS INTEGER)) AS county_fips"
src_co <- sprintf(
  "SELECT %s, %s AS year,
     CASE WHEN AGEGRP IN (0,1) THEN 0 ELSE (AGEGRP-1)*5 END AS age, %s
   FROM %s
   WHERE CAST(SUMLEV AS INTEGER) = 50 AND YEAR BETWEEN 2 AND 11
     AND AGEGRP BETWEEN 0 AND 18", fips_sel, yc_co, on_list, rd(f_co2000))
src_10 <- sprintf(
  "SELECT %s, %s AS year, (AGEGRP-1)*5 AS age, %s
   FROM %s
   WHERE CAST(SUMLEV AS INTEGER) = 50 AND YEAR BETWEEN 2 AND 11
     AND AGEGRP BETWEEN 1 AND 18", fips_sel, yc_10, on_list, rd(f_cc2010))
src_24 <- sprintf(
  "SELECT %s, %s AS year, (AGEGRP-1)*5 AS age, %s
   FROM %s
   WHERE CAST(SUMLEV AS INTEGER) = 50 AND YEAR BETWEEN 2 AND 6
     AND AGEGRP BETWEEN 1 AND 18", fips_sel, yc_24, on_list, rd(f_cc2024))

invisible(dbExecute(con, sprintf(
  "CREATE TEMP TABLE decode AS SELECT * FROM read_csv_auto(%s)", sqlq(decode_csv))))
build_sql <- sprintf("
  WITH src AS (%s UNION ALL %s UNION ALL %s),
       long AS (UNPIVOT src ON %s INTO NAME col_name VALUE pop)
  SELECT l.state_fips, l.county_fips, l.year, l.age,
         d.sex, d.race, d.hispanic_origin,
         SUM(l.pop)::BIGINT AS pop,
         'single' AS scheme, 'census_pep' AS source,
         CASE WHEN l.year < 2010 THEN 'int2000'
              WHEN l.year < 2020 THEN 'int2010' ELSE 'V2024' END AS vintage
  FROM long l JOIN decode d ON l.col_name = d.\"column\"
  GROUP BY ALL", src_co, src_10, src_24, on_list)

invisible(dbExecute(con, sprintf(
  "CREATE TEMP TABLE finest_county AS %s", build_sql)))

## --- Structural checks (post-reshape age domain; unique key; year set) ------
stopifnot(
  setequal(g("SELECT DISTINCT age a FROM finest_county")$a, seq(0, 85, 5)),
  identical(as.integer(sort(g("SELECT DISTINCT year y FROM finest_county")$y)),
            2000:2024),
  g("SELECT COUNT(*) n FROM finest_county")$n ==
    g("SELECT COUNT(*) n FROM (SELECT DISTINCT state_fips, county_fips, year, age,
       sex, race, hispanic_origin FROM finest_county)")$n,
  g("SELECT MIN(pop) m FROM finest_county")$m >= 0,
  g("SELECT COUNT(*) n FROM finest_county WHERE pop IS NULL")$n == 0L,
  ## §3.7(e): all 51 states PRESENT IN THE PARSED int2000 data (not files on disk).
  g("SELECT COUNT(DISTINCT state_fips) n FROM finest_county
     WHERE vintage = 'int2000'")$n == 51L,
  ## Year-boundary exclusivity (defense-in-depth, mirrors the state build): a
  ## future YEAR-CASE overlap that double-counts 2010/2020 is caught here.
  g("SELECT COUNT(*) n FROM finest_county
     WHERE (year = 2010 AND vintage <> 'int2010')
        OR (year = 2020 AND vintage <> 'V2024')")$n == 0L)

## Trap-band PARSE-OUTPUT proof (CP-1 round 2): the int2000 age=0 bin equals the
## raw co-est00int store-col sum over AGEGRP 0+1 (owned years) and strictly exceeds
## AGEGRP 1 alone -- proving the age-0 band actually flowed through src_co's
## `AGEGRP BETWEEN 0 AND 18` + the 0/1 merge (not the old tautological count check).
raw01 <- g(sprintf("SELECT SUM(%s) s FROM %s WHERE CAST(SUMLEV AS INTEGER) = 50
                    AND YEAR BETWEEN 2 AND 11 AND AGEGRP IN (0,1)",
                   store_sum, rd(f_co2000)))$s
raw1  <- g(sprintf("SELECT SUM(%s) s FROM %s WHERE CAST(SUMLEV AS INTEGER) = 50
                    AND YEAR BETWEEN 2 AND 11 AND AGEGRP = 1",
                   store_sum, rd(f_co2000)))$s
parsed0 <- g("SELECT SUM(pop) s FROM finest_county
              WHERE vintage = 'int2000' AND age = 0")$s
stopifnot(parsed0 == raw01, raw01 > raw1)

## --- Cross-validation GATES run BEFORE writing anything (a failed gate must not
## leave a poisoned parquet/fixture on disk -- CP-1). Both are HARD requirements
## (their inputs must exist): G5 needs the state parquet (run
## build_pop_singlerace_full.R first); G12 needs the frozen 0.5.0 county asset via
## NARCAN_050_COUNTY_PARQUET. A missing input STOPs, it does not silently skip. ---
state_parquet <- file.path(out_dir, "pop_singlerace_state_full.parquet")
stopifnot(file.exists(state_parquet))            # G5 input (build state first)
mism <- g(sprintf("
  WITH cty AS (SELECT state_fips, year, age, sex, race, hispanic_origin,
                      SUM(pop) p FROM finest_county GROUP BY ALL),
       st AS (SELECT state_fips, year, age, sex, race, hispanic_origin, pop p
              FROM read_parquet(%s))
  SELECT COUNT(*) n FROM cty FULL JOIN st USING
    (state_fips, year, age, sex, race, hispanic_origin)
  WHERE cty.p IS DISTINCT FROM st.p", sqlq(state_parquet)))$n
stopifnot(mism == 0L)                            # G5: state==county to the person

frozen <- Sys.getenv("NARCAN_050_COUNTY_PARQUET", "")
stopifnot(nzchar(frozen), file.exists(frozen))   # G12 input (frozen 0.5.0 asset)
key <- "state_fips, county_fips, year, age, sex, race, hispanic_origin"
bij <- g(sprintf("
  WITH f AS (SELECT %1$s, pop FROM read_parquet(%2$s)),
       n AS (SELECT %1$s, pop FROM finest_county WHERE year BETWEEN 2020 AND 2024)
  SELECT (SELECT COUNT(*) FROM f) nf, (SELECT COUNT(*) FROM n) nn,
         (SELECT COUNT(*) FROM f ANTI JOIN n USING (%1$s)) f_only,
         (SELECT COUNT(*) FROM n ANTI JOIN f USING (%1$s)) n_only,
         (SELECT COUNT(*) FROM f JOIN n USING (%1$s)
          WHERE f.pop IS DISTINCT FROM n.pop) val_mismatch",
  key, sqlq(frozen)))
stopifnot(bij$nf == bij$nn, bij$f_only == 0L, bij$n_only == 0L,
          bij$val_mismatch == 0L)                # G12: freeze bijection on overlap

## --- Write outputs (only after both gates passed) ---------------------------
invisible(dbExecute(con, sprintf("
  COPY (SELECT state_fips, county_fips, year, age, sex, race, hispanic_origin,
               pop, scheme, source, vintage FROM finest_county
        ORDER BY year, state_fips, county_fips, race, hispanic_origin, sex, age)
  TO %s (FORMAT PARQUET, COMPRESSION 'zstd', ROW_GROUP_SIZE 122880)",
  sqlq(county_parquet))))
invisible(dbExecute(con, sprintf("
  COPY (SELECT * FROM finest_county WHERE state_fips = '56'
        ORDER BY year, county_fips, race, hispanic_origin, sex, age)
  TO %s (FORMAT PARQUET, COMPRESSION 'zstd', ROW_GROUP_SIZE 122880)",
  sqlq(fixture_parquet))))

cat("county parquet:", county_parquet, "\nrows:",
    g("SELECT COUNT(*) n FROM finest_county")$n, "\n")
