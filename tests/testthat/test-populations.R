# Characterization (Bucket A) for the denominator joiners add_pop_counts() and
# add_std_pop(). Inputs use REAL bundled narcan::pop_est / std_pops keys (see the
# rate_input() helper); these functions only join, so behavior is preserved by
# any Phase 2/3 refactor iff these properties hold.

test_that("add_pop_counts() joins bridged-race pop for real keys, no rows lost", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    out <- add_pop_counts(inp)

    expect_equal(nrow(out), nrow(inp))
    expect_true("pop" %in% names(out))
    expect_false(anyNA(out$pop))          # every real key matches a pop_est row
    expect_true(all(out$pop > 0))
    # join key columns are preserved unchanged
    expect_equal(out$age, inp$age)
    expect_equal(out$deaths, inp$deaths)
})

test_that("add_pop_counts() leaves pop NA for keys absent from pop_est", {
    inp <- rate_input(year = 2015L, sex = "male", race = "white")
    inp$year <- 3000L                     # a year not in pop_est
    expect_warning(out <- add_pop_counts(inp), "no matching population")
    expect_true(all(is.na(out$pop)))
})

test_that("add_std_pop() attaches the US-2000 standard and unit weights summing to 1", {
    inp <- add_pop_counts(rate_input(year = 2015L, sex = "male", race = "white"))
    out <- add_std_pop(inp)               # default std_cat = "s204" (US 2000)

    expect_equal(nrow(out), nrow(inp))
    expect_true(all(c("pop_std", "unit_w") %in% names(out)))
    expect_false(anyNA(out$unit_w))
    # one row per 5-year age bin -> the joined unit weights sum to 1
    expect_equal(sum(out$unit_w), 1, tolerance = 1e-8)
})
