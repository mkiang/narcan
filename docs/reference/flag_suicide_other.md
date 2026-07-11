# Flag suicide by other (not poison, fall, firearm, suffocation)

ICD-10 codes: U03, X71, X75-X79, X81-X84, Y870. ICD-10 only (see
flag_suicide_types). Warns if an explicit pre-1999 \`year\` is supplied.

## Usage

``` r
flag_suicide_other(df, year = NULL)
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
df <- data.frame(ucod = c("X78", "X83", "X72"))
flag_suicide_other(df)
#>   ucod suicide_other
#> 1  X78             1
#> 2  X83             1
#> 3  X72             0
```
