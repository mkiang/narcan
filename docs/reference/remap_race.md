# Remaps the race column to a standardized code across data years

The race coding in MCOD data changed repeatedly. Through 2020 the
bridged-race detailed \`race\` column is standardized to a common set
(white, black, American Indian, and the Asian/Pacific Islander
subgroups, with the remainder collapsed to 99). From 2022 the bridged
race column is gone; this reads the single-race Race Recode 6
(\`racer5\`) instead and maps it to a non-colliding code space (101-106)
so bridged and single-race values can share one column without being
confused. Data year 2021 is a transition gap – the bridged race fields
are dropped and the single-race recodes are not yet populated – so
\`race\` is set to NA.

## Usage

``` r
remap_race(icd_df, year = NULL)
```

## Arguments

- icd_df:

  an MCOD dataframe (a single data year)

- year:

  year of file; if NULL will try to extract year automatically

## Value

dataframe with a standardized \`race\` column

## Details

Bridged (2020 and earlier) and single-race (2022+) codes are NOT
comparable and must not be chained into a single trend. Use with
categorize_race().

## Examples

``` r
df <- data.frame(year = 2019, race = c(1, 2, 3, 18))
remap_race(df, year = 2019)
#>   year race
#> 1 2019    1
#> 2 2019    2
#> 3 2019    3
#> 4 2019   99
```
