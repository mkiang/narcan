# Flag all opioid deaths that were not from heroin

NOTE: assumes flag_opioid_types() has already been run.

## Usage

``` r
flag_nonheroin(processed_df)
```

## Arguments

- processed_df:

  MCOD dataframe with flag_opioid_types() columns

## Value

dataframe

## Examples

``` r
df <- data.frame(year = 2019, ucod = "X42", f_records_all = "T402")
df |>
    flag_opioid_deaths(year = 2019) |>
    flag_opioid_types(year = 2019) |>
    flag_nonheroin()
#>   year ucod f_records_all opioid_death opium_present heroin_present
#> 1 2019  X42          T402            1             0              0
#>   other_natural_present methadone_present other_synth_present other_op_present
#> 1                     1                 0                   0                0
#>   unspecified_op_present num_opioids multi_opioids nonheroin_present
#> 1                      0           1             0                 1
```
