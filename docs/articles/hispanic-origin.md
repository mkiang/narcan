# Hispanic origin: the two recode pairs

narcan gives you two ways to recode the NCHS `hspanicr` (Hispanic
Origin/Race Recode) field, and picking the wrong one is a common, quiet
mistake. This vignette is about which pair to use, and why they are not
interchangeable.

All data here are synthetic death counts joined to bundled public
Census/SEER population estimates; no restricted NCHS records are used,
and no chunk downloads anything.

``` r

library(narcan)
```

## Two pairs, two jobs

|  | Detailed pair | Binary pair |
|----|----|----|
| Vectorized recode | [`categorize_hspanicr()`](https://mkiang.github.io/narcan/reference/categorize_hspanicr.md) | [`categorize_hispanic_origin()`](https://mkiang.github.io/narcan/reference/categorize_hispanic_origin.md) |
| Add-a-column helper | [`add_hspanicr_column()`](https://mkiang.github.io/narcan/reference/add_hspanicr_column.md) | [`add_hispanic_origin()`](https://mkiang.github.io/narcan/reference/add_hispanic_origin.md) |
| Output | 9- or 14-category ethnicity factor | `"hispanic"` / `"non_hispanic"` / `"unknown"` |
| Use for | descriptive counts and proportions by subgroup | **rates** (it has a matching denominator) |

The **detailed** pair returns the full NCHS recode – Mexican, Puerto
Rican, Cuban, and so on, with non-Hispanic race detail. It is the right
tool for a table or figure that breaks Hispanic deaths into subgroups.
It has **no matching population denominator**: Census and SEER do not
publish population by these subgroups, so you cannot turn these counts
into rates.

The **binary** pair collapses the same field to the only Hispanic-origin
granularity the population data resolve – Hispanic vs non-Hispanic. That
is the recode to use when you are going to divide by a population.

``` r

codes <- c(1, 5, 6, 9)   # 9-category: Mexican, Other/unknown Hispanic,
                         # non-Hispanic white, Hispanic origin unknown
categorize_hspanicr(codes, year = 2019)          # detailed (subgroups)
#> [1] mexican           other_hispanic    nonhispanic_white hispanic_unknown 
#> 9 Levels: mexican < puerto_rican < cuban < ... < hispanic_unknown
categorize_hispanic_origin(codes, year = 2019)   # binary (for rates)
#> [1] "hispanic"     "hispanic"     "non_hispanic" "unknown"
```

Two subtleties are baked into the binary recode. Code 5 (“Other or
unknown Hispanic”) **is** Hispanic, so it maps to `"hispanic"`; only
code 9 (“Hispanic origin unknown/not stated”) maps to `"unknown"`. And
`year` is required, because the recode changed from 9 categories
(1989-2020) to 14 (2022+) and is reserved in 2021 – the two schemes are
not comparable, though the binary axis they collapse to is.

## Adding the column and joining a denominator

[`add_hispanic_origin()`](https://mkiang.github.io/narcan/reference/add_hispanic_origin.md)
reads the data year per row (from `year`, or two-digit `datayear`), so a
multi-year frame is labeled correctly:

``` r

deaths <- data.frame(
    year          = c(2019L, 2019L, 2019L),
    age           = 25L,
    sex           = "male",
    race          = "white_only",
    hspanicr      = c(1, 6, 9),   # Hispanic, non-Hispanic, origin-unknown
    deaths        = c(40, 900, 5)
)
deaths <- add_hispanic_origin(deaths)
deaths[, c("hspanicr", "hispanic_origin", "deaths")]
#>   hspanicr hispanic_origin deaths
#> 1        1        hispanic     40
#> 2        6    non_hispanic    900
#> 3        9         unknown      5
```

To get Hispanic-stratified **rates**, put `hispanic_origin` in `by_vars`
and use a scheme that resolves origin – `"single"` (2000+) or
`"bridged"` (1990+). Drop the origin-unknown deaths first: they have no
denominator.

``` r

strat <- deaths[deaths$hispanic_origin != "unknown", ]
add_pop_counts(
    strat,
    race_scheme = "single",
    by_vars = c("year", "age", "sex", "race", "hispanic_origin")
)[, c("hispanic_origin", "deaths", "pop")]
#>   hispanic_origin deaths     pop
#> 1        hispanic     40 2028208
#> 2    non_hispanic    900 6102642
```

Each origin gets its own denominator. An `"unknown"` or `NA` origin left
in the frame is a hard error, not a silent all-origin fallback – the
counts for those deaths belong in an all-origin numerator, never a
stratified one.

When you carry this into an age-standardized rate
([`add_std_pop()`](https://mkiang.github.io/narcan/reference/add_std_pop.md)
then
[`calc_stdrate_var()`](https://mkiang.github.io/narcan/reference/calc_stdrate_var.md)),
list `hispanic_origin` among the grouping variables you pass to the rate
helper, alongside the others (e.g. `year`, `sex`). Omitting a stratifier
does not error – it silently averages over it – so a forgotten
`hispanic_origin` returns one blended rate instead of a per-origin pair.

### Which knob? A shared name, two mechanisms

The join and the accessors both say `hispanic_origin`, but they are
different controls:

- [`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
  joins on a `hispanic_origin` **column** you list in `by_vars` (above).
- [`get_pop_state()`](https://mkiang.github.io/narcan/reference/get_pop_state.md)
  /
  [`get_pop_county()`](https://mkiang.github.io/narcan/reference/get_pop_county.md)
  take a `hispanic_origin=` **filter argument** that selects which
  origin’s population to return.

``` r

get_pop_state(scheme = "single", states = "06", years = 2024L,
              hispanic_origin = "hispanic")[1, ]
#> # A tibble: 1 × 10
#>   state_fips  year   age sex   race  hispanic_origin   pop scheme source vintage
#>   <chr>      <int> <dbl> <chr> <chr> <chr>           <int> <chr>  <chr>  <chr>  
#> 1 06          2024     0 fema… amer… hispanic        19836 single censu… V2024
```

Confusing the two is loud, not silent: passing the filter argument to
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
errors (`unused argument`), and putting a `hispanic_origin` column in a
frame without listing it in `by_vars` errors on the stray column.

## The mixed-era trap

SEER resolves Hispanic origin only from 1990. Before 1990 the bridged
denominators carry origin `"all"` only, so there is no such thing as a
pre-1990 Hispanic-specific rate – the population does not exist.
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
enforces this: a pre-1990 row with a stratified origin is a hard error.

That makes a continuous 1969-2024 “Hispanic trend” impossible, and
narcan will not let you fake one. A single frame that mixes the pre-1990
`"all"` marginal with post-1990 stratified rows is rejected, because
`"all"` already sums the strata – combining them double-counts:

``` r

mixed <- data.frame(
    year = c(1985L, 2000L), age = 40L, sex = "male", race = "white",
    hispanic_origin = c("all", "hispanic"), deaths = c(500, 30)
)
try(add_pop_counts(mixed, race_scheme = "bridged",
                   by_vars = c("year", "age", "sex", "race", "hispanic_origin")))
#> Error : add_pop_counts(): `hispanic_origin` mixes "all" with stratified values (hispanic/non_hispanic) in one frame; "all" already sums the strata, so this double-counts. Use one origin granularity per join (all-origin, OR hispanic+non_hispanic); combine eras with separate calls + rbind.
```

If you genuinely want to show the eras side by side, compute each
**separately** (each call internally homogeneous, so neither trips the
guard) and [`rbind()`](https://rdrr.io/r/base/cbind.html) the results –
keeping the pre-1990 segment as all-origin:

``` r

pre <- data.frame(year = 1985L, age = 40L, sex = "male", race = "white",
                  hispanic_origin = "all", deaths = 500)
pre <- add_pop_counts(pre, race_scheme = "bridged",
                      by_vars = c("year", "age", "sex", "race", "hispanic_origin"))

post <- expand.grid(year = c(1990L, 2000L), age = 40L, sex = "male",
                    race = "white",
                    hispanic_origin = c("hispanic", "non_hispanic"),
                    stringsAsFactors = FALSE)
post$deaths <- c(20, 480, 40, 520)
post <- add_pop_counts(post, race_scheme = "bridged",
                       by_vars = c("year", "age", "sex", "race", "hispanic_origin"))

trend <- rbind(pre, post)
trend$rate <- trend$deaths / trend$pop * 1e5
trend[order(trend$year), c("year", "hispanic_origin", "rate")]
#>   year hispanic_origin       rate
#> 1 1985             all  8.3092794
#> 2 1990        hispanic  3.3810398
#> 4 1990    non_hispanic  0.5743297
#> 3 2000        hispanic 42.9855622
#> 5 2000    non_hispanic  6.3746270
```

The discontinuity is the point. The 1985 row is an all-origin rate; the
1990 and 2000 rows are Hispanic-specific. They are different series and
must be read that way – the pre-1990 segment shows only the collapsed
line, never a stratified one. **Restrict origin-stratified trend
analysis to 1990+ (bridged) or 2000+ (single);** the pre-1990 point
exists here only to make the break visible.

## Two caveats for Hispanic-stratified rates

**Misclassification.** The numerator’s Hispanic origin comes from the
death certificate; the denominator’s comes from Census/SEER. They are
measured separately and are differentially misclassified – modest for
Hispanic and Asian or Pacific Islander populations, large for American
Indian or Alaska Native – so origin-specific rates carry a
numerator/denominator bias (Arias E, Heron M, Hakes J. The Validity of
Race and Hispanic-origin Reporting on Death Certificates in the United
States: An Update. *Vital Health Stat 2*(172). Hyattsville, MD: National
Center for Health Statistics; 2016).

**Incomplete early reporting.** The Hispanic-origin item was phased onto
state death certificates through about 1997, so national
origin-stratified numerators for 1990-1996 undercount Hispanic deaths
and the resulting rates run low.
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
emits a once-per-session message when a bridged join touches that span.
