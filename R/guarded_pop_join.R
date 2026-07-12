## The single guarded entry point that joins a death frame to population
## denominators. add_pop_counts() (and, in a later step, the rate helpers over
## get_pop_state()/get_pop_county()) all route through .guarded_pop_join(): no
## guard predicate is reimplemented at a call site or in SQL. The accessors may
## return raw rows; every correctness guard runs here, R-side, always.
##
## Three schemes: "legacy" (frozen pop_est, warn+NA, byte-for-byte current
## behavior) and the two STRICT schemes "single" (single-race, 2000-2024) and
## "bridged" (SEER-uniform bridged, 1969-2024). The strict schemes guarantee no
## silent NA denominator; bridged additionally era-conditions the valid race and
## Hispanic-origin sets (SEER resolves AIAN/API and Hispanic origin only from
## 1990), so its guard is year-aware and evaluated PER ROW.

## Package-internal mutable state, used only for once-per-session informational
## messages (see .inform_once); never holds data.
.narcan_state <- new.env(parent = emptyenv())

## Emit `msg` at most once per session for a given `id`. Uses message() (not a
## warning or captured output) so it never perturbs a returned value -- the
## legacy path must stay byte-for-byte identical.
.inform_once <- function(id, msg) {
    if (!isTRUE(get0(id, envir = .narcan_state, ifnotfound = FALSE))) {
        assign(id, TRUE, envir = .narcan_state)
        message(msg)
    }
    invisible(NULL)
}

## The six single-race (OMB 1997) labels produced by categorize_race() for 2022+
## deaths (codes 101-106). "multiracial" has no `_only` suffix, so membership is
## tested against this SET rather than a suffix pattern.
.single_race_labels <- c("white_only", "black_only", "american_indian_only",
                         "asian_only", "nhopi_only", "multiracial")

## Bridged (SEER) denominator race labels, era-conditioned. SEER 1990+ resolves
## White/Black/AIAN/API (4 groups) + Hispanic origin; pre-1990 only
## White/Black/Other (3 groups), no Hispanic. The detailed Asian subgroups a
## bridged death frame may carry (categorize_race() 4-7) must be pre-collapsed by
## the caller to `api` -- numerator AND denominator together -- because a silent
## auto-relabel would attach the full `api` pop to each subgroup row and
## double-count the denominator (the many-to-one join cannot catch it: many
## deaths -> one pop is legal). So subgroups hard-error here.
.bridged_race_labels_1990    <- c("white", "black", "american_indian", "api")
.bridged_race_labels_pre1990 <- c("white", "black", "other")
.bridged_api_subgroups <- c("chinese", "japanese", "hawaiian", "filipino")

## Reserved aggregate tokens, one per collapsible dimension. A death frame that
## carries the token means "already summed over this dimension"; the matching
## population marginal is synthesized on demand (only finest cells are stored,
## so synthesis can never double-count a stored marginal).
.pop_reserved <- c(race = "total", sex = "both", hispanic_origin = "all")

## Every population dimension the strict schemes key on. A death frame carrying
## one of these as a column MUST list it in by_vars, or the denominator would be
## silently summed over it. Enforced at the add_pop_counts() call site AND, belt-
## and-suspenders, in .guarded_pop_join() (below) so a direct internal call --
## e.g. the future rate-helper routing -- cannot slip a silent miscount past the
## framing check.
.pop_dimensions <- c("year", "age", "sex", "race", "hispanic_origin",
                     "state_fips", "county_fips")

