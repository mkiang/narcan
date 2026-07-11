# Create a categorical age column from a converted ager27 column

Simply makes more meaningful labels on the age column. Assumes that the
age column was created from the convert_ager27() function. Allows for
using tidyr::complete() even when some age/year/race combinations have
no observations.

## Usage

``` r
categorize_age_5u1(ageu1_column)
```

## Arguments

- ageu1_column:

  age column created from convert_ager27u1()

## Value

factor

## Examples

``` r
categorize_age_5u1(c(0, 1, seq(5, 85, 5)))
#>  [1] <1    1-4   5-9   10-14 15-19 20-24 25-29 30-34 35-39 40-44 45-49 50-54
#> [13] 55-59 60-64 65-69 70-74 75-79 80-84 85+  
#> 19 Levels: <1 < 1-4 < 5-9 < 10-14 < 15-19 < 20-24 < 25-29 < 30-34 < ... < 85+
```
