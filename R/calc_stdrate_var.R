#' Calculate age-standardized rates and variance
#'
#' Given a bare (unquoted) column of age-specific rates, variance, and weights,
#' will return the age-standardized rate and variance.
#'
#' @param df processed MCOD dataframe
#' @param asrate_col age-specific rate column
#' @param asvar_col variance of the age-specific rate
#' @param weight_col column of (unit) weights
#' @param ... grouping variables. These are **not** added automatically: pass
#'   every dimension you want preserved in the output (e.g. `year`, `race`), or
#'   pre-group `df`. Age bins are collapsed into the standardized rate.
#'
#' @return dataframe with two new columns
#' @importFrom rlang :=
#' @importFrom dplyr group_by summarize group_vars pull
#' @importFrom stats na.omit
#' @export
#' @examples
#' df <- data.frame(
#'     year = c(2015, 2015),
#'     race = c("white", "white"),
#'     opioid_rate = c(5, 7),
#'     opioid_var = c(0.1, 0.2),
#'     unit_w = c(0.5, 0.5)
#' )
#' calc_stdrate_var(df, opioid_rate, opioid_var, year, race)
calc_stdrate_var <- function(df, asrate_col, asvar_col, ...,
                             weight_col = unit_w) {
    ## Returns the age-standardized rate given an age-specific rate column
    ## (asrate_col) and some weights (weight_col). Unit weights are expected.
    ## The standardized columns reuse the input rate/variance names.
    .check_mcod_df(df, fn = "calc_stdrate_var")

    grouped <- df |> dplyr::group_by(..., .add = TRUE)

    ## Guard: grouping is NOT added automatically. A frame that varies over a
    ## demographic dimension not in the grouping silently collapses that dimension
    ## into one blended standardized rate (e.g. forgetting `hispanic_origin`
    ## averages hispanic + non_hispanic into a meaningless single rate). Flag any
    ## such dimension. The fixed dimension list avoids false positives on
    ## passenger columns (deaths, pop, ...) that legitimately vary within a group.
    .dims <- c("year", "sex", "race", "hispanic_origin", "state_fips",
               "county_fips")
    gv <- dplyr::group_vars(grouped)
    collapsed <- Filter(function(d) {
        d %in% names(df) && !d %in% gv &&
            length(unique(stats::na.omit(df[[d]]))) > 1L
    }, .dims)
    if (length(collapsed) > 0L) {
        warning(sprintf(paste0(
            "`df` varies over dimension(s) %s not in the grouping; ",
            "calc_stdrate_var() will collapse each into a single blended rate. ",
            "Pass them via `...` (or pre-group `df`)."),
            paste(sprintf("`%s`", collapsed), collapse = ", ")), call. = FALSE)
    }

    ## Guard: an NA weight (e.g. an age that is not a 5-year-bin start) or an
    ## NaN age-specific rate (a legitimate pop == 0 stratum) drops that stratum.
    ## Both the rate and the variance drop the SAME strata and renormalize over
    ## the survivors (see .std_rate/.std_var), so they stay consistent -- but the
    ## result then standardizes to a *truncated* standard, which is worth a flag.
    w <- dplyr::pull(df, {{ weight_col }})
    if (all(is.na(w)) || sum(w, na.rm = TRUE) == 0) {
        warning("Standardization weights are all missing or sum to zero; the ",
                "standardized rate will be NA. ", call. = FALSE)
    } else if (anyNA(w)) {
        warning("Some standardization weights are NA (e.g. ages that are not ",
                "5-year-bin starts); those strata are dropped from both the ",
                "standardized rate and its variance, so the result standardizes ",
                "to a truncated standard. Check that `add_std_pop()` was applied ",
                "to binned ages.", call. = FALSE)
    }

    grouped |>
        dplyr::summarize(
            "{{ asrate_col }}" := .std_rate({{ asrate_col }}, {{ asvar_col }},
                                            {{ weight_col }}),
            "{{ asvar_col }}" := .std_var({{ asrate_col }}, {{ asvar_col }},
                                          {{ weight_col }})
        )
}

## The age-standardized rate and its variance MUST agree on which strata
## contributed. A stratum is dropped iff its rate, variance, or weight is NA/NaN
## (a pop == 0 cell gives a NaN rate+variance; an unbinned age gives an NA
## weight). Both statistics then renormalize over the identical surviving set:
## rate = sum(w*r)/sum(w); var = sum(w^2*v)/sum(w)^2, over survivors. With no
## missing strata (the usual case) this is byte-for-byte the old weighted.mean +
## sum((w/sum w)^2 v).
.std_keep <- function(asrate, asvar, weight) {
    !is.na(asrate) & !is.na(asvar) & !is.na(weight)
}

.std_rate <- function(asrate, asvar, weight) {
    k <- .std_keep(asrate, asvar, weight)
    if (!any(k)) return(NA_real_)
    sum(weight[k] * asrate[k]) / sum(weight[k])
}

.std_var <- function(asrate, asvar, weight) {
    k <- .std_keep(asrate, asvar, weight)
    if (!any(k)) return(NA_real_)
    sum(weight[k]^2 * asvar[k]) / sum(weight[k])^2
}