#' Guarded death-to-population join (single entry point)
#'
#' @param deaths death frame (grouping, incl. rowwise, is preserved).
#' @param pop_slice population table for the chosen scheme/geography. For the
#'   strict schemes it holds only the finest cells; marginals are synthesized
#'   here from the death frame's reserved tokens.
#' @param by_vars join keys.
#' @param scheme \code{"legacy"} (frozen \code{pop_est}, warn+NA on unmatched,
#'   byte-for-byte current behavior), \code{"single"} (single-race, guarded, no
#'   silent NA), or \code{"bridged"} (SEER bridged, guarded, year-aware).
#' @return \code{deaths} with a \code{pop} column, original grouping restored.
#' @importFrom dplyr ungroup group_vars group_by rowwise across all_of
#' @importFrom dplyr summarize mutate left_join
#' @keywords internal
.guarded_pop_join <- function(deaths, pop_slice, by_vars, scheme) {
    ## Preserve grouping (incl. rowwise, whose group_vars() is empty) so the
    ## join runs on a flat frame and the result is regrouped as it came in.
    was_rowwise <- inherits(deaths, "rowwise_df")
    grp_vars <- dplyr::group_vars(deaths)
    deaths <- dplyr::ungroup(deaths)

    ## A categorize_race() factor must join a character pop table; this coercion
    ## is value-neutral (the golden legacy test proves it does not shift output).
    if ("race" %in% names(deaths) && is.factor(deaths[["race"]])) {
        deaths[["race"]] <- as.character(deaths[["race"]])
    }
    ## Same value-neutral coercion for a factor-valued hispanic_origin join key,
    ## so the string domain guard and the character-keyed pop join see labels, not
    ## factor levels. add_hispanic_origin() emits character, but a user-supplied
    ## factor must coerce before the guards run.
    if ("hispanic_origin" %in% names(deaths) &&
        is.factor(deaths[["hispanic_origin"]])) {
        deaths[["hispanic_origin"]] <- as.character(deaths[["hispanic_origin"]])
    }
    ## A factor OR character year/age JOIN KEY passes the (factor-safe) routing
    ## and per-row coverage guards but then dplyr::left_join hard-errors on a type
    ## mismatch against the integer-keyed pop table. Coerce ONLY the keys named in
    ## by_vars (never a like-named passenger column, which must pass through
    ## untouched) to numeric the same value-neutral way, via as.character() so a
    ## factor yields its LABEL not its level code (project idiom). suppressWarnings
    ## matches the idiom used elsewhere; a malformed value still surfaces loudly
    ## downstream via the no-silent-NA guard.
    for (col in intersect(c("year", "age"), by_vars)) {
        if (col %in% names(deaths) &&
            (is.factor(deaths[[col]]) || is.character(deaths[[col]]))) {
            deaths[[col]] <- suppressWarnings(
                as.numeric(as.character(deaths[[col]])))
        }
    }

    ## Contradiction guard -- fires on any non-single scheme (legacy AND bridged).
    ## Single-race race values under a non-single scheme would otherwise all-NA
    ## (legacy) or fan out; hard-error so a mis-set scheme is caught, not silently
    ## wrong. (Legacy vs bridged share white/black/other/total and are NOT
    ## label-separable -- that foot-gun is handled by the once-per-session nudge
    ## in add_pop_counts(), since no guard can distinguish them.)
    if (scheme != "single" && "race" %in% by_vars &&
        "race" %in% names(deaths)) {
        rv <- deaths[["race"]]
        looks_single <- (is.character(rv) & rv %in% .single_race_labels) |
            (is.numeric(rv) & rv %in% 101:106)
        if (any(looks_single, na.rm = TRUE)) {
            stop("add_pop_counts(): `race` holds single-race values (101-106 ",
                 "or *_only/multiracial) but race_scheme is not \"single\". ",
                 "Pass race_scheme = \"single\" to use single-race ",
                 "denominators.", call. = FALSE)
        }
    }

    strict <- scheme %in% c("single", "bridged")
    if (strict) {
        ## Belt-and-suspenders framing check (add_pop_counts() enforces this at
        ## the call site too). A pop-dimension column present in `deaths` but not
        ## in by_vars would be silently summed over by .synthesize_pop() and
        ## attached to the wrong stratum -- a silent miscount. Re-assert here so a
        ## direct internal caller cannot bypass it.
        stray <- setdiff(intersect(.pop_dimensions, names(deaths)), by_vars)
        if (length(stray) > 0L) {
            stop(sprintf(paste0(
                "add_pop_counts(): `deaths` carries population-dimension ",
                "column(s) %s not in `by_vars`; under a strict race_scheme the ",
                "denominator would be silently summed over them. Add them to ",
                "`by_vars`, or drop them to aggregate that dimension."),
                paste0("`", stray, "`", collapse = ", ")), call. = FALSE)
        }
        if (identical(scheme, "single")) {
            .check_single_death_keys(deaths, by_vars)
        } else {
            .check_bridged_death_keys(deaths, by_vars)
        }
        pop_slice <- .synthesize_pop(deaths, pop_slice, by_vars)
    }

    ## The strict schemes assert many-to-one: the synthesized slice is unique on
    ## by_vars, so this is a belt-and-suspenders check that a synthesis bug can
    ## never silently fan out the denominator. Legacy is a bare join -- identical
    ## to the historical (0.4.2) behavior on the frozen path, with no new failure
    ## mode (a narrow by_vars fans out exactly as it did before).
    x <- if (strict) {
        dplyr::left_join(deaths, pop_slice, by = by_vars,
                         relationship = "many-to-one")
    } else {
        dplyr::left_join(deaths, pop_slice, by = by_vars)
    }

    if (strict) {
        ## No silent NA: the strict schemes guarantee a matched denominator.
        if (anyNA(x[["pop"]])) {
            na_rows <- is.na(x[["pop"]])
            combos <- unique(x[na_rows, by_vars, drop = FALSE])
            lab <- if (identical(scheme, "single")) "single-race" else "bridged"
            cov <- if (identical(scheme, "single")) {
                "single-race denominators cover 2000-2024"
            } else {
                paste0("bridged denominators cover 1969-2024 (AIAN/API and ",
                       "Hispanic origin only from 1990)")
            }
            stop(sprintf(
                paste0("add_pop_counts(): %d row(s) had no %s population ",
                       "(pop = NA), spanning %d distinct %s combination(s). ",
                       "%s; check the year/age/sex/race coverage of these ",
                       "rows."),
                sum(na_rows), lab, nrow(combos),
                paste(by_vars, collapse = "/"), cov),
                call. = FALSE)
        }
    } else {
        unmatched <- is.na(x[["pop"]])
        if (any(unmatched)) {
            combos <- unique(x[unmatched, by_vars, drop = FALSE])
            warning(sprintf(
                paste0("add_pop_counts(): %d row(s) had no matching ",
                       "population in narcan::pop_est (pop = NA), spanning %d ",
                       "distinct %s combination(s). Check that these values ",
                       "use pop_est's coding -- e.g. categorize_race()'s finer ",
                       "bridged categories ",
                       "(american_indian/chinese/japanese/hawaiian/filipino) ",
                       "have no rows in pop_est."),
                sum(unmatched), nrow(combos), paste(by_vars, collapse = "/")),
                call. = FALSE)
        }
    }

    ## Restore the caller's grouping. group_vars() also captures a rowwise frame's
    ## kept variables (rowwise(df, x)), so pass them back through.
    if (was_rowwise) {
        x <- dplyr::rowwise(x, dplyr::all_of(grp_vars))
    } else if (length(grp_vars) > 0L) {
        x <- dplyr::group_by(x, dplyr::across(dplyr::all_of(grp_vars)))
    }
    x
}

