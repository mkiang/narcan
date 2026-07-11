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

    if (identical(hispanic_origin, "all")) {
        ## Sum the origin dimension; carry the (constant) metadata through the
        ## grouping so nothing is hardcoded.
        x <- x |>
            dplyr::group_by(dplyr::across(dplyr::all_of(
                c("state_fips", "year", "age", "sex", "race",
                  "scheme", "source", "vintage")))) |>
            dplyr::summarize(pop = sum(pop), .groups = "drop") |>
            dplyr::mutate(hispanic_origin = "all")
    } else {
        x <- x[x$hispanic_origin == hispanic_origin, , drop = FALSE]
    }
    x
}
