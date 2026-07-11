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
#' (county support arrives with the Release-asset parquet). The \code{"total"}
#' (race), \code{"both"} (sex), and \code{"all"} (Hispanic origin) aggregate
#' tokens are synthesized on demand.
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
    ## H2: geography is routed by by_vars MEMBERSHIP. A frame that carries a
    ## geography column absent from by_vars would silently collapse sub-national
    ## deaths onto a national denominator -> hard-error instead.
    stray_geo <- setdiff(intersect(c("state_fips", "county_fips"), names(df)),
                         by_vars)
    if (length(stray_geo) > 0L) {
        stop(sprintf(
            paste0("add_pop_counts(): `df` carries geography column(s) %s not ",
                   "in `by_vars`. Add them to `by_vars` for a sub-national ",
                   "join, or drop them for a national join (never a silent ",
                   "national join on sub-national deaths)."),
            paste0("`", stray_geo, "`", collapse = ", ")), call. = FALSE)
    }
    if ("county_fips" %in% by_vars) {
        stop("add_pop_counts(): county single-race denominators are delivered ",
             "as a tag-pinned GitHub Release asset (parquet); the downloader ",
             "and accessor land in a subsequent narcan 0.5.0 build step. ",
             "National (no geography) and state (state_fips) joins are ",
             "available now.", call. = FALSE)
    } else if ("state_fips" %in% by_vars) {
        pop_slice <- narcan::pop_singlerace_state
    } else {
        pop_slice <- narcan::pop_singlerace
    }
    .guarded_pop_join(df, pop_slice, by_vars, scheme = "single")
}


#' Given a dataframe with age, returns a standard population
#'
#' Returns the US 2000 population by default, by any population from the
#' narcan::std_pop$std_cat column is valid.
#'
#' @param df dataframe with age column (in 5-year bins)
#' @param std_cat standard population to use (default: US 2000 standard pop)
#' @param by_vars variables to merge on
#'
#' @return dataframe
#' @importFrom dplyr filter select mutate left_join
#' @export
#' @examples
#' df <- data.frame(age = c(0, 5, 25, 85))
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
    return(x)
}
