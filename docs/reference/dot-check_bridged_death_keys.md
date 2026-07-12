# Pre-join domain guards for the bridged scheme (year-aware, per row, no silent NA)

Bridged denominators are era-ragged: SEER resolves AIAN/API and Hispanic
origin only from 1990 (pre-1990 is White/Black/Other only). So `year`
must be a join key, and the valid race set is checked PER ROW against
that row's era – a single combined domain would let a pre-1990 `api` row
pass and then join the wrong denominator. Mirrors the per-era straddle
pattern in
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md).

## Usage

``` r
.check_bridged_death_keys(deaths, by_vars)
```

## Arguments

- deaths:

  ungrouped death frame.

- by_vars:

  join keys.

## Value

invisibly NULL; stops on any violation.
