#' Join population denominators to a death frame
#'
#' Attaches a \code{pop} column of population estimates matched on \code{by_vars}.
#' Two denominator schemes are available; both route through the single guarded
#' join so the same correctness guards always apply.
#'
#' \code{race_scheme = "legacy"} (default) joins the frozen bridged-race
#' \code{narcan::pop_est} (1979-2020) and reproduces the historical behavior
#' byte-for-byte: unmatched keys warn and leave \code{pop = NA}. Use this to
#' reproduce published bridged-race rates.
#'
#' \code{race_scheme = "single"} joins the single-race denominators
#' (\code{pop_singlerace}, 2020-2024) for deaths coded with \code{remap_race()}
#' /\code{categorize_race()} codes 101-106. This scheme is strict: it guarantees
#' no silent NA denominator, so out-of-domain \code{age}/\code{sex}/\code{race}
#' values hard-error rather than passing through. Geography is routed by
#' \code{by_vars} membership -- include \code{state_fips} for state denominators
#' or \code{county_fips} (5-digit, as produced by \code{add_county_fips()}) for
#' county (fetched via \code{download_pop_data()}). Note \code{add_county_fips()}
#' names its state column \code{st_fips}; rename it to \code{state_fips} for a
#' state join. Any population dimension present in \code{df} must appear in
#' \code{by_vars}, or it is a hard error (it would otherwise be silently summed
#' over); to aggregate a dimension, drop it from \code{df} or use its reserved
#' token. The \code{"total"} (race), \code{"both"} (sex), and \code{"all"}
#' (Hispanic origin) aggregate tokens are synthesized on demand.
#'
#' @note Bridged-race (\code{"legacy"}, 2020 and earlier) and single-race
#'   (\code{"single"}, 2022+) schemes are NOT comparable and must not be chained
#'   into a single trend. In this release the death-side join is pinned to
#'   all-origin denominators (\code{hispanic = "all"}); the Hispanic-stratified
#'   death join arrives in a later version.
#'
#' @param df MCOD dataframe
#' @param by_vars variables to match on
#' @param race_scheme denominator scheme: \code{"legacy"} (bridged-race
#'   \code{pop_est}, the default) or \code{"single"} (single-race, 2020-2024)
#' @param hispanic Hispanic-origin denominator to use; only \code{"all"} is
#'   supported in this release
#'
#' @return dataframe
#' @importFrom dplyr left_join select
#' @export
#' @examples
#' df <- data.frame(year = 2019, age = 25, sex = "male", race = "white")
#' add_pop_counts(df)
add_pop_counts <- function(df, by_vars = c("year", "age", "sex", "race"),
                           race_scheme = c("legacy", "single"),
                           hispanic = "all") {
    race_scheme <- match.arg(race_scheme)
    .check_mcod_df(df, need = by_vars, fn = "add_pop_counts")
    if ("pop" %in% names(df)) {
        stop("add_pop_counts(): `df` already has a `pop` column; remove or ",
             "rename it before joining population estimates.", call. = FALSE)
    }

    if (identical(race_scheme, "legacy")) {
        pop_slice <- dplyr::select(narcan::pop_est, -age_cat)
        return(.guarded_pop_join(df, pop_slice, by_vars, scheme = "legacy"))
    }

    ## race_scheme == "single".
    if (!identical(hispanic, "all")) {
        stop("add_pop_counts(): `hispanic` must be \"all\" in this release; ",
             "the death-side Hispanic join arrives in narcan 0.5.2. Use ",
             "get_pop_state()/get_pop_county() for Hispanic-stratified counts.",
             call. = FALSE)
    }
    ## Every population dimension present in `df` must also be in `by_vars`. A
    ## stratifier left out of `by_vars` (geography OR sex/race/age/origin) would
    ## be silently summed over -- e.g. asian_only deaths joined without `race`
    ## get the all-race population, and sub-national deaths would collapse onto a
    ## national count. To aggregate a dimension, drop it from `df` (or use its
    ## reserved token: race "total", sex "both"), never omit it while it is still
    ## a column. Geography is also routed by this membership.
    pop_dims <- c("year", "age", "sex", "race", "hispanic_origin",
                  "state_fips", "county_fips")
    stray <- setdiff(intersect(pop_dims, names(df)), by_vars)
    if (length(stray) > 0L) {
        stop(sprintf(
            paste0("add_pop_counts(): `df` carries population-dimension ",
                   "column(s) %s not in `by_vars`; under race_scheme = ",
                   "\"single\" the denominator would be silently summed over ",
                   "them. Add them to `by_vars`, or drop them from `df` to ",
                   "aggregate that dimension."),
            paste0("`", stray, "`", collapse = ", ")), call. = FALSE)
    }
    ## add_county_fips() names its state column `st_fips`, but the single-race
    ## population keys on `state_fips`/`county_fips`. If `st_fips` is present and
    ## NO geography key is in `by_vars`, a state-stratified frame would silently
    ## get the national denominator -- hard-error instead. (It is harmless and
    ## redundant when `county_fips` is already the join key.)
    if ("st_fips" %in% names(df) &&
        !any(c("state_fips", "county_fips") %in% by_vars)) {
        stop("add_pop_counts(): `df` has `st_fips` (from add_county_fips()) but ",
             "no geography key in `by_vars`. The single-race population keys on ",
             "`state_fips`/`county_fips`: rename `st_fips` to `state_fips` and ",
             "add it for a state join, use `county_fips` for a county join, or ",
             "drop geography for a national join.", call. = FALSE)
    }
    ## `year`-pooling is rarely intended: with no `year` in by_vars the single
    ## denominator is summed over 2020-2024. Warn (do not error -- age pooling to
    ## a crude rate is legitimate, but a 5-year pooled denominator usually is not).
    if (!"year" %in% by_vars) {
        warning("add_pop_counts(): `year` is not in `by_vars`; the single-race ",
                "denominator is pooled over all covered years (2020-2024). Add ",
                "`year` to `by_vars` for year-specific denominators.",
                call. = FALSE)
    }
    if ("county_fips" %in% by_vars) {
        pop_slice <- .load_pop_county(
            scheme = "single",
            states = if ("state_fips" %in% names(df)) unique(df$state_fips) else NULL,
            counties = if ("county_fips" %in% names(df)) unique(df$county_fips) else NULL,
            years = if ("year" %in% names(df)) unique(df$year) else NULL)
    } else if ("state_fips" %in% by_vars) {
        pop_slice <- narcan::pop_singlerace_state
    } else {
        pop_slice <- narcan::pop_singlerace
    }
    .guarded_pop_join(df, pop_slice, by_vars, scheme = "single")
}


