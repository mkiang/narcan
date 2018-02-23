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
#' @importFrom rlang := !! !!! enquo quos quo_name
#' @importFrom stats weighted.mean
#' @export
calc_stdrate_var <- function(df, asrate_col, asvar_col, ...,
                             weight_col = unit_w) {
    ## Returns the age-standardized rate given an age-specific rate column
    ## (asrate_col) and some weights (weight_col). Unit weights are expected.

    asrate_col <- enquo(asrate_col)
    asvar_col  <- enquo(asvar_col)
    weight_col <- enquo(weight_col)
    add_grps   <- quos(...)
    rcol_name  <- paste0(quo_name(asrate_col))
    vcol_name  <- paste0(quo_name(asvar_col))

    new_df <- df %>%
        group_by(!!!add_grps, add = TRUE) %>%
        summarize(!!rcol_name := weighted.mean(!!asrate_col, !!weight_col,
                                               na.rm = TRUE),
                  !!vcol_name := sum((!!weight_col)^2 * (!!asvar_col),
                                     na.rm = TRUE))

    return(new_df)
}
