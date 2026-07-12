# Single-race population estimates, state, 2020-2024

State-level counterpart of `pop_singlerace`: annual state population by
age (5-year bins), sex, single-race group, and Hispanic origin, from the
US Census Bureau Population Estimates Program (Vintage 2024). Same
schema as `pop_singlerace` plus a `state_fips` column. Only finest cells
are stored; totals are synthesized on demand.

## Usage

``` r
pop_singlerace_state
```

## Format

A data frame with 110160 rows and 10 columns

- state_fips:

  2-digit state FIPS code

- year:

  year of observation (2020-2024)

- age:

  starting age for the 5-year age bin (0, 5, ..., 85 = 85+)

- sex:

  `"male"` or `"female"`

- race:

  single-race group (see `pop_singlerace`)

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

County-level single-race denominators are distributed separately (too
large to bundle) and fetched via
[`download_pop_data()`](https://mkiang.github.io/narcan/reference/download_pop_data.md)
/
[`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md).
