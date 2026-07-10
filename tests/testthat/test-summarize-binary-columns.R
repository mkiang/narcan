# Bucket B: summarize_binary_columns() ERRORS today -- its first operation is
# group_by(..., add = TRUE), and `add` is defunct in dplyr 1.2 (Phase 0). The
# KNOWN-BUG test locks the current failure; the desired-behavior test is skipped
# until the Phase 2 `.add` (and summarize_all -> across) fix lands, then un-skip
# it and DELETE the KNOWN-BUG test in the same commit.

sbc_input <- function() {
    tibble::tibble(
        year    = 2015L,
        age     = c(0L, 0L, 5L),
        age_cat = factor(c("0-4", "0-4", "5-9"), levels = c("0-4", "5-9"), ordered = TRUE),
        flag_a  = c(1L, 1L, 0L),
        flag_b  = c(0L, 1L, 1L)
    )
}

test_that("KNOWN BUG: summarize_binary_columns() errors on defunct group_by(add=)", {
    expect_error(summarize_binary_columns(sbc_input()), regexp = "add")
})

test_that("summarize_binary_columns() counts deaths and sums flag columns per group", {
    skip("Bucket B: un-skip after Phase 2 fixes group_by(add=)/summarize_all; delete the KNOWN BUG test above")
    out <- suppressMessages(summarize_binary_columns(sbc_input()))

    # two groups: (2015,0,"0-4") from 2 rows, (2015,5,"5-9") from 1 row
    expect_equal(nrow(out), 2L)
    g1 <- out[out$age == 0L, ]
    g2 <- out[out$age == 5L, ]
    expect_equal(g1$deaths, 2L)
    expect_equal(g1$flag_a, 2L)
    expect_equal(g1$flag_b, 1L)
    expect_equal(g2$deaths, 1L)
    expect_equal(g2$flag_a, 0L)
    expect_equal(g2$flag_b, 1L)
})
