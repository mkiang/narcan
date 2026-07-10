# Characterization (Bucket A) for zap_dta_data(). Phase 0 confirmed it RUNS today
# (funs() is deprecated-not-defunct in dplyr 1.2 -- it only warns), so it has a
# valid oracle. The Phase 2 funs() -> across() fix must preserve these values (and
# silence the warning). Input is a small Stata-shaped tibble -- not MCOD micro-
# data, so a constructed input is appropriate here.

test_that("zap_dta_data() converts empty strings and NaN to NA", {
    df <- tibble::tibble(
        a = c("x", "", NA),
        b = c(1, NaN, 3)
    )
    out <- suppressWarnings(zap_dta_data(df))
    expect_equal(out$a, c("x", NA, NA))
    expect_equal(out$b, c(1, NA, 3))
    expect_equal(nrow(out), 3L)
})
