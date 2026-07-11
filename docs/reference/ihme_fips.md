# Mapping original FIPS codes to temporally stable FIPS codes from IHME

Counties change over time, which can make comparing across two different
time periods difficult. Researchers often use temporally-stable FIPS
designations to simplify comparing counties across long time periods.
This dataframe comes from the appendix of Dwyer-Lindgren L, et al. US
County-Level Trends in Mortality Rates for Major Causes of Death,
1980-2014. JAMA. 2016;316(22):2385–2401. doi:10.1001/jama.2016.13645

## Usage

``` r
ihme_fips
```

## Format

A data frame with 77 rows and 4 columns

- state:

  character, name of state

- group:

  character, grouping of FIPS characters to be collapsed

- orig_fips:

  character, FIPS code from the US Census

- ihme_fips:

  character, temporally stable FIPS code from IHME

## Source

<http://jamanetwork.com/journals/jama/fullarticle/2592499>
