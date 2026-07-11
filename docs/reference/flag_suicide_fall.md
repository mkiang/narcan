# Flag suicide by fall

ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999
\`year\` is supplied.

## Usage

``` r
flag_suicide_fall(df, year = NULL)
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
df <- data.frame(ucod = c("X80", "X72"))
flag_suicide_fall(df)
#>   ucod suicide_fall
#> 1  X80            1
#> 2  X72            0
```
