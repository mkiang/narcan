## Assemble the MCOD fixed-width dictionaries from the verified-layout CSVs.
##
## Network-free. Reads the two reviewed source CSVs in data-raw/fwf_layouts/ and
## writes BOTH exported datasets (data/*.rda) and the internal copy (R/sysdata.rda)
## from the same in-memory objects, so the exported and internal dictionaries can
## never drift. Positions were verified against raw NCHS bytes (public 1979-2024 +
## restricted 1989-2024) by the narcan_c verification pipeline; see NEWS.md for the
## corrections relative to 0.1.1.
##
## The CSVs are the source of truth: edit those (or re-run the verification pipeline)
## and re-run this script -- do not hand-edit the .rda.

library(dplyr)
library(readr)
library(here)
library(usethis)

restricted <- read_csv(
    here("data-raw", "fwf_layouts", "mcod_fwf_restricted.csv"),
    col_types = "cciiii"
) %>%
    arrange(year, ord) %>%
    select(name, type, start, end, year)

public <- read_csv(
    here("data-raw", "fwf_layouts", "mcod_fwf_public.csv"),
    col_types = "cciiili"
) %>%
    arrange(year, ord) %>%
    select(name, type, start, end, year, suppressed)

mcod_fwf_dicts <- restricted
mcod_public_fwf_dicts <- public

## Validate before writing (fail loud).
.valid_dict <- function(d, tiered = FALSE) {
    stopifnot(all(d$type %in% c("c", "n")))
    stopifnot(all(d$year >= 1979L & d$year <= 2024L))
    stopifnot(!anyNA(d$name), !anyNA(d$type), !anyNA(d$year))
    present <- if (tiered) filter(d, !suppressed) else d
    stopifnot(all(present$start >= 1L), all(present$start <= present$end))
    if (tiered) stopifnot(all(is.na(filter(d, suppressed)$start)))
    invisible(TRUE)
}
stopifnot(.valid_dict(mcod_fwf_dicts))
stopifnot(.valid_dict(mcod_public_fwf_dicts, tiered = TRUE))

## Column-set parity: public names == restricted names for every shared year.
shared_years <- intersect(unique(mcod_fwf_dicts$year), unique(mcod_public_fwf_dicts$year))
stopifnot(all(vapply(shared_years, function(y) {
    setequal(mcod_fwf_dicts$name[mcod_fwf_dicts$year == y],
             mcod_public_fwf_dicts$name[mcod_public_fwf_dicts$year == y])
}, logical(1))))

## Write exported (data/*.rda) and internal (R/sysdata.rda) from the SAME objects.
usethis::use_data(mcod_fwf_dicts, mcod_public_fwf_dicts, overwrite = TRUE)
usethis::use_data(mcod_fwf_dicts, mcod_public_fwf_dicts, internal = TRUE, overwrite = TRUE)
