#' Dataframe of common standard populations in 18 age categories
#'
#' A data set containing a variety of common standard populations including:
#' 2000 US standard million, 2000 US standard population, 1960 world standard
#' million, WHO standard million. Created by using the download_standard_pops()
#' function.
#'
#' @format A data frame with 234 rows and 5 columns
#' \describe{
#'   \item{age_cat}{factor, age group}
#'   \item{standard_cat}{factor, description of standard population}
#'   \item{pop_std}{count, population in that age group for that standard}
#'   \item{stadard}{code, character code for that standard population}
#'   \item{age}{starting age of that age group}
#' }
#' @source \url{https://seer.cancer.gov/stdpopulations/stdpop.18ages.txt}
"std_pops"
