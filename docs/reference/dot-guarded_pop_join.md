# Guarded death-to-population join (single entry point)

Guarded death-to-population join (single entry point)

## Usage

``` r
.guarded_pop_join(deaths, pop_slice, by_vars, scheme)
```

## Arguments

- deaths:

  death frame (grouping, incl. rowwise, is preserved).

- pop_slice:

  population table for the chosen scheme/geography. For the strict
  schemes it holds only the finest cells; marginals are synthesized here
  from the death frame's reserved tokens.

- by_vars:

  join keys.

- scheme:

  `"legacy"` (frozen `pop_est`, warn+NA on unmatched, byte-for-byte
  current behavior), `"single"` (single-race, guarded, no silent NA), or
  `"bridged"` (SEER bridged, guarded, year-aware).

## Value

`deaths` with a `pop` column, original grouping restored.
