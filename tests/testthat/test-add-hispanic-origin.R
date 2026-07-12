test_that("adds a correct hispanic_origin column from year + hspanicr", {
    df <- data.frame(year = 2019, hspanicr = c(1, 6, 9))
    out <- add_hispanic_origin(df)
    expect_equal(out$hispanic_origin, c("hispanic", "non_hispanic", "unknown"))
})

test_that("a missing hspanicr column yields all-NA origin (pre-1989 tolerant)", {
    df <- data.frame(year = 1985, ucod = c("X42", "E850"))
    out <- add_hispanic_origin(df)
    expect_true("hispanic_origin" %in% names(out))
    expect_true(all(is.na(out$hispanic_origin)))
})

test_that("multi-year frame is labeled per row (bind_rows use case)", {
    df <- rbind(
        data.frame(year = 2000, hspanicr = 1),
        data.frame(year = 2023, hspanicr = 8)
    )
    out <- add_hispanic_origin(df)
    expect_equal(out$hispanic_origin, c("hispanic", "non_hispanic"))
})

test_that("two-digit datayear is normalized (1979-1995 fallback)", {
    df <- data.frame(datayear = 96, hspanicr = 6)
    out <- add_hispanic_origin(df)
    expect_equal(out$hispanic_origin, "non_hispanic")
})

test_that("errors when neither year nor datayear is present", {
    expect_error(add_hispanic_origin(data.frame(hspanicr = 1)),
                 "no `year` or `datayear`")
})

test_that("errors (clash) when hispanic_origin already exists", {
    df <- data.frame(year = 2019, hspanicr = 1, hispanic_origin = "hispanic")
    expect_error(add_hispanic_origin(df), "already has a `hispanic_origin`")
})

test_that("a zero-row frame returns a zero-row frame with the column", {
    df <- data.frame(year = integer(0), hspanicr = numeric(0))
    out <- add_hispanic_origin(df)
    expect_equal(nrow(out), 0L)
    expect_true("hispanic_origin" %in% names(out))
})
