# A wrapper function to perform basic cleaning of ICD-9 dataframes

Across 1979-1998, MCOD data have minor inconsistencies. This wrapper
function renames nature of injury columns, pads UCOD codes with no
sub-codes, prefixes an E to external cause of injury codes and an N to
nature of injury codes, and trims unnecessary characters and whitespace.

## Usage

``` r
clean_icd9_data(icd9_df)
```

## Arguments

- icd9_df:

  an ICD-9 dataframe

## Value

dataframe

## Examples

``` r
df <- data.frame(
    ucod = c("8001", "4321"),
    record_1 = c("8001", "4321"),
    rniflag_1 = c(0, 1)
)
clean_icd9_data(df)
#>    ucod record_1 rnifla_1
#> 1 E8001     8001        0
#> 2  4321     4321        1
```
