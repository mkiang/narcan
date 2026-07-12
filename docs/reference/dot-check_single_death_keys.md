# Pre-join domain guards for the single-race scheme (no silent NA)

Validates the death frame's join keys against the single-race domain
BEFORE the join so out-of-domain values hard-error instead of passing
through to an NA denominator. Reserved aggregate tokens are exempt per
dimension.

## Usage

``` r
.check_single_death_keys(deaths, by_vars)
```

## Arguments

- deaths:

  ungrouped death frame.

- by_vars:

  join keys.

## Value

invisibly NULL; stops on any violation.
