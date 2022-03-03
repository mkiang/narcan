#' Dataframe of fixed width format information for MCOD files
#'
#' @docType data
#'
#' @format A data frame with 5 columns
#' \describe{
#'   \item{name}{string, variable name}
#'   \item{type}{string, variable type (i.e., numeric, character, etc.)}
#'   \item{start}{integer, starting position of this column}
#'   \item{end}{integer, ending position of this column}
#'   \item{year}{integer, year of this dictionary}
#' }
#' @source \url{https://www.cdc.gov/nchs/nvss/mortality_public_use_data.htm}
#' @keywords datasets
"mcod_fwf_dicts"
