#' Label intent from underlying cause column for overdose drugs
#'
#' @param processed_df MCOD dataframe already processed
#'
#' @return dataframe
#' @importFrom dplyr case_when mutate
#' @export
label_od_intent <- function(processed_df) {
    ## Makes 1 new columns with labels for intent of the UCOD for overdoses.
    ## Intents are: unintended, suicide, homicide, and undetermined.
    ##
    ## NOTE: This assumes the opioid_death column (flag_opioid_deaths()) and
    ## intent columns (flag_od_intent()) already exists.

    new_df <- processed_df %>%
        mutate(od_intent = case_when(
            unintended_intent   == 1 ~ "unintended",
            suicide_intent      == 1 ~ "suicide",
            homicide_intent     == 1 ~ "homicide",
            undetermined_intent == 1 ~ "undetermined",
            TRUE ~ "not_overdose"))

    return(new_df)
}
