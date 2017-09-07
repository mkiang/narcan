#' Trim ICD-9 record columns that include the nature of injury flag
#'
#' For some years, the ICD-9 record columns are 5 character codes with the last
#' character representing the nature of injury (N) flag. Just trim off these
#' columns and use the appropriate rnifla_ column for the N flag.
#'
#' @param record_col The record column from an ICD-9 dataframe
#'
#' @return vector
#' @export
#' @examples
#' trim_5char_record(c("400 1", "40000", "400", "400 "))
trim_5char_record <- function(record_col) {
    new_col <- substr(record_col, 1, 4)
    return(new_col)
}
