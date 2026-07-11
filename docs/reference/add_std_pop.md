# Given a dataframe with age, returns a standard population

Returns the US 2000 population by default, by any population from the
narcan::std_pop\$std_cat column is valid.

## Usage

``` r
add_std_pop(df, std_cat = "s204", by_vars = "age")
```

## Arguments

- df:

  dataframe with age column (in 5-year bins)

- std_cat:

  standard population to use (default: US 2000 standard pop)

- by_vars:

  variables to merge on

## Value

dataframe

## Examples

``` r
df <- data.frame(age = c(0, 5, 25, 85))
add_std_pop(df)
#>   age  pop_std     unit_w
#> 1   0 18986520 0.06913399
#> 2   5 19919840 0.07253241
#> 3  25 17722067 0.06452985
#> 4  85  4259173 0.01550856
```
