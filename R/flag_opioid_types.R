#' Take a processed MCOD dataframe and create indicators for opioid types
#'
#' Creates 9 indicators for all opioid deaths. 7 for type of opioid (opium,
#' heroin, natural, methadone, synthetic, other, unknown), 1 column for
#' the number of opioids, and 1 column to indicate presence of more than one opioid.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#' @param opioid_deaths_only if `TRUE` (default), types are flagged only for
#'   opioid deaths (`opioid_death == 1`) -- the historical behavior. If `FALSE`,
#'   an opioid *type* is flagged wherever its code appears in the contributory
#'   causes, even when the death is not an opioid death under the ISW7 combined
#'   rule; the presence of an opioid in contributory causes does NOT mean the
#'   death was an opioid death, so the caller is expected to
#'   `filter(opioid_death == 1)` themselves. See issue #2.
#'
#' @return a new dataframe with 9 additional columns
#' @importFrom dplyr mutate case_when
#' @export
#' @examples
#' df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401 T404")
#' df |>
#'     flag_opioid_deaths(year = 2019) |>
#'     flag_opioid_types(year = 2019)
flag_opioid_types <- function(processed_df, year = NULL,
                              opioid_deaths_only = TRUE) {
    ## Makes a bunch of new columns.
    ## 7 for specific type of opioid:
    ##      opium,
    ##      heroin,
    ##      natural,
    ##      methadone,
    ##      synthetic,
    ##      other,
    ##      unspecified
    ## 1 for total number of opioids
    ## 1 for indicator if more than 1 opioids
    .check_mcod_df(processed_df, fn = "flag_opioid_types")

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    ## Find specific opioids
    new_df <- processed_df |>
        flag_opium_present(year = year, opioid_deaths_only = opioid_deaths_only) |>
        flag_heroin_present(year = year, opioid_deaths_only = opioid_deaths_only) |>
        flag_other_natural_present(year = year,
                                   opioid_deaths_only = opioid_deaths_only) |>
        flag_methadone_present(year = year,
                               opioid_deaths_only = opioid_deaths_only) |>
        flag_other_synth_present(year = year,
                                 opioid_deaths_only = opioid_deaths_only) |>
        flag_other_op_present(year = year,
                              opioid_deaths_only = opioid_deaths_only)

    ## Residual "unspecified" opioid: an opioid is present but none of the six
    ## specific types matched. Under opioid_deaths_only = TRUE this keys off the
    ## opioid_death flag (its historical definition); under FALSE it keys off an
    ## era-appropriate "any opioid present" indicator, so the residual (and
    ## therefore num_opioids) never fires on a non-opioid row.
    if (opioid_deaths_only) {
        op_present <- .opioid_gate(new_df, TRUE, "flag_opioid_types")
    } else if (.dispatch_era(year) == "icd9") {
        op_present <- rlang::expr(
            grepl(.regex_opioid_icd9(), ucod) |
                grepl(.regex_opioid_icd9(n_codes = TRUE), f_records_all))
    } else {
        op_present <- rlang::expr(
            grepl(.regex_opioid_icd10(t_codes = TRUE), f_records_all))
    }

    ## Add unspecified opioid
    new_df <- new_df |>
        dplyr::mutate(unspecified_op_present =
                   dplyr::case_when(
                       !!op_present &
                           opium_present == 0 &
                           heroin_present == 0 &
                           other_natural_present == 0 &
                           methadone_present == 0 &
                           other_synth_present == 0 &
                           other_op_present == 0 ~ 1,
                       TRUE ~ 0))


    ## Count up total number of opioids
    new_df <- new_df |>
        dplyr::mutate(num_opioids =
                   opium_present +
                   heroin_present +
                   other_natural_present +
                   methadone_present +
                   other_synth_present +
                   other_op_present +
                   unspecified_op_present)

    ## More than one opioid?
    new_df <- new_df |>
        dplyr::mutate(multi_opioids = ifelse(num_opioids > 1, 1, 0))

    return(new_df)
}
