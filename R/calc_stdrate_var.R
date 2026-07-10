#' Calculate age-standardized rates and variance
#'
#' Given a bare (unquoted) column of age-specific rates, variance, and weights,
#' will return the age-standardized rate and variance.
#'
#' @param df processed MCOD dataframe
#' @param asrate_col age-specific rate column
#' @param asvar_col variance of the age-specific rate
#' @param weight_col column of (unit) weights
#' @param ... grouping variables (in addition to year and race)
#'
#' @return dataframe with two new columns
#' @importFrom rlang :=
#' @importFrom dplyr group_by summarize
#' @importFrom stats weighted.mean
#' @export
calc_stdrate_var <- function(df, asrate_col, asvar_col, ...,
                             weight_col = unit_w) {
    ## Returns the age-standardized rate given an age-specific rate column
    ## (asrate_col) and some weights (weight_col). Unit weights are expected.
    ## The standardized columns reuse the input rate/variance names.
    df |>
        group_by(..., .add = TRUE) |>
        summarize(
            "{{ asrate_col }}" := weighted.mean({{ asrate_col }},
                                                {{ weight_col }},
                                                na.rm = TRUE),
            "{{ asvar_col }}" := sum({{ weight_col }}^2 * {{ asvar_col }},
                                     na.rm = TRUE)
        )
}
