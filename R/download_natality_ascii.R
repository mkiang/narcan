#' Download NCHS Natality (Live Births) Data from the CDC FTP (ASCII)
#'
#' Fair warning: These files are very large when uncompressed. They range
#' between 3 and 5 GB uncompressed with a compression ratio of around 90%.
#'
#' @param year year to download (as integer)
#' @param download_dir file path to save dowhlo data
#'
#' @return none
#' @export
#' @importFrom utils download.file
#' @source https://www.cdc.gov/nchs/data_access/vitalstatsonline.htm

download_natality_ascii <- function(year, download_dir = './raw_data') {
    base_url <- paste0("ftp://ftp.cdc.gov/pub/Health_Statistics/",
                       "NCHS/Datasets/DVS/natality")

    ## Inconsistent CDC file naming
    if (year %in% 2013:2014) {
        file_name <- sprintf("Nat%sUS.zip", year)
    } else {
        file_name <- sprintf("Nat%sus.zip", year)
    }

    file_url  <- sprintf("%s/%s/%s", base_url, year, file_name)
    dest_file <- sprintf('%s/%s', download_dir, file_name)

    ## mkdir -p
    if (download_dir != './') {
        dir.create(download_dir, showWarnings = FALSE)
    }

    ## Get
    utils::download.file(file_url, dest_file)
}
