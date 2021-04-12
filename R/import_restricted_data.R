#' Wrapper for importing restricted MCOD data
#'
#' Restricted MCOD data contains geographical location (for years after 2004),
#' that the public-use files do not contain. Further, restricted files come as
#' plaintext, fixed-width files. This helper function simply imports these
#' text files with known dictionaries.
#'
#' @param file path to restricted MCOD plaintext file
#' @param year year of MCOD data
#' @param fix_states recode state abbreviations to their FIPS code
#'
#' @return dataframe
#' @importFrom readr read_fwf fwf_positions
#' @importFrom dplyr mutate
.import_restricted_data <- function(file, year, fix_states = TRUE) {
    if (year < 2003) {
        df <- readr::read_fwf(file = file, col_positions = fwf_1999,
                              col_types = ctype_1999,  na = c("", "NA", " "))
    } else if (year >= 2003) {
        df <- readr::read_fwf(file = file, col_positions = fwf_2003,
                              col_types = ctype_2003,  na = c("", "NA", " "))

        ## The restricted data and documentation indicate the state should be
        ## encoded as a FIPS code, but they are actually abbreviation. Convert
        ## to FIPS.
        if (fix_states) {
            df <- df %>%
                mutate_at(vars(one_of("countyoc", "exstatoc", "staters",
                                      "countyrs", "exstares", "statbth",
                                      "statbthr")),
                          state_abbrev_to_fips)
        }

    }
    return(df)
}
