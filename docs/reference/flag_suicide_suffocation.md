# Flag suicide by suffocation

ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999
\`year\` is supplied.

## Usage

``` r
flag_suicide_suffocation(df, year = NULL)
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
df <- data.frame(ucod = c("X70", "X80"))
flag_suicide_suffocation(df)
#>   ucod suicide_suffocation
#> 1  X70                   1
#> 2  X80                   0
```
