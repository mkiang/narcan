#' Downloads the NBER Stata dct file and returns a dictionary with column data
#'
#' The NBER has Stata dictionary files for each of the MCOD public use datasets
#' or Natality public use datasets. This function downloads the dictionary file
#' and converts it to a dataframe with column name, column start position,
#' column end position, and column time (in readr::col() format).
#'
#' @param year year of the dictionary you want to convert
#' @param natality set to TRUE if you want to download natality dictionaries
#'
#' @return dataframe
#' @importFrom tibble as_data_frame
#' @source http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html
#' @source http://www.nber.org/data/vital-statistics-natality-data.html
.dct_to_fwf_df <- function(year, natality = FALSE) {
    ## Create URL
    if (natality) {
        base_url <- "http://www.nber.org/natality"
        dct_url  <- sprintf("%s/%s/natl%s.dct", base_url, year, year)
    } else {
        base_url <- "http://www.nber.org/mortality"
        dct_url  <- sprintf("%s/%s/mort%s.dct", base_url, year, year)
    }

    ## Download
    all_text <- readLines(dct_url)

    ## Subset to just rows with column info, split by white space
    col_text <- all_text[grepl(all_text, pattern = "_column(", fixed = TRUE)]
    text_split <- strsplit(col_text, split = "\\s+")

    ## First, take the column names
    col_names <- unlist(lapply(text_split, FUN = function(x) {
        ifelse(x[2] == ")", x[4], x[3])
        }))

    ## Extract column widths
    col_width <- unlist(lapply(text_split, FUN = function(x) {
        ifelse(x[2] == ")", x[5], x[4])
    }))
    col_width <- as.numeric(gsub(".*?([0-9]+).*$", "\\1", col_width))

    ## Column starting positions
    col_start <- unlist(lapply(text_split, FUN = function(x) x[1]))
    col_start <- as.numeric(gsub(".*?([0-9]+).*$", "\\1", col_start))

    ## Column ending positions
    col_ends <- col_start + (col_width - 1)

    ## Now convert the column types to types `readr` understands
    col_types <- sub("[^[:alpha:]]+", "",
                     unlist(lapply(text_split,
                                   FUN = function(x) {
                                       ifelse(x[2] == ")",
                                              x[5], x[4])
                                       })))
    col_types <- gsub("s", "c", col_types)
    col_types <- gsub("f", "n", col_types)

    ## Return
    df <- tibble::as_data_frame(list(name  = col_names,
                                     type  = col_types,
                                     start = col_start,
                                     end   = col_ends))

    return(df)
}
