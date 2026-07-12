#' Add the external cause flag (E) to appropriate ICD-9 UCOD codes
#'
#' All UCOD ICD-9 codes between 800 and 999 are external cause of injury (E)
#' codes. Because this operates on the padded 4-character code (e.g. "8001"
#' for 800.1, as produced by \code{pad_3char_codes()}, which \code{
#' clean_icd9_data()} already runs before this), the numeric guard checks
#' 8000-9999, the padded-code equivalent of the 800-999 range. We append the E
#' to them to make regexing across UCOD and record columns consistent.
#'
#' @param icd9_ucod The ucod column from an ICD-9 dataframe
#'
#' @return vector
#' @export
#' @examples
#' prefix_e_to_ucod(c(7951, 8001, 9992, 6000, 4000))
prefix_e_to_ucod <- function(icd9_ucod) {
    ## Coerce once; an already-prefixed value (e.g. "E8500") is non-numeric ->
    ## NA -> left unchanged, so re-running clean_icd9_data() is idempotent
    ## rather than silently NA-ing every external-cause UCOD.
    num <- suppressWarnings(as.numeric(icd9_ucod))
    new_col <- ifelse(!is.na(num) & num >= 8000 & num <= 9999,
                      paste0("E", icd9_ucod),
                      icd9_ucod)
    return(new_col)
}
