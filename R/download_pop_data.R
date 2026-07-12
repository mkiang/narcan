## Provenance-driven downloader + source accessor for the single-race population
## data (narcan 0.5.0). Small denominators ship as bundled .rda; the large
## county grain ships as a tag-pinned GitHub Release asset (parquet) fetched on
## demand and sha256-verified against the shipped manifest. raw = TRUE instead
## fetches the ORIGINAL public Census source files (the same pull the data-raw
## builders use) so a user can reproduce the processed data from scratch.
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

#' Download single-race population data (processed asset or raw source)
#'
#' Fetches population data that is too large to bundle. \code{raw = FALSE} (the
#' default) fetches the narcan-processed county parquet from the tag-pinned
#' GitHub Release asset and verifies its sha256 against the shipped manifest.
#' \code{raw = TRUE} instead fetches the ORIGINAL public Census source file(s)
#' verbatim -- the same pull the data-raw builders use -- so the processed data
#' can be reproduced and the fuller detail narcan drops (single-year age, the
#' all-origin and alone-or-in-combination columns) is available.
#'
#' Files cache under \code{tools::R_user_dir("narcan", "cache")}. Only bulk
#' flat-files are used (never the Census Data API); requests carry a generic
#' \code{narcan/<version>} User-Agent and no personal identifiers.
#'
#' @param scheme denominator scheme; only \code{"single"} is available in this
#'   release
#' @param years optional numeric vector; reserved for multi-file sources (the
#'   0.5.0 Census files are single files covering 2020-2024)
#' @param raw if \code{FALSE} (default), fetch the processed Release-asset
#'   parquet; if \code{TRUE}, fetch the original Census source file(s)
#' @param refresh re-download even if a cached copy exists
#' @param dest optional destination directory (default: the narcan cache)
#'
#' @return the local path(s) of the fetched file(s), invisibly
#' @export
#' @examples
#' \dontrun{
#' # processed county parquet (analysis-ready)
#' download_pop_data(scheme = "single")
#' # original Census source files (reproduce from scratch)
#' download_pop_data(scheme = "single", raw = TRUE)
#' }
download_pop_data <- function(scheme = "single", years = NULL, raw = FALSE,
                              refresh = FALSE, dest = NULL) {
    scheme <- match.arg(scheme, "single")
    m <- .pop_manifest()
    m <- m[m$scheme == scheme, , drop = FALSE]

    if (isTRUE(raw)) {
        rows <- m[nzchar(m$source_url), , drop = FALSE]
        rows <- rows[!duplicated(rows$source_url), , drop = FALSE]
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
