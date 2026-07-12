# Regression tests for the package-wide 6-agent review fixes (0.5.0). Each locks
# a confirmed bug so it cannot silently return.

# --- calc_stdrate_var: rate and variance share one surviving-strata set --------

test_that("std variance renormalizes consistently when a stratum rate is NaN", {
    # pop == 0 & deaths == 0 -> NaN age-specific rate. The rate renormalizes over
    # the surviving strata; the variance must use the SAME renormalization.
    df <- data.frame(age = c(0, 5, 10), deaths = c(2, 3, 0), pop = c(1000, 2000, 0),
                     unit_w = c(0.2, 0.3, 0.5))
    df <- suppressWarnings(calc_asrate_var(df, x, deaths))   # pop==0 diagnostic
    out <- suppressWarnings(calc_stdrate_var(df, x_rate, x_var, weight_col = unit_w))

    surv <- !is.na(df$x_rate)
    w <- df$unit_w[surv] / sum(df$unit_w[surv])
    expect_equal(out$x_rate, sum(w * df$x_rate[surv]))
    expect_equal(out$x_var, sum(w^2 * df$x_var[surv]))   # was sum(w_full^2 * v): too small
})

test_that("complete-data standardization is unchanged (byte-for-byte)", {
    df <- data.frame(age = c(0, 5, 10), deaths = c(4, 3, 5), pop = c(1000, 2000, 3000),
                     unit_w = c(0.2, 0.3, 0.5))
    df <- calc_asrate_var(df, x, deaths)
    out <- calc_stdrate_var(df, x_rate, x_var, weight_col = unit_w)
    expect_equal(out$x_rate, weighted.mean(df$x_rate, df$unit_w))
    expect_equal(out$x_var, sum((df$unit_w / sum(df$unit_w))^2 * df$x_var))
})

test_that("an NA weight drops that stratum from BOTH rate and variance", {
    df <- suppressWarnings(add_std_pop(data.frame(
        race = "white", age = c(20, 23), opioid_rate = c(5, 8),
        opioid_var = c(.4, .9))))
    out <- suppressWarnings(calc_stdrate_var(df, opioid_rate, opioid_var, race))
    expect_equal(out$opioid_rate, 5)      # age 23 (NA weight) dropped, not NA-poisoned
    expect_equal(out$opioid_var, 0.4)
})

# --- add_std_pop: granularity guard -------------------------------------------

test_that("add_std_pop warns when the standard granularity mismatches the ages", {
    # a single-year standard joined to 5-year bins matches only bin starts
    full5 <- data.frame(age = seq(0, 85, 5))
    expect_silent(add_std_pop(full5))                     # s204 matches -> quiet
    if ("s202" %in% narcan::std_pops$standard) {
        expect_warning(add_std_pop(full5, std_cat = "s202"), "sum to")
    }
})

# --- clean_icd9_data idempotency (prefix helpers) ------------------------------

test_that("prefix_e_to_ucod is idempotent (a 2nd pass does not NA E-codes)", {
    once <- prefix_e_to_ucod(c("8500", "9503", "4275"))
    expect_identical(once, c("E8500", "E9503", "4275"))
    expect_identical(prefix_e_to_ucod(once), once)        # was: E-codes -> NA
})

test_that("prefix_to_record is idempotent and never drops an in-range record", {
    once <- prefix_to_record(c("8500", "9999", "7500"), c(0, 1, 0))
    expect_identical(once, c("E8500", "N9999", "7500"))
    expect_identical(prefix_to_record(once, c(0, 1, 0)), once)
    # an NA nature-of-injury flag keeps the raw code rather than dropping to NA
    expect_identical(prefix_to_record("8500", NA), "8500")
})

# --- opioid subtypes + aggregate opioid regex share one source (SSOT) ----------

test_that("opioid subtype regexes and the aggregate opioid regex derive from one source", {
    agg10 <- narcan:::.regex_opioid_icd10(t_codes = TRUE)
    subs10 <- c(opium = 0, heroin = 1, other_natural = 2, methadone = 3,
                other_synth = 4, other_op = 6)
    for (s in names(subs10)) {
        code <- paste0("T40", subs10[[s]])
        expect_true(grepl(narcan:::.opioid_subtype_regex(s, "icd10"), code))
        expect_true(grepl(agg10, code))          # aggregate covers every subtype
    }
    expect_false(grepl(agg10, "T405"))           # cocaine excluded from both

    agg9 <- narcan:::.regex_opioid_icd9()
    subs9 <- c(heroin = 0, methadone = 1, other_op = 2)
    for (s in names(subs9)) {
        code <- paste0("E850", subs9[[s]])
        expect_true(grepl(narcan:::.opioid_subtype_regex(s, "icd9"), code))
        expect_true(grepl(agg9, code))
    }
    for (s in c("opium", "other_natural", "other_synth")) {
        expect_true(is.na(narcan:::.opioid_subtype_regex(s, "icd9")))
    }
})

# --- remap_race / remap_age: warn on unmapped codes ----------------------------

test_that("remap_race warns on a code outside the era's known set", {
    expect_warning(remap_race(data.frame(year = 2000, race = c(1, 2, 55)),
                              year = 2000), "outside the known set")
})

test_that("remap_age warns on an unknown unit code but not on not-stated", {
    expect_warning(remap_age(data.frame(year = 2010, age = c(1037, 7000)),
                             year = 2010), "outside the known set")
    # 9999 / 1999 are not-stated (NA by design) -> no unmapped warning
    expect_silent(remap_age(data.frame(year = 2010, age = c(1037, 9999, 1999)),
                            year = 2010))
})
