#' Download NCHS Natality (Live Births) Data from the CDC FTP (ASCII)
#'
#' Fair warning: These files are very large when uncompressed. They range
#' between 3 and 5 GB uncompressed with a compression ratio of around 90%.
#' Also, it appears the CDC rate limits downloads so I do not export this
#' function. To use it, you'll need to use the triple colon:
#' `narcan:::download_natality_ascii()`.
#'
#' Further, the unzip() function in R will not unzip files that are larger
#' than 4GB so this needs to be unzipped using a system call or external
#' program.
#'
#' @param year year to download (as integer)
#' @param download_dir file path to save downloaded data
#' @param return_path return the path of the file that was downloaded
#'
#' @return none
#' @importFrom utils download.file
#' @source https://www.cdc.gov/nchs/data_access/vitalstatsonline.htm

download_natality_ascii <- function(year, download_dir = './raw_data',
                                    return_path = FALSE) {
    base_url <- paste0("ftp://ftp.cdc.gov/pub/Health_Statistics/",
                       "NCHS/Datasets/DVS/natality")

    ## Inconsistent CDC file naming
    if (year %in% 2013:2014) {
        file_name <- sprintf("Nat%sUS.zip", year)
    } else {
        file_name <- sprintf("Nat%sus.zip", year)
    }

    file_url  <- sprintf("%s/%s", base_url, file_name)
    dest_file <- sprintf('%s/%s', download_dir, file_name)

    ## mkdir -p
    if (download_dir != './') {
        dir.create(download_dir, showWarnings = FALSE)
    }

    ## Get
    utils::download.file(file_url, dest_file)

    if (return_path) {
        return(dest_file)
    }
}
