## Hotfix (0.4.2): remove the spurious `year == 420` block from pop_est.
##
## The bundled pop_est carried a 43rd year-block labeled year == 420 (216 rows =
## 18 age groups x 4 races x 3 sexes). It is an alternate-vintage COPY of the 2020
## estimates whose year field was mangled during the original network build: every
## cell is within ~1.2% of the legitimate 2020 block (median ratio 1.0004), and vs
## 2019 it is off by up to 5.5%. The legitimate 2020 block is already present, and
## all 42 real years (1979-2020) are complete, so dropping these rows loses no
## data. Root cause lives in the network download/build (deferred to the 0.5.0
## pop-data rebuild); making_population_dataframes.R now asserts the year range so
## a future rebuild fails loud instead of reshipping this artifact.
##
## This script edits the existing data/pop_est.rda in place (no network) and is the
## reproducible record of the hotfix. Run from the package root.

library(tidyverse)

load("data/pop_est.rda")

## Guard the assumptions before mutating: the only out-of-range year is 420, it is
## exactly one 216-row block, and 1979-2020 are all present and complete.
bad <- pop_est %>% filter(year == 420)
stopifnot(
    setdiff(unique(pop_est$year), 1979:2020) == 420,
    nrow(bad) == 216,
    setequal(unique(pop_est$year[pop_est$year != 420]), 1979:2020),
    all(table(pop_est$year[pop_est$year != 420]) == 216)
)

## Confirm year 420 tracks 2020 (alternate vintage), not any other year, so the
## honest characterisation in NEWS holds.
y2020 <- pop_est %>% filter(year == 2020)
chk <- bad %>%
    select(age, sex, race, pop_420 = pop) %>%
    left_join(y2020 %>% select(age, sex, race, pop_2020 = pop),
              by = c("age", "sex", "race")) %>%
    mutate(ratio = pop_420 / pop_2020)
stopifnot(max(abs(chk$ratio - 1)) < 0.02)

pop_est <- pop_est %>%
    filter(year != 420) %>%
    arrange(year, race, sex, age)

stopifnot(
    setequal(unique(pop_est$year), 1979:2020),
    nrow(pop_est) == 9072,
    is.ordered(pop_est$age_cat)
)

usethis::use_data(pop_est, overwrite = TRUE)
