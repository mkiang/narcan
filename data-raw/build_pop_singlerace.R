## Build the single-race population denominators (narcan 0.5.0) from the Census
## PEP Vintage 2024 single-race state file. PARSE step (pull-from-parse): reads a
## cached raw file (see download_pop_singlerace.R for the pull) and writes the
## bundled national + state .rda. Quiet; run from the package root.
##
## No double-count: store ONLY finest cells -- sex {male,female}, race (the
## six OMB single-race groups), hispanic_origin {non_hispanic, hispanic}, 5-year
## age bins. total/both/all are SYNTHESIZED downstream, never stored. The Census
## provided marginals (SEX=0, ORIGIN=0) are read for VALIDATION ONLY, then dropped.

library(tidyverse)
library(data.table)

## Cached raw file (the pull step drops it here). Stable R_user_dir default with
## an env override -- never a session scratchpad path baked into the package.
raw_path <- Sys.getenv(
    "NARCAN_SC_EST2024",
    file.path(tools::R_user_dir("narcan", "cache"), "raw",
              "sc-est2024-alldata6.csv"))
stopifnot(file.exists(raw_path))

raw <- fread(raw_path)
yrcols <- paste0("POPESTIMATE", 2020:2024)

race_lab <- c("white_only", "black_only", "american_indian_only",
              "asian_only", "nhopi_only", "multiracial")

## --- Validation: provided marginals must equal sums of finest cells ---
## National 2020 total from the provided SEX=0/ORIGIN=0 marginal (all races).
tot_marginal_2020 <- raw[SEX == 0 & ORIGIN == 0 & RACE %in% 1:6,
                         sum(POPESTIMATE2020)]
## National 2020 total from the finest cells (SEX 1/2, ORIGIN 1/2, RACE 1-6).
tot_finest_2020 <- raw[SEX %in% 1:2 & ORIGIN %in% 1:2 & RACE %in% 1:6,
                       sum(POPESTIMATE2020)]
stopifnot(tot_marginal_2020 == tot_finest_2020,
          tot_finest_2020 == 331577720L)

## --- Finest cells -> long, labeled, 5-year age bins ---
finest <- raw[SEX %in% 1:2 & ORIGIN %in% 1:2 & RACE %in% 1:6]
finest_long <- finest |>
    as_tibble() |>
    mutate(
        state_fips = sprintf("%02d", STATE),
        sex = if_else(SEX == 1L, "male", "female"),
        ## Census ORIGIN 1 = Not Hispanic, 2 = Hispanic (polarity).
        hispanic_origin = if_else(ORIGIN == 1L, "non_hispanic", "hispanic"),
        race = race_lab[RACE],
        age = pmin(floor(AGE / 5) * 5, 85)
    ) |>
    select(state_fips, sex, hispanic_origin, race, age, all_of(yrcols)) |>
    pivot_longer(all_of(yrcols), names_to = "year", values_to = "pop") |>
    mutate(year = as.integer(sub("POPESTIMATE", "", year)))

## State grain (collapse single-year -> 5-year age bins).
pop_singlerace_state <- finest_long |>
    group_by(state_fips, year, age, sex, race, hispanic_origin) |>
    summarize(pop = sum(pop), .groups = "drop") |>
    mutate(scheme = "single", source = "census_pep_v2024", vintage = "V2024") |>
    arrange(year, state_fips, race, hispanic_origin, sex, age)

## National grain (sum states).
pop_singlerace <- pop_singlerace_state |>
    group_by(year, age, sex, race, hispanic_origin) |>
    summarize(pop = sum(pop), .groups = "drop") |>
    mutate(scheme = "single", source = "census_pep_v2024", vintage = "V2024") |>
    arrange(year, race, hispanic_origin, sex, age)

## --- Post-build checks ---
stopifnot(
    !anyNA(pop_singlerace$pop), all(pop_singlerace$pop >= 0),
    setequal(pop_singlerace$year, 2020:2024),
    setequal(pop_singlerace$race, race_lab),
    setequal(pop_singlerace$hispanic_origin, c("non_hispanic", "hispanic")),
    setequal(pop_singlerace$sex, c("male", "female")),
    setequal(pop_singlerace$age, seq(0, 85, 5)),
    ## national 2020 all-origin total reconciles again after reshape
    sum(pop_singlerace$pop[pop_singlerace$year == 2020]) == 331577720L,
    ## every state's finest is unique on the full key (no stored marginals)
    nrow(pop_singlerace_state) ==
        nrow(dplyr::distinct(pop_singlerace_state,
                             state_fips, year, age, sex, race, hispanic_origin))
)

usethis::use_data(pop_singlerace, overwrite = TRUE)
usethis::use_data(pop_singlerace_state, overwrite = TRUE)
