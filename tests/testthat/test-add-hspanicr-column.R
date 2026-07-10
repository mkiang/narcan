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
