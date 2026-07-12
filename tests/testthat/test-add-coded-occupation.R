# Golden regression for the occupation type-stability fix (0.5.1).
# add_coded_occupation() must return occ_coded/ind_coded as zero-padded CHARACTER
# in BOTH eras (3-digit Census 1982-1999, 4-digit NIOSH 2020+). Before the fix the
# Census era returned numeric codes with leading zeros dropped, so 3-digit
# crosswalks broke and a bind_rows() of a pre-2000 and a 2020+ result errored on
# the numeric-vs-character clash.

test_that("occ_coded/ind_coded are zero-padded character in both schemes", {
    census <- add_coded_occupation(
        data.frame(occup = c("007", "120"), industry = c("012", "500")), 1990)
    niosh <- add_coded_occupation(
        data.frame(occupation = c("0110", "9840"),
                   industry = c("0230", "9590")), 2023)
    expect_type(census$occ_coded, "character")
    expect_type(niosh$occ_coded, "character")
    expect_identical(census$occ_coded, c("007", "120"))    # leading zero kept
    expect_identical(census$ind_coded, c("012", "500"))
    expect_identical(niosh$occ_coded, c("0110", "9840"))
})

test_that("numeric Census input (leading zeros already lost) is re-zero-padded", {
    num_in <- add_coded_occupation(
        data.frame(occup = 7L, industry = 12L), 1990)
    expect_identical(num_in$occ_coded, "007")
    expect_identical(num_in$ind_coded, "012")
})

test_that("pre-2000 and 2020+ results bind_rows without a type clash", {
    census <- add_coded_occupation(data.frame(occup = "007", industry = "012"), 1990)
    niosh <- add_coded_occupation(
        data.frame(occupation = "0110", industry = "0230"), 2023)
    expect_no_error(dplyr::bind_rows(
        census[, c("occ_scheme", "occ_coded", "ind_coded")],
        niosh[, c("occ_scheme", "occ_coded", "ind_coded")]))
})

test_that("factor input yields the code LABEL, not the factor level index", {
    # pad_code() must as.character() before as.integer(); a bare as.integer() on a
    # factor returns the level index (silent corruption). stringsAsFactors merges
    # and legacy imports are a real source of factor-typed code columns.
    r <- add_coded_occupation(
        data.frame(occup = factor(c("412", "007", "832")),
                   industry = factor(c("100", "012", "500"))), 1990)
    expect_identical(r$occ_coded, c("412", "007", "832"))
    expect_identical(r$ind_coded, c("100", "012", "500"))
})

test_that("numeric NIOSH input is re-zero-padded to 4 digits", {
    # the documented import types these as character, but a direct caller can pass
    # numeric; the coded columns must still come back zero-padded to width 4.
    r <- add_coded_occupation(
        data.frame(occupation = 110L, industry = 230L), 2023)
    expect_identical(r$occ_coded, "0110")
    expect_identical(r$ind_coded, "0230")
})

test_that("the 2000-2019 no-scheme era returns character NA (type-stable)", {
    r <- add_coded_occupation(data.frame(sex = c("M", "F")), 2010)
    expect_true(all(is.na(r$occ_scheme)))
    expect_type(r$occ_coded, "character")
    expect_type(r$ind_coded, "character")
    expect_true(all(is.na(r$occ_coded)))
    expect_false(any(r$occ_available))
    # binds cleanly with a coded-era (character) result
    census <- add_coded_occupation(data.frame(occup = "007", industry = "012"), 1990)
    expect_no_error(dplyr::bind_rows(
        r[, c("occ_scheme", "occ_coded", "ind_coded")],
        census[, c("occ_scheme", "occ_coded", "ind_coded")]))
})

test_that("zero-row input returns a zero-row df with typed columns, no error (0.5.1)", {
    empty <- data.frame(occupation = character(0), occupationr = character(0),
                         industry = character(0), industryr = character(0))
    r <- expect_no_error(add_coded_occupation(empty, 2023))
    expect_equal(nrow(r), 0L)
    expect_type(r$occ_scheme, "character")
    expect_type(r$occ_coded, "character")
    expect_type(r$ind_coded, "character")
    expect_type(r$occ_recode, "character")
    expect_type(r$ind_recode, "character")
    expect_type(r$occ_available, "logical")
    expect_length(r$occ_scheme, 0L)
    expect_length(r$occ_available, 0L)
})

test_that("zero-row input works across all three era branches (0.5.1)", {
    expect_no_error(add_coded_occupation(data.frame(occup = character(0),
                                                      industry = character(0)), 1990))
    expect_no_error(add_coded_occupation(data.frame(sex = character(0)), 2010))
    expect_no_error(add_coded_occupation(data.frame(occupation = character(0),
                                                      industry = character(0)), 2023))
})

test_that("NA year errors with a clear message instead of crashing (0.5.1)", {
    df <- data.frame(occupation = "0110", industry = "0230")
    expect_error(add_coded_occupation(df, NA), "single non-NA value")
    expect_error(add_coded_occupation(df, c(2020, 2021)), "single non-NA value")
})

test_that("numeric NIOSH occupationr/industryr recodes pad to 2 digits (0.5.1)", {
    df <- data.frame(occupation = "1010", occupationr = 1L,
                      industry = "8680", industryr = 9L)
    r <- add_coded_occupation(df, 2023)
    expect_identical(r$occ_recode, "01")
    expect_identical(r$ind_recode, "09")
})
