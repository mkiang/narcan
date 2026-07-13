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
        sum((df$unit_w / sum(df$unit_w, na.rm = TRUE))^2 * df$opioid_var,
            na.rm = TRUE)
    )
})

test_that("calc_stdrate_var() renormalizes the variance when age bins are dropped (C2)", {
    # P1 repro: the point rate is renormalized by weighted.mean() but the OLD
    # variance sum(w^2 * var) was not, so it under-stated when weights did not
    # sum to 1 (e.g. dropped age bins). The fix renormalizes the variance too.
    full <- data.frame(
        race = "white",
        opioid_rate = c(2, 4, 10),
        opioid_var = c(0.5, 0.8, 3.0),
        unit_w = c(0.2, 0.3, 0.5)
    )
    dropped <- full[1:2, ]
    out <- calc_stdrate_var(dropped, opioid_rate, opioid_var, race)
    # renormalized variance = sum((w/sum(w))^2 * var) = 0.368 (not the old 0.092)
    expect_equal(out$opioid_var, 0.368, tolerance = 1e-9)
    # the point rate is unchanged by the fix (weighted.mean already renormalizes)
    expect_equal(out$opioid_rate,
                 stats::weighted.mean(dropped$opioid_rate, dropped$unit_w))
})

test_that("calc_stdrate_var() variance drops the SAME strata as the rate (masking fix)", {
    # Regression: the std rate was written into the input rate column's name,
    # exposing that scalar to the variance expression, so .std_var() dropped the
    # wrong strata. Stratum 2 has a NaN rate but a finite variance -> both the
    # rate and the variance must drop it (variance was wrongly 0.375, not 1).
    df <- data.frame(race = "white", r = c(10, NaN), v = c(1, 0.5),
                     unit_w = c(0.5, 0.5))
    out <- suppressWarnings(calc_stdrate_var(df, r, v, race))
    expect_equal(out$r, 10)
    expect_equal(out$v, 1)
})

test_that("calc_stdrate_var() drops non-finite (Inf/NaN) strata and warns", {
    # A pop == 0, deaths > 0 cell yields an Inf age-specific rate/variance;
    # .std_keep now uses is.finite(), so the stratum is dropped rather than
    # poisoning the whole group to Inf, and the drop is flagged.
    df <- data.frame(race = "white", r = c(5, Inf, 7), v = c(0.1, Inf, 0.2),
                     unit_w = c(0.4, 0.2, 0.4))
    expect_warning(out <- calc_stdrate_var(df, r, v, race), "non-finite")
    expect_true(is.finite(out$r))
    expect_true(is.finite(out$v))
    keep <- c(1L, 3L)
    expect_equal(out$r,
                 sum(df$unit_w[keep] * df$r[keep]) / sum(df$unit_w[keep]))
})
