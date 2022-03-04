#' Wrapper for importing restricted MCOD data
#'
#' Restricted MCOD data contains geographical location (for years after 2004),
#' that the public-use files do not contain. Further, restricted files come as
#' plaintext, fixed-width files. This helper function simply imports these
#' text files with known dictionaries.
#'
#' @param file path to restricted MCOD plaintext file
#' @param year_x year of MCOD data
#'
#' @return dataframe
#' @importFrom readr read_fwf fwf_positions
#' @importFrom dplyr mutate
.import_restricted_data <- function(file, year_x) {
    fwf_col_pos <- narcan::mcod_fwf_dicts %>%
        filter(year == year_x) %>%
        select("start",
               "end",
               "col_names" = "name")

    c_types <- mcod_fwf_dicts %>%
        filter(year == year_x) %>%
        pull("type") %>%
        paste(collapse = "")

    df <- readr::read_fwf(
        file = file,
        col_positions = readr::fwf_positions(
            start = fwf_col_pos$start,
            end = fwf_col_pos$end,
            col_names = fwf_col_pos$col_names
        ),
        col_types = c_types,
        na = c("", "NA", " ")
    )
    return(df)
}
