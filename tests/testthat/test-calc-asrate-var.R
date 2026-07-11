# Characterization (Bucket A) for calc_asrate_var(). It is pure arithmetic on a
# count and a population, so property-based checks lock the exact formulas: the
# age-specific rate is deaths / pop * 100,000 and the Poisson-approximation
# variance is rate^2 / deaths. Guards the Phase 3 rlang/NSE modernization.

test_that("calc_asrate_var() computes rate = deaths/pop*1e5 and var = rate^2/deaths", {
    df <- add_std_pop(add_pop_counts(rate_input(year = 2015L, sex = "male", race = "white")))
    out <- calc_asrate_var(df, new_name = opioid, death_col = deaths)

    expect_true(all(c("opioid_rate", "opioid_var") %in% names(out)))
    expect_equal(nrow(out), nrow(df))
    expect_equal(out$opioid_rate, out$deaths / out$pop * 1e5)
    expect_equal(out$opioid_var, out$opioid_rate^2 / out$deaths)
})

test_that("calc_asrate_var() warns (value-neutral) on a pop == 0 cell", {
    df <- data.frame(deaths = c(0, 5), pop = c(0, 1e5))
    expect_warning(out <- calc_asrate_var(df, opioid, deaths), "pop == 0")
    # arithmetic is unchanged: the warning does not alter the numeric output
    expect_true(is.infinite(out$opioid_rate[1]) || is.nan(out$opioid_rate[1]))
    expect_equal(out$opioid_rate[2], 5 / 1e5 * 1e5)
})

test_that("calc_asrate_var() honors a custom death_col and pop_col and new_name", {
    df <- add_pop_counts(rate_input(year = 2015L, sex = "male", race = "white"))
    df$my_pop <- df$pop
    out <- calc_asrate_var(df, new_name = drug, death_col = deaths, pop_col = my_pop)

    expect_true(all(c("drug_rate", "drug_var") %in% names(out)))
    expect_equal(out$drug_rate, df$deaths / df$my_pop * 1e5)
})
