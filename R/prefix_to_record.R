#' Add the prefix to appropriate ICD-9 record columns
#'
#' For record columns, codes between 800-999 can be either nature of injury (N)
#' or external cause of innjury (E) codes. To determine the correct code, there
#' is a corresponding nature of injury flag column where 0 indicates an E code
#' and 1 indicates an N code. This takes the record/flag pair of columns and
#' prefixes the record column as appropriate.
#'
#' @param record_col The record column from an ICD-9 dataframe
#' @param rnifla_col The corresponding nature of injury flag column
#'
#' @return vector
#' @export
#' @examples
#' record_col <- c(7500, 8000, 8001, 9999, 10000)
#' rnifla_col <- c(0, 1, 0, 1, 0)
#' prefix_to_record(record_col, rnifla_col)
prefix_to_record <- function(record_col, rnifla_col) {
    ## If record code is [800, 999] AND rnifla is 0, then code is an E code.
    ## If record code is [800, 999] AND fnifla is 1, then it is an N code.
    ## Else, leave it alone.
    record_in_range <- (as.numeric(record_col) >= 8000 &
                            as.numeric(record_col) <= 9999)
    rnifla_is_zero  <- rnifla_col == 0

    new_col <- ifelse(record_in_range & rnifla_is_zero,
                      paste0("E", record_col),
                      ifelse(record_in_range & !rnifla_is_zero,
                             paste0("N", record_col),
                             record_col))

    return(new_col)
}
