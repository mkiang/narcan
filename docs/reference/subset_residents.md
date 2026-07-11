# Subset to US residents

Subset to US residents

## Usage

``` r
subset_residents(df, drop_col = TRUE)
```

## Arguments

- df:

  an MCOD dataframe

- drop_col:

  drop the \`restatus\` column after subsetting (default: TRUE)

## Value

dataframe

## Examples

``` r
df <- data.frame(
    restatus = c(1, 2, 3, 4),
    ucod = c("X42", "I250", "O95", "X72")
)
subset_residents(df)
#>   ucod
#> 1  X42
#> 2 I250
#> 3  O95
```
