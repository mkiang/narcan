#' Add the prefix to appropriate ICD-9 record columns
#'
#' For record columns, codes between 800-999 can be either nature of injury (N)
#' or external cause of injury (E) codes. To determine the correct code, there
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
    ## If record code is [800, 999] AND rnifla is 1, then it is an N code.
    ## Else (out of range, an NA/other flag, or an already-prefixed code that is
    ## non-numeric -> NA) leave it unchanged: never drop an in-range record to NA
    ## and never invent an E/N classification for an unknown flag. Coercing once
    ## also makes a second cleaning pass idempotent.
    num <- suppressWarnings(as.numeric(record_col))
    record_in_range <- !is.na(num) & num >= 8000 & num <= 9999
    is_e <- record_in_range & !is.na(rnifla_col) & rnifla_col == 0
    is_n <- record_in_range & !is.na(rnifla_col) & rnifla_col == 1

    new_col <- ifelse(is_e, paste0("E", record_col),
                      ifelse(is_n, paste0("N", record_col), record_col))

    return(new_col)
}
