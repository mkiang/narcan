# Synthesize the population slice to the join grain (strict schemes)

Collapses the stored finest cells to exactly `by_vars`: pins Hispanic
origin to `"all"`, relabels a dimension to its reserved token when the
death frame is aggregated there (so the group-sum yields the matching
marginal), sums over every dimension not in `by_vars`, and drops all
metadata. The result is unique on `by_vars` (asserted by the many-to-one
join downstream). Scheme-agnostic: used by both "single" and "bridged".

## Usage

``` r
.synthesize_pop(deaths, pop_slice, by_vars)
```

## Arguments

- deaths:

  ungrouped death frame (read for its reserved-token usage).

- pop_slice:

  finest-cell population table.

- by_vars:

  join keys.

## Value

a population slice with columns `by_vars` + `pop`.
