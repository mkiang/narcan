#' Download the multiple cause of death data as a CSV file
#'
#' @param year year to download (as integer)
#' @param download_dir file path to save downlaoded data
#'
#' @return none
#' @export
#' @source http://www.nber.org/data/vital-statistics-mortality-data-multiple-cause-of-death.html

download_mcod_csv <- function(year, download_dir = './raw_data') {
    ## Downloads the raw MCOD data (as csv) for specified year
    ##
    ## Source: print(paste0('http://www.nber.org/data/vital-statistics',
    ##                      '-mortality-data-multiple-cause-of-death.html'))

    ## Create URL
    base_url  <- "http://www.nber.org/mortality"
    file_name <- sprintf('mort%s.csv', year)
    file_url  <- sprintf("%s/%s/%s.zip", base_url, year, file_name)
    dest_file <- sprintf('%s/%s.zip', download_dir, file_name)

    ## mkdir -p
    if (download_dir != './') {
        dir.create(download_dir, showWarnings = FALSE)
    }

    ## Get, unzip
    utils::download.file(file_url, dest_file)
}
