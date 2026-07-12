# Regression tests for the 0.4-P2b exhaustive-panel findings (rates, recodes,
# imports). See verify_fwf/output/review/40_p2b_findings.md. add_county_fips
# (C1-C5) is covered in test-add-county-fips.R.

test_that("calc_asrate_var: a zero-death cell gets variance 0, not NaN (R1)", {
    out <- calc_asrate_var(data.frame(deaths = c(0, 25), pop = c(1e5, 1e5)),
                           opioid, deaths)
    expect_equal(out$opioid_var[1], 0)
    expect_false(is.nan(out$opioid_var[1]))
    ## unchanged for deaths > 0 (algebraically identical to rate^2 / deaths)
    expect_equal(out$opioid_var[2], (out$opioid_rate[2]^2) / 25)
})

test_that("calc_stdrate_var: a multi-year frame without year grouping warns (R2)", {
    df <- data.frame(year = c(2010, 2010, 2011, 2011), race = "white",
                     opioid_rate = c(5, 7, 50, 70), opioid_var = c(.1, .2, 1, 2),
                     unit_w = c(.5, .5, .5, .5))
    expect_warning(calc_stdrate_var(df, opioid_rate, opioid_var, race),
                   "collapse across years")
    expect_no_warning(calc_stdrate_var(df, opioid_rate, opioid_var, year, race))
})

test_that("calc_stdrate_var: an NA standardization weight warns (R3)", {
    # age 23 is not a 5-year-bin start -> add_std_pop() now also warns on the
    # unmatched age; suppress that setup warning and assert only the target one.
    df <- suppressWarnings(add_std_pop(data.frame(race = "white",
                                 age = c(20, 23),
                                 opioid_rate = c(5, 8), opioid_var = c(.4, .9))))
    expect_warning(calc_stdrate_var(df, opioid_rate, opioid_var, race),
                   "weights are NA")
})

test_that("summarize_binary_columns: a non-binary column warns; NAs use na.rm (R4)", {
    df1 <- data.frame(year = 2019, age = 25, age_cat = "20-24",
                      opioid_death = c(1, 0, 1), some_score = c(10.5, 2.1, 7))
    expect_warning(summarize_binary_columns(df1), "Non-binary")

    df2 <- data.frame(year = 2019, age = 25, age_cat = "20-24",
                      opioid_death = c(1, NA, 1))
    out <- suppressWarnings(summarize_binary_columns(df2))
    expect_equal(out$opioid_death, 2)     # na.rm = TRUE
    expect_equal(out$deaths, 3L)
})

test_that("state_abbrev_to_fips: unknown/wrong-case abbrev -> NA + warning (C5)", {
    expect_warning(res <- state_abbrev_to_fips(c("CA", "ZZ", NA, "ca", "TX")),
                   "Unrecognized")
    expect_equal(res, c("06", NA, NA, NA, "48"))
})

test_that("add_coded_occupation: 1982-1984 use the 3-digit scheme (C6)", {
    for (yr in 1982:1984) {
        r <- add_coded_occupation(data.frame(occup = 412L, industry = 832L), yr)
        expect_equal(r$occ_scheme, "3digit_census")
        expect_true(r$occ_available)
        expect_equal(r$occ_coded, 412L)
    }
})

test_that(".extract_year normalizes a 2-digit datayear (D1)", {
    expect_equal(.extract_year(data.frame(datayear = 85)), 1985)
    expect_equal(.extract_year(data.frame(datayear = 79)), 1979)
    expect_equal(.extract_year(data.frame(year = 2019)), 2019)
})

test_that("remap_race handles a raw 2-digit datayear; errors on an impossible year (D1)", {
    out <- remap_race(data.frame(datayear = 85, race = c(0, 1, 8)))
    expect_equal(out$race, c(99, 1, 7))       # 1979-1988 mapping
    expect_error(remap_race(data.frame(year = 1850, race = 1)), "cannot map race")
})

test_that("unite_records strips a leading NA token (D2)", {
    df <- data.frame(year = 2019, record_1 = NA_character_, record_2 = "T401")
    expect_equal(unite_records(df, year = 2019)$f_records_all, "T401")
})

test_that("calc_stdrate_var: a legitimate single-year, ungrouped collapse does not warn (R2)", {
    df <- data.frame(year = 2015, race = "white",
                     opioid_rate = c(0, 5, 8), opioid_var = c(0, .2, .3),
                     unit_w = c(.3, .3, .4))
    expect_no_warning(calc_stdrate_var(df, opioid_rate, opioid_var, race))
})

test_that("calc_stdrate_var: all-NA / zero-sum weights warn (R3)", {
    df0 <- data.frame(race = "white", opioid_rate = c(5, 8),
                      opioid_var = c(.4, .9), unit_w = c(NA_real_, NA_real_))
    expect_warning(calc_stdrate_var(df0, opioid_rate, opioid_var, race),
                   "all missing or sum to zero")
})

test_that("summarize_binary_columns: clean numeric grouping vars do not warn (R4)", {
    df <- data.frame(year = 2019, age = 25, age_cat = "20-24",
                     opioid_death = c(1, 0, 1), drug_death = c(1, 1, 1))
    expect_no_warning(summarize_binary_columns(df))
})

test_that("a character-typed datayear is coerced, not lexicographically misrouted (D1)", {
    expect_equal(.extract_year(data.frame(datayear = "85")), 1985)
    d <- data.frame(datayear = "85", ucod = "E8500", f_records_all = "N9650",
                    stringsAsFactors = FALSE)
    expect_equal(flag_drug_deaths(d, keep_cols = TRUE)$drug_death, 1)
})

test_that("unite_records collapses an all-missing record row to empty, not 'NA' (D2)", {
    df <- data.frame(year = 2019, record_1 = NA_character_, record_2 = NA_character_)
    expect_equal(unite_records(df, year = 2019)$f_records_all, "")
})

test_that("flag_od_intent gates every intent on drug_death (B1)", {
    ## poisoning UCOD with no contributory T-code -> drug_death 0 -> no intent
    d0 <- data.frame(year = 2019, ucod = c("X42", "X62", "X85", "Y14"),
                     f_records_all = "") |>
        flag_drug_deaths(year = 2019) |>
        flag_od_intent(year = 2019)
    expect_true(all(d0$drug_death == 0))
    expect_true(all(d0$unintended_intent == 0 & d0$suicide_intent == 0 &
                    d0$homicide_intent == 0 & d0$undetermined_intent == 0))

    ## a real drug death is still classified
    d1 <- data.frame(year = 2019, ucod = "X42", f_records_all = "T401") |>
        flag_drug_deaths(year = 2019) |>
        flag_od_intent(year = 2019)
    expect_equal(d1$unintended_intent, 1)
})
