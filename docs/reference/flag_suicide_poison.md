# Flag suicide by poison

ICD-10 only (see flag_suicide_types). Warns if an explicit pre-1999
\`year\` is supplied.

## Usage

``` r
flag_suicide_poison(df, year = NULL)
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
df <- data.frame(ucod = c("X60", "X64", "X72"))
flag_suicide_poison(df)
#>   ucod suicide_poison
#> 1  X60              1
#> 2  X64              1
#> 3  X72              0
```
