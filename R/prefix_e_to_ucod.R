#' Add the external cause flag (E) to appropriate ICD-9 UCOD codes
#'
#' All UCOD ICD-9 codes between 800 and 999 are external cause of injury (E)
#' codes. We append the E to them to make regexing across UCOD and record
#' columns consistent.
#'
#' @param icd9_ucod The ucod column from an ICD-9 dataframe
#'
#' @return vector
#' @export
#' @examples
#' prefix_e_to_ucod(c(7951, 8001, 9992, 6000, 4000))
prefix_e_to_ucod <- function(icd9_ucod) {
    new_col <- ifelse(as.numeric(icd9_ucod) >= 8000 &
                          as.numeric(icd9_ucod) <= 9999,
                      paste0("E", icd9_ucod),
                      icd9_ucod)
    return(new_col)
}
