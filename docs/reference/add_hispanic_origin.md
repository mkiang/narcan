# Add a binary Hispanic-origin column from hspanicr

Adds a `hispanic_origin` column (`"hispanic"` / `"non_hispanic"` /
`"unknown"` / `NA`) derived from `hspanicr` and the data year, so a
death frame can be joined to Hispanic-stratified population denominators
via
[`add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md).
This is the population-join counterpart of
[`add_hspanicr_column`](https://mkiang.github.io/narcan/reference/add_hspanicr_column.md)
(which backfills the raw `hspanicr` field): Hispanic origin is ragged
across years – absent before 1989, reserved in 2021, and recoded from 9
to 14 categories in 2022 – so, like
[`add_hspanicr_column()`](https://mkiang.github.io/narcan/reference/add_hspanicr_column.md),
this reads the canonical year and tolerates a missing/NA `hspanicr`
(yielding `NA` origin for those rows).

## Usage

``` r
add_hispanic_origin(df)
```

## Arguments

- df:

  an MCOD dataframe with `hspanicr` (or none, treated as NA) and a
  `year` or `datayear` column.

## Value

`df` with an added `hispanic_origin` character column.

## Details

Year is read per row: `year` (1996+) where present, otherwise the
two-digit `datayear` (1979-1995, normalized to four digits). When a
frame carries both columns – e.g. a `bind_rows()` of pre-1996 and 1996+
chunks, where each era's column is `NA` outside its own rows – the two
are coalesced per row, so every row is labeled by its own data year. It
errors if neither column is present.

## See also

[`categorize_hispanic_origin`](https://mkiang.github.io/narcan/reference/categorize_hispanic_origin.md)
(the vectorized recode);
[`add_hspanicr_column`](https://mkiang.github.io/narcan/reference/add_hspanicr_column.md)
(backfills the raw `hspanicr` field);
[`add_pop_counts`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
for the Hispanic-stratified population join.

## Examples

``` r
df <- data.frame(year = 2019, hspanicr = c(1, 6, 9))
add_hispanic_origin(df)
#>   year hspanicr hispanic_origin
#> 1 2019        1        hispanic
#> 2 2019        6    non_hispanic
#> 3 2019        9         unknown
```
