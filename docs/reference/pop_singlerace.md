# Single-race population estimates, national, 2020-2024

Annual US resident population by age (5-year bins, 18 groups), sex,
single-race group, and Hispanic origin, from the US Census Bureau
Population Estimates Program (Vintage 2024, single-race Alldata6). The
single-race groups follow the 1997 OMB standard and match the labels
produced by
[`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
for 2022+ deaths (codes 101-106). Use these denominators only with
single-race death counts; they are NOT comparable to the bridged-race
`pop_est`.

## Usage

``` r
pop_singlerace
```

## Format

A data frame with 2160 rows and 9 columns

- year:

  year of observation (2020-2024)

- age:

  starting age for the 5-year age bin (0, 5, ..., 85 = 85+)

- sex:

  `"male"` or `"female"`

- race:

  single-race group: `white_only`, `black_only`, `american_indian_only`,
  `asian_only`, `nhopi_only`, `multiracial`

- hispanic_origin:

  `"non_hispanic"` or `"hispanic"`

- pop:

  population count

- scheme:

  race scheme (`"single"`)

- source:

  data source (`"census_pep_v2024"`)

- vintage:

  Census vintage (`"V2024"`)

## Source

<https://www.census.gov/programs-surveys/popest.html>

## Details

Only the finest cells are stored (sex male/female, the six single races,
Hispanic origin non_hispanic/hispanic); `"total"` / `"both"` / `"all"`
are synthesized on demand, never stored, so aggregation never
double-counts a marginal.
