# Flag drug deaths according to ISW7 rules

Given an MCOD dataframe, will apply ISW7 rules to flag drug deaths for
both ICD9 and ICD10 codes.For ICD9, it is true if any poison code is in
any record field. For ICD10, it is true if there is a specific UCOD code
\*\*and\*\* at least one specified T-code.

## Usage

``` r
flag_drug_deaths(processed_df, year = NULL, keep_cols = FALSE)
```

## Arguments

- processed_df:

  processed dataframe

- year:

  if NULL, will attempt to detect

- keep_cols:

  keep intermediate columns

## Value

new dataframe with a drug_death column

## Examples

``` r
df <- data.frame(
    year = 2019,
    ucod = c("X42", "I250"),
    f_records_all = c("T400 T401", "I250")
)
flag_drug_deaths(df, year = 2019)
#>   year ucod f_records_all drug_death
#> 1 2019  X42     T400 T401          1
#> 2 2019 I250          I250          0
```
