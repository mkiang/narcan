# Creates a new column called maternal_death with 1 if maternal death

Maternal deaths according to ICD-10 codes.

## Usage

``` r
flag_maternal_deaths(
  processed_df,
  year = NULL,
  ucod_only = FALSE,
  keep_cols = FALSE
)
```

## Arguments

- processed_df:

  MCOD dataframe already processed

- year:

  if NULL, will attempt to detect

- ucod_only:

  if TRUE, only flag maternal deaths in underlying cause

- keep_cols:

  keep intermediate columns

## Value

a new dataframe with a binary maternal_death column

## Examples

``` r
df <- data.frame(
    year = 2019,
    ucod = c("O95", "I250"),
    f_records_all = c("O95", "I250")
)
flag_maternal_deaths(df, year = 2019)
#>   year ucod f_records_all maternal_death
#> 1 2019  O95           O95              1
#> 2 2019 I250          I250              0
```
