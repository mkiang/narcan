## PULL step (pull-from-parse) for the narcan 0.5.1 single-race backfill: fetch the
## raw Census PEP intercensal source files into the cache so the build scripts
## (build_pop_singlerace_full.R / _county_full.R) can parse them network-free.
## Public aggregates, bulk flat-files ONLY (never the Census Data API). Reuses the
## package's own .narcan_ua() (generic `narcan/<version>`, no personal identifier)
## and .download_file() so the outbound-request discipline is identical to
## download_pop_data(). Idempotent: skip-if-cached; on any fetch failure it STOPs
## loudly, naming the file (so a missing 1-of-51 county file never becomes a
## silent gap). Run from the package root.

pkgload::load_all(".", quiet = TRUE)

cache <- Sys.getenv("NARCAN_SC_CACHE",
                    file.path(tools::R_user_dir("narcan", "cache"), "raw"))
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
base <- "https://www2.census.gov/programs-surveys/popest/datasets"

## A cached file counts as good only if it looks like a complete Census CSV: a
## non-trivial size AND a header row with many columns. Guards against a truncated
## download (non-empty but cut short) being cached permanently under skip-if-cached
## (CP-1) and against an HTML soft-error page.
## 2e4 floor: the smallest real file is the DC county file (~60 KB), so 20 KB
## leaves comfortable headroom while still rejecting an HTML soft-error page.
.looks_complete <- function(path) {
  if (!file.exists(path) || file.size(path) < 2e4) return(FALSE)
  h <- tryCatch(readLines(path, n = 1L, warn = FALSE), error = function(e) character())
  length(h) == 1L && lengths(gregexpr(",", h)) >= 5L
}

## Per-file helper (testable in isolation): fetch `url` -> `cache/name` unless a
## COMPLETE copy is already cached; STOP with an informative message on failure or
## on an incomplete result (never cache a truncated file).
.fetch_one <- function(url, name, cache, pause = 0.2) {
  dest <- file.path(cache, name)
  if (.looks_complete(dest)) return(invisible(dest))
  if (file.exists(dest)) unlink(dest)              # drop a truncated cached copy
  ok <- tryCatch({ narcan:::.download_file(url, dest); TRUE },
                 error = function(e) FALSE)
  if (!ok || !.looks_complete(dest)) {
    if (file.exists(dest)) unlink(dest)
    stop(sprintf("fetch failed or incomplete for %s (%s) -- the backfill pull ",
                 name, url), "is incomplete; re-run after checking the URL/network.",
         call. = FALSE)
  }
  Sys.sleep(pause)                       # per-host pacing (unidentified traffic)
  invisible(dest)
}

## State + combined-county files.
singles <- c(
  "st-est00int-alldata.csv"    = file.path(base, "2000-2010/intercensal/state/st-est00int-alldata.csv"),
  "sc-est2020int-alldata6.csv" = file.path(base, "2010-2020/intercensal/state/asrh/sc-est2020int-alldata6.csv"),
  "cc-est2020int-alldata.csv"  = file.path(base, "2010-2020/intercensal/county/asrh/cc-est2020int-alldata.csv"),
  "us-est00int-alldata.csv"    = file.path(base, "2000-2010/intercensal/national/us-est00int-alldata.csv"))
for (nm in names(singles)) .fetch_one(singles[[nm]], nm, cache)

## The 51 per-state 2000-2010 county files (50 states + DC). FIPS set is fixed;
## assert 51 so a wrong list fails loud.
state_fips <- c("01","02","04","05","06","08","09","10","11","12","13","15","16",
                "17","18","19","20","21","22","23","24","25","26","27","28","29",
                "30","31","32","33","34","35","36","37","38","39","40","41","42",
                "44","45","46","47","48","49","50","51","53","54","55","56")
stopifnot(length(state_fips) == 51L)
for (fp in state_fips) {
  nm <- sprintf("co-est00int-alldata-%s.csv", fp)
  .fetch_one(file.path(base, "2000-2010/intercensal/county", nm), nm, cache)
}

## V2024 state + county (0.5.0 sources) -- fetched only if not already cached.
.fetch_one(file.path(base, "2020-2024/state/asrh/sc-est2024-alldata6.csv"),
           "sc-est2024-alldata6.csv", cache)
.fetch_one(file.path(base, "2020-2024/counties/asrh/cc-est2024-alldata.csv"),
           "cc-est2024-alldata.csv", cache)

message("backfill raw pull complete: ", length(Sys.glob(
  file.path(cache, "co-est00int-alldata-*.csv"))), " county files + state/national.")
