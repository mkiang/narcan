# Create a new column with labels for suicide type

Create a new column with labels for suicide type

## Usage

``` r
label_suicide_type(processed_df)
```

## Arguments

- processed_df:

  processed MCOD dataframe

## Value

dataframe

## Examples

``` r
df <- data.frame(year = 2019, ucod = c("X72", "X68"))
df |>
    flag_suicide_types(year = 2019) |>
    label_suicide_type()
#>   year ucod suicide_firearm suicide_poison suicide_fall suicide_suffocation
#> 1 2019  X72               1              0            0                   0
#> 2 2019  X68               0              1            0                   0
#>   suicide_other    suicide_type
#> 1             0 suicide_firearm
#> 2             0  suicide_poison
```
