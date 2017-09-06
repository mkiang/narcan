#' narcan R package for working with multiple cause of death data
#'
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
}
