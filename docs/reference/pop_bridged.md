# Bridged-race population estimates, national, 1969-2024

Annual US resident population by age (5-year bins, 18 groups), sex,
bridged-race group, and Hispanic origin, from the SEER U.S. Population
Data (Vintage 2024). This is the SEER-uniform bridged series: use it
with bridged-race death counts
([`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
for deaths coded 2020 and earlier). It is NOT comparable to the
single-race `pop_singlerace` or to the legacy single-race-alone
`pop_est`.

## Usage

``` r
pop_bridged
```

## Format

A data frame with 12348 rows and 9 columns

- year:

  year of observation (1969-2024)

- age:

  starting age for the 5-year age bin (0, 5, ..., 85 = 85+)

- sex:

  `"male"` or `"female"`

- race:

  bridged-race group. 1969-1989: `white`, `black`, `other`. 1990-2024:
  `white`, `black`, `american_indian`, `api` (Asian + Pacific Islander
  combined)

- hispanic_origin:

  `"non_hispanic"` or `"hispanic"` (1990+); `"all"` only for 1969-1989

- pop:

  population count

- scheme:

  race scheme (`"bridged"`)

- source:

  data source (`"seer_uspop"`)

- vintage:

  SEER vintage (`"SEER2024"`)

## Source

<https://seer.cancer.gov/popdata/>

## Details

The series is era-ragged, reflecting what SEER resolves: 1969-1989
carries race `white`/`black`/`other` with `hispanic_origin = "all"` only
(no Hispanic detail before 1990); 1990-2024 carries
`white`/`black`/`american_indian`/`api` with `hispanic_origin`
`non_hispanic`/`hispanic`. Asian and Pacific Islander are combined as
`api` (SEER has no finer Asian detail). Only the finest cells are
stored; `"total"`/`"both"`/`"all"` are synthesized on demand, never
stored, so aggregation never double-counts a marginal.

State- and county-level bridged denominators are distributed separately
(too large to bundle) and fetched via
`download_pop_data(scheme = "bridged")` /
`get_pop_county(scheme = "bridged")`.
