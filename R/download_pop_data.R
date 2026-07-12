## Provenance-driven downloader for the population denominators (narcan 0.5.x),
## serving BOTH schemes ("single" and "bridged"). Small denominators ship as
## bundled .rda; the large state/county grains ship as tag-pinned GitHub Release
## assets (parquet) fetched on demand and sha256-verified against the shipped
## manifest. raw = TRUE instead fetches the PRIMARY published source file(s) for
## the scheme (the recent-vintage pull only). It does NOT reproduce the
## multi-vintage backfill from scratch: the single-race processed data pools
## 2000-2019 Census intercensal inputs and bridged draws on more than one SEER
## extract, none of which the manifest lists. Point users at the data-raw
## builders for a full from-scratch rebuild.
##
## DUA/privacy: bulk flat-files only (NEVER the Census API), generic User-Agent
## (narcan/<version>), no personal identifiers in any outbound request.

.pop_manifest <- function() {
    ## Option hook lets a test (or an advanced user) point at a local manifest
    ## with file:// URLs, so the download/verify flow runs offline.
    f <- getOption("narcan.pop_manifest_path", default = NULL)
    if (is.null(f) || !nzchar(f)) {
        f <- system.file("extdata", "pop_manifest.csv", package = "narcan")
    }
    if (!nzchar(f)) {
        stop("narcan population manifest not found; reinstall the package.",
             call. = FALSE)
    }
    utils::read.csv(f, colClasses = "character")
}

.pop_cache_dir <- function(sub = NULL) {
    d <- tools::R_user_dir("narcan", "cache")
    if (!is.null(sub)) {
        d <- file.path(d, sub)
    }
    if (!dir.exists(d)) {
        dir.create(d, recursive = TRUE, showWarnings = FALSE)
    }
    d
}

.narcan_ua <- function() {
    v <- tryCatch(as.character(utils::packageVersion("narcan")),
                  error = function(e) NA_character_)
    if (is.na(v)) "narcan" else paste0("narcan/", v)
}

## sha256 of a file, using whatever is available without a hard dependency.
.sha256_file <- function(path) {
    if (getRversion() >= "4.5.0") {
        return(unname(tools::sha256sum(path)))
    }
    if (requireNamespace("openssl", quietly = TRUE)) {
        return(as.character(openssl::sha256(file(path))))
    }
    if (requireNamespace("digest", quietly = TRUE)) {
        return(digest::digest(path, algo = "sha256", file = TRUE))
    }
    NA_character_
}

.verify_sha256 <- function(path, expected, what) {
    if (is.na(expected) || !nzchar(expected)) {
        return(invisible(NULL))
    }
    got <- .sha256_file(path)
    if (is.na(got)) {
        ## Never keep an unverified download: fail loud rather than silently
        ## trust an unchecked file.
        stop(sprintf(paste0(
            "Cannot verify the sha256 of %s: no hasher available. Install ",
            "'openssl' or 'digest', or use R >= 4.5, then retry."), what),
            call. = FALSE)
    }
    if (!identical(tolower(got), tolower(expected))) {
        stop(sprintf(paste0(
            "sha256 mismatch for %s.\n  expected: %s\n  got:      %s\n",
            "The file may be corrupt or the manifest is stale; delete the ",
            "cached copy and retry."), what, expected, got), call. = FALSE)
    }
    invisible(NULL)
}

.download_file <- function(url, dest) {
    utils::download.file(url, dest, mode = "wb", quiet = TRUE,
                         method = "libcurl",
                         headers = c("User-Agent" = .narcan_ua()))
    if (!file.exists(dest) || file.size(dest) == 0) {
        stop(sprintf("download failed or produced an empty file: %s", url),
             call. = FALSE)
    }
    invisible(dest)
}

