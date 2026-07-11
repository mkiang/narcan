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
#' @importFrom stats weighted.mean na.omit
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

    ## Guard: grouping is NOT added automatically. A multi-year frame passed
    ## without `year` in the grouping silently collapses every year into one
    ## standardized rate.
    if ("year" %in% names(df) && !"year" %in% dplyr::group_vars(grouped) &&
        length(unique(stats::na.omit(df$year))) > 1L) {
        warning("`df` spans multiple years but `year` is not a grouping ",
                "variable; calc_stdrate_var() will collapse across years into a ",
                "single rate. Pass `year` via `...` (or pre-group `df`).",
                call. = FALSE)
    }

    ## Guard: NA/zero weights make the rate and variance disagree -- the rate
    ## (weighted.mean) goes NA on any NA weight, while the variance renormalizes
    ## over the non-NA weights.
    w <- dplyr::pull(df, {{ weight_col }})
    if (all(is.na(w)) || sum(w, na.rm = TRUE) == 0) {
        warning("Standardization weights are all missing or sum to zero; the ",
                "standardized rate will be NA/NaN.", call. = FALSE)
    } else if (anyNA(w)) {
        warning("Some standardization weights are NA (e.g. ages that are not ",
                "5-year-bin starts); the standardized rate drops those rows ",
                "while the variance renormalizes over the rest. Check that ",
                "`add_std_pop()` was applied to binned ages.", call. = FALSE)
    }

    grouped |>
        dplyr::summarize(
            "{{ asrate_col }}" := stats::weighted.mean({{ asrate_col }},
                                                {{ weight_col }},
                                                na.rm = TRUE),
            "{{ asvar_col }}" := sum(
                ({{ weight_col }} / sum({{ weight_col }}, na.rm = TRUE))^2 *
                    {{ asvar_col }},
                na.rm = TRUE)
        )
}
