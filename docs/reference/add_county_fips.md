# Make a new county_fips column that is consistent across years

Make a new county_fips column that is consistent across years

## Usage

``` r
add_county_fips(df, county_vector)
```

## Arguments

- df:

  cleaned MCOD dataframe with countyoc or countyrs column

- county_vector:

  specify if we should use countyoc or countyrs

## Value

same dataframe with new county_fips column

## Examples

``` r
df <- data.frame(countyrs = c("53033", "54001", "55079", "56001"))
add_county_fips(df, countyrs)
#>   countyrs state_substr county_substr st_fips county_fips
#> 1    53033           53           033      53       53033
#> 2    54001           54           001      54       54001
#> 3    55079           55           079      55       55079
#> 4    56001           56           001      56       56001
```