#' Given a dataframe with age, returns a standard population
#'
#' Attaches a standard-population column (`pop_std`) and its unit weights
#' (`unit_w`, summing to 1 across the standard's age groups), matched on `age`.
#' The default `"s204"` is the US 2000 standard in 18 five-year age groups
#' (0, 5, ..., 85), which matches narcan's binned `age`.
#'
#' The `std_cat` must use the SAME age grouping as `df`. The 18-group five-year
#' standards match narcan's 5-year bins; a single-year standard (e.g. `"s202"`,
#' `"s205"`) joined to 5-year-binned ages matches only the bin-start years and
#' silently misweights every stratum. When the joined weights do not sum to ~1,
#' this warns.
#'
#' @param df dataframe with age column (in 5-year bins)
#' @param std_cat standard population to use (default: US 2000 standard pop);
#'   must share `df`'s age grouping (see Details)
#' @param by_vars variables to merge on
#'
#' @return dataframe
#' @importFrom dplyr filter select mutate left_join
#' @export
#' @examples
#' df <- data.frame(age = seq(0, 85, 5))
#' add_std_pop(df)
add_std_pop <- function(df, std_cat = "s204", by_vars = "age") {
    .check_mcod_df(df, need = by_vars, fn = "add_std_pop")
    clash <- intersect(c("pop_std", "unit_w"), names(df))
    if (length(clash) > 0L) {
        stop(sprintf(
            "add_std_pop(): `df` already has column(s) %s; remove or rename before joining.",
            paste0("`", clash, "`", collapse = ", ")), call. = FALSE)
    }
    std_pop_df <- narcan::std_pops |>
        dplyr::filter(standard == std_cat) |>
        dplyr::select(pop_std, age) |>
        dplyr::mutate(unit_w = pop_std / sum(pop_std))

    x <- dplyr::left_join(df, std_pop_df, by = by_vars)

    ## Guard the standard's age granularity against `df`'s. If the joined weights
    ## do not sum to ~1 over the distinct ages present, either the standard is
    ## finer-grained than `df` (e.g. single-year weights on 5-year bins, which
    ## misweights every stratum) or `df` omits age groups.
    ages_w <- unique(x[, c(by_vars, "unit_w"), drop = FALSE])
    if (anyNA(x[["unit_w"]])) {
        warning("add_std_pop(): some ages in `df` have no match in standard \"",
                std_cat, "\" (unit_w = NA); check that `age` uses the standard's ",
                "age grouping.", call. = FALSE)
    } else if (abs(sum(ages_w[["unit_w"]], na.rm = TRUE) - 1) > 1e-4) {
        warning(sprintf(paste0(
            "add_std_pop(): joined standard weights sum to %.3f, not 1. The ",
            "standard \"%s\" may have a different age granularity than `df` ",
            "(e.g. single-year vs 5-year bins), which misweights standardized ",
            "rates; or `df` omits age groups."),
            sum(ages_w[["unit_w"]], na.rm = TRUE), std_cat), call. = FALSE)
    }
    return(x)
}
