#' Retrieve state-level population denominators
#'
#' A descriptive accessor over the state population denominators. For
#' \code{scheme = "single"} it reads the bundled, dependency-free
#' \code{narcan::pop_singlerace_state} table (Census PEP) when the requested
#' \code{years} stay inside the frozen 2020-2024 window (the default), and the
#' single-race backfill parquet (2000-2024) when any pre-2020 year is requested
#' or a \code{parquet} is supplied (which needs the \code{duckdb} package). For
#' \code{scheme = "bridged"} it reads the SEER-uniform bridged state parquet
#' (1969-2024), fetched once from the tag-pinned GitHub Release asset and cached
#' (see \code{download_pop_data()}). Unlike \code{add_pop_counts()}, this returns
#' population rows for descriptive use and exposes the Hispanic-origin dimension.
#' It does NOT guard a death-side join -- validate uniqueness/coverage yourself
#' if you hand-join.
#'
#' Note the default-span asymmetry between schemes: \code{scheme = "single"}
#' defaults to the frozen 5-year window (2020-2024; pass pre-2020 \code{years}
#' to reach the 2000-2024 backfill), whereas \code{scheme = "bridged"} defaults
#' to its full 56-year span (1969-2024).
#'
#' @param scheme denominator scheme: \code{"single"} (default) or
#'   \code{"bridged"}
#' @param states optional character vector of 2-digit state FIPS codes to keep
#'   (default: all states)
#' @param years optional numeric vector of years to keep (default: all covered
#'   for bridged; the frozen 2020-2024 window for single -- request pre-2020
#'   years to reach the backfill)
#' @param hispanic_origin \code{"all"} (default; sums the origin dimension),
#'   \code{"non_hispanic"}, or \code{"hispanic"}. Bridged pre-1990 rows carry
#'   only \code{"all"} (SEER has no Hispanic origin before 1990).
#' @param parquet optional path to a local state parquet (single-race backfill
#'   or bridged); default resolves the cached Release asset when the request
#'   falls outside the bundled frozen window
#'
#' @return a tibble with columns \code{state_fips}, \code{year}, \code{age},
#'   \code{sex}, \code{race}, \code{hispanic_origin}, \code{pop}, and metadata
#' @seealso \code{\link{add_pop_counts}} for the death-to-population JOIN, which
#'   keys on a \code{hispanic_origin} COLUMN in \code{by_vars}; this accessor
#'   instead takes a \code{hispanic_origin=} filter ARGUMENT (same name, different
#'   mechanism).
#' @importFrom dplyr group_by across all_of summarize mutate
#' @export
#' @examples
#' get_pop_state(states = "06", years = 2024)
get_pop_state <- function(scheme = c("single", "bridged"), states = NULL,
                          years = NULL,
                          hispanic_origin = c("all", "non_hispanic",
                                              "hispanic"),
                          parquet = NULL) {
    scheme <- match.arg(scheme)
    hispanic_origin <- match.arg(hispanic_origin)

    if (identical(scheme, "single")) {
        ## Default to the frozen dependency-free table; widen to the *_full
        ## backfill parquet only when a pre-2020 year is requested (factor-safe
        ## idiom) or an explicit parquet is supplied.
        pre2020 <- !is.null(years) &&
            any(suppressWarnings(as.numeric(as.character(years))) < 2020,
                na.rm = TRUE)
        if (pre2020 || !is.null(parquet)) {
            x <- .load_pop_parquet(scheme = "single", grain = "state",
                                   states = states, years = years,
                                   parquet = parquet)
        } else {
            x <- tibble::as_tibble(narcan::pop_singlerace_state)
            if (!is.null(states)) {
                x <- x[x$state_fips %in% states, , drop = FALSE]
            }
            if (!is.null(years)) {
                yy <- suppressWarnings(as.numeric(as.character(years)))
                ## Fail LOUD on an out-of-coverage year, mirroring the parquet
                ## coverage guard (the frozen branch is only reached with years
                ## >= 2020, so any miss is past the frozen 2020-2024 window). A
                ## silent 0-row return would otherwise be a MISSING denominator.
                ## Derive coverage from the STATE table being filtered just below
                ## (not .narrow_single_years(), which reads the NATIONAL
                ## pop_singlerace table) -- both happen to span 2020-2024 today,
                ## but deriving from the table actually filtered here means the
                ## guard cannot drift out of sync with it.
                cov <- sort(unique(narcan::pop_singlerace_state$year))
                miss <- sort(setdiff(yy, cov))
                if (length(miss) > 0L) {
                    stop(sprintf(paste0(
                        "get_pop_state(): single-race state denominators cover ",
                        "%d-%d; year(s) %s were requested (pre-2020 years route to ",
                        "the backfill; there is no coverage past %d)."),
                        min(cov), max(cov), paste(miss, collapse = ", "),
                        max(cov)), call. = FALSE)
                }
                x <- x[x$year %in% yy, , drop = FALSE]
            }
        }
    } else {
        x <- .load_pop_parquet(scheme = "bridged", grain = "state",
                               states = states, years = years,
                               parquet = parquet)
    }
    .collapse_origin(x, hispanic_origin,
                     c("state_fips", "year", "age", "sex", "race"))
}

