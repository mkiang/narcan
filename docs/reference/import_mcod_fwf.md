# Import MCOD fixed-width data (restricted or public tier)

Reads a raw NCHS Multiple Cause of Death fixed-width file into a data
frame using the byte-verified column dictionary for the given year and
tier. The restricted and public files share the within-record layout;
the public file suppresses (blanks) sub-state geography from 2005 and
the certifier-entered items (certifier, tobacco, pregnancy) from 2003.
Those suppressed columns are returned as all-`NA` so the public output
is column-compatible with the restricted output. Data year 2013 is a
separate case: `certifier` and `tobacco_use` are blank in the
*restricted* 2013 file, which is an upstream NCHS source gap rather than
a suppression (2012 and 2014 are populated, and `pregnancy_status` is
populated in 2013). Both fields read as `NA` from either tier that year,
but for different reasons – the public tier blanks them in every year as
a standing suppression.

## Usage

``` r
import_mcod_fwf(file, year, tier = c("restricted", "public"))
```

## Arguments

- file:

  path to the raw MCOD plaintext (or unzipped) fixed-width file

- year:

  year of the MCOD data (integer)

- tier:

  `"restricted"` (default) or `"public"`

## Value

a tibble with one row per death and columns in the restricted layout
order for that year, plus a canonical `year` column (1979-1995 files
also retain their original `datayear` column)

## Examples

``` r
if (FALSE) { # \dontrun{
df <- import_mcod_fwf("MULT2020.USAllCnty.txt", 2020, tier = "restricted")
pub <- import_mcod_fwf("mort2020us.dat", 2020, tier = "public")
} # }
```
