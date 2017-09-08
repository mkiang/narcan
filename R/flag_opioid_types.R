#' Take a processed MCOD dataframe and create indicators for opioid types
#'
#' Creates 9 indicators for all opioid deaths. 7 for type of opioid (opium,
#' heroin, natural, methadone, synethtic, other, unknown), 1 column for
#' the number of opioids, and 1 column to indicate presence of more than one opioid.
#'
#' @param processed_df MCOD dataframe already processed
#' @param year if NULL, will attempt to detect
#'
#' @return a new dataframe with 9 additional columns
#' @importFrom dplyr mutate case_when
#' @export
flag_opioid_types <- function(processed_df, year = NULL) {
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

    ## Extract year
    if (is.null(year)) {
        year <- .extract_year(processed_df)
    }

    ## Find specific opioids
    if (year >= 1979 & year <= 1998) {
        new_df <- processed_df %>%
            mutate(
                opium_present = 0,
                heroin_present = case_when(
                    grepl(ucod, pattern = "E8500") &
                        opioid_death == 1 ~ 1,
                    grepl(f_records_all, pattern = "E8500") &
                        opioid_death == 1 ~ 1,
                    TRUE ~ 0),
                other_natural_present = 1,
                methadone_present = case_when(
                    grepl(ucod, pattern = "E8501") &
                        opioid_death == 1 ~ 1,
                    grepl(f_records_all, pattern = "E8501") &
                        opioid_death == 1 ~ 1,
                    TRUE ~ 0),
                other_synth_present = 0,
                other_op_present = case_when(
                    grepl(ucod, pattern = "E8502") &
                        opioid_death == 1 ~ 1,
                    grepl(f_records_all, pattern = "E8502") &
                        opioid_death == 1 ~ 1,
                    TRUE ~ 0))
    } else {
        new_df <- processed_df %>%
            mutate(
                opium_present = case_when(
                    grepl(f_records_all, pattern = "T400") &
                        opioid_death == 0 ~ 1, TRUE ~ 0),
                heroin_present = case_when(
                    grepl(f_records_all, pattern = "T401") &
                        opioid_death == 1 ~ 1, TRUE ~ 0),
                other_natural_present = case_when(
                    grepl(f_records_all, pattern = "T402") &
                        opioid_death == 1 ~ 1, TRUE ~ 0),
                methadone_present = case_when(
                    grepl(f_records_all, pattern = "T403") &
                        opioid_death == 1 ~ 1, TRUE ~ 0),
                other_synth_present = case_when(
                    grepl(f_records_all, pattern = "T404") &
                        opioid_death == 1 ~ 1, TRUE ~ 0),
                other_op_present = case_when(
                    grepl(f_records_all, pattern = "T406") &
                        opioid_death == 1 ~ 1, TRUE ~ 0))
    }

    ## Add unspecified opioid
    new_df <- new_df %>%
        mutate(unspecified_op_present =
                   case_when(
                       opioid_death == 1 & opium_present == 0 &
                           heroin_present == 0 & other_natural_present == 0 &
                           methadone_present == 0 & other_synth_present == 0 &
                           other_op_present == 0 ~ 1,
                       TRUE ~ 0))


    ## Count up total number of opioids
    new_df <- new_df %>%
        mutate(num_opioids = opium_present + heroin_present +
                   other_natural_present + methadone_present +
                   other_synth_present + other_op_present +
                   unspecified_op_present)

    ## More than one opioid?
    new_df <- new_df %>%
        mutate(multi_opioids = ifelse(num_opioids > 1, 1, 0))

    return(new_df)
}
