# Retrieve county-level population denominators

Reads the county population parquet with DuckDB predicate pushdown. The
county table is too large to bundle, so it is fetched once from the
tag-pinned GitHub Release asset and cached (see
[`download_pop_data()`](https://mkiang.github.io/narcan/reference/download_pop_data.md));
pass `parquet` to read a local copy instead. Like
[`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md),
this returns population rows for descriptive use and does NOT guard a
hand-join.

## Usage

``` r
get_pop_county(
  scheme = c("single", "bridged"),
  states = NULL,
  counties = NULL,
  years = NULL,
  hispanic_origin = c("all", "non_hispanic", "hispanic"),
  parquet = NULL
)
```

## Arguments

- scheme:

  denominator scheme: `"single"` (default) or `"bridged"`

- states:

  optional 2-digit state FIPS codes to keep

- counties:

  optional 5-digit county FIPS codes to keep

- years:

  optional numeric vector of years to keep (single-race defaults to the
  frozen 2020-2024 window; request pre-2020 years for the backfill)

- hispanic_origin:

  `"all"` (default), `"non_hispanic"`, or `"hispanic"`

- parquet:

  optional path to a local county parquet (default: the cached Release
  asset, downloaded on first use)

## Value

a tibble with the county population schema plus metadata

## Details

Default-span asymmetry (mirrors
[`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)):
with `scheme = "single"` and no `years`, this defaults to the frozen
2020-2024 window; request pre-2020 `years` to reach the 2000-2024
backfill. `scheme = "bridged"` defaults to its full 1969-2024 span.

## See also

[`add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
for the death-to-population JOIN, which keys on a `hispanic_origin`
COLUMN in `by_vars`; this accessor instead takes a `hispanic_origin=`
filter ARGUMENT (same name, different mechanism).

## Examples

``` r
if (FALSE) { # \dontrun{
get_pop_county(states = "06", years = 2024)
} # }
```
