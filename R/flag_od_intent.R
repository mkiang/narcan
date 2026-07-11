#' Flag overdose deaths by their UCOD intent code
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to extract
#'
#' @return dataframe
#' @importFrom dplyr case_when mutate
#' @export
#' @examples
#' df <- data.frame(
#'     year = 2019,
#'     ucod = c("X42", "X62"),
#'     f_records_all = c("T400", "T400")
#' )
#' df |>
#'     flag_drug_deaths(year = 2019) |>
#'     flag_od_intent(year = 2019)
flag_od_intent <- function(processed_df, year = NULL) {
    ## Makes 4 new columns indicating intent of the UCOD for overdoses.
    ## Intents are: unintended, suicide, homicide, and undetermined.
    ##
    ## Every intent flag is gated on `drug_death == 1`, so a poisoning UCOD that
    ## is not a drug death under narcan's combined rule (drug UCOD AND a
    ## contributory T-code) yields all-zero intents -> "not_overdose", matching
    ## the death-flag definition. Requires the `drug_death` column from
    ## flag_drug_deaths().
    .check_mcod_df(processed_df, need = c("ucod", "drug_death"),
                   fn = "flag_od_intent")

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (.dispatch_era(year) == "icd9") {
        new_df <- processed_df |>
            dplyr::mutate(
                unintended_intent = dplyr::case_when(
                    drug_death == 1 &
                        grepl(ucod, pattern = "\\<E85[012345678]\\d{1}\\>") ~ 1,
                    TRUE ~ 0),
                suicide_intent = dplyr::case_when(
                    drug_death == 1 &
                        grepl(ucod, pattern = "\\<E950[012345]\\>") ~ 1,
                    TRUE ~ 0),
                homicide_intent = dplyr::case_when(
                    drug_death == 1 & grepl(ucod, pattern = "\\<E9620\\>") ~ 1,
                    TRUE ~ 0),
                undetermined_intent = dplyr::case_when(
                    drug_death == 1 &
                        grepl(ucod, pattern = "\\<E980[012345]\\>") ~ 1,
                    drug_death == 1 &
                        unintended_intent == 0 &
                        suicide_intent == 0 &
                        homicide_intent == 0 ~ 1,
                    TRUE ~ 0))
    } else {
        new_df <- processed_df |>
            dplyr::mutate(
                unintended_intent = dplyr::case_when(
                    drug_death == 1 &
                        grepl(ucod, pattern = "\\<X4[01234]\\d{0,1}\\>") ~ 1,
                    TRUE ~ 0),
                suicide_intent = dplyr::case_when(
                    drug_death == 1 &
                        grepl(ucod, pattern = "\\<X6[01234]\\d{0,1}\\>") ~ 1,
                    TRUE ~ 0),
                homicide_intent = dplyr::case_when(
                    drug_death == 1 & grepl(ucod, pattern = "\\<X85\\d{0,1}\\>") ~ 1,
                    TRUE ~ 0),
                undetermined_intent = dplyr::case_when(
                    drug_death == 1 &
                        grepl(ucod, pattern = "\\<Y1[01234]\\d{0,1}\\>") ~ 1,
                    drug_death == 1 &
                        unintended_intent == 0 &
                        suicide_intent == 0 &
                        homicide_intent == 0 ~ 1,
                    TRUE ~ 0))
    }
    return(new_df)
}
