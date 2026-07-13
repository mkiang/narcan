# Retrieve state-level population denominators

A descriptive accessor over the state population denominators. For
`scheme = "single"` it reads the bundled, dependency-free
[`narcan::pop_singlerace_state`](https://mkiang.github.io/narcan/reference/pop_singlerace_state.md)
table (Census PEP) when the requested `years` stay inside the frozen
2020-2024 window (the default), and the single-race backfill parquet
(2000-2024) when any pre-2020 year is requested or a `parquet` is
supplied (which needs the `duckdb` package). For `scheme = "bridged"` it
reads the SEER-uniform bridged state parquet (1969-2024), fetched once
from the tag-pinned GitHub Release asset and cached (see
[`download_pop_data()`](https://mkiang.github.io/narcan/reference/download_pop_data.md)).
Unlike
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md),
this returns population rows for descriptive use and exposes the
Hispanic-origin dimension. It does NOT guard a death-side join –
validate uniqueness/coverage yourself if you hand-join.

## Usage

``` r
get_pop_state(
  scheme = c("single", "bridged"),
  states = NULL,
  years = NULL,
  hispanic_origin = c("all", "non_hispanic", "hispanic"),
  parquet = NULL
)
```

## Arguments

- scheme:

  denominator scheme: `"single"` (default) or `"bridged"`

- states:

  optional character vector of 2-digit state FIPS codes to keep
  (default: all states)

- years:

  optional numeric vector of years to keep (default: all covered for
  bridged; the frozen 2020-2024 window for single – request pre-2020
  years to reach the backfill)

- hispanic_origin:

  `"all"` (default; sums the origin dimension), `"non_hispanic"`, or
  `"hispanic"`. Bridged pre-1990 rows carry only `"all"` (SEER has no
  Hispanic origin before 1990), so requesting a pre-1990 `years` with a
  stratified origin under `scheme = "bridged"` is an error, not a silent
  empty result.

- parquet:

  optional path to a local state parquet (single-race backfill or
  bridged); default resolves the cached Release asset when the request
  falls outside the bundled frozen window

## Value

a tibble with columns `state_fips`, `year`, `age`, `sex`, `race`,
`hispanic_origin`, `pop`, and metadata

## Details

Note the default-span asymmetry between schemes: `scheme = "single"`
defaults to the frozen 5-year window (2020-2024; pass pre-2020 `years`
to reach the 2000-2024 backfill), whereas `scheme = "bridged"` defaults
to its full 56-year span (1969-2024).

## See also

[`add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
for the death-to-population JOIN, which keys on a `hispanic_origin`
COLUMN in `by_vars`; this accessor instead takes a `hispanic_origin=`
filter ARGUMENT (same name, different mechanism).

## Examples

``` r
get_pop_state(states = "06", years = 2024)
#> # A tibble: 216 × 10
#>    state_fips  year   age sex    race               scheme source vintage    pop
#>    <chr>      <int> <dbl> <chr>  <chr>              <chr>  <chr>  <chr>    <int>
#>  1 06          2024     0 female american_indian_o… single censu… V2024    22881
#>  2 06          2024     0 female asian_only         single censu… V2024   145503
#>  3 06          2024     0 female black_only         single censu… V2024    64521
#>  4 06          2024     0 female multiracial        single censu… V2024    88452
#>  5 06          2024     0 female nhopi_only         single censu… V2024     5698
#>  6 06          2024     0 female white_only         single censu… V2024   693613
#>  7 06          2024     0 male   american_indian_o… single censu… V2024    24038
#>  8 06          2024     0 male   asian_only         single censu… V2024   154491
#>  9 06          2024     0 male   black_only         single censu… V2024    67363
#> 10 06          2024     0 male   multiracial        single censu… V2024    92709
#> # ℹ 206 more rows
#> # ℹ 1 more variable: hispanic_origin <chr>
```
