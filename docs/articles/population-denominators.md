# Population denominators: bridged, single-race, and legacy

A mortality rate is death counts over a matching population, and
“matching” is the whole problem. NCHS has coded race three incompatible
ways over the series, so narcan ships three denominator schemes and
routes all of them through one guarded join,
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md).
The schemes are NOT comparable – you cannot chain them into one trend –
so set `race_scheme` deliberately.

| Scheme | `race_scheme` | Source | Coverage | Use for |
|----|----|----|----|----|
| Legacy bridged | `"legacy"` (default) | frozen `pop_est` (single-race-alone PEP) | 1979-2020 | reproducing published bridged-race rates byte-for-byte |
| Single-race | `"single"` | Census PEP single-race (OMB 1997) | 2000-2024 | 2022+ single-race deaths (codes 101-106) |
| SEER bridged | `"bridged"` | SEER U.S. Population Data (Vintage 2024) | 1969-2024 | coherent bridged-race trends, including pre-2020 |

All data here are public (bundled Census/SEER estimates, or a small
bundled county fixture) plus synthetic death counts; no restricted NCHS
records are used, and no chunk downloads anything.

``` r

library(narcan)
```

Across every scheme,
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
joins on `by_vars` – default `c("year", "age", "sex", "race")`, which
returns a national denominator; adding `state_fips` or `county_fips` to
`by_vars` routes the same call to sub-national denominators.

## `add_pop_counts()`, scheme by scheme

### Legacy (the default)

`race_scheme = "legacy"` joins the frozen `pop_est` and reproduces the
historical behavior byte-for-byte: unmatched keys warn and leave
`pop = NA`. Use it only to reproduce published bridged-race rates.

``` r

legacy <- data.frame(year = 1999L, age = 25L, sex = "male", race = "white")
add_pop_counts(legacy)                    # default scheme; adds `pop`
#>   year age  sex  race     pop
#> 1 1999  25 male white 7289220
```

For 2000-2020 the legacy denominator is single-race-alone (it runs low
against bridged-race deaths), so
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
nudges you once per session in that span toward `"bridged"` or
`"single"`.

### Single-race, end to end

`race_scheme = "single"` joins single-race denominators (2000-2024) for
deaths coded 101-106
(`white_only`/`black_only`/`american_indian_only`/`asian_only`/
`nhopi_only`/`multiracial`). It is strict: out-of-domain age/sex/race
and any unmatched key hard-error, so a denominator is never silently
`NA`. Below is a full `asian_only` age-standardized rate, one step at a
time.

``` r

deaths <- expand.grid(
    year = 2024L, age = seq(0, 85, 5), sex = c("male", "female"),
    race = "asian_only", stringsAsFactors = FALSE
)
deaths$deaths <- rep(c(1, 2, 5, 12, 30, 55), length.out = nrow(deaths))
head(deaths)
#>   year age  sex       race deaths
#> 1 2024   0 male asian_only      1
#> 2 2024   5 male asian_only      2
#> 3 2024  10 male asian_only      5
#> 4 2024  15 male asian_only     12
#> 5 2024  20 male asian_only     30
#> 6 2024  25 male asian_only     55
```

