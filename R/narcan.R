#' narcan R package for working with multiple cause of death data
#'
#' @description R package for working with multiple cause of death data
#' @docType package
#' @name narcan
#' @importFrom dplyr %>%
NULL

## These are just here to declare globals so I don't get notes on R CMD check
if(getRversion() >= "2.15.1") {
    ## Add global variables for download_standard_pops()
    utils::globalVariables(c(".", "standard", "age", "age_cat",
                             "standard_cat", "pop"))

    ## Add global variables for population estimate functions
    utils::globalVariables(c("year", "age_years", "race", "delete",
                             "series", "total", "month",
                             "other_both", "other_female", "other_male",
                             "total_both",  "total_male", "total_female",
                             "black_both", "black_male", "black_female",
                             "nhapi_both", "nhapi_male", "nhapi_female",
                             "nhw_total", "nhw_male", "nhw_female",
                             "white_total", "white_male", "white_female",
                             "htom_female", "htom_male", "census2010pop",
                             "division", "estimatesbase2010", "name", "origin",
                             "popestimate2010", "popestimate2011",
                             "popestimate2015", "race_original", "region",
                             "sex", "state", "sumlev"))

    ## Globals for cleaning MCOD files
    utils::globalVariables(c("record_1",  "record_2",  "record_3",  "record_4",
                             "record_5",  "record_6",  "record_7",  "record_8",
                             "record_9",  "record_10", "record_11", "record_12",
                             "record_13", "record_14", "record_15", "record_16",
                             "record_17", "record_18", "record_19", "record_20",
                             "rnifla_1",  "rnifla_2",  "rnifla_3",  "rnifla_4",
                             "rnifla_5",  "rnifla_6",  "rnifla_7",  "rnifla_8",
                             "rnifla_9",  "rnifla_10", "rnifla_11", "rnifla_12",
                             "rnifla_13", "rnifla_14", "rnifla_15", "rnifla_16",
                             "rnifla_17", "rnifla_18", "rnifla_19", "rnifla_20",
                             "ager27", "ucod", "f_records_all"))

    ## Globals for flagging opioid types
    utils::globalVariables(c("heroin_present", "methadone_present",
                             "num_opioids", "opium_present",
                             "other_natural_present", "other_op_present",
                             "other_synth_present", "unspecified_op_present"))

    ## Globals for subsetting function
    utils::globalVariables(c("restatus"))

    ## Globals for adding population data
    utils::globalVariables(c("pop_std", "unit_w"))

    ## Globals for state_abbrev_to_fips examples
    utils::globalVariables(c("AK", "AL", "MA", "CA",
                             "AK202", "AL001", "MA101", "CA321"))

    ## Globals for import_restricted_data
    utils::globalVariables(c("staters", "countyrs", "exstares", "statbth",
                             "statbthr"))
}
