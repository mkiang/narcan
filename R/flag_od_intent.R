#' Flag overdose deaths by their UCOD intent code
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to extract
#'
#' @return dataframe
#' @importFrom dplyr case_when mutate
#' @export
flag_od_intent <- function(processed_df, year = NULL) {
    ## Makes 4 new columns indicating intent of the UCOD for overdoses.
    ## Intents are: unintended, suicide, homicide, and undetermined.
    ##
    ## NOTE: This assumes the opioid_death column (created by
    ## flag_opioid_deaths()) already exists.

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    if (year >= 1979 & year <= 1998) {
        new_df <- processed_df %>%
            mutate(
                unintended_intent = case_when(
                    grepl(ucod, pattern = "\\<E85[012345678]\\d{1}\\>") ~ 1,
                    TRUE ~ 0),
                suicide_intent = case_when(
                    grepl(ucod, pattern = "\\<E950[012345]\\>") ~ 1,
                    TRUE ~ 0),
                homicide_intent = case_when(grepl(ucod, pattern = "E9620") ~ 1,
                                            TRUE ~ 0),
                undetermined_intent = case_when(
                    grepl(ucod, pattern = "\\<E980[012345]\\>") ~ 1,
                    drug_death == 1 &
                        unintended_intent == 0 &
                        suicide_intent == 0 &
                        homicide_intent == 0 ~ 1,
                    TRUE ~ 0))
    } else {
        new_df <- processed_df %>%
            mutate(
                unintended_intent = case_when(
                    grepl(ucod, pattern = "\\<X4[01234]\\>") ~ 1, TRUE ~ 0),
                suicide_intent = case_when(
                    grepl(ucod, pattern = "\\<X6[01234]\\>") ~ 1, TRUE ~ 0),
                homicide_intent = case_when(
                    grepl(ucod, pattern = "X85") ~ 1, TRUE ~ 0),
                undetermined_intent = case_when(
                    grepl(ucod, pattern = "\\<Y1[01234]\\>") ~ 1,
                    drug_death == 1 &
                        unintended_intent == 0 &
                        suicide_intent == 0 &
                        homicide_intent == 0 ~ 1,
                    TRUE ~ 0))
    }
    return(new_df)
}
