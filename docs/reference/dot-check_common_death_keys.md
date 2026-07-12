# Shared pre-join domain guards (sex, age, Hispanic origin)

The scheme-agnostic domain checks used by both strict schemes. Reserved
aggregate tokens (`"both"`, `"all"`) are exempt per dimension; the
death-side Hispanic join is pinned to `"all"` in this release (0.5.2).

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
