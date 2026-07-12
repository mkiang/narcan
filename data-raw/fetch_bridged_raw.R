## PULL step (pull-from-parse) for the narcan 0.5.1 SEER-uniform bridged
## population denominators: fetch BOTH raw SEER U.S. Population Data files into
## the cache so build_pop_bridged.R can parse them network-free.
##
## build_pop_bridged.R needs TWO SEER source files, but only ONE is registered
## in inst/extdata/pop_manifest.csv:
##   - us.1969_2024.20ages.adjusted.txt.gz -- IS in the manifest (`source_url`
##     on the bridged rows) and IS fetched by
##     download_pop_data(scheme = "bridged", raw = TRUE).
##   - us.1990_2024.20ages.adjusted.txt.gz -- NOT in the manifest (no
##     download_pop_data() route reaches it); this script fetches it directly
##     from the same SEER "yr<span>.20ages" naming convention as the 1969 file.
## Both must sit in the cache before build_pop_bridged.R will run past its
## `stopifnot(file.exists(raw_1969), file.exists(raw_1990))` guard.
##
## Public aggregates, bulk flat-files ONLY (never a Census/SEER API). Reuses the
## package's own .download_file() (generic `narcan/<version>` User-Agent, no
## personal identifier), so the outbound-request discipline matches
## download_pop_data(). Idempotent: skip-if-cached; on any fetch failure it
## STOPs loudly, naming the file (so a missing SEER file never becomes a silent
## gap). This script does NOT ship (data-raw/ is .Rbuildignore'd) and does NOT
## touch inst/extdata/pop_manifest.csv. Run from the package root.

pkgload::load_all(".", quiet = TRUE)

cache <- Sys.getenv("NARCAN_SEER_CACHE",
                    file.path(tools::R_user_dir("narcan", "cache"), "raw"))
dir.create(cache, showWarnings = FALSE, recursive = TRUE)
base <- "https://seer.cancer.gov/popdata"

## A cached .txt.gz counts as complete only if it is non-trivially sized AND
## starts with the gzip magic bytes (0x1f 0x8b). Guards against a truncated
## download (non-empty but cut short) being cached permanently under
## skip-if-cached, and against an HTML soft-error page.
## 1e7 floor: the smaller (1990-2024) file is ~75MB gzipped, so 10MB leaves
## comfortable headroom while still rejecting a short/garbled response.
.looks_complete <- function(path) {
  if (!file.exists(path) || file.size(path) < 1e7) return(FALSE)
  magic <- tryCatch(readBin(path, "raw", n = 2L), error = function(e) raw())
  length(magic) == 2L && identical(magic, as.raw(c(0x1f, 0x8b)))
}

## Per-file helper (mirrors fetch_singlerace_backfill_raw.R's .fetch_one):
## fetch `url` -> `cache/name` unless a COMPLETE copy is already cached; STOP
## with an informative message on failure or on an incomplete result (never
## cache a truncated file).
.fetch_one <- function(url, name, cache) {
  dest <- file.path(cache, name)
  if (.looks_complete(dest)) return(invisible(dest))
  if (file.exists(dest)) unlink(dest)              # drop a truncated cached copy
  ok <- tryCatch({ narcan:::.download_file(url, dest); TRUE },
                 error = function(e) FALSE)
  if (!ok || !.looks_complete(dest)) {
    if (file.exists(dest)) unlink(dest)
    stop(sprintf("fetch failed or incomplete for %s (%s) -- the bridged raw ",
                 name, url), "pull is incomplete; re-run after checking the ",
         "URL/network.", call. = FALSE)
  }
  invisible(dest)
}

## 1969-2024 (registered in the manifest; same file download_pop_data(scheme =
## "bridged", raw = TRUE) fetches -- refetched here only if not already cached).
.fetch_one(file.path(base, "yr1969_2024.20ages",
                     "us.1969_2024.20ages.adjusted.txt.gz"),
          "us.1969_2024.20ages.adjusted.txt.gz", cache)

## 1990-2024 (NOT in the manifest -- build_pop_bridged.R's second required
## file; download_pop_data() has no route to it, so it is fetched directly here).
.fetch_one(file.path(base, "yr1990_2024.20ages",
                     "us.1990_2024.20ages.adjusted.txt.gz"),
          "us.1990_2024.20ages.adjusted.txt.gz", cache)

message("bridged raw pull complete: ", length(Sys.glob(
  file.path(cache, "us.19*_2024.20ages.adjusted.txt.gz"))),
  " SEER file(s) cached at ", cache, ". The 1990-2024 file has no manifest ",
  "entry to auto-verify against -- eyeball its sha256 before trusting the ",
  "parse (tools::sha256sum()).")
