# Collapse hspanicr to the binary Hispanic-origin axis (for population joins)

Maps the NCHS \`hspanicr\` (Hispanic Origin/Race Recode) to the binary
Hispanic-origin axis the population denominators use: `"hispanic"`,
`"non_hispanic"`, or `"unknown"` (and `NA` where origin is not
recorded). This is the death-side counterpart of the `hispanic_origin`
dimension in
[`pop_bridged`](https://mkiang.github.io/narcan/reference/pop_bridged.md)
/
[`pop_singlerace_full`](https://mkiang.github.io/narcan/reference/pop_singlerace_full.md),
so a death frame carrying a `hispanic_origin` column can be joined to
Hispanic-stratified denominators via
[`add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md).

## Usage

``` r
categorize_hispanic_origin(hspanicr_column, year)
```

## Arguments

- hspanicr_column:

  hspanicr column from an MCOD dataframe.

- year:

  data year(s); a single value or a vector aligned to `hspanicr_column`.
  Required (no default) so the 9- vs 14-category scheme is selected
  correctly.

## Value

a character vector of `"hispanic"` / `"non_hispanic"` / `"unknown"` /
`NA`, matching the population tables' labels.

## Details

Unlike
[`categorize_hspanicr`](https://mkiang.github.io/narcan/reference/categorize_hspanicr.md)
(which returns the full 9- or 14-category ethnicity recode, for
descriptive counts and proportions that have no matching denominator),
this returns only the two-level origin axis that Census/SEER resolve, so
it is the recode to use when computing *rates*.

The recode is year-dependent: a 9-category scheme for 1989-2020,
reserved (not populated) in 2021, and an expanded 14-category scheme
from 2022. In every scheme the Hispanic subgroups (including "Other or
unknown Hispanic") map to `"hispanic"`, the non-Hispanic categories to
`"non_hispanic"`, and "Hispanic origin unknown" to `"unknown"`. Rows
with no recorded origin (pre-1989, 2021, or a code outside the year's
valid range) return `NA`; an out-of-range code additionally warns.

## See also

[`categorize_hspanicr`](https://mkiang.github.io/narcan/reference/categorize_hspanicr.md)
for the full 9/14-category ethnicity recode;
[`add_hispanic_origin`](https://mkiang.github.io/narcan/reference/add_hispanic_origin.md)
to add this as a column;
[`add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
for the Hispanic-stratified population join.

## Examples

``` r
categorize_hispanic_origin(c(1, 5, 6, 9), year = 2019)
#> [1] "hispanic"     "hispanic"     "non_hispanic" "unknown"     
categorize_hispanic_origin(c(1, 7, 8, 14), year = 2023)
#> [1] "hispanic"     "hispanic"     "non_hispanic" "unknown"     
```
