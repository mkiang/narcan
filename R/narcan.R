#' narcan R package for working with multiple cause of death data
#'
#' @docType package
#' @name narcan
#' @importFrom dplyr %>%
NULL

if(getRversion() >= "2.15.1") {
    ## Add global variables for download_standard_pops()
    utils::globalVariables(c(".", "standard", "age", "age_cat",
                             "standard_cat", "pop"))
}

