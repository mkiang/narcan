library(tidyverse)

## We use the 2000 dct file from NBER as our baseline. We need to remove
## overlapping column specs (readr::read_fwf() doesn't accept them).
## We add `default = Inf` because we don't want to drop the last column.
dct_1999_2002 <- narcan:::.dct_to_fwf_df(1999) %>%
    filter(end < lead(start, default = Inf))

## NBER codes 2003 in a weird way. Use 2004 because it's closer to
## what we want.
dct_2003_2015 <- narcan:::.dct_to_fwf_df(2004) %>%
    filter(end <= lead(start, default = Inf)) %>%
    mutate(end = case_when(
        grepl("record_", name, fixed = TRUE) ~ end + 1,
        TRUE ~ end))

fwf_1999   <- readr::fwf_positions(dct_1999_2002$start,
                                   dct_1999_2002$end,
                                   dct_1999_2002$name)
ctype_1999 <- paste(dct_1999_2002$type, collapse = "")

fwf_2003   <- readr::fwf_positions(dct_2003_2015$start,
                                   dct_2003_2015$end,
                                   dct_2003_2015$name)
ctype_2003 <- paste(dct_2003_2015$type, collapse = "")

devtools::use_data(dct_1999_2002, fwf_1999, ctype_1999,
                   dct_2003_2015, fwf_2003, ctype_2003,
                   internal = TRUE, overwrite = TRUE)

