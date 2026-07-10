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

test_that("convert_ager27u1() splits the under-1 / 1-4 codes", {
    out <- convert_ager27u1(tibble::tibble(ager27 = 1:27))
    # codes 3-6 map to 1 (the 1-4 bin) instead of 0, distinguishing infants
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