#' Shared pre-join domain guards (sex, age, Hispanic origin)
#'
#' The scheme-agnostic domain checks used by both strict schemes. Reserved
#' aggregate tokens (\code{"both"}, \code{"all"}) are exempt per dimension.
#' \code{hispanic_origin} must be \code{"hispanic"}/\code{"non_hispanic"}/
#' \code{"all"} (\code{"unknown"} and \code{NA} are non-denominable and
#' hard-error here, NOT \code{na.rm}-exempt); a frame mixing \code{"all"} with
#' stratified values is rejected as an incoherent double-count.
#'
#' @param deaths ungrouped death frame.
#' @param by_vars join keys.
#' @return invisibly NULL; stops on any violation.
#' @keywords internal
.check_common_death_keys <- function(deaths, by_vars) {
    if ("sex" %in% by_vars && "sex" %in% names(deaths)) {
        bad <- setdiff(unique(deaths[["sex"]]),
                       c("male", "female", .pop_reserved[["sex"]]))
        bad <- bad[!is.na(bad)]
        if (length(bad) > 0L) {
            stop(sprintf(
                paste0("add_pop_counts(): `sex` must be ",
                       "\"male\"/\"female\"/\"both\"; got %s."),
                paste(shQuote(bad), collapse = ", ")), call. = FALSE)
        }
    }
    if ("age" %in% by_vars && "age" %in% names(deaths)) {
        bad <- setdiff(unique(deaths[["age"]]), seq(0, 85, 5))
        bad <- bad[!is.na(bad)]
        if (length(bad) > 0L) {
            stop(sprintf(
                paste0("add_pop_counts(): `age` must be a 5-year bin start ",
                       "(0, 5, ..., 85); got %s. Bin ages to 5-year groups ",
                       "first."),
                paste(bad, collapse = ", ")), call. = FALSE)
        }
    }
    if ("hispanic_origin" %in% by_vars && "hispanic_origin" %in% names(deaths)) {
        hv <- unique(deaths[["hispanic_origin"]])
        valid <- c("hispanic", "non_hispanic", .pop_reserved[["hispanic_origin"]])
        ## DD2: NOT na.rm-exempt (unlike the sex/age checks above). NA and
        ## "unknown" origin are non-denominable and must fail loud HERE, not slip
        ## to the generic downstream no-silent-NA guard. `%in%` is FALSE for NA.
        is_bad <- is.na(hv) | !(hv %in% valid)
        bad <- hv[is_bad]
        if (length(bad) > 0L) {
            bad_disp <- ifelse(is.na(bad), "NA", paste0("'", bad, "'"))
            msg <- sprintf(paste0(
                "add_pop_counts(): unrecognized `hispanic_origin` value(s): %s; ",
                "valid: hispanic/non_hispanic/all."),
                paste(bad_disp, collapse = ", "))
            ## Origin-unknown carve-out: only when the offenders are exactly NA
            ## and/or "unknown" (a user who mis-passed categorize_hspanicr()'s
            ## detailed labels, e.g. "mexican", reads the generic message instead).
            if (all(is.na(bad) | bad %in% "unknown")) {
                msg <- paste0(msg, " Origin-unknown deaths have no denominator: ",
                    "exclude them from stratified rates (they belong in the ",
                    "numerator only), or use hispanic_origin = \"all\".")
            }
            stop(msg, call. = FALSE)
        }
        ## DD6 mixed-era hard stop: "all" already sums the strata, so a frame
        ## mixing "all" with hispanic/non_hispanic double-counts. Reached only
        ## after the domain check, so hv is clean of NA/unknown here.
        if (any(hv %in% c("hispanic", "non_hispanic")) &&
            any(hv %in% .pop_reserved[["hispanic_origin"]])) {
            stop(paste0(
                "add_pop_counts(): `hispanic_origin` mixes \"all\" with ",
                "stratified values (hispanic/non_hispanic) in one frame; \"all\" ",
                "already sums the strata, so this double-counts. Use one origin ",
                "granularity per join (all-origin, OR hispanic+non_hispanic); ",
                "combine eras with separate calls + rbind."), call. = FALSE)
        }
    }
    invisible(NULL)
}

