# Bucket B: calc_stdrate_var() ERRORS today -- it calls group_by(..., add = TRUE)
# and the `add` argument is defunct in dplyr 1.2 (confirmed in Phase 0). The
# KNOWN-BUG test locks the current failure; the desired-behavior test is skipped
# until the Phase 2 `.add` fix lands, at which point un-skip it and DELETE the
# KNOWN-BUG test in the same commit.

std_input <- function() {
    # age-specific rates + variance + unit weights for one year/race group
    calc_asrate_var(
        add_std_pop(add_pop_counts(rate_input(year = 2015L, sex = "male", race = "white"))),
        new_name = opioid, death_col = deaths
    )
}

test_that("KNOWN BUG: calc_stdrate_var() errors on defunct group_by(add=)", {
    df <- std_input()
    expect_error(
        calc_stdrate_var(df, opioid_rate, opioid_var, year, race),
        regexp = "add"
    )
})

test_that("calc_stdrate_var() returns the weighted age-standardized rate + variance", {
    skip("Bucket B: un-skip after Phase 2 fixes group_by(add=) -> .add; delete the KNOWN BUG test above")
    df <- std_input()
    out <- calc_stdrate_var(df, opioid_rate, opioid_var, year, race)

    expect_equal(nrow(out), 1L)                       # one year x race group
    expect_equal(
        out$opioid_rate,
        stats::weighted.mean(df$opioid_rate, df$unit_w, na.rm = TRUE)
    )
    expect_equal(
        out$opioid_var,
        sum(df$unit_w^2 * df$opioid_var, na.rm = TRUE)
    )
})
