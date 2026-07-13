# Make a new county_fips column that is consistent across years

Adds a \`county_fips\` column (2-digit state FIPS + 3-digit county) that
is comparable across data years, translating whichever state-coding
scheme the input uses into FIPS.

## Usage

``` r
add_county_fips(
  df,
  county_vector,
  year = NULL,
  scheme = c("auto", "nchs", "abbrev", "fips")
)
```

## Arguments

- df:

  cleaned MCOD dataframe with a \`countyoc\` or \`countyrs\` column

- county_vector:

  unquoted column to use (\`countyoc\` or \`countyrs\`)

- year:

  data year(s) for the records, used to pick the coding scheme. A scalar
  (or vector) of 4-digit years, or \`NULL\` (default) to read a \`year\`
  column from \`df\` if present.

- scheme:

  state-coding scheme: \`"auto"\` (default; resolve from \`year\`, then
  from the codes) or force \`"nchs"\`, \`"abbrev"\`, or \`"fips"\`.

## Value

same dataframe with new \`st_fips\` and \`county_fips\` columns

## Details

NCHS mortality files do not code state the same way in every era, so the
scheme must be identified before it can be translated:

|  |  |  |
|----|----|----|
| **Data years** | **State field** | **\`scheme\`** |
| 1979-2002 | NCHS numeric codes (e.g. Colorado = \`"06"\`) | \`"nchs"\` |
| 2003-present | 2-letter postal abbreviations (e.g. \`"CO"\`, \`"ZZ"\`) | \`"abbrev"\` |
| (user-preconverted) | already FIPS numeric (Colorado = \`"08"\`) | \`"fips"\` |

The NCHS numeric codes overlap the FIPS numeric codes but mean
\*different\* states (NCHS Colorado \`"06"\` is FIPS California), so a
bare 2-digit numeric code is ambiguous on its own. This is resolved by
the data year: pass \`year\` (a scalar, or leave \`NULL\` to read a
\`year\` column from \`df\`) and the scheme is chosen deterministically.
Only if no year is available does the function fall back to guessing
from the observed codes, and it then \*\*warns loudly\*\* whenever the
codes are ambiguous. \`"fips"\` is never auto-detected from numeric
codes with a year \>= 2003 (raw files use abbreviations by then); pass
\`scheme = "fips"\` explicitly for data you have already converted.

narcan is US-only: the crosswalk covers the 50 states and DC, not
territories. Any code that is not one of those – a
territory/associated-state code, a foreign/unknown residence (\`"ZZ"\`),
or an otherwise unrecognized code – resolves to \`NA\` state FIPS (with
a warning for genuinely unexpected codes), and its \`county_fips\` is
\`NA\` rather than a spurious string.

Safest usage for a subset analysis: call \`add_county_fips()\` on the
full national frame \*first\*, then filter to the states you want.
Filtering to a single ambiguous numeric code before translation removes
the context needed to identify the scheme.

## Examples

``` r
## Modern (2003+) abbreviation-coded data
df <- data.frame(countyrs = c("CA001", "NY001", "ZZ999"), year = 2019)
add_county_fips(df, countyrs)
#>   countyrs year state_substr county_substr st_fips county_fips
#> 1    CA001 2019           CA           001      06       06001
#> 2    NY001 2019           NY           001      36       36001
#> 3    ZZ999 2019           ZZ           999    <NA>        <NA>

## Pre-2003 NCHS-numeric data -- pass the year so "06" resolves to Colorado
old <- data.frame(countyrs = c("06031", "06005"))
add_county_fips(old, countyrs, year = 2000)
#>   countyrs state_substr county_substr st_fips county_fips
#> 1    06031           06           031      08       08031
#> 2    06005           06           005      08       08005
```
