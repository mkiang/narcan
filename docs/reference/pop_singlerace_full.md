# Single-race population estimates, national, 2000-2024 (backfill)

Annual US resident population by age (5-year bins, 18 groups), sex,
single-race group (the six OMB-1997 alone categories), and Hispanic
origin, from the Census Bureau Population Estimates Program (PEP). This
is the 2000-2024 BACKFILL of the single-race series: it extends
[`pop_singlerace`](https://mkiang.github.io/narcan/reference/pop_singlerace.md)
(2020-2024 only) back to 2000 by stitching three PEP vintages, each
contributing a disjoint, non-overlapping calendar-year range.

## Usage

``` r
pop_singlerace_full
```

## Format

A data frame with 10800 rows and 9 columns

- year:

  year of observation (2000-2024)

- age:

  starting age for the 5-year age bin (0, 5, ..., 85 = 85+)

- sex:

  `"male"` or `"female"`

- race:

  single-race group: `white_only`, `black_only`, `american_indian_only`,
  `asian_only`, `nhopi_only`, `multiracial`

- hispanic_origin:

  `"non_hispanic"` or `"hispanic"`

- pop:

  population count

- vintage:

  PEP vintage for that row: `"int2000"`, `"int2010"`, or `"V2024"`

- scheme:

  race scheme (`"single"`)

- source:

  data source (`"census_pep"`)

## Source

<https://www2.census.gov/programs-surveys/popest/datasets/>

## Details

Use it with single-race death counts
([`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)/[`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
codes 101-106, coded 2020 and later). It is a single, consistent
taxonomy across all 25 years (RACE 1-6), NOT comparable to the bridged
[`pop_bridged`](https://mkiang.github.io/narcan/reference/pop_bridged.md)
or the legacy single-race-alone
[`pop_est`](https://mkiang.github.io/narcan/reference/pop_est.md). The
2020-2024 slice is identical (to the person) to the frozen
[`pop_singlerace`](https://mkiang.github.io/narcan/reference/pop_singlerace.md).
Only the finest cells are stored; `"total"`/`"both"`/`"all"` are
synthesized on demand, never stored, so aggregation never double-counts.

The `vintage` column records each row's provenance: `"int2000"`
(2000-2009, the 2000-2010 intercensal estimates), `"int2010"`
(2010-2019, the rebased 2010-2020 intercensal estimates – NOT the
postcensal V2020 series, which was never re-based to the 2020 census),
and `"V2024"` (2020-2024, the Vintage-2024 estimates).

State- and county-level single-race backfill denominators are
distributed separately (too large to bundle) as
`pop_singlerace_state_full` / `pop_singlerace_county_full` and fetched
via `download_pop_data(scheme = "single")` /
[`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md).
