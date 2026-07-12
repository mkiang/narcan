# Characterization (Bucket A) for the age recoders. These feed the `age` column
# consumed by add_std_pop()/calc_asrate_var(), so an off-by-one here would corrupt
# every downstream rate. The full ager27 -> age mapping is locked with an explicit
# expect_equal (not a snapshot: snapshots skip on CRAN, and this oracle is too
# important to skip). Factor level sets are locked for the categorizers.

test_that("convert_ager27() maps all 27 codes to 5-year ages", {
    out <- convert_ager27(tibble::tibble(ager27 = 1:27))
    expect_true("age" %in% names(out))
    expect_false("ager27" %in% names(out))     # removed by default
    expect_equal(
        out$age,
        c(0, 0, 0, 0, 0, 0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
          65, 70, 75, 80, 85, 85, 85, 85, NA)
    )
})

test_that("convert_ager27u1() splits under-1 (codes 1-2) from 1-4 years (codes 3-6)", {
    out <- convert_ager27u1(tibble::tibble(ager27 = 1:27))
    # NCHS Age Recode 27 (verified against the MCOD public-use record layout):
    # code 1 = "Under 1 month", 2 = "1-11 months" (both under 1 year -> age 0);
    # codes 3-6 = "1 year"/"2 years"/"3 years"/"4 years" (the 1-4 bin -> age 1).
    # Corroborated by Age Recode 12 (01 = under 1 year from ager27 1-2; 02 = 1-4
    # years from ager27 3-6). Codes 7-26 match convert_ager27()'s 5-year mapping.
    expect_equal(
        out$age,
        c(0, 0, 1, 1, 1, 1, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60,
          65, 70, 75, 80, 85, 85, 85, 85, NA)
    )
})

test_that("categorize_age_5() returns an ordered factor with 18 five-year bins", {
    f <- categorize_age_5(c(0, 5, 25, 85))
    expect_s3_class(f, "factor")
    expect_true(is.ordered(f))
    expect_equal(nlevels(f), 18L)
    expect_equal(as.character(f), c("0-4", "5-9", "25-29", "85+"))
})

test_that("categorize_age_5u1() adds the <1 bin (19 levels)", {
    f <- categorize_age_5u1(c(0, 1, 5, 25))
    expect_s3_class(f, "factor")
    expect_true(is.ordered(f))
    expect_equal(nlevels(f), 19L)
    expect_equal(as.character(f), c("<1", "1-4", "5-9", "25-29"))
})
