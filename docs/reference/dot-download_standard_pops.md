# Download Standard Populations

Download a variety of common standard populations from the SEER website.
Performs minimal manipulation to make age and standard factors human
readable and consistent across standards. Note that one must
dplyr::filter() to a single standard before performing
dplyr::left_join() on age_cat.

## Usage

``` r
.download_standard_pops()
```

## Source

https://seer.cancer.gov/stdpopulations/

## Value

Dataframe with SEER standard populations