## Resolve (download + verify + cache) the SINGLE processed parquet asset for a
## given (scheme, grain). A scheme can carry several parquets (state + county),
## so the asset is selected by (scheme, grain) rather than "the first asset row"
## -- picking the first would silently return the wrong grain/coverage. Returns
## the local cached path.
.pop_asset_path <- function(scheme, grain, refresh = FALSE, dest = NULL) {
    m <- .pop_manifest()
    rows <- m[m$scheme == scheme & m$grain == grain & nzchar(m$asset_url), ,
              drop = FALSE]
    if (nrow(rows) == 0L) {
        stop(sprintf(paste0(
            "no downloadable %s %s parquet in the manifest (national/state ",
            "data may be bundled; see pop_sources())."), scheme, grain),
            call. = FALSE)
    }
    rows <- rows[!duplicated(rows[, c("asset_url", "asset_sha256")]), ,
                 drop = FALSE]
    ## D-COUNTYASSET (supersede): exactly one asset per (scheme, grain). Benign
    ## exact-duplicate rows (same URL AND sha256) were collapsed just above, so >1
    ## row here means genuinely ambiguous assets -- a different URL, OR the same
    ## URL with a conflicting sha256 -- refuse rather than silently taking the
    ## first. Guards 0.5.2's future assets too.
    if (nrow(rows) > 1L) {
        stop(sprintf(paste0(
            "pop manifest is ambiguous: %d distinct downloadable assets for ",
            "(scheme = %s, grain = %s); expected exactly one. Fix the manifest ",
            "so a single asset supersedes the rest."),
            nrow(rows), scheme, grain), call. = FALSE)
    }
    dir <- if (is.null(dest)) .pop_cache_dir() else dest
    if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    url <- rows$asset_url[1L]
    p <- file.path(dir, basename(url))
    if (refresh || !file.exists(p)) {
        .download_file(url, p)
    }
    .verify_sha256(p, rows$asset_sha256[1L], basename(url))
    p
}

#' Print the bundled population-data provenance manifest
#'
#' Shows every population dataset narcan can provide -- scheme, grain, vintage,
#' source URL, coverage, and delivery -- from the shipped
#' \code{inst/extdata/pop_manifest.csv}. Use it to check which vintage a bundled
#' dataset carries before mixing it with a freshly downloaded one.
#'
#' @return the manifest, invisibly, as a data frame
#' @export
#' @examples
#' pop_sources()
pop_sources <- function() {
    m <- .pop_manifest()
    show <- m[, c("dataset", "scheme", "grain", "vintage", "year_min",
                  "year_max", "n_rows", "note")]
    print(show, row.names = FALSE)
    invisible(m)
}

