## Fixtures are a small random sample of REAL public MCOD data spanning every race
## coding era (built by verify_fwf/scripts/70_build_recode_fixtures.R).
fx <- readRDS(test_path("fixtures", "recode_public_sample.rds"))

test_that("categorize_race labels real bridged data (<=2020)", {
    out <- remap_race(fx[fx$year == 2015, c("year", "race")])
    lab <- categorize_race(out$race)
    expect_equal(as.character(lab[out$race == 1])[1], "white")
    expect_equal(as.character(lab[out$race == 99])[1], "other")
})

test_that("categorize_race labels real single-race data (2022+) with _only suffix + warning", {
    out <- suppressWarnings(remap_race(fx[fx$year == 2023, c("year", "racer5")]))
    expect_warning(lab <- categorize_race(out$race), "not comparable")
    expect_equal(as.character(lab[out$race == 101])[1], "white_only")
    expect_equal(as.character(lab[out$race == 106])[1], "multiracial")
})

test_that("categorize_race keeps bridged and single-race distinct in a stacked column", {
    lab <- suppressWarnings(categorize_race(c(1, 101, 2, 102)))
    expect_equal(as.character(lab), c("white", "white_only", "black", "black_only"))
    expect_equal(nlevels(lab), 15)
})

test_that("categorize_race preserves the legacy 9-level factor (backward compat)", {
    lab <- categorize_race(c(0:7, 99))
    expect_equal(levels(lab),
                 c("total", "white", "black", "american_indian", "chinese",
                   "japanese", "hawaiian", "filipino", "other"))
    expect_true(is.ordered(lab))
})

test_that("categorize_race warns only when single-race codes are present", {
    expect_silent(categorize_race(c(0:7, 99)))
    expect_warning(categorize_race(c(1, 101)), "not comparable")
})
