#' Flag overdose deaths by their UCOD intent code
#'
#' @details
#' Intent is read from the underlying-cause code. For ICD-9-era data this
#' interacts with narcan's ICD-9 "any-mention" drug-death rule: a death can be a
#' drug death because a drug/opioid code appears in a contributory field while
#' its underlying cause is a determinate NON-drug mechanism (e.g. E955 firearm
#' suicide with an opiate elsewhere on the record). Such a death matches none of
#' the four drug-poisoning intent sub-ranges and is labeled
#' `undetermined_intent`. This is deliberate -- narcan derives overdose intent
#' only from a drug-poisoning underlying cause and will not import a non-drug
#' manner of death into the drug-intent columns (which would pull, say, firearm
#' suicides into the suicide-overdose count). The *manner* of these deaths is
#' known; what is undetermined is the intent of the drug involvement.
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

    ## Derive the four intent UCOD patterns from the single source of truth so
    ## the intent partition can never diverge from the drug-death definition.
    intents <- .drug_ucod_intents(.dispatch_era(year))

    new_df <- processed_df |>
        dplyr::mutate(
            unintended_intent = dplyr::case_when(
                drug_death == 1 &
                    grepl(ucod, pattern = intents[["unintended"]]) ~ 1,
                TRUE ~ 0),
            suicide_intent = dplyr::case_when(
                drug_death == 1 &
                    grepl(ucod, pattern = intents[["suicide"]]) ~ 1,
                TRUE ~ 0),
            homicide_intent = dplyr::case_when(
                drug_death == 1 &
                    grepl(ucod, pattern = intents[["homicide"]]) ~ 1,
                TRUE ~ 0),
            undetermined_intent = dplyr::case_when(
                drug_death == 1 &
                    grepl(ucod, pattern = intents[["undetermined"]]) ~ 1,
                drug_death == 1 &
                    unintended_intent == 0 &
                    suicide_intent == 0 &
                    homicide_intent == 0 ~ 1,
                TRUE ~ 0))
    return(new_df)
}
