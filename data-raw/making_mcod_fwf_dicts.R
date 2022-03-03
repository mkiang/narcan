## Create the MCOD fixed width format dictionary
mcod_fwf_dicts  <- narcan:::.download_mcod_fwf_dicts()

usethis::use_data(mcod_fwf_dicts, overwrite = TRUE)
