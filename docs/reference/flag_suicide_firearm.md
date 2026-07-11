# Flag suicide by firearm

ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999
\`year\` is supplied.

## Usage

``` r
flag_suicide_firearm(df, year = NULL)
```

## Arguments

- df:

  a processed MCOD dataframe

- year:

  optional; warns if explicitly \< 1999

## Value

dataframe

## Examples

``` r
df <- data.frame(ucod = c("X72", "X73", "X60"))
flag_suicide_firearm(df)
#>   ucod suicide_firearm
#> 1  X72               1
#> 2  X73               1
#> 3  X60               0
```