#' Pre-join domain guards for the single-race scheme (no silent NA)
#'
#' Validates the death frame's join keys against the single-race domain BEFORE
#' the join so out-of-domain values hard-error instead of passing through to an
#' NA denominator. Reserved aggregate tokens are exempt per dimension.
#'
#' @param deaths ungrouped death frame.
#' @param by_vars join keys.
#' @return invisibly NULL; stops on any violation.
#' @keywords internal
.check_single_death_keys <- function(deaths, by_vars) {
    if ("race" %in% by_vars && "race" %in% names(deaths)) {
        rv <- deaths[["race"]]
        if (is.numeric(rv)) {
            stop("add_pop_counts(): `race` is numeric under race_scheme = ",
                 "\"single\". Run remap_race() then categorize_race() first so ",
                 "`race` holds the single-race labels.", call. = FALSE)
        }
        bad <- setdiff(unique(rv), c(.single_race_labels, .pop_reserved[["race"]]))
        bad <- bad[!is.na(bad)]
        if (length(bad) > 0L) {
            stop(sprintf(
                paste0("add_pop_counts(): unrecognized single-race `race` ",
                       "value(s): %s. Valid: %s (or \"total\")."),
                paste(shQuote(bad), collapse = ", "),
                paste(.single_race_labels, collapse = ", ")), call. = FALSE)
        }
    }
    .check_common_death_keys(deaths, by_vars)
    invisible(NULL)
}

