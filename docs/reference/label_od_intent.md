# Label intent from underlying cause column for overdose drugs

Label intent from underlying cause column for overdose drugs

## Usage

``` r
label_od_intent(processed_df)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

## Value

dataframe

## Examples

``` r
df <- data.frame(
    year = 2019,
    ucod = c("X42", "X62"),
    f_records_all = c("T400", "T400")
)
df |>
    flag_drug_deaths(year = 2019) |>
    flag_od_intent(year = 2019) |>
    label_od_intent()
#>   year ucod f_records_all drug_death unintended_intent suicide_intent
#> 1 2019  X42          T400          1                 1              0
#> 2 2019  X62          T400          1                 0              1
#>   homicide_intent undetermined_intent  od_intent
#> 1               0                   0 unintended
#> 2               0                   0    suicide
```
