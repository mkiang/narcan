# summarize_binary_columns(): Phase 2 fixed the defunct group_by(add=) -> .add,
# summarize_all -> summarize(across(everything())), and the by-less join ->
# explicit by = group_vars(df). Characterizes per-group death counts + flag sums.

sbc_input <- function() {
    tibble::tibble(
        year    = 2015L,
        age     = c(0L, 0L, 5L),
        age_cat = factor(c("0-4", "0-4", "5-9"), levels = c("0-4", "5-9"), ordered = TRUE),
        flag_a  = c(1L, 1L, 0L),
        flag_b  = c(0L, 1L, 1L)
    )
}

test_that("summarize_binary_columns() counts deaths and sums flag columns per group", {
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
