# Synthesize the population slice to the join grain (strict schemes)

Collapses the stored finest cells to exactly `by_vars`: relabels a
dimension (`race`/`sex`/`hispanic_origin`) to its reserved token when
the death frame is aggregated there (so the group-sum yields the
matching marginal – e.g. an all-`"all"` origin frame collapses the
finest origin cells to the all-origin denominator), sums over every
dimension not in `by_vars`, and drops all metadata. First asserts
finest-key uniqueness and the per-year origin invariant on the RAW
input. The result is unique on `by_vars` (asserted by the many-to-one
join downstream). Scheme-agnostic: used by both "single" and "bridged".

## Usage

``` r
.synthesize_pop(deaths, pop_slice, by_vars, scheme)
```

## Arguments

- deaths:

  ungrouped death frame (read for its reserved-token usage).

- pop_slice:

  finest-cell population table.

- by_vars:

  join keys.

- scheme:

  the strict scheme (`"single"`/`"bridged"`); scopes the race-label
  domain check so it cannot pass a cross-scheme/cross-era mislabel.

## Value

a population slice with columns `by_vars` + `pop`.
