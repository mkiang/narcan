# Join population denominators to a death frame

Attaches a `pop` column of population estimates matched on `by_vars`.
Two denominator schemes are available; both route through the single
guarded join so the same correctness guards always apply.

## Usage

``` r
add_pop_counts(
  df,
  by_vars = c("year", "age", "sex", "race"),
  race_scheme = c("legacy", "single", "bridged"),
  hispanic = "all"
)
```

## Arguments

- df:

  MCOD dataframe

- by_vars:

  variables to match on

- race_scheme:

  denominator scheme: `"legacy"` (bridged-race `pop_est`, the default),
  `"single"` (single-race), or `"bridged"` (SEER-uniform bridged-race,
  1969-2024)

- hispanic:

  Hispanic-origin denominator to use; only `"all"` is supported in this
  release

## Value

dataframe

## Details

`race_scheme = "legacy"` (default) joins the frozen bridged-race
[`narcan::pop_est`](https://mkiang.github.io/narcan/reference/pop_est.md)
(1979-2020) and reproduces the historical behavior byte-for-byte:
unmatched keys warn and leave `pop = NA`. Use this to reproduce
published bridged-race rates.

`race_scheme = "single"` joins the single-race denominators
(`pop_singlerace_full`, 2000-2024; the frozen `pop_singlerace` 2020-2024
slice is used unchanged when no pre-2020 year is requested) for deaths
coded with
[`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)/[`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
codes 101-106. `race_scheme = "bridged"` joins the SEER-uniform
bridged-race denominators (`pop_bridged`, 1969-2024) for deaths coded
with the bridged categories. Both are strict: they guarantee no silent
NA denominator, so out-of-domain `age`/`sex`/`race` values hard-error
rather than passing through. Geography is routed by `by_vars` membership
– include `state_fips` for state denominators or `county_fips` (5-digit,
as produced by
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md))
for county (fetched via
[`download_pop_data()`](https://mkiang.github.io/narcan/reference/download_pop_data.md)).
Note
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
names its state column `st_fips`; rename it to `state_fips` for a state
join. Any population dimension present in `df` must appear in `by_vars`,
or it is a hard error (it would otherwise be silently summed over); to
aggregate a dimension, drop it from `df` or use its reserved token. The
`"total"` (race), `"both"` (sex), and `"all"` (Hispanic origin)
aggregate tokens are synthesized on demand.

The `"bridged"` scheme is era-ragged: SEER resolves AIAN/API and
Hispanic origin only from 1990 (pre-1990 is white/black/other only), so
it REQUIRES `year` in `by_vars` and validates the race set per row
against that row's era. Asian/Pacific-Islander subgroups
(chinese/japanese/hawaiian/ filipino) have no separate bridged
denominator; collapse them to `api` (numerator and denominator together)
before joining.

## Note

Legacy bridged-race (`"legacy"`), SEER bridged (`"bridged"`), and
single-race (`"single"`) schemes are NOT comparable and must not be
chained into a single trend. `"legacy"` and `"bridged"` share the labels
white/black/other/total, so passing the wrong `race_scheme` cannot be
detected automatically – set it deliberately. In this release the
death-side join is pinned to all-origin denominators
(`hispanic = "all"`); the Hispanic-stratified death join arrives in a
later version.

## Examples

``` r
df <- data.frame(year = 2019, age = 25, sex = "male", race = "white")
add_pop_counts(df)
#> add_pop_counts(): race_scheme = "legacy" pairs bridged-race death counts with single-race-alone PEP denominators for 2000-2020 (the denominator runs low; see ?add_pop_counts). For coherent bridged-race denominators use race_scheme = "bridged"; for 2022+ single-race deaths use "single".
#>   year age  sex  race     pop
#> 1 2019  25 male white 8739704
```
