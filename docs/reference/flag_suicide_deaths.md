# Flag suicide deaths (no accidental poisoning)

ICD-10 only. Pre-1999 (ICD-9) data returns all zeros and emits a
warning; ICD-9 suicide detection is a future work item.

## Usage

``` r
flag_suicide_deaths(df, year = NULL)
```

## Arguments

- df:

  processed MCOD dataframe

- year:

  if NULL, detected from \`year\`/\`datayear\`; used only to warn on
  pre-1999 (ICD-9) data

## Value

new dataframe

## Examples

``` r
df <- data.frame(year = 2019, ucod = c("X72", "I250"))
flag_suicide_deaths(df, year = 2019)
#>   year ucod suicide_death
#> 1 2019  X72             1
#> 2 2019 I250             0
```