[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
adds the matched `pop` column:

``` r

rated <- add_pop_counts(deaths, race_scheme = "single")
head(rated)
#>   year age  sex       race deaths    pop pop_scheme
#> 1 2024   0 male asian_only      1 600728     single
#> 2 2024   5 male asian_only      2 678658     single
#> 3 2024  10 male asian_only      5 659666     single
#> 4 2024  15 male asian_only     12 666097     single
#> 5 2024  20 male asian_only     30 760220     single
#> 6 2024  25 male asian_only     55 826163     single
```

[`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
adds the US 2000 standard population (`pop_std`) and its unit weights
(`unit_w`, summing to 1 across age groups). `s204` is narcan’s code for
that standard population in 18 five-year age bins (the default
`std_cat`); see
[`?add_std_pop`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
for single-year alternatives, which must match your age binning:

``` r

weighted <- add_std_pop(rated, std_cat = "s204", by_vars = "age")
head(weighted[, c("age", "sex", "pop", "pop_std", "unit_w")])
#>   age  sex    pop  pop_std     unit_w
#> 1   0 male 600728 18986520 0.06913399
#> 2   5 male 678658 19919840 0.07253241
#> 3  10 male 659666 20056779 0.07303103
#> 4  15 male 666097 19819518 0.07216712
#> 5  20 male 760220 18257225 0.06647847
#> 6  25 male 826163 17722067 0.06452985
```

[`calc_asrate_var()`](https://mkiang.github.io/narcan/reference/calc_asrate_var.md)
adds the **age-specific** rate per 100,000 (`drug_rate`) and its Poisson
variance (`drug_var`) – one rate per age/sex cell:

``` r

asr <- calc_asrate_var(weighted, new_name = drug, death_col = deaths)
head(asr[, c("age", "sex", "deaths", "pop", "drug_rate", "drug_var")])
#>   age  sex deaths    pop drug_rate   drug_var
#> 1   0 male      1 600728 0.1664647 0.02771049
#> 2   5 male      2 678658 0.2946992 0.04342382
#> 3  10 male      5 659666 0.7579593 0.11490047
#> 4  15 male     12 666097 1.8015394 0.27046202
#> 5  20 male     30 760220 3.9462261 0.51909001
#> 6  25 male     55 826163 6.6572819 0.80580732
```

[`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md)
collapses the age bins into one **age-standardized** rate per group
(grouping is not automatic – pass every dimension to keep):

``` r

calc_stdrate_var(asr, drug_rate, drug_var, sex, race)
#> # A tibble: 2 × 4
#> # Groups:   sex [2]
#>   sex    race       drug_rate drug_var
#>   <chr>  <chr>          <dbl>    <dbl>
#> 1 female asian_only      2.48   0.0199
#> 2 male   asian_only      2.91   0.0274
```

### Bridged (SEER-uniform, era-ragged)

`race_scheme = "bridged"` joins the SEER bridged denominators
(1969-2024). It is strict and era-ragged: SEER resolves AIAN/API and
Hispanic origin only from 1990 (pre-1990 is white/black/other), so
`year` MUST be a join key.

``` r

api <- data.frame(year = 2019L, age = 40L, sex = "female", race = "api")
add_pop_counts(api, race_scheme = "bridged",
               by_vars = c("year", "age", "sex", "race"))
#>   year age    sex race    pop pop_scheme
#> 1 2019  40 female  api 874749    bridged
```

Omitting `year` from `by_vars` is an error – the valid race set is
era-dependent:

``` r

add_pop_counts(api, race_scheme = "bridged",
               by_vars = c("age", "sex", "race"))
#> Error:
#> ! add_pop_counts(): `df` carries population-dimension column(s) `year` not in `by_vars`; under a strict race_scheme ("single"/"bridged") the denominator would be silently summed over them. Add them to `by_vars`, or drop them from `df` to aggregate that dimension.
```

And an `api` row before 1990 errors, because SEER has no AIAN/API split
yet:

``` r

old_api <- data.frame(year = 1985L, age = 40L, sex = "female", race = "api")
add_pop_counts(old_api, race_scheme = "bridged",
               by_vars = c("year", "age", "sex", "race"))
#> Error:
#> ! add_pop_counts(): race value(s) 'api' are not denominable under race_scheme = "bridged" before 1990 (SEER pre-1990 race = white/black/other only; the AIAN/API split begins in 1990). Valid pre-1990: white, black, other (or "total"). Restrict to year >= 1990, or collapse to `other`.
```

## Strictness guards

Legacy and bridged share the labels white/black/other/total, so a
mis-set `race_scheme` cannot always be detected. But single-race labels
under a non-single scheme always can be – passing them to the default is
a hard error, a guard against forgetting `race_scheme = "single"`:

``` r

bad <- data.frame(year = 2024L, age = 25L, sex = "male", race = "asian_only")
add_pop_counts(bad)                       # default is "legacy" -> error
#> Error:
#> ! add_pop_counts(): `race` holds single-race values (101-106 or *_only/multiracial) but race_scheme is not "single". Pass race_scheme = "single" to use single-race denominators.
```

A frame already summed over a dimension uses a reserved token –
`race = "total"`, `sex = "both"`, `hispanic_origin = "all"`. The
matching marginal is synthesized on demand (finest cells summed; no
marginal is stored, so it cannot double-count):

``` r

both_sex <- data.frame(year = 2024L, age = 65L, sex = "both", race = "asian_only")
add_pop_counts(both_sex, race_scheme = "single")$pop        # male + female
#> [1] 1042672
```

## State and county grains

Include `state_fips` (or `county_fips`) in `by_vars` to route to
sub-national denominators. The state single-race table is bundled, so a
state join needs no extra package. See the *Harmonizing geography with
FIPS* article for how to derive harmonized `state_fips`/`county_fips`
columns from raw NCHS fields.

``` r

ca <- data.frame(state_fips = "06", year = 2024L, age = 40L, sex = "female",
                 race = "asian_only", deaths = 20)
add_pop_counts(ca, race_scheme = "single",
               by_vars = c("state_fips", "year", "age", "sex", "race"))
#>   state_fips year age    sex       race deaths    pop pop_scheme
#> 1         06 2024  40 female asian_only     20 269078     single
```

A geography column that is in the frame but absent from `by_vars` is an
error, never a silent national join:

``` r

add_pop_counts(ca, race_scheme = "single",
               by_vars = c("year", "age", "sex", "race"))
#> Error:
#> ! add_pop_counts(): `df` carries population-dimension column(s) `state_fips` not in `by_vars`; under a strict race_scheme ("single"/"bridged") the denominator would be silently summed over them. Add them to `by_vars`, or drop them from `df` to aggregate that dimension.
```

Public MCOD carries state/county geographic detail only through data
year 2004 (2005+ county detail needs restricted NCHS files). The county
denominators are distributed as a downloadable parquet; here we point
narcan at the small bundled Wyoming fixture instead of a live download.

``` r

fx <- system.file("extdata", "pop_singlerace_county_fixture.parquet",
                  package = "narcan")

wy_deaths <- data.frame(
    county_fips = "56013", year = 1999:2004, age = 40L, sex = "male",
    race = "white_only", deaths = c(1, 2, 4, 3, 5, 2)
)
wy_deaths
#>   county_fips year age  sex       race deaths
#> 1       56013 1999  40 male white_only      1
#> 2       56013 2000  40 male white_only      2
#> 3       56013 2001  40 male white_only      4
#> 4       56013 2002  40 male white_only      3
#> 5       56013 2003  40 male white_only      5
#> 6       56013 2004  40 male white_only      2

options(narcan.pop_single_county_parquet = fx)   # normally a downloaded parquet
add_pop_counts(subset(wy_deaths, year >= 2000), race_scheme = "single",
               by_vars = c("county_fips", "year", "age", "sex", "race"))
#>   county_fips year age  sex       race deaths  pop pop_scheme
#> 1       56013 2000  40 male white_only      2 1198     single
#> 2       56013 2001  40 male white_only      4 1195     single
#> 3       56013 2002  40 male white_only      3 1201     single
#> 4       56013 2003  40 male white_only      5 1180     single
#> 5       56013 2004  40 male white_only      2 1106     single
```

Single-race denominators start in 2000, so the 1999 row is dropped
before the join above – death-side coverage (public MCOD geography) and
denominator-side coverage (single-race) can differ, so join only where
both exist.

## Coverage and the frozen slice

The **national** single-race table is bundled at every covered year: the
frozen 0.5.0 `pop_singlerace` (2020-2024) plus `pop_singlerace_full`
(2000-2024, dependency-free `.rda`), so a national pre-2020 request
needs no download. The 2000-2019 backfill is additive – it does not
change those five years. The **state and county** backfills are the ones
distributed as downloadable single-race `*_full` parquets (tag-pinned
GitHub Release assets, cached on first use). So
[`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)/[`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md)
serve 2020-2024 from the bundled frozen table, but a pre-2020 `years`
request at state/county grain routes to that downloadable parquet – or
to a local copy via the `narcan.pop_single_<grain>_parquet` option, as
in the county chunk above. A request for a year the resolved data does
not cover hard-errors – never a silent 0-row or `NA`:

``` r

get_pop_state(scheme = "single", years = 2025)
#> Error:
#> ! get_pop_state(): single-race state denominators cover 2020-2024; year(s) 2025 were requested (pre-2020 years route to the backfill; there is no coverage past 2024).
```

## Provenance

[`pop_sources()`](https://mkiang.github.io/narcan/reference/pop_sources.md)
prints the manifest – dataset, scheme, grain, vintage, and coverage for
every dataset. Check a bundled dataset’s vintage before mixing it with a
freshly downloaded file.

``` r

invisible(utils::capture.output(src <- pop_sources()))
knitr::kable(src[, c("dataset", "scheme", "grain", "vintage",
                     "year_min", "year_max")])
```

| dataset | scheme | grain | vintage | year_min | year_max |
|:---|:---|:---|:---|:---|:---|
| pop_singlerace | single | national | V2024 | 2020 | 2024 |
| pop_singlerace_state | single | state | V2024 | 2020 | 2024 |
| pop_singlerace_full | single | national | int2000/int2010/V2024 | 2000 | 2024 |
| pop_bridged | bridged | national | seer_1969_2024 | 1969 | 2024 |
| pop_singlerace_county_full | single | county | int2000/int2010/V2024 | 2000 | 2024 |
| pop_singlerace_state_full | single | state | int2000/int2010/V2024 | 2000 | 2024 |
| pop_bridged_state | bridged | state | seer_1969_2024 | 1969 | 2024 |
| pop_bridged_county | bridged | county | seer_1969_2024 | 1969 | 2024 |

## Hispanic-stratified denominators

Both strict schemes carry a Hispanic-origin axis. For an origin-specific
denominator, add a `hispanic_origin` column (from
[`add_hispanic_origin()`](https://mkiang.github.io/narcan/reference/add_hispanic_origin.md))
to `by_vars`; for the all-origin denominator, drop the column entirely.
The two answer different questions – and origin-unknown deaths belong
only in the all-origin numerator, because there is no “unknown-origin”
population to divide by.

``` r

# All-origin: one row, every death counts (the 3 origin-unknown deaths are here).
all_origin <- data.frame(year = 2024L, age = 30L, sex = "female",
                         race = "white_only", deaths = 12 + 210 + 3)
add_pop_counts(all_origin, race_scheme = "single",
               by_vars = c("year", "age", "sex", "race"))$pop
#> [1] 8373814
```

``` r

# Origin-stratified: the non-denominable unknowns are dropped; origin is a key.
strat <- data.frame(
    year = 2024L, age = 30L, sex = "female", race = "white_only",
    hispanic_origin = c("hispanic", "non_hispanic"), deaths = c(12, 210)
)
add_pop_counts(strat, race_scheme = "single",
               by_vars = c("year", "age", "sex", "race", "hispanic_origin")
)[, c("hispanic_origin", "deaths", "pop")]
#>   hispanic_origin deaths     pop
#> 1        hispanic     12 2199747
#> 2    non_hispanic    210 6174067
```

The two stratified denominators sum to the all-origin one; the
difference is only which deaths sit in the numerator. Leaving a
`hispanic_origin` column in the frame but out of `by_vars` is a hard
error (it would be silently summed over), as is an `"unknown"`/`NA`
origin in a stratified join. The detailed-vs-binary recode distinction,
the pre-1990 mixed-era trap, and the misclassification caveats are
covered in
[`vignette("hispanic-origin")`](https://mkiang.github.io/narcan/articles/hispanic-origin.md).

## A note on hand-joins

Always join through
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
(or the guarded rate helpers). The descriptive accessors
[`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)/[`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md)
return population rows but do NOT guard a hand-join – if you
`left_join()` a slice yourself, or query the parquet with raw SQL, you
own verifying that the slice is unique on your keys and that no key is
silently dropped. The guarded path exists precisely to make those
mistakes impossible.

## See also

**Age-standardized fentanyl death rates by sex** – feeds these
denominators through a full age-standardized rate pipeline end to end.
