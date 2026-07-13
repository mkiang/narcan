#' Join population denominators to a death frame
#'
#' Attaches a \code{pop} column of population estimates matched on \code{by_vars}.
#' Two denominator schemes are available; both route through the single guarded
#' join so the same correctness guards always apply.
#'
#' \code{race_scheme = "legacy"} (default) joins the frozen \code{narcan::pop_est}
#' (1979-2020) and reproduces the historical behavior byte-for-byte: unmatched
#' keys warn and leave \code{pop = NA}. It reproduces published bridged-race
#' rates, though \code{pop_est} is a pieced-together legacy series -- its
#' 2000-2020 denominators are single-race-alone Census estimates, which run low
#' against bridged-race death counts. Prefer \code{"bridged"} for a coherent
#' 1969-2024 series.
#'
#' \code{race_scheme = "single"} joins the single-race denominators
#' (\code{pop_singlerace_full}, 2000-2024; the frozen \code{pop_singlerace}
#' 2020-2024 slice is used unchanged when no pre-2020 year is requested) for
#' deaths coded with \code{remap_race()}/\code{categorize_race()} codes 101-106.
#' \code{race_scheme = "bridged"} joins
#' the SEER-uniform bridged-race denominators (\code{pop_bridged}, 1969-2024) for
#' deaths coded with the bridged categories. Both are strict: they guarantee no
#' silent NA denominator, so out-of-domain \code{age}/\code{sex}/\code{race}
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
#' The \code{"bridged"} scheme is era-ragged: SEER resolves AIAN/API and Hispanic
#' origin only from 1990 (pre-1990 is white/black/other only), so it REQUIRES
#' \code{year} in \code{by_vars} and validates the race set per row against that
#' row's era. Asian/Pacific-Islander subgroups (chinese/japanese/hawaiian/
#' filipino) have no separate bridged denominator; collapse them to \code{api}
#' (numerator and denominator together) before joining.
#'
#' @note Legacy (\code{"legacy"}), SEER bridged (\code{"bridged"}),
#'   and single-race (\code{"single"}) schemes are NOT comparable and must not be
#'   chained into a single trend. \code{"legacy"} and \code{"bridged"} share the
#'   labels white/black/other/total, so passing the wrong \code{race_scheme}
#'   cannot be detected automatically -- set it deliberately. For
#'   Hispanic-stratified denominators, add a \code{hispanic_origin} column
#'   (\code{"hispanic"}/\code{"non_hispanic"}, from \code{add_hispanic_origin()})
#'   to \code{by_vars} under \code{"single"} (2000+) or \code{"bridged"} (1990+);
#'   \code{"unknown"}/\code{NA} origin is non-denominable and hard-errors. (Note
#'   the shared name: \code{add_pop_counts()} joins on a \code{hispanic_origin}
#'   COLUMN listed in \code{by_vars}, whereas \code{get_pop_state()} /
#'   \code{get_pop_county()} take a \code{hispanic_origin=} filter ARGUMENT.) Two
#'   caveats apply to origin-stratified rates: (A) numerator origin (death
#'   certificate) and denominator origin (Census/SEER) are separately measured
#'   and differentially misclassified; (B) origin was phased onto state death
#'   certificates through ~1997, so 1990-1996 rates are biased low.
#'
#' @param df MCOD dataframe. A two-digit \code{datayear} (1979-1995) is coalesced
#'   into \code{year} per row when \code{year} is absent or \code{NA}.
#' @param by_vars variables to match on
#' @param race_scheme denominator scheme: \code{"legacy"} (bridged-race
#'   \code{pop_est}, the default), \code{"single"} (single-race), or
#'   \code{"bridged"} (SEER-uniform bridged-race, 1969-2024)
#'
#' @return \code{df} with an added \code{pop} column. Under the strict schemes
#'   (\code{"single"}/\code{"bridged"}) it also carries a \code{pop_scheme} column
#'   marking which scheme produced it, so results from different schemes are not
#'   accidentally combined. The \code{"legacy"} output is unchanged.
#' @importFrom dplyr left_join select
#' @export
#' @examples
#' df <- data.frame(year = 2019, age = 25, sex = "male", race = "white")
#' add_pop_counts(df)
add_pop_counts <- function(df, by_vars = c("year", "age", "sex", "race"),
                           race_scheme = c("legacy", "single", "bridged")) {
    race_scheme <- match.arg(race_scheme)
    ## Accept a two-digit `datayear` (pre-1996 files) the way add_hispanic_origin()
    ## does: coalesce it into a canonical `year` per row, so the documented
    ## add_hispanic_origin() -> add_pop_counts() pipeline works for a datayear-only
    ## frame (the join keys on `year`). `year` takes precedence where present.
    if (is.data.frame(df) && "datayear" %in% names(df)) {
        dy <- suppressWarnings(as.numeric(as.character(df[["datayear"]])))
        two <- !is.na(dy) & dy < 100
        dy[two] <- dy[two] + 1900
        if (!"year" %in% names(df)) {
            df[["year"]] <- dy
        } else {
            yy <- suppressWarnings(as.numeric(as.character(df[["year"]])))
            df[["year"]] <- ifelse(!is.na(yy), yy, dy)
        }
    }
    .check_mcod_df(df, need = by_vars, fn = "add_pop_counts")
    if ("pop" %in% names(df)) {
        stop("add_pop_counts(): `df` already has a `pop` column; remove or ",
             "rename it before joining population estimates.", call. = FALSE)
    }
    ## `year` is the join key: an NA year (e.g. a pre-1996 row whose `datayear`
    ## was absent, so the coalesce above could not fill it) would otherwise
    ## surface downstream as a misleading "no population / check coverage" error.
    ## Fail early and name the real cause.
    if ("year" %in% by_vars && "year" %in% names(df) && anyNA(df[["year"]])) {
        stop("add_pop_counts(): `year` is a join key but has NA value(s); every ",
             "row needs a data year -- a 4-digit `year`, or a two-digit ",
             "`datayear` to coalesce from. Fill or drop the NA-year rows.",
             call. = FALSE)
    }

    if (identical(race_scheme, "legacy")) {
        ## DD4: legacy pop_est has no Hispanic-origin denominator. Key on
        ## names(df), NOT by_vars: a non-"all" hispanic_origin column left OUT of
        ## by_vars (the documented add_hispanic_origin() -> add_pop_counts()
        ## handoff, run with the legacy default) would otherwise be silently
        ## summed over, giving BOTH strata of a cell the same all-origin pop_est
        ## denominator. A pure-"all" (or absent) column is harmless. Fail fast on
        ## this structural error, before the bridged-overlap nudge below.
        if ("hispanic_origin" %in% names(df)) {
            ho <- df[["hispanic_origin"]]
            ## Error if origin is a join key (any value -- pop_est has no origin
            ## column to join on) OR a non-"all" passenger (the silent-sum trap).
            ## A pure-"all" passenger is harmless and allowed.
            if ("hispanic_origin" %in% by_vars || anyNA(ho) || !all(ho == "all")) {
                stop(paste0(
                    "add_pop_counts(): race_scheme = \"legacy\" has no ",
                    "Hispanic-origin denominator (pop_est is not ",
                    "origin-stratified); `df` carries a `hispanic_origin` column ",
                    "that this scheme cannot denominate. Drop the ",
                    "hispanic_origin column for an all-origin legacy join, or ",
                    "use race_scheme = \"single\"/\"bridged\" for ",
                    "Hispanic-stratified denominators."), call. = FALSE)
            }
        }
        ## Geography: pop_est is NATIONAL, so a sub-national key (st_fips from
        ## add_county_fips(), or state_fips/county_fips) would silently attach the
        ## national denominator to every area -- the same silent-sum class as the
        ## origin guard above. Reject up front. (Strict schemes DO support
        ## geography, so this is legacy-only.)
        geo <- intersect(c("st_fips", "state_fips", "county_fips"), names(df))
        if (length(geo) > 0L) {
            stop(sprintf(paste0(
                "add_pop_counts(): race_scheme = \"legacy\" uses the national ",
                "pop_est and has no geographic denominator, but `df` carries ",
                "%s. Drop the geography column(s) for a national legacy join, or ",
                "use race_scheme = \"single\"/\"bridged\" (which support ",
                "state_fips/county_fips denominators)."),
                paste0("`", geo, "`", collapse = ", ")), call. = FALSE)
        }
        ## D-SCHEMESELECT: "legacy" and "bridged" share the race labels
        ## white/black/other/total, so a bridged-intent by-race join left on the
        ## legacy default silently gets single-race-alone denominators. No guard
        ## can distinguish them (label-identical), so nudge once per session in
        ## the bridged-overlap span. message() (not a warning/output) keeps the
        ## legacy return value byte-for-byte identical.
        if ("race" %in% by_vars && "year" %in% names(df) &&
            any(df[["year"]] %in% 2000:2020, na.rm = TRUE)) {
            .inform_once("legacy_bridged_overlap", paste0(
                "add_pop_counts(): race_scheme = \"legacy\" pairs bridged-race ",
                "death counts with single-race-alone PEP denominators for ",
                "2000-2020 (the denominator runs low; see ?add_pop_counts). For ",
                "coherent bridged-race denominators use race_scheme = ",
                "\"bridged\"; for 2022+ single-race deaths use \"single\"."))
        }
        pop_slice <- dplyr::select(narcan::pop_est, -age_cat)
        return(.guarded_pop_join(df, pop_slice, by_vars, scheme = "legacy"))
    }

    ## Strict schemes ("single", "bridged"): shared call-site guards, then
    ## scheme-aware geography routing. Every per-row correctness guard runs in
    ## .guarded_pop_join(); these are the call-site framing checks.
    ## Every population dimension present in `df` must also be in `by_vars`. A
    ## stratifier left out of `by_vars` (geography OR sex/race/age/origin) would
    ## be silently summed over -- e.g. asian_only deaths joined without `race`
    ## get the all-race population, and sub-national deaths would collapse onto a
    ## national count. To aggregate a dimension, drop it from `df` (or use its
    ## reserved token: race "total", sex "both"), never omit it while it is still
    ## a column. Geography is also routed by this membership.
    stray <- setdiff(intersect(.pop_dimensions, names(df)), by_vars)
    if (length(stray) > 0L) {
        stop(sprintf(
            paste0("add_pop_counts(): `df` carries population-dimension ",
                   "column(s) %s not in `by_vars`; under a strict race_scheme ",
                   "(\"single\"/\"bridged\") the denominator would be silently ",
                   "summed over them. Add them to `by_vars`, or drop them from ",
                   "`df` to aggregate that dimension."),
            paste0("`", stray, "`", collapse = ", ")), call. = FALSE)
    }
    ## add_county_fips() names its state column `st_fips`, but the population
    ## keys on `state_fips`/`county_fips`. If `st_fips` is present and NO
    ## geography key is in `by_vars`, a state-stratified frame would silently get
    ## the national denominator -- hard-error instead. (It is harmless and
    ## redundant when `county_fips` is already the join key.)
    if ("st_fips" %in% names(df) &&
        !any(c("state_fips", "county_fips") %in% by_vars)) {
        stop("add_pop_counts(): `df` has `st_fips` (from add_county_fips()) but ",
             "no geography key in `by_vars`. The population keys on ",
             "`state_fips`/`county_fips`: rename `st_fips` to `state_fips` and ",
             "add it for a state join, use `county_fips` for a county join, or ",
             "drop geography for a national join.", call. = FALSE)
    }
    ## Year handling by scheme: single MAY pool (warn, crude-rate use is
    ## legitimate); bridged REQUIRES year. The bridged check is also enforced in
    ## .check_bridged_death_keys() (the definitive guard, shared with the
    ## accessors), but it is hoisted HERE ahead of .route_pop_slice() so a missing
    ## `year` fails fast rather than first downloading a (possibly large) bridged
    ## Release-asset parquet only to reject the frame.
    if (identical(race_scheme, "single") && !"year" %in% by_vars) {
        warning("add_pop_counts(): `year` is not in `by_vars`; the single-race ",
                "denominator is pooled over all covered years. Add `year` to ",
                "`by_vars` for year-specific denominators.", call. = FALSE)
    }
    if (identical(race_scheme, "bridged") && !"year" %in% by_vars) {
        stop("add_pop_counts(): race_scheme = \"bridged\" requires `year` in ",
             "`by_vars`. The valid race and Hispanic-origin sets are ",
             "era-dependent (SEER resolves AIAN/API and Hispanic origin only ",
             "from 1990), so `year` must be a join key.", call. = FALSE)
    }

    pop_slice <- .route_pop_slice(df, by_vars, race_scheme)
    .guarded_pop_join(df, pop_slice, by_vars, scheme = race_scheme)
}

