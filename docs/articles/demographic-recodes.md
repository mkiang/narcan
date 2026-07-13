# Demographic recodes across coding eras

NCHS changed how it codes age, sex, and race several times over the
decades. narcan’s recoders normalize each raw field to one stable
scheme, dispatching on the data year. The recurring hazard is that codes
which look continuous across a revision are not, and chaining them
produces artifactual trends. This vignette walks the three families –
age, sex, and race – and shows where each one breaks.

Every input below is a small illustrative vector, not an NCHS record,
and every chunk runs.

``` r

library(narcan)
```

## Age: two recodes, two outputs

narcan carries two age recoders because MCOD files carry two different
age fields.

**Detail age (`age`) to completed years.**
[`remap_age()`](https://mkiang.github.io/narcan/reference/remap_age.md)
reads the unit-coded detail-age field and returns completed years in a
new `age_years` column. The encoding changed at 2003 (a 3-digit code
before, 4-digit after), so pass `year`. Sub-year ages (months, weeks,
days) collapse to 0; not-stated codes become `NA`.

``` r

remap_age(data.frame(year = 1999, age = c(37, 206, 999)))$age_years    # pre-2003
#> [1] 37  0 NA
remap_age(data.frame(year = 2019, age = c(1037, 2006, 1999, 9999)))$age_years  # 2003+
#> [1] 37  0 NA NA
```

Pre-2003, a years-unit code is the age itself (37 -\> 37) and `206` is 6
months -\> 0. From 2003 a leading `1` marks years, so `1037` -\> 37 and
`2006` (months) -\> 0; both `1999` and `9999` are not-stated -\> `NA`.

**AGER27 recode (`ager27`) to 5-year bins.**
[`convert_ager27()`](https://mkiang.github.io/narcan/reference/convert_ager27.md)
maps the NCHS 27-level age recode (codes 1-26 are age groups, 27 is “not
stated” -\> `NA`) to 5-year-bin starts (0, 5, …, 85). The finer under-5
categories collapse into the 0-4 bin, and everything 85 and older into
85.

``` r

convert_ager27(data.frame(ager27 = c(1, 7, 10, 23, 27)))
#>   age
#> 1   0
#> 2   5
#> 3  20
#> 4  85
#> 5  NA
```

**Label the bins.**
[`categorize_age_5()`](https://mkiang.github.io/narcan/reference/categorize_age_5.md)
turns 5-year-bin starts into an ordered factor with readable labels –
the form
[`tidyr::complete()`](https://tidyr.tidyverse.org/reference/complete.html)
and ggplot2 expect.

``` r

categorize_age_5(seq(0, 85, 5))
#>  [1] 0-4   5-9   10-14 15-19 20-24 25-29 30-34 35-39 40-44 45-49 50-54 55-59
#> [13] 60-64 65-69 70-74 75-79 80-84 85+  
#> 18 Levels: 0-4 < 5-9 < 10-14 < 15-19 < 20-24 < 25-29 < 30-34 < ... < 85+
```

The two age outputs are **not** interchangeable. `age_years` is single
completed years; the AGER27 path – and the standard populations
[`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
uses – are 5-year bins. To bin `age_years` yourself:

``` r

age_years <- c(0, 3, 37, 88)
pmin(floor(age_years / 5) * 5, 85)     # -> 0, 0, 35, 85
#> [1]  0  0 35 85
```

## Sex: numeric before 2003, character after

[`categorize_sex()`](https://mkiang.github.io/narcan/reference/categorize_sex.md)
maps either coding – numeric `1`/`2` (1979-2002) or character
`"M"`/`"F"` (2003+) – to `"male"`/`"female"`, the labels
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
joins on. Pass `year`; it is authoritative.

``` r

categorize_sex(c(1, 2, 9), year = 2000)       # pre-2003 numeric
#> [1] "male"   "female" NA
categorize_sex(c("M", "F", "U"), year = 2019) # 2003+ character
#> [1] "male"   "female" NA
categorize_female(c(1, 2), year = 2000)       # 1 = female, 0 = male
#> [1] 0 1
```

The trap: omit `year` and the era is guessed from the column type. A
pre-2003 sex column re-read from a CSV as the **characters** `"1"`/`"2"`
is guessed to be the modern `"M"`/`"F"` scheme and maps to all-`NA` –
loudly, with a warning.

``` r

categorize_sex(c("1", "2"), year = NULL)     # guesses modern -> NA (with a warning)
#> Warning: categorize_sex(): `year` not supplied; inferring the coding era from
#> the column type (2003+ 'M'/'F'). Pass `year` to be explicit.
#> Warning: categorize_sex(): every value mapped to NA -- this usually means the
#> `year`/era does not match the column's coding (numeric 1/2 vs character M/F).
#> [1] NA NA
categorize_sex(c("1", "2"), year = 2000)     # year fixes it -> male, female
#> [1] "male"   "female"
```

## Race: the most-revised field

Race coding changed repeatedly, and
[`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
dispatches on `year` to a standardized code that
[`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
then labels. These eras are genuinely different schemes, not one
evolving list.

**1992-2020 (bridged race).** Detailed codes 1-7, plus a family of
“other” codes that all collapse to 99.

``` r

r <- remap_race(data.frame(year = 2004, race = c(1, 2, 3, 6, 18)), year = 2004)
r$race                          # 1 2 3 6 99
#> [1]  1  2  3  6 99
categorize_race(r$race)         # white, black, american_indian, hawaiian, other
#> [1] white           black           american_indian hawaiian       
#> [5] other          
#> 9 Levels: total < white < black < american_indian < chinese < ... < other
```

The Asian and Pacific Islander subgroups (Chinese, Japanese, Hawaiian,
Filipino) are resolved separately in this era but have no matching
bridged population denominator, so collapse them to a single API group
before computing rates.

**Earlier eras differ.** The same raw code means different things before
1992, which is exactly why
[`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
refuses to run without a year.

``` r

remap_race(data.frame(year = 1985, race = c(0, 1, 7, 8)), year = 1985)$race  # 99 1 99 7
#> [1] 99  1 99  7
```

**2021 is a gap.** The bridged race fields were dropped and the
single-race recodes were not yet populated, so
[`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
sets race to `NA` (with a warning).

``` r

remap_race(data.frame(year = 2021, race = c(1, 2)), year = 2021)$race
#> Warning in remap_race(data.frame(year = 2021, race = c(1, 2)), year = 2021):
#> race is retired in 2021 (bridged race dropped; single-race recodes not
#> populated until 2022); setting race to NA.
#> [1] NA NA
```

**2022+ (single race).** From 2022 the bridged column is gone;
[`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
reads the single-race Race Recode (`racer5`) and maps it into a
**non-colliding** code space (101-106) so the two schemes cannot be
silently mixed.
[`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
labels these with an `_only` suffix.

``` r

r22 <- remap_race(data.frame(year = 2022, racer5 = c(1, 2, 4, 6)), year = 2022)
#> Warning in remap_race(data.frame(year = 2022, racer5 = c(1, 2, 4, 6)), year =
#> 2022): 2022+ race uses the single-race Race Recode 6 mapped to codes 101-106;
#> these are NOT comparable to the bridged race scheme (2020 and earlier).
r22$race                                # 101 102 104 106
#> [1] 101 102 104 106
categorize_race(c(101, 102, 104, 106))  # white_only, black_only, asian_only, multiracial
#> Warning in categorize_race(c(101, 102, 104, 106)): single-race codes (101-106)
#> are not comparable to the bridged race scheme (2020 and earlier); do not
#> combine the two into a single trend.
#> [1] white_only  black_only  asian_only  multiracial
#> 6 Levels: white_only < black_only < american_indian_only < ... < multiracial
```

Both
[`remap_race()`](https://mkiang.github.io/narcan/reference/remap_race.md)
and
[`categorize_race()`](https://mkiang.github.io/narcan/reference/categorize_race.md)
warn on the single-race codes, because bridged (2020 and earlier) and
single-race (2022+) categories are **not comparable**. Do not chain them
into one trend.

## Why the year matters

Two coding boundaries hide in these recoders, and neither is the ICD
boundary:

- **Age and sex** change their coding at **2003** (the death-certificate
  revision).
- **Race** changes repeatedly, with the sharpest break at **2021/2022**
  (bridged to single race).

Neither lines up with the ICD-9-to-ICD-10 boundary at **1999** that the
flag functions dispatch on. A long multi-year analysis therefore carries
several independent comparability breaks at once, so each recoder reads
the data year to apply the right map, and not-stated codes always become
`NA` rather than a guessed value.

These recoders produce exactly the `age`, `sex`, and `race` columns that
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
joins on, with labels that match the population data.

## See also

- [`vignette("getting-started")`](https://mkiang.github.io/narcan/articles/getting-started.md)
  – where these recodes sit in the full pipeline.
- [`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)
  – the denominators these columns join to, and the matching race-scheme
  caveats.
- [`vignette("real-data-end-to-end")`](https://mkiang.github.io/narcan/articles/real-data-end-to-end.md)
  – the recoders applied to a real public-use file.
