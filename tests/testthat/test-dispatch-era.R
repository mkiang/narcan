# .dispatch_era(): single source of truth for ICD era selection (C1). Must route
# valid 4-digit years and error on a 2-digit datayear or a 4-digit year < 1979,
# so the flag_* family can no longer silently misroute an out-of-range year.

test_that(".dispatch_era() routes valid 4-digit years", {
    expect_identical(narcan:::.dispatch_era(1979L), "icd9")
    expect_identical(narcan:::.dispatch_era(1998L), "icd9")
    expect_identical(narcan:::.dispatch_era(1999L), "icd10")
    expect_identical(narcan:::.dispatch_era(2019L), "icd10")
})

test_that(".dispatch_era() errors on 2-digit and out-of-range years", {
    expect_error(narcan:::.dispatch_era(93L))            # 2-digit datayear
    expect_error(narcan:::.dispatch_era(0L))
    expect_error(narcan:::.dispatch_era(1975L))          # 4-digit before 1979
    expect_error(narcan:::.dispatch_era(NA_integer_))
})

test_that("flag_* error on a 2-digit or pre-1979 year instead of silent misroute (C1)", {
    df <- data.frame(datayear = 93, ucod = "E8500", f_records_all = "N9650")
    expect_error(flag_drug_deaths(df, year = 93, keep_cols = TRUE))
    expect_error(flag_opioid_deaths(df, year = 93, keep_cols = TRUE))
    expect_error(flag_od_intent(
        flag_drug_deaths(data.frame(year = 1999, ucod = "X42",
                                    f_records_all = "T401"), year = 1999),
        year = 1975))

    # a valid 4-digit ICD-9 year is unaffected
    df9 <- data.frame(year = 1993, ucod = "E8500", f_records_all = "N9650")
    expect_equal(flag_drug_deaths(df9, year = 1993, keep_cols = TRUE)$drug_death, 1)
})
