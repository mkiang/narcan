## Scripts used to create the pop_est and std_pops dataframes
library(tidyverse)

pop_est  <- narcan:::.download_all_pop_data() %>% ungroup()
std_pops <- narcan:::.download_standard_pops() %>% ungroup()

usethis::use_data(pop_est, overwrite = TRUE)
usethis::use_data(std_pops, overwrite = TRUE)
