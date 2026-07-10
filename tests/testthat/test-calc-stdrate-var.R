# calc_stdrate_var(): age-standardized rate + variance. Phase 2 fixed the defunct
# group_by(add=) -> .add, so this now runs. Characterizes the weighted-mean rate
# and the variance formula over one year x race group.

std_input <- function() {
    # age-specific rates + variance + unit weights for one year/race group
    calc_asrate_var(
        add_std_pop(add_pop_counts(rate_input(year = 2015L, sex = "male", race = "white"))),
        new_name = opioid, death_col = deaths
    )
}

test_that("calc_stdrate_var() returns the weighted age-standardized rate + variance", {
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
