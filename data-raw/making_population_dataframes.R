## Scripts used to create the pop_est and std_pops dataframes

pop_est  <- narcan:::.download_all_pop_data() %>% ungroup()
std_pops <- narcan:::.download_standard_pops() %>% ungroup()

devtools::use_data(pop_est, overwrite = TRUE)
devtools::use_data(std_pops, overwrite = TRUE)
