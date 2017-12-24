#' A dictionary of year:URL key:value pairs for the CDC FTP MCOD files
#'
#' The CDC stores their multiple cause of death files on an FTP in fixed-width
#' format. However, the naming convention changes slightly from year to year.
#' This dictionary just contains the file name and the year as 12/24/2017.
#'
#' @docType data
#'
#' @format A dictionary
#' \describe{
#'   \item{key}{chr, year of file}
#'   \item{value}{chr, URL of file}
#' }
#' @source \url{ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/mortality/}
#' @keywords datasets
"cdc_dict"
