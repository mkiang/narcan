#' Trim trailing whitespace on 3-char ICD-9 codes
#'
#' Some of the ICD-9 codes only contain 3 characters (i.e., they do not contain
#' subcodes) but have a space at the end. This function just takes the record
#' column and strips out the trailing space.
#'
#' @param icd9_record One of the record columns from an ICD-9 dataframe
#'
#' @return vector
#' @export
#' @examples
#' trim_trailing_whitespace(c("400 ", "402", "4032"))
trim_trailing_whitespace <- function(icd9_record) {
    ## Some 3 char ICD9 codes are followed by a space. Remove so consistent.
    new_col <- ifelse(substr(icd9_record, 4, 4) == " ",
                      gsub(icd9_record, pattern = " ", replacement = ""),
                      icd9_record)

    return(new_col)
}