#' Retrieve county-level population denominators
#'
#' Reads the county population parquet with DuckDB predicate pushdown. The county
#' table is too large to bundle, so it is fetched once from the tag-pinned GitHub
#' Release asset and cached (see \code{download_pop_data()}); pass \code{parquet}
#' to read a local copy instead. Like \code{get_pop_state()}, this returns
#' population rows for descriptive use and does NOT guard a hand-join.
#'
#' Default-span asymmetry (mirrors \code{get_pop_state()}): with
#' \code{scheme = "single"} and no \code{years}, this defaults to the frozen
#' 2020-2024 window; request pre-2020 \code{years} to reach the 2000-2024
#' backfill. \code{scheme = "bridged"} defaults to its full 1969-2024 span.
#'
#' @param scheme denominator scheme: \code{"single"} (default) or
#'   \code{"bridged"}
#' @param states optional 2-digit state FIPS codes to keep
#' @param counties optional 5-digit county FIPS codes to keep
#' @param years optional numeric vector of years to keep (single-race defaults
#'   to the frozen 2020-2024 window; request pre-2020 years for the backfill)
#' @param hispanic_origin \code{"all"} (default), \code{"non_hispanic"}, or
#'   \code{"hispanic"}
#' @param parquet optional path to a local county parquet (default: the cached
#'   Release asset, downloaded on first use)
#'
#' @return a tibble with the county population schema plus metadata
#' @seealso \code{\link{add_pop_counts}} for the death-to-population JOIN, which
#'   keys on a \code{hispanic_origin} COLUMN in \code{by_vars}; this accessor
#'   instead takes a \code{hispanic_origin=} filter ARGUMENT (same name, different
#'   mechanism).
#' @importFrom dplyr group_by across all_of summarize mutate
#' @export
#' @examples
#' \dontrun{
#' get_pop_county(states = "06", years = 2024)
#' }
get_pop_county <- function(scheme = c("single", "bridged"), states = NULL,
                           counties = NULL, years = NULL,
                           hispanic_origin = c("all", "non_hispanic",
                                               "hispanic"),
                           parquet = NULL) {
    scheme <- match.arg(scheme)
    hispanic_origin <- match.arg(hispanic_origin)
    ## D-COUNTYDEFAULT: single-race county defaults to the frozen narrow window
    ## (2020-2024, derived from the frozen coverage, not a literal); pre-2020 is
    ## opt-in via years=. Bridged defaults to its full span.
    if (identical(scheme, "single") && is.null(years)) {
        years <- .narrow_single_years()
    }
    x <- .load_pop_parquet(scheme = scheme, grain = "county", states = states,
                           counties = counties, years = years, parquet = parquet)
    .collapse_origin(x, hispanic_origin,
                     c("state_fips", "county_fips", "year", "age", "sex",
                       "race"))
}

## Shared origin collapse/filter for the descriptive accessors: "all" sums the
## origin dimension (carrying the constant metadata through the grouping);
## otherwise filter to that origin level.
.collapse_origin <- function(x, hispanic_origin, keys) {
    if (identical(hispanic_origin, "all")) {
        meta <- intersect(c("scheme", "source", "vintage"), names(x))
        x |>
            dplyr::group_by(dplyr::across(dplyr::all_of(c(keys, meta)))) |>
            dplyr::summarize(pop = sum(pop), .groups = "drop") |>
            dplyr::mutate(hispanic_origin = "all")
    } else {
        x[x$hispanic_origin == hispanic_origin, , drop = FALSE]
    }
}