## The frozen single-race coverage (0.5.0): the year span of the bundled
## dependency-free pop_singlerace table. The county "narrow" default and any
## "does this request stay inside the frozen window" test derive their year
## window from this, so they track the frozen data in lockstep instead of a
## magic 2020:2024 literal.
.narrow_single_years <- function() sort(unique(narcan::pop_singlerace$year))

## Route a strict-scheme death frame to its population slice by geography
## (by_vars membership). single: national bundled (frozen pop_singlerace 2020-2024,
## or pop_singlerace_full 2000-2024 when a pre-2020 year is present), state via
## the same split (frozen .rda vs the *_full parquet), county via parquet.
## bridged: bundled national .rda, state + county parquet (too large to bundle).
## Every guard still runs downstream in .guarded_pop_join(); this only selects
## the source table.
.route_pop_slice <- function(df, by_vars, scheme) {
    county <- "county_fips" %in% by_vars
    state  <- "state_fips" %in% by_vars
    yrs <- if ("year" %in% names(df)) unique(df$year) else NULL
    sts <- if ("state_fips" %in% names(df)) unique(df$state_fips) else NULL
    cts <- if ("county_fips" %in% names(df)) unique(df$county_fips) else NULL
    ## Single-race spans 2000-2024, but the bundled frozen 0.5.0 tables cover
    ## 2020-2024 only; a request reaching any pre-2020 year routes to the *_full
    ## backfill. Use the project's as.numeric(as.character(.)) idiom
    ## (add_county_fips.R:166 / extract_year.R:34) so a factor year -- whose
    ## as.integer() is a level CODE, not the year -- does not silently mis-route.
    pre2020 <- !is.null(yrs) &&
        any(suppressWarnings(as.numeric(as.character(yrs))) < 2020, na.rm = TRUE)
    if (identical(scheme, "single")) {
        if (county) {
            return(.load_pop_parquet(
                "single", "county", states = sts, counties = cts,
                years = if (!is.null(yrs)) yrs else .narrow_single_years()))
        }
        if (state) {
            if (pre2020) {
                return(.load_pop_parquet("single", "state", states = sts,
                                         years = yrs))
            }
            return(narcan::pop_singlerace_state)
        }
        if (pre2020) return(narcan::pop_singlerace_full)
        return(narcan::pop_singlerace)
    }
    ## bridged
    if (county) {
        return(.load_pop_parquet("bridged", "county", states = sts,
                                 counties = cts, years = yrs))
    }
    if (state) {
        return(.load_pop_parquet("bridged", "state", states = sts, years = yrs))
    }
    narcan::pop_bridged
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
