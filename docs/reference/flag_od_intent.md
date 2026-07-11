# Flag overdose deaths by their UCOD intent code

Flag overdose deaths by their UCOD intent code

## Usage

``` r
flag_od_intent(processed_df, year = NULL)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to extract

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
    flag_od_intent(year = 2019)
#>   year ucod f_records_all drug_death unintended_intent suicide_intent
#> 1 2019  X42          T400          1                 1              0
#> 2 2019  X62          T400          1                 0              1
#>   homicide_intent undetermined_intent
#> 1               0                   0
#> 2               0                   0
```
