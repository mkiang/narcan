#' Collapse hspanicr to the binary Hispanic-origin axis (for population joins)
#'
#' Maps the NCHS `hspanicr` (Hispanic Origin/Race Recode) to the binary
#' Hispanic-origin axis the population denominators use: \code{"hispanic"},
#' \code{"non_hispanic"}, or \code{"unknown"} (and \code{NA} where origin is not
#' recorded). This is the death-side counterpart of the \code{hispanic_origin}
#' dimension in \code{\link{pop_bridged}} / \code{\link{pop_singlerace_full}}, so
#' a death frame carrying a \code{hispanic_origin} column can be joined to
#' Hispanic-stratified denominators via \code{\link{add_pop_counts}}.
#'
#' Unlike \code{\link{categorize_hspanicr}} (which returns the full 9- or
#' 14-category ethnicity recode, for descriptive counts and proportions that have
#' no matching denominator), this returns only the two-level origin axis that
#' Census/SEER resolve, so it is the recode to use when computing \emph{rates}.
#'
#' The recode is year-dependent: a 9-category scheme for 1989-2020, reserved (not
#' populated) in 2021, and an expanded 14-category scheme from 2022. In every
#' scheme the Hispanic subgroups (including "Other or unknown Hispanic") map to
#' \code{"hispanic"}, the non-Hispanic categories to \code{"non_hispanic"}, and
#' "Hispanic origin unknown" to \code{"unknown"}. Rows with no recorded origin
#' (pre-1989, 2021, or a code outside the year's valid range) return \code{NA};
#' an out-of-range code additionally warns.
#'
#' @param hspanicr_column hspanicr column from an MCOD dataframe.
#' @param year data year(s); a single value or a vector aligned to
#'   \code{hspanicr_column}. Required (no default) so the 9- vs 14-category
#'   scheme is selected correctly.
#'
#' @return a character vector of \code{"hispanic"} / \code{"non_hispanic"} /
#'   \code{"unknown"} / \code{NA}, matching the population tables' labels.
#' @seealso \code{\link{categorize_hspanicr}} for the full 9/14-category
#'   ethnicity recode; \code{\link{add_hispanic_origin}} to add this as a column;
#'   \code{\link{add_pop_counts}} for the Hispanic-stratified population join.
#' @export
#'
#' @examples
#' categorize_hispanic_origin(c(1, 5, 6, 9), year = 2019)
#' categorize_hispanic_origin(c(1, 7, 8, 14), year = 2023)
categorize_hispanic_origin <- function(hspanicr_column, year) {
    if (missing(year) || is.null(year)) {
        stop("categorize_hispanic_origin(): `year` is required (no default). ",
             "Pass the data year(s) so the 9-category (1989-2020) vs ",
             "14-category (2022+) hspanicr scheme is selected correctly.",
             call. = FALSE)
    }

    code <- as.integer(hspanicr_column)
    n <- length(code)
    yr <- suppressWarnings(as.integer(as.numeric(as.character(year))))
    if (length(yr) == 1L) {
        yr <- rep(yr, n)
    } else if (length(yr) != n) {
        stop("categorize_hispanic_origin(): `year` must be length 1 or the ",
             "same length as `hspanicr_column`.", call. = FALSE)
    }

    ## Detailed label from the year-aware recode. suppressWarnings() so
    ## categorize_hspanicr()'s own reserved-2021 warning stays silent here (2021
    ## is an intended silent NA per the frozen oracle 81_hspanicr_origin_oracle).
    lab <- suppressWarnings(
        as.character(categorize_hspanicr(hspanicr_column, year = yr)))

    ## String-keyed label -> binary origin. Keyed on the label STRING, never the
    ## factor's integer position: categorize_hspanicr()'s levels REORDER in a
    ## mixed-era call (the union-levels path), so a position index would mis-map
    ## a bind_rows(9-cat, 14-cat) frame. Covers every level the recode emits.
    origin_map <- c(
        mexican = "hispanic", puerto_rican = "hispanic", cuban = "hispanic",
        central_south_america = "hispanic", dominican = "hispanic",
        central_american = "hispanic", south_american = "hispanic",
        other_hispanic = "hispanic",
        nonhispanic_white = "non_hispanic", nonhispanic_black = "non_hispanic",
        nonhispanic_other = "non_hispanic", nonhispanic_aian = "non_hispanic",
        nonhispanic_asian = "non_hispanic", nonhispanic_nhopi = "non_hispanic",
        nonhispanic_multi = "non_hispanic",
        hispanic_unknown = "unknown")

    ## Fail loud if categorize_hspanicr() ever emits a label this lookup does not
    ## classify (e.g. a future recode adds a level) -- a hard error beats a
    ## silent NA origin. NA labels (pre-1989/2021/out-of-range) are exempt.
    produced <- unique(lab[!is.na(lab)])
    unmapped <- setdiff(produced, names(origin_map))
    if (length(unmapped) > 0L) {
        stop(sprintf(paste0(
            "categorize_hispanic_origin(): unclassified hspanicr label(s): %s. ",
            "The origin lookup is out of sync with categorize_hspanicr()."),
            paste(shQuote(unmapped), collapse = ", ")), call. = FALSE)
    }

    out <- unname(origin_map[lab])

    ## Out-of-range warning, computed independently (categorize_hspanicr() NAs a
    ## bad code silently) and NA-safely (`yr >= 2022` is NA on an NA year, which
    ## would make `any()` return NA): a non-NA code in a valid scheme year that
    ## yields no label is out of range.
    in_scheme <- !is.na(yr) & ((yr >= 1989 & yr <= 2020) | yr >= 2022)
    oor <- !is.na(code) & in_scheme & is.na(lab)
    if (any(oor)) {
        warning(sprintf(paste0(
            "categorize_hispanic_origin(): %d hspanicr value(s) are outside the ",
            "valid code range for their data year and were set to NA."),
            sum(oor)), call. = FALSE)
    }

    out
}
