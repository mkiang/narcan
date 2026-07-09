## A tiny synthetic restricted dictionary + matching fixed-width records, used to
## exercise the importer engine without any real (DUA) data. Overlapping fields
## (st nested in cty) mirror the real geography nesting.
mini_restricted_dict <- function(year = 2050L) {
    tibble::tibble(
        name  = c("cty",   "st",    "sex", "age",  "ucod"),
        type  = c("c",     "c",     "c",   "n",    "c"),
        start = c(1L,      1L,      6L,    7L,     9L),
        end   = c(5L,      2L,      6L,    8L,     12L),
        year  = year
    )
}

## public variant: geography suppressed (NA positions), same names for parity
mini_public_dict <- function(year = 2050L) {
    d <- mini_restricted_dict(year)
    d$suppressed <- d$name %in% c("cty", "st")
    d$start[d$suppressed] <- NA_integer_
    d$end[d$suppressed] <- NA_integer_
    d
}

## fixed-width lines matching mini_restricted_dict: cty(1-5) st(1-2 nested) sex(6)
## age(7-8) ucod(9-12)
mini_fixture_lines <- function() {
    c(
        "06075M07C509",
        "36061F88X44 "
    )
}

write_fixture <- function() {
    f <- withr::local_tempfile(fileext = ".txt", .local_envir = parent.frame())
    writeLines(mini_fixture_lines(), f, sep = "\n")
    f
}
