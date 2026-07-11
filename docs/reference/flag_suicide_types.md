# Flag suicide five types: firearm, poisoning, fall, suffocation, or other

ICD-10 only. Pre-1999 (ICD-9) data returns all zeros and emits a single
warning; ICD-9 detection is a future work item. The subtype helpers
below warn only when a pre-1999 \`year\` is passed explicitly, so
calling this orchestrator does not emit duplicate warnings.

## Usage

``` r
flag_suicide_types(df, year = NULL)
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
df <- data.frame(
    year = 2019,
    ucod = c("X72", "X68", "X80", "X70", "X78")
)
flag_suicide_types(df, year = 2019)
#>   year ucod suicide_firearm suicide_poison suicide_fall suicide_suffocation
#> 1 2019  X72               1              0            0                   0
#> 2 2019  X68               0              1            0                   0
#> 3 2019  X80               0              0            1                   0
#> 4 2019  X70               0              0            0                   1
#> 5 2019  X78               0              0            0                   0
#>   suicide_other
#> 1             0
#> 2             0
#> 3             0
#> 4             0
#> 5             1
```