#' Pre-join domain guards for the bridged scheme (year-aware, per row, no silent NA)
#'
#' Bridged denominators are era-ragged: SEER resolves AIAN/API and Hispanic
#' origin only from 1990 (pre-1990 is White/Black/Other only). So \code{year}
#' must be a join key, and the valid race set is checked PER ROW against that
#' row's era -- a single combined domain would let a pre-1990 \code{api} row
#' pass and then join the wrong denominator. Mirrors the per-era straddle
#' pattern in \code{add_county_fips()}.
#'
#' @param deaths ungrouped death frame.
#' @param by_vars join keys.
#' @return invisibly NULL; stops on any violation.
#' @keywords internal
.check_bridged_death_keys <- function(deaths, by_vars) {
    if (!"year" %in% by_vars) {
        stop("add_pop_counts(): race_scheme = \"bridged\" requires `year` in ",
             "`by_vars`. The valid race and Hispanic-origin sets are ",
             "era-dependent (SEER resolves AIAN/API and Hispanic origin only ",
             "from 1990), so `year` must be a join key.", call. = FALSE)
    }
    ## Per-row era from `year`, computed once (shared by the race guard and the
    ## Hispanic-origin era guard). Factor-safe via as.character(): as.integer() on
    ## a factor yields level CODES (~always < 1990), which would misclassify a
    ## post-1990 factor year as pre-1990. Project idiom (see .route_pop_slice()).
    yr <- if ("year" %in% names(deaths)) {
        suppressWarnings(as.integer(as.numeric(as.character(deaths[["year"]]))))
    } else {
        integer(0)
    }
    if ("race" %in% by_vars && "race" %in% names(deaths)) {
        rv <- deaths[["race"]]
        if (is.numeric(rv)) {
            stop("add_pop_counts(): `race` is numeric under race_scheme = ",
                 "\"bridged\". Run remap_race() then categorize_race() first so ",
                 "`race` holds the bridged race labels.", call. = FALSE)
        }
        reserved <- .pop_reserved[["race"]]
        ## Detailed Asian/PI subgroups are non-denominable (any era): actionable
        ## pre-collapse message rather than a bare "unrecognized" error.
        subs <- intersect(unique(rv[!is.na(rv)]), .bridged_api_subgroups)
        if (length(subs) > 0L) {
            stop(sprintf(
                paste0("add_pop_counts(): race_scheme = \"bridged\" has no ",
                       "separate Asian/Pacific-Islander subgroup denominators; ",
                       "SEER resolves them only as combined `api` (from 1990). ",
                       "Collapse %s to `api` on BOTH the death counts and the ",
                       "denominator before joining. Subgroup denominators are ",
                       "tracked in issue #18."),
                paste(shQuote(subs), collapse = ", ")), call. = FALSE)
        }
        pre_bad <- setdiff(unique(rv[!is.na(yr) & yr < 1990]),
                           c(.bridged_race_labels_pre1990, reserved))
        pre_bad <- pre_bad[!is.na(pre_bad)]
        if (length(pre_bad) > 0L) {
            stop(sprintf(
                paste0("add_pop_counts(): race value(s) %s are not denominable ",
                       "under race_scheme = \"bridged\" before 1990 (SEER ",
                       "pre-1990 race = white/black/other only; the AIAN/API ",
                       "split begins in 1990). Valid pre-1990: %s (or ",
                       "\"total\"). Restrict to year >= 1990, or collapse to ",
                       "`other`."),
                paste(shQuote(pre_bad), collapse = ", "),
                paste(.bridged_race_labels_pre1990, collapse = ", ")),
                call. = FALSE)
        }
        post_bad <- setdiff(unique(rv[!is.na(yr) & yr >= 1990]),
                            c(.bridged_race_labels_1990, reserved))
        post_bad <- post_bad[!is.na(post_bad)]
        if (length(post_bad) > 0L) {
            stop(sprintf(
                paste0("add_pop_counts(): unrecognized bridged `race` value(s) ",
                       "for year >= 1990: %s. Valid: %s (or \"total\")."),
                paste(shQuote(post_bad), collapse = ", "),
                paste(.bridged_race_labels_1990, collapse = ", ")),
                call. = FALSE)
        }
    }
    ## Hispanic-origin era guard: SEER resolves origin only from 1990, so a
    ## pre-1990 stratified (hispanic/non_hispanic) value is not denominable.
    ## Pre-1990 "all" passes here; unknown/NA at any era are caught by DD2 below.
    if ("hispanic_origin" %in% by_vars && "hispanic_origin" %in% names(deaths)) {
        ho <- deaths[["hispanic_origin"]]
        pre1990_strat <- unique(ho[!is.na(yr) & yr < 1990 &
                                   ho %in% c("hispanic", "non_hispanic")])
        if (length(pre1990_strat) > 0L) {
            stop(paste0(
                "add_pop_counts(): Hispanic-origin stratification is not ",
                "available before 1990 under race_scheme = \"bridged\" (SEER ",
                "resolves Hispanic origin only from 1990; pre-1990 rows carry ",
                "origin \"all\" only). Restrict origin-stratified analysis to ",
                "year >= 1990, or use hispanic_origin = \"all\" for the full ",
                "span."), call. = FALSE)
        }
    }
    ## DD2 (domain) + DD6 (mixed-era coherence) via the shared common-keys check.
    .check_common_death_keys(deaths, by_vars)
    ## CAVEAT-B nudge LAST -- after every stop() above -- so the once-per-session
    ## message is spent only on a fully-valid frame, never burned on a call that
    ## then errors. 1990-1996 origin-stratified bridged numerators undercount
    ## Hispanic deaths (origin phased onto state certificates through ~1997) ->
    ## rates biased low.
    if ("hispanic_origin" %in% by_vars && "hispanic_origin" %in% names(deaths)) {
        ho <- deaths[["hispanic_origin"]]
        if (any(!is.na(yr) & yr >= 1990 & yr <= 1996 &
                ho %in% c("hispanic", "non_hispanic"))) {
            .inform_once("bridged_hispanic_early_reporting", paste0(
                "add_pop_counts(): Hispanic origin was phased onto state death ",
                "certificates through ~1997, so 1990-1996 origin-stratified ",
                "rates undercount Hispanic deaths (biased low). See ",
                "?add_pop_counts."))
        }
    }
    invisible(NULL)
}

