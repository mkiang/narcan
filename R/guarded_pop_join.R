## The single guarded entry point that joins a death frame to population
## denominators. add_pop_counts() (and, in a later step, the rate helpers over
## get_pop_state()/get_pop_county()) all route through .guarded_pop_join(): no
## guard predicate is reimplemented at a call site or in SQL. The accessors may
## return raw rows; every correctness guard runs here, R-side, always.

## The six single-race (OMB 1997) labels produced by categorize_race() for 2022+
## deaths (codes 101-106). "multiracial" has no `_only` suffix, so membership is
## tested against this SET rather than a suffix pattern.
.single_race_labels <- c("white_only", "black_only", "american_indian_only",
                         "asian_only", "nhopi_only", "multiracial")

## Reserved aggregate tokens, one per collapsible dimension. A death frame that
## carries the token means "already summed over this dimension"; the matching
## population marginal is synthesized on demand (only finest cells are stored,
## so synthesis can never double-count a stored marginal).
.pop_reserved <- c(race = "total", sex = "both", hispanic_origin = "all")

#' Guarded death-to-population join (single entry point)
#'
#' @param deaths death frame (grouping, incl. rowwise, is preserved).
#' @param pop_slice population table for the chosen scheme/geography. For
#'   \code{"single"} it holds only the finest cells; marginals are synthesized
#'   here from the death frame's reserved tokens.
#' @param by_vars join keys.
#' @param scheme \code{"legacy"} (frozen \code{pop_est}, warn+NA on unmatched,
#'   byte-for-byte current behavior) or \code{"single"} (guarded, no silent NA).
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

    ## Contradiction guard -- fires even on the default. Single-race race values
    ## under a non-single scheme would otherwise all-NA (legacy) or fan out;
    ## hard-error so a mis-set scheme is caught, not silently wrong.
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

    if (identical(scheme, "single")) {
        .check_single_death_keys(deaths, by_vars)
        pop_slice <- .synthesize_single_pop(deaths, pop_slice, by_vars)
    }

    ## Single-scheme join asserts many-to-one: the synthesized slice is unique on
    ## by_vars, so this is a belt-and-suspenders check that a synthesis bug can
    ## never silently fan out the denominator. Legacy is a bare join -- identical
    ## to the historical (0.4.2) behavior on the frozen path, with no new failure
    ## mode (a narrow by_vars fans out exactly as it did before).
    x <- if (identical(scheme, "single")) {
        dplyr::left_join(deaths, pop_slice, by = by_vars,
                         relationship = "many-to-one")
    } else {
        dplyr::left_join(deaths, pop_slice, by = by_vars)
    }

    if (identical(scheme, "single")) {
        ## No silent NA: the single regime guarantees a matched denominator.
        if (anyNA(x[["pop"]])) {
            na_rows <- is.na(x[["pop"]])
            combos <- unique(x[na_rows, by_vars, drop = FALSE])
            stop(sprintf(
                paste0("add_pop_counts(): %d row(s) had no single-race ",
                       "population (pop = NA), spanning %d distinct %s ",
                       "combination(s). Single-race denominators cover ",
                       "2020-2024; check the year/age/sex/race coverage of ",
                       "these rows."),
                sum(na_rows), nrow(combos), paste(by_vars, collapse = "/")),
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
        if (!all(hv == "all", na.rm = TRUE)) {
            stop("add_pop_counts(): Hispanic-stratified death joins arrive in ",
                 "narcan 0.5.2. Use hispanic_origin = \"all\", or ",
                 "get_pop_state()/get_pop_county() for descriptive ",
                 "Hispanic-stratified counts.", call. = FALSE)
        }
    }
    invisible(NULL)
}

#' Synthesize the single-race population slice to the join grain
#'
#' Collapses the stored finest cells to exactly \code{by_vars}: pins Hispanic
#' origin to \code{"all"}, relabels a dimension to its reserved token when
#' the death frame is aggregated there (so the group-sum yields the matching
#' marginal), sums over every dimension not in \code{by_vars}, and drops all
#' metadata. The result is unique on \code{by_vars} (asserted by the many-to-one
#' join downstream).
#'
#' @param deaths ungrouped death frame (read for its reserved-token usage).
#' @param pop_slice finest-cell single-race population table.
#' @param by_vars join keys.
#' @return a population slice with columns \code{by_vars} + \code{pop}.
#' @importFrom dplyr group_by across all_of summarize mutate
#' @keywords internal
.synthesize_single_pop <- function(deaths, pop_slice, by_vars) {
    ## Pin Hispanic origin to "all" by summing the origin dimension, then
    ## re-labeling it so it can still serve as a join key if requested.
    if ("hispanic_origin" %in% names(pop_slice)) {
        keep <- setdiff(names(pop_slice),
                        c("hispanic_origin", "pop", "scheme", "source",
                          "vintage"))
        pop_slice <- pop_slice |>
            dplyr::group_by(dplyr::across(dplyr::all_of(keep))) |>
            dplyr::summarize(pop = sum(pop), .groups = "drop") |>
            dplyr::mutate(hispanic_origin = "all")
    }

    ## Reserved-token relabel: if the death frame aggregates a dimension (all
    ## values equal the token), relabel the pop dimension so the group-sum below
    ## produces that marginal. Mixed disaggregated/aggregated frames are left
    ## alone -> the token rows fail to match -> the no-silent-NA guard fires.
    for (d in c("race", "sex")) {
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
