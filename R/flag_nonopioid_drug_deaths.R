#' Flag non-opioid drug deaths according to ISW7 rules
#'
#' Given an MCOD dataframe **with** drug_death and opioid_death columns
#' already, will flag non-opioid deaths. Must run flag_opioid_deaths() and
#' flag_drug_deaths() first.
#'
#' @param processed_df processed dataframe
#'
#' @return new dataframe with a nonop_drug_death column
#' @importFrom dplyr mutate case_when
#' @export
flag_nonopioid_drug_deaths <- function(processed_df) {
    ## This assumes you already ran flag_drug_deaths() and flag_opioid_deaths()
    ## Returns a new tibble with a `nonop_drug_death` representing drug deaths
    ## due to something other than opioid.
    df <- processed_df %>%
        mutate(nonop_drug_death =
                   case_when(drug_death == 1 & opioid_death == 0 ~ 1,
                             TRUE ~ 0))

    return(df)
}
