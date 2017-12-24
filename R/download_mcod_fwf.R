#' Download the multiple cause of death data as an ASCII file from the CDC
#'
#' The CDC hosts publicly available multiple cause of death data as a fixed-
#' width text file. This function downloads that file as a zip. Note that the
#' CDC FTP is very slow--downloading from NBER via the download_mcod_dta() or
#' download_mcod_csv() functions is strongly suggested.
#'
#' @param year year to download (as integer)
#' @param download_dir file path to save downloaded data
#'
#' @return none
#' @export
#' @importFrom utils download.file
#' @source ftp://ftp.cdc.gov/pub/Health_Statistics/NCHS/Datasets/DVS/mortality/

download_mcod_fwf <- function(year, download_dir = './raw_data') {
    ## Downloads the raw MCOD data (as FWF text) for specified year
    ##
    ## Source: print(paste0('https://www.cdc.gov/nchs/nvss/',
    ##                      'mortality_public_use_data.htm'))

    ## Create URL
    base_url  <- paste0("ftp://ftp.cdc.gov/pub/Health_Statistics/",
                        "NCHS/Datasets/DVS/mortality")
    file_name <- narcan::cdc_dict[[as.character(year)]]
    file_url  <- sprintf("%s/%s", base_url, file_name)
    dest_file <- sprintf('%s/%s', download_dir, file_name)

    ## mkdir -p
    if (download_dir != './') {
        dir.create(download_dir, showWarnings = FALSE)
    }

    ## Get, unzip
    utils::download.file(file_url, dest_file)
}
