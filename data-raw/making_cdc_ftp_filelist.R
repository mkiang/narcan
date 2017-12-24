## Just a simple directory with year as the key and CDC's FTP location as the
## value. I got the original FTP file list using:
##
## cdc_filelist <- RCurl::getURL(paste0("ftp://ftp.cdc.gov/pub/",
##                                      "Health_Statistics/",
##                                      "NCHS/Datasets/DVS/mortality/"),
##                               dirlistonly = TRUE)
## write(cdc_filelist, "./inst/extdata/cdc_filelist.txt")
##
## Which saves the text (as of 12/24/2017) to ./inst/extdata/cdc_filelist.txt

## Read in the files on the FTP
cdc_filelist <- scan("./inst/extdata/cdc_filelist.txt", what = "char")

## Remove the non-US files
cdc_filelist <- cdc_filelist[grepl("[0-9]{4}us\\.", cdc_filelist)]

## Extract the year
years <- tidyr::extract_numeric(cdc_filelist)

## Make the dictionary
cdc_dict <- as.list(cdc_filelist)
names(cdc_dict) <- years

## Export it
devtools::use_data(cdc_dict, overwrite = TRUE)
