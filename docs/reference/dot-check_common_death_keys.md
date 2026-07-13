# Shared pre-join domain guards (sex, age, Hispanic origin)

The scheme-agnostic domain checks used by both strict schemes. Reserved
aggregate tokens (`"both"`, `"all"`) are exempt per dimension.
`hispanic_origin` must be `"hispanic"`/`"non_hispanic"`/ `"all"`
(`"unknown"` and `NA` are non-denominable and hard-error here, NOT
`na.rm`-exempt); a frame mixing `"all"` with stratified values is
rejected as an incoherent double-count.

## Usage

``` r
.check_common_death_keys(deaths, by_vars)
```

## Arguments

- deaths:

  ungrouped death frame.

- by_vars:

  join keys.

## Value

invisibly NULL; stops on any violation.
