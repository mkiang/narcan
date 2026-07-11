## Scripts used to create the pop_est and std_pops dataframes
library(tidyverse)

pop_est  <- narcan:::.download_all_pop_data() %>% ungroup()
std_pops <- narcan:::.download_standard_pops() %>% ungroup()

## Guard against the year==420 artifact (a mislabeled alternate-vintage 2020
## block) ever reshipping from a fresh network build. A mangled year label sits
## far outside the plausible range, so a wide sanity band catches it without
## tripping when a later rebuild legitimately extends coverage past 2020. Fail
## loud so the root cause gets fixed upstream, not filtered away silently.
stopifnot(all(pop_est$year >= 1979 & pop_est$year <= 2100))

usethis::use_data(pop_est, overwrite = TRUE)
usethis::use_data(std_pops, overwrite = TRUE)
