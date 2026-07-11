#' Retrieve state-level single-race population denominators
#'
#' A thin, dependency-free accessor over the bundled
#' \code{narcan::pop_singlerace_state} table (Census PEP Vintage 2024,
#' 2020-2024). Unlike \code{add_pop_counts()}, this returns population rows for
#' descriptive use and exposes the Hispanic-origin dimension. It does NOT guard a
#' death-side join -- validate uniqueness/coverage yourself if you hand-join.
#'
#' @param scheme denominator scheme; only \code{"single"} is available in this
#'   release
#' @param states optional character vector of 2-digit state FIPS codes to keep
#'   (default: all states)
#' @param years optional numeric vector of years to keep (default: all,
#'   2020-2024)
#' @param hispanic_origin \code{"all"} (default; sums the origin dimension),
#'   \code{"non_hispanic"}, or \code{"hispanic"}
#'
#' @return a tibble with columns \code{state_fips}, \code{year}, \code{age},
#'   \code{sex}, \code{race}, \code{hispanic_origin}, \code{pop}, and metadata
#' @importFrom dplyr group_by across all_of summarize mutate
#' @export
#' @examples
#' get_pop_state(states = "06", years = 2024)
get_pop_state <- function(scheme = "single", states = NULL, years = NULL,
                          hispanic_origin = c("all", "non_hispanic",
                                              "hispanic")) {
    scheme <- match.arg(scheme, "single")
    hispanic_origin <- match.arg(hispanic_origin)

    x <- tibble::as_tibble(narcan::pop_singlerace_state)
    if (!is.null(states)) {
        x <- x[x$state_fips %in% states, , drop = FALSE]
    }
    if (!is.null(years)) {
        x <- x[x$year %in% years, , drop = FALSE]
    }
    .collapse_origin(x, hispanic_origin,
                     c("state_fips", "year", "age", "sex", "race"))
}

#' Retrieve county-level single-race population denominators
#'
#' Reads the county single-race parquet (Census PEP Vintage 2024, 2020-2024) with
#' DuckDB predicate pushdown. The county table is too large to bundle, so it is
#' fetched once from the tag-pinned GitHub Release asset and cached (see
#' \code{download_pop_data()}); pass \code{parquet} to read a local copy instead.
#' Like \code{get_pop_state()}, this returns population rows for descriptive use
#' and does NOT guard a hand-join.
#'
#' @param scheme denominator scheme; only \code{"single"} is available
#' @param states optional 2-digit state FIPS codes to keep
#' @param counties optional 5-digit county FIPS codes to keep
#' @param years optional numeric vector of years to keep
#' @param hispanic_origin \code{"all"} (default), \code{"non_hispanic"}, or
#'   \code{"hispanic"}
#' @param parquet optional path to a local county parquet (default: the cached
#'   Release asset, downloaded on first use)
#'
#' @return a tibble with the county single-race schema plus metadata
#' @importFrom dplyr group_by across all_of summarize mutate
#' @export
#' @examples
#' \dontrun{
#' get_pop_county(states = "06", years = 2024)
#' }
get_pop_county <- function(scheme = "single", states = NULL, counties = NULL,
                           years = NULL,
                           hispanic_origin = c("all", "non_hispanic",
                                               "hispanic"),
                           parquet = NULL) {
    scheme <- match.arg(scheme, "single")
    hispanic_origin <- match.arg(hispanic_origin)
    x <- .load_pop_county(scheme = scheme, states = states, counties = counties,
                          years = years, parquet = parquet)
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

## Internal: read the finest-cell county rows (BOTH origins) from the parquet,
## with DuckDB predicate pushdown. Used by get_pop_county() (which then collapses
## origin) and by add_pop_counts()'s county routing (which passes the finest
## cells to .guarded_pop_join() so Hispanic origin is pinned there). Resolution
## order for the parquet: explicit arg -> option (test hook) -> cached Release
## asset (downloaded on cache miss).
.load_pop_county <- function(scheme = "single", states = NULL, counties = NULL,
                             years = NULL, parquet = NULL) {
    if (!requireNamespace("duckdb", quietly = TRUE) ||
        !requireNamespace("DBI", quietly = TRUE)) {
        stop("get_pop_county() needs the 'duckdb' package (in Suggests). ",
             "Install it with install.packages(\"duckdb\").", call. = FALSE)
    }
    if (is.null(parquet)) {
        parquet <- getOption("narcan.pop_county_parquet", default = NULL)
    }
    if (is.null(parquet)) {
        parquet <- tryCatch(
            unname(download_pop_data(scheme = scheme))[[1L]],
            error = function(e) {
                stop("get_pop_county(): could not obtain the county parquet ",
                     "(offline and not cached?). ", conditionMessage(e),
                     call. = FALSE)
            })
    }
    if (!file.exists(parquet)) {
        stop(sprintf("get_pop_county(): county parquet not found at %s.",
                     parquet), call. = FALSE)
    }

    ## SQL string literals (single-quoted, escaped) -- shQuote's OS convention
    ## would use double quotes (identifiers) on Windows.
    sqlq <- function(x) paste0("'", gsub("'", "''", x), "'")

    con <- DBI::dbConnect(duckdb::duckdb())
    on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
    where <- character()
    if (!is.null(states)) {
        where <- c(where, sprintf("state_fips IN (%s)",
                                  paste(sqlq(states), collapse = ", ")))
    }
    if (!is.null(counties)) {
        where <- c(where, sprintf("county_fips IN (%s)",
                                  paste(sqlq(counties), collapse = ", ")))
    }
    if (!is.null(years)) {
        where <- c(where, sprintf("year IN (%s)",
                                  paste(as.integer(years), collapse = ", ")))
    }
    wsql <- if (length(where)) paste("WHERE", paste(where, collapse = " AND ")) else ""
    sql <- sprintf("SELECT * FROM read_parquet(%s) %s", sqlq(parquet), wsql)
    tibble::as_tibble(DBI::dbGetQuery(con, sql))
}