#' Download population data (processed asset or primary source)
#'
#' Fetches population denominators that are too large to bundle, for either
#' scheme. \code{raw = FALSE} (the default) fetches the narcan-processed
#' Release-asset parquet(s) (state and/or county) for the scheme and verifies
#' each sha256 against the shipped manifest. \code{raw = TRUE} instead fetches
#' the PRIMARY published source file(s) for the scheme -- Census PEP for
#' \code{"single"}, SEER for \code{"bridged"} -- verbatim.
#'
#' \code{raw = TRUE} returns the recent-vintage source only and does NOT fully
#' reproduce the multi-vintage backfill: the single-race processed data
#' (2000-2024) pools 2000-2019 Census intercensal inputs and the bridged data
#' (1969-2024) draws on more than one SEER extract, none of which the manifest
#' lists. For a complete from-scratch rebuild use the \code{data-raw/} builders.
#' \code{raw = TRUE} emits a one-time message saying as much, so an incomplete
#' pull never silently looks complete.
#'
#' Files cache under \code{tools::R_user_dir("narcan", "cache")}. Only bulk
#' flat-files are used (never the Census Data API); requests carry a generic
#' \code{narcan/<version>} User-Agent and no personal identifiers.
#'
#' @param scheme denominator scheme: \code{"single"} (default) or
#'   \code{"bridged"}
#' @param raw if \code{FALSE} (default), fetch the narcan-processed
#'   Release-asset parquet(s) for the scheme; if \code{TRUE}, fetch the primary
#'   published source file(s) only (not a full from-scratch reproduction of the
#'   backfill -- see Details)
#' @param refresh re-download even if a cached copy exists
#' @param dest optional destination directory (default: the narcan cache)
#'
#' @return the local path(s) of the fetched file(s), invisibly
#' @export
#' @examples
#' \dontrun{
#' # processed parquet(s) for the scheme (analysis-ready)
#' download_pop_data(scheme = "single")
#' # primary published source file(s) (recent vintage only; see Details)
#' download_pop_data(scheme = "single", raw = TRUE)
#' }
download_pop_data <- function(scheme = c("single", "bridged"),
                              raw = FALSE, refresh = FALSE, dest = NULL) {
    scheme <- match.arg(scheme)
    m <- .pop_manifest()
    m <- m[m$scheme == scheme, , drop = FALSE]

    if (isTRUE(raw)) {
        ## Be loud about what raw = TRUE actually returns: the primary,
        ## recent-vintage source(s) the manifest lists -- NOT the full
        ## multi-vintage backfill. Once per session per scheme, so an incomplete
        ## pull never silently looks like a from-scratch reproduction.
        detail <- if (identical(scheme, "single")) {
            paste0("the 2000-2024 single-race backfill also pools 2000-2019 ",
                   "Census intercensal inputs the manifest does not list")
        } else {
            paste0("the 1969-2024 bridged backfill also draws on more than one ",
                   "SEER extract the manifest does not list")
        }
        .inform_once(paste0("download_pop_data_raw_incomplete_", scheme),
            sprintf(paste0(
                "download_pop_data(raw = TRUE) returns the primary published ",
                "source file(s) for scheme \"%s\" (recent vintage only). This ",
                "is NOT a complete from-scratch reproduction: %s. Use the ",
                "data-raw/ builders for a full rebuild."), scheme, detail))
        rows <- m[nzchar(m$source_url), , drop = FALSE]
        ## Benign exact-duplicate rows (same URL AND sha256) collapse here.
        rows <- rows[!duplicated(rows[, c("source_url", "source_sha256")]), ,
                     drop = FALSE]
        ## Mirror .pop_asset_path's ambiguity guard: >1 row surviving for the
        ## SAME source_url means the sha256 disagrees across rows -- refuse
        ## rather than silently keeping whichever row duplicated() saw first.
        dup_url <- unique(rows$source_url[duplicated(rows$source_url)])
        if (length(dup_url) > 0L) {
            stop(sprintf(paste0(
                "pop manifest is ambiguous: source_url %s has more than one ",
                "distinct source_sha256 for scheme = %s; expected exactly one. ",
                "Fix the manifest so a single source_sha256 supersedes the rest."),
                paste(dup_url, collapse = ", "), scheme),
                call. = FALSE)
        }
        dir <- if (is.null(dest)) .pop_cache_dir("raw") else dest
        if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
        paths <- vapply(seq_len(nrow(rows)), function(i) {
            url <- rows$source_url[i]
            p <- file.path(dir, basename(url))
            if (refresh || !file.exists(p)) {
                .download_file(url, p)
            }
            .verify_sha256(p, rows$source_sha256[i], basename(url))
            p
        }, character(1))
        return(invisible(stats::setNames(paths, rows$dataset)))
    }

    ## Processed asset(s): the rows that carry an asset_url (county parquet).
    rows <- m[nzchar(m$asset_url), , drop = FALSE]
    if (nrow(rows) == 0L) {
        stop("download_pop_data(): no downloadable processed asset for scheme ",
             sprintf("\"%s\"; national/state data are bundled with the ", scheme),
             "package (see pop_singlerace / pop_singlerace_state).",
             call. = FALSE)
    }
    dir <- if (is.null(dest)) .pop_cache_dir() else dest
    if (!dir.exists(dir)) dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    paths <- vapply(seq_len(nrow(rows)), function(i) {
        url <- rows$asset_url[i]
        p <- file.path(dir, basename(url))
        if (refresh || !file.exists(p)) {
            .download_file(url, p)
        }
        .verify_sha256(p, rows$asset_sha256[i], basename(url))
        p
    }, character(1))
    invisible(stats::setNames(paths, rows$dataset))
}
