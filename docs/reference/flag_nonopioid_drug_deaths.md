# Flag non-opioid drug deaths according to ISW7 rules

Given an MCOD dataframe \*\*with\*\* drug_death and opioid_death columns
already, will flag non-opioid deaths. Must run flag_opioid_deaths() and
flag_drug_deaths() first.

## Usage

``` r
flag_nonopioid_drug_deaths(processed_df)
```

## Arguments

- processed_df:

  processed dataframe

## Value

new dataframe with a nonop_drug_death column

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T509")
df |>
    flag_drug_deaths(year = 2019) |>
    flag_opioid_deaths(year = 2019) |>
    flag_nonopioid_drug_deaths()
#>   year ucod f_records_all drug_death opioid_death nonop_drug_death
#> 1 2019  X42          T509          1            0                1
```
