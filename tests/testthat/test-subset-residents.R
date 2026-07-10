# Characterization (Bucket A) for subset_residents(): keep restatus 1-3
# (US residents), drop non-residents (4), and drop the restatus column by default.

test_that("subset_residents() keeps restatus 1-3 and drops the column by default", {
    df <- tibble::tibble(restatus = c(1L, 2L, 3L, 4L), v = 1:4)
    out <- subset_residents(df)
    expect_equal(out$v, 1:3)
    expect_false("restatus" %in% names(out))
})

test_that("subset_residents(drop_col = FALSE) retains the restatus column", {
    df <- tibble::tibble(restatus = c(1L, 4L), v = 1:2)
    out <- subset_residents(df, drop_col = FALSE)
    expect_true("restatus" %in% names(out))
    expect_equal(out$v, 1L)
})