#' Synthesize the population slice to the join grain (strict schemes)
#'
#' Collapses the stored finest cells to exactly \code{by_vars}: relabels a
#' dimension (\code{race}/\code{sex}/\code{hispanic_origin}) to its reserved
#' token when the death frame is aggregated there (so the group-sum yields the
#' matching marginal -- e.g. an all-\code{"all"} origin frame collapses the
#' finest origin cells to the all-origin denominator), sums over every dimension
#' not in \code{by_vars}, and drops all metadata. First asserts finest-key
#' uniqueness and the per-year origin invariant on the RAW input. The result is
#' unique on \code{by_vars} (asserted by the many-to-one join downstream).
#' Scheme-agnostic: used by both "single" and "bridged".
#'
#' @param deaths ungrouped death frame (read for its reserved-token usage).
#' @param pop_slice finest-cell population table.
#' @param by_vars join keys.
#' @return a population slice with columns \code{by_vars} + \code{pop}.
#' @importFrom dplyr group_by across all_of summarize mutate
#' @keywords internal
.synthesize_pop <- function(deaths, pop_slice, by_vars) {
    ## Defense in depth: the strict-scheme population tables store exactly one row
    ## per finest cell (the builders assert this before writing). If a resolved
    ## slice has DUPLICATE finest-cell rows -- a corrupted or partially-appended
    ## asset, a hand-supplied parquet -- the group-sums below would silently
    ## DOUBLE the denominator, and the downstream many-to-one join CANNOT catch it
    ## (summarize() forces the synthesized slice unique on by_vars regardless of
    ## the input). So assert finest-key uniqueness on the INPUT, before grouping.
    fk <- intersect(c("state_fips", "county_fips", "year", "age", "sex", "race",
                      "hispanic_origin"), names(pop_slice))
    if (length(fk) > 0L &&
        nrow(pop_slice) != nrow(dplyr::distinct(pop_slice[, fk, drop = FALSE]))) {
        stop(sprintf(paste0(
            "add_pop_counts(): the population slice has duplicate finest-cell ",
            "rows (keyed on %s); the denominator would be double-counted. The ",
            "population asset may be corrupt -- re-download or rebuild it."),
            paste(fk, collapse = "/")), call. = FALSE)
    }

    ## Per-year origin invariant (raw input, BEFORE any relabel): for each year
    ## the stored origin domain must be {all} OR a subset of {hispanic,
    ## non_hispanic} -- never both. A slice storing an "all" marginal beside
    ## stratified cells for the same year would double-count on an all-origin
    ## request (the relabel/collapse below would mask it), and the finest-key
    ## uniqueness assert above cannot see it (three distinct "unique" rows). Base
    ## R (no NSE) with na.rm so a stray NA never makes the predicate itself NA.
    if (all(c("hispanic_origin", "year") %in% names(pop_slice))) {
        origin_by_year <- tapply(
            as.character(pop_slice[["hispanic_origin"]]),
            pop_slice[["year"]],
            function(s) {
                any(s == "all", na.rm = TRUE) &&
                    any(s %in% c("hispanic", "non_hispanic"))
            })
        if (any(origin_by_year, na.rm = TRUE)) {
            bad_years <- names(origin_by_year)[which(origin_by_year)]
            stop(sprintf(paste0(
                "add_pop_counts(): the population slice stores an \"all\" origin ",
                "marginal beside stratified (hispanic/non_hispanic) cells for ",
                "year(s) %s; the denominator would be double-counted. The ",
                "population asset may be corrupt -- re-download or rebuild it."),
                paste(sort(bad_years), collapse = ", ")), call. = FALSE)
        }
    }

    ## Reserved-token relabel: if the death frame aggregates a dimension (all
    ## values equal the token), relabel the pop dimension so the group-sum below
    ## produces that marginal. Mixed disaggregated/aggregated frames are left
    ## alone -> the token rows fail to match -> the no-silent-NA guard fires.
    for (d in c("race", "sex", "hispanic_origin")) {
        tok <- .pop_reserved[[d]]
        if (d %in% by_vars && d %in% names(deaths) && d %in% names(pop_slice)) {
            dv <- unique(deaths[[d]])
            dv <- dv[!is.na(dv)]
            if (length(dv) > 0L && all(dv == tok)) {
                pop_slice[[d]] <- tok
            }
        }
    }

    ## Collapse to the join grain: keep only by_vars present in pop, summing pop
    ## over every dropped/relabeled dimension. Metadata columns are dropped.
    group_keys <- intersect(by_vars, names(pop_slice))
    pop_slice |>
        dplyr::group_by(dplyr::across(dplyr::all_of(group_keys))) |>
        dplyr::summarize(pop = sum(pop), .groups = "drop")
}
