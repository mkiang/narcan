# Add harmonized coded occupation and industry columns

Coded occupation and industry appear in the MCOD files under two
different, \*\*non-comparable\*\* coding schemes at different byte
positions and column names. This helper hides those details: given an
imported MCOD data frame and its data year, it appends standardized
columns (\`occ_coded\`, \`ind_coded\`, their recodes, the scheme, and an
availability flag) so downstream code does not need to know which era or
tier the data came from.

## Usage

``` r
add_coded_occupation(df, year)
```

## Arguments

- df:

  a data frame imported via \[import_mcod_fwf()\] (or
  \`.import_restricted_data()\`)

- year:

  the data year of \`df\` (integer)

## Value

\`df\` with added columns: \`occ_scheme\` (character, the coding scheme
or \`NA\`), \`occ_coded\`, \`ind_coded\`, \`occ_recode\`,
\`ind_recode\`, and \`occ_available\` (logical; \`TRUE\` when the scheme
applies and \`occ_coded\` has any non-missing value)

## Details

Availability matrix (coded occupation/industry):

|  |  |  |
|----|----|----|
| **Years** | **Scheme** | **Notes** |
| 1985-1999 | \`3digit_census\` | 1980-Census basis 1985-1992, 1990-Census 1993-1999; source columns \`occup\` (@88-90) and \`industry\` (@85-87); state-dependent coverage |
| 2000-2019 | (none) | coded occupation/industry not collected |
| 2020+ | \`4digit_niosh\` | NCHS+NIOSH 4-digit codes; source columns \`occupation\`/\`occupationr\` (@806-811) and \`industry\`/\`industryr\` (@812-817) |

The 3-digit (1985-1999) and 4-digit (2020+) codes are \*\*not
comparable\*\* – do not chain a series across the gap. Tier difference:
the 4-digit codes reach the **public** file in data year 2020 but the
**restricted** file only in 2021, so \`occ_coded\` is all-\`NA\` for
restricted 2020 (use the public file for 2020 occupation); from 2021 the
public and restricted codes are identical.

## Examples

``` r
if (FALSE) { # \dontrun{
df <- import_mcod_fwf("mort2023us.dat", 2023, tier = "public")
df <- add_coded_occupation(df, 2023)
table(df$occ_scheme)          # "4digit_niosh"
} # }
```
