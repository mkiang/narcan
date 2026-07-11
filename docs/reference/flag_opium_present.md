# Creates a column called \`opium_present\` if opioid death involved opium

Note that ICD9 years did not include an opium code. We code it as 0 by
default, but can be coded however specified in missing_val parameter.
This function flags all opioid deaths that involved opium.

## Usage

``` r
flag_opium_present(processed_df, year = NULL, missing_val = 0)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to detect

- missing_val:

  value to indicate missing (i.e., code did not exist)

## Value

a new dataframe with 1 additional column

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T400")
df |>
    flag_opioid_deaths(year = 2019) |>
    flag_opium_present(year = 2019)
#>   year ucod f_records_all opioid_death opium_present
#> 1 2019  X42          T400            1             1
```
