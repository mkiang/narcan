#' Pad ICD-9 codes that do not have a sub-code (i.e., 3-character codes)
#'
#' Some of the ICD-9 codes only contain 3 characters (i.e., they do not contain
#' subcodes). This function just takes the UCOD column and converts all of
#' these 3 character codes into 4 by padding a zero at the end.
#'
#' @param icd9_ucod The ucod column from an ICD-9 dataframe
#'
#' @return vector
#' @export
#' @examples
#' pad_3char_codes(c("400", "4043", "304", "5062"))
pad_3char_codes <- function(icd9_ucod) {
    ## If ucod is coded as just three characters (i.e., no subcodes),
    ## add a zero to the end so regex is easier.
    new_col <- ifelse(nchar(icd9_ucod) == 3,
                      paste0(icd9_ucod, 0),
                      icd9_ucod)
    return(new_col)
}
