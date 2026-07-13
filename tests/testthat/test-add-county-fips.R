# Regression tests for add_county_fips() -- P2b redesign: year-primary scheme
# detection (NCHS numeric <=2002, postal abbreviations 2003+), explicit scheme
# override, and safe NA handling. See verify_fwf/output/review/40_p2b_findings.md
# (findings C1-C5).

test_that("NCHS-numeric data (<=2002) with a year resolves to the correct state (C1)", {
    # NCHS 06 is Colorado (FIPS 08), NOT California (FIPS 06). The year picks nchs.
    df <- tibble::tibble(countyrs = c("06031", "06005"))
    out <- add_county_fips(df, countyrs, year = 2000)
    expect_equal(out$st_fips, c("08", "08"))
    expect_equal(out$county_fips, c("08031", "08005"))
})

test_that("abbreviation data (2003+) resolves; year read from a `year` column", {
    df <- tibble::tibble(countyrs = c("CA001", "NY013", "ZZ999"), year = 2019)
    out <- add_county_fips(df, countyrs)
    expect_equal(out$st_fips, c("06", "36", NA))       # ZZ -> NA (unknown/foreign)
    expect_equal(out$county_fips, c("06001", "36013", NA))
})

test_that("explicit scheme= overrides detection", {
    df <- tibble::tibble(countyrs = c("06031", "06005"))
    expect_equal(add_county_fips(df, countyrs, scheme = "nchs")$st_fips, c("08", "08"))
    expect_equal(add_county_fips(df, countyrs, scheme = "fips")$st_fips, c("06", "06"))
})

test_that("ambiguous numeric codes with no year warn loudly, default to FIPS (C1)", {
    df <- tibble::tibble(countyrs = c("06031", "06005"))
    expect_warning(out <- add_county_fips(df, countyrs), "valid in BOTH")
    expect_equal(out$st_fips, c("06", "06"))
})

test_that("a missing county code becomes NA, not the string 'NANA' (C2)", {
    df <- tibble::tibble(countyrs = c("CA001", NA), year = 2019)
    out <- suppressWarnings(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, c("06001", NA_character_))
})

test_that("all-missing state codes raise a clean error (C3)", {
    df <- tibble::tibble(countyrs = c(NA, NA))
    expect_error(add_county_fips(df, countyrs), "missing or blank")
})

test_that("territory NCHS code becomes NA with a warning; batch survives (C4)", {
    # 62 (American Samoa / N. Mariana Islands) is a territory code; narcan is
    # US-only, so it is not in st_fips_map -- the row goes NA, not abort.
    df <- tibble::tibble(countyrs = c("01001", "06005", "62001"))
    expect_warning(out <- add_county_fips(df, countyrs, year = 2000), "62")
    expect_equal(nrow(out), 3L)
    expect_equal(out$st_fips, c("01", "08", NA))
})

test_that("NCHS branch preserves rows and resolves all valid codes", {
    df <- tibble::tibble(countyoc = c("03001", "07001", "14001", "43001"))
    out <- add_county_fips(df, countyoc, year = 2000)
    expect_equal(nrow(out), nrow(df))
    expect_false(anyNA(out$st_fips))
    expect_equal(out$county_fips, paste0(out$st_fips, out$county_substr))
})

test_that("realistic abbreviation subsets resolve", {
    out1 <- add_county_fips(tibble::tibble(countyoc = c("CA001", "CA003")), countyoc)
    expect_equal(unique(out1$st_fips), "06")
    out2 <- add_county_fips(tibble::tibble(countyoc = c("CA001", "NY001")), countyoc)
    expect_false(anyNA(out2$st_fips))
    expect_equal(nrow(out2), 2L)
})

test_that("genuinely unrecognizable numeric codes error informatively", {
    df <- tibble::tibble(countyoc = c("99001", "98002"))    # in neither scheme
    expect_error(add_county_fips(df, countyoc), "Unrecognized state coding system")
})

test_that("mixed alphabetic + numeric state codes error with guidance", {
    df <- tibble::tibble(countyoc = c("CA001", "06001"))
    expect_error(add_county_fips(df, countyoc), "Mixed")
})

test_that("an unknown abbreviation becomes NA with a warning", {
    df <- tibble::tibble(countyoc = c("CA001", "QQ002"), year = 2019)
    expect_warning(out <- add_county_fips(df, countyoc), "QQ")
    expect_equal(out$st_fips, c("06", NA))
})

test_that("an NA in the year argument is handled like an NA year column (re-review #1)", {
    codes <- c("06031", "06005", "06013")
    arg <- add_county_fips(tibble::tibble(countyrs = codes), countyrs,
                           year = c(2000, 2001, NA))
    col <- add_county_fips(tibble::tibble(countyrs = codes,
                                          year = c(2000, 2001, NA)), countyrs)
    expect_equal(arg$st_fips, c("08", "08", "08"))     # Colorado, not California
    expect_equal(arg$st_fips, col$st_fips)             # both paths agree
})

test_that("a boundary-spanning per-row year decodes each era with its own scheme", {
    # Per-row year straddling 2002/2003: resolve the scheme SEPARATELY per era so
    # a single global scheme cannot mis-decode the minority era. "06" is NCHS
    # Colorado (-> FIPS 08) in 2002 but assumed FIPS California ("06") in 2003.
    df <- tibble::tibble(countyrs = c("06031", "06005"), year = c(2002, 2003))
    expect_warning(out <- add_county_fips(df, countyrs), "already|FIPS")
    expect_equal(out$st_fips, c("08", "06"))
    expect_equal(out$county_fips, c("08031", "06005"))
})

test_that("a mixed-era frame decodes NCHS-only and FIPS codes to the right states", {
    # AZ NCHS "03" (2002) and TX FIPS "48" (2003): the old global scheme decoded
    # TX as NCHS Washington; per-era decoding keeps them Arizona and Texas.
    df <- tibble::tibble(countyrs = c("03013", "48001"), year = c(2002, 2003))
    out <- suppressWarnings(add_county_fips(df, countyrs))
    expect_equal(out$county_fips, c("04013", "48001"))
})

test_that("a numeric county_vector is refused (leading zeros already lost)", {
    df <- data.frame(countyrs = c(6031, 1001), year = 2000)
    expect_error(add_county_fips(df, countyrs, year = 2000), "numeric")
})

test_that("whitespace-padded state codes still resolve (re-review #3)", {
    df <- tibble::tibble(countyrs = c(" CA001", "NY013 "), year = 2019)
    out <- add_county_fips(df, countyrs)
    expect_equal(out$st_fips, c("06", "36"))
})

test_that("a factor/character year is coerced by label, not factor code (R2 guard)", {
    codes <- c("06031", "06005")
    # factor("2019") must coerce to 2019 (>=2003 -> FIPS -> CA 06), NOT the factor
    # integer code 1 (which would pick NCHS -> CO 08). Locks the as.character() guard.
    expect_equal(
        suppressWarnings(add_county_fips(tibble::tibble(countyrs = codes),
                                         countyrs, year = factor("2019"))$st_fips),
        c("06", "06"))
    # character pre-2003 year -> NCHS -> Colorado
    expect_equal(
        add_county_fips(tibble::tibble(countyrs = codes), countyrs,
                        year = "2000")$st_fips,
        c("08", "08"))
    # an all-NA year argument falls through to the code-guess (FIPS default)
    expect_warning(out <- add_county_fips(tibble::tibble(countyrs = codes),
                                          countyrs, year = c(NA, NA)),
                   "not available")
    expect_equal(out$st_fips, c("06", "06"))
})