## Internal: read the finest-cell rows (BOTH origins) from a population parquet at
## a given grain ("state" or "county"), with DuckDB predicate pushdown. Used by
## the descriptive accessors (which then collapse origin) and by
## add_pop_counts()'s geography routing (which passes the finest cells to
## .guarded_pop_join(), where origin is kept as a join key when the death frame
## is stratified and collapsed to "all" only when it is all-origin). Resolution order for
## the parquet: explicit arg -> option (test hook
## narcan.pop_<scheme>_<grain>_parquet) -> the cached Release asset for (scheme,
## grain), downloaded on cache miss.
## Selecting by (scheme, grain) -- not the first asset row -- so a scheme with
## several parquets (state + county) resolves the right one.
.load_pop_parquet <- function(scheme = "single", grain = c("county", "state"),
                              states = NULL, counties = NULL, years = NULL,
                              parquet = NULL) {
    grain <- match.arg(grain)
    if (!requireNamespace("duckdb", quietly = TRUE) ||
        !requireNamespace("DBI", quietly = TRUE)) {
        stop("get_pop_county()/get_pop_state(scheme=\"bridged\") needs the ",
             "'duckdb' package (in Suggests). Install it with ",
             "install.packages(\"duckdb\").", call. = FALSE)
    }
    if (is.null(parquet)) {
        parquet <- getOption(paste0("narcan.pop_", scheme, "_", grain,
                                    "_parquet"), default = NULL)
    }
    if (is.null(parquet)) {
        parquet <- tryCatch(
            .pop_asset_path(scheme = scheme, grain = grain),
            error = function(e) {
                stop(sprintf(paste0(
                    "get_pop_%s(): could not obtain the %s %s parquet (offline ",
                    "and not cached?). %s"), grain, scheme, grain,
                    conditionMessage(e)), call. = FALSE)
            })
    }
    if (!file.exists(parquet)) {
        stop(sprintf("get_pop_%s(): %s parquet not found at %s.", grain, grain,
                     parquet), call. = FALSE)
    }

    yi <- NULL
    if (!is.null(years)) {
        ## Factor-safe: as.integer() on a factor returns level CODES, not the
        ## years, so route through as.character() first (project idiom). Reused
        ## for the WHERE clause below so both see the same coerced values.
        yi <- suppressWarnings(as.integer(as.numeric(as.character(years))))
        if (anyNA(yi)) {
            stop(sprintf(paste0("get_pop_%s(): `years` must be numeric year(s) ",
                                "(e.g. 2020:2024)."), grain), call. = FALSE)
        }
        if (length(yi) == 0L) {
            stop(sprintf(paste0("get_pop_%s(): `years` is empty (length 0). Pass ",
                                "at least one year, or NULL for all covered."),
                         grain), call. = FALSE)
        }
    }

    ## SQL string literals (single-quoted, escaped) -- shQuote's OS convention
    ## would use double quotes (identifiers) on Windows.
    sqlq <- function(x) paste0("'", gsub("'", "''", x), "'")

    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)

    ## Coverage guard: a resolved asset must actually cover every requested year.
    ## The descriptive accessors do NOT guard result completeness, so a stale/short
    ## OR non-contiguous asset -- e.g. a manifest row still pointing at a 0.5.0
    ## 2020-2024 parquet before the 2000-2024 backfill is published, or a
    ## partially-appended download with an interior gap -- would otherwise return a
    ## SILENT empty/short slice instead of erroring. Checks year MEMBERSHIP (every
    ## requested year present), not just the MIN/MAX range, so a mid-range hole is
    ## caught too (does not rely on the contiguity invariant).
    if (!is.null(yi)) {
        have <- DBI::dbGetQuery(con, sprintf(
            "SELECT DISTINCT year FROM read_parquet(%s)", sqlq(parquet)))$year
        miss <- sort(setdiff(yi, have))
        if (length(miss) > 0L) {
            span <- if (length(have)) {
                sprintf("%d-%d", as.integer(min(have)), as.integer(max(have)))
            } else {
                "no years"
            }
            stop(sprintf(paste0(
                "get_pop_%s(): the resolved %s %s parquet does not cover year(s) ",
                "%s (it holds %s). The asset may be stale or non-contiguous (a ",
                "0.5.0 2020-2024 parquet before the 2000-2024 backfill, or a ",
                "partial download). Pass an up-to-date `parquet=` or refresh the ",
                "cached download."),
                grain, scheme, grain, paste(miss, collapse = ", "), span),
                call. = FALSE)
        }
    }

    where <- character()
    if (!is.null(states)) {
        where <- c(where, sprintf("state_fips IN (%s)",
                                  paste(sqlq(states), collapse = ", ")))
    }
    ## county_fips only exists in the county grain -- never reference it for state.
    if (!is.null(counties) && identical(grain, "county")) {
        where <- c(where, sprintf("county_fips IN (%s)",
                                  paste(sqlq(counties), collapse = ", ")))
    }
    if (!is.null(years)) {
        where <- c(where, sprintf("year IN (%s)",
                                  paste(yi, collapse = ", ")))
    }
    wsql <- if (length(where)) paste("WHERE", paste(where, collapse = " AND ")) else ""
    sql <- sprintf("SELECT * FROM read_parquet(%s) %s", sqlq(parquet), wsql)
    tibble::as_tibble(DBI::dbGetQuery(con, sql))
}
