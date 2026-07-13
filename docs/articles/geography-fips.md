# Harmonizing geography with FIPS

County identifiers are not stable across data years. New counties
appear, a few merge or are renamed, and – more disruptively – NCHS does
not encode state the same way in every era. Public
multiple-cause-of-death (MCOD) files use NCHS numeric state codes
through 2002 and 2-letter postal abbreviations from 2003 on, and the
numeric schemes overlap while meaning different states (NCHS `"06"` is
Colorado; FIPS `"06"` is California).
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
translates whichever scheme a file uses into one 5-digit `county_fips`
that is comparable across years.

**Public-data caveat.** Public-use MCOD carries state and county
geography only through **2004**. From 2005 on, any sub-national analysis
requires the restricted NCHS All-County files. Every example below
therefore uses data years **1999-2004**, and nothing here works for
later years without the restricted data.

All data here are small synthetic frames plus bundled narcan crosswalks
(`st_fips_map`, `ihme_fips`); no chunk downloads anything and no
restricted NCHS records are used.

``` r

library(narcan)
```

## `state_abbrev_to_fips()` – one column at a time

The simplest helper maps a postal abbreviation to its zero-padded
2-digit state FIPS. Pair the input with the output to see the mapping:

``` r

abbrevs <- c("CA", "NY", "TX", "PA")
data.frame(abbrev = abbrevs, state_fips = state_abbrev_to_fips(abbrevs))
#>   abbrev state_fips
#> 1     CA         06
#> 2     NY         36
#> 3     TX         48
#> 4     PA         42
```

`"CA"` becomes `"06"`, not `"6"` – the zero-padding is what lets the
result feed a FIPS-keyed join. Unrecognized abbreviations and the
foreign/unknown code `"ZZ"` return `NA` (with a warning) rather than
passing through unconverted.

## `add_county_fips()` – the core call

Feed
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
the raw county column as **character** (`countyrs` for county of
residence, `countyoc` for occurrence). A numeric column is refused,
because numeric input has already dropped the leading zero (`01001`
reads as `1001`, whose first two digits parse as a different state).
Pass `year` – a scalar or a `year` column – so the coding scheme is
chosen deterministically.

Start with a small synthetic frame that straddles the 2002/2003
boundary. The 1999-2002 rows carry NCHS numeric state codes; the
2003-2004 rows carry postal abbreviations, exactly as the public files
do:

``` r

deaths <- tibble::tibble(
    id       = 1:5,
    year     = c(1999L, 2001L, 2002L, 2003L, 2004L),
    countyrs = c("06031", "36061", "48059", "CA075", "TX201")
)
deaths
#> # A tibble: 5 × 3
#>      id  year countyrs
#>   <int> <int> <chr>   
#> 1     1  1999 06031   
#> 2     2  2001 36061   
#> 3     3  2002 48059   
#> 4     4  2003 CA075   
#> 5     5  2004 TX201
```

Now harmonize. The call adds two columns – `st_fips` (2-digit state) and
`county_fips` (5-digit state + county) – decoding each row under its own
era’s scheme:

``` r

harmonized <- add_county_fips(deaths, countyrs)
harmonized[c("id", "year", "countyrs", "st_fips", "county_fips")]
#> # A tibble: 5 × 5
#>      id  year countyrs st_fips county_fips
#>   <int> <int> <chr>    <chr>   <chr>      
#> 1     1  1999 06031    08      08031      
#> 2     2  2001 36061    39      39061      
#> 3     3  2002 48059    53      53059      
#> 4     4  2003 CA075    06      06075      
#> 5     5  2004 TX201    48      48201
```

Read the before/after together. The raw `countyrs` string `"06031"`
(1999) maps to `st_fips` `"08"` and `county_fips` `"08031"` – NCHS
`"06"` is **Colorado**, not California. In 2003, California enters
instead through the abbreviation `"CA"`, giving `"06075"`. A single
numeric code like `"06..."` is therefore ambiguous on its own;
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
resolves it row by row from the year, so one frame spanning both eras
comes out on a consistent 5-digit FIPS grain. Codes it cannot place –
`"ZZ"` foreign residence, or the ambiguous NCHS code `"62"` – yield `NA`
rather than a spurious string.

## The bundled crosswalks

Both helpers read `st_fips_map`, which lines up state name, postal
abbreviation, FIPS code, and NCHS code so the two numeric schemes can be
told apart:

``` r

head(st_fips_map)
#> # A tibble: 6 × 4
#>   name           abbrev  fips  nchs
#>   <chr>          <chr>  <dbl> <dbl>
#> 1 Alabama        AL         1     1
#> 2 Alaska         AK         2     2
#> 3 American Samoa AS        60    62
#> 4 Arizona        AZ         4     3
#> 5 Arkansas       AR         5     4
#> 6 California     CA         6     5
```

`ihme_fips` handles the other half of the problem – counties that split,
merge, or are renamed over a long series. It collapses unstable
`orig_fips` codes to a temporally stable `ihme_fips` (from
Dwyer-Lindgren et al., JAMA 2016), so a county can be compared across
periods:

``` r

head(ihme_fips)
#>    state group orig_fips ihme_fips
#> 1 Alaska     1     02158     02158
#> 2 Alaska     1     02270     02158
#> 3 Alaska     2     02140     02188
#> 4 Alaska     2     02188     02188
#> 5 Alaska     3     02010     02013
#> 6 Alaska     3     02013     02013
```

For a multi-year county analysis, remap `county_fips` through
`ihme_fips` before comparing – several Alaska areas and Virginia
independent cities are otherwise not comparable across the 1999-2004
window.

## From FIPS to denominators

Once `county_fips` or a `state_fips` column exists, it is the join key
for sub-national denominators.
[`add_county_fips()`](https://mkiang.github.io/narcan/reference/add_county_fips.md)
names its state column `st_fips`;
[`add_pop_counts()`](https://mkiang.github.io/narcan/reference/add_pop_counts.md)
keys on `state_fips`, so rename `st_fips` to `state_fips` for a state
join, or use the 5-digit `county_fips` directly for a county join (see
the companion
[`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)).
As above, this path is only valid for **1999-2004** public data – 2005+
sub-national denominators require the restricted NCHS All-County files.

## See also

- [`vignette("population-denominators")`](https://mkiang.github.io/narcan/articles/population-denominators.md)
  – sub-national denominators use these FIPS-harmonized geographies as
  their join key.
- [`vignette("getting-started")`](https://mkiang.github.io/narcan/articles/getting-started.md)
  – the package overview and where this vignette fits in the pipeline.
