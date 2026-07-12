# Characterization (Bucket A) for add_hspanicr_column(): adds an all-NA hspanicr
# column when absent (so downstream year-aware hispanic recodes have a column to
# operate on), and leaves an existing hspanicr untouched.

test_that("add_hspanicr_column() adds an all-NA hspanicr when missing", {
    out <- add_hspanicr_column(tibble::tibble(x = 1:2))
    expect_true("hspanicr" %in% names(out))
    expect_true(all(is.na(out$hspanicr)))
})

test_that("add_hspanicr_column() leaves an existing hspanicr unchanged", {
    df <- tibble::tibble(x = 1:2, hspanicr = c(6L, 7L))
    out <- add_hspanicr_column(df)
    expect_equal(out$hspanicr, c(6L, 7L))
})

test_that("add_hspanicr_column() synthesizes a double, not logical, NA column", {
    ## The real hspanicr column is imported as readr type "n" (double; see
    ## .import_mcod_data()). A bare NA (logical) here would make the
    ## synthesized pre-1989 column type-mismatch a real hspanicr column on
    ## bind_rows() (regression for the logical-vs-numeric coercion bug).
    out <- add_hspanicr_column(tibble::tibble(x = 1:2))
    expect_type(out$hspanicr, "double")
    expect_false(is.logical(out$hspanicr))
})

test_that("add_hspanicr_column() output binds with a real-hspanicr frame without a type clash", {
    pre_1989 <- add_hspanicr_column(tibble::tibble(year = 1985, x = 1:2))
    real <- tibble::tibble(year = 1990, x = 3:4, hspanicr = c(1, 2))

    combined <- expect_no_error(dplyr::bind_rows(pre_1989, real))
    expect_type(combined$hspanicr, "double")
    expect_equal(combined$hspanicr, c(NA, NA, 1, 2))
})
