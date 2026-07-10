## Fixtures are a small random sample of REAL public MCOD data spanning every race
## coding era (built by verify_fwf/scripts/70_build_recode_fixtures.R).
fx <- readRDS(test_path("fixtures", "recode_public_sample.rds"))

test_that("remap_race standardizes real bridged data (1992-2020)", {
    s <- fx[fx$year == 2015, c("year", "race")]
    out <- remap_race(s)
    ## real 2015 race codes 1,2,3,68 -> 1,2,3,99
    expect_setequal(unique(out$race[!is.na(out$race)]), c(1, 2, 3, 99))
    expect_true(all(out$race[s$race == 68] == 99))
})

test_that("remap_race handles the 1979-1988 and 1989-1991 eras on real data", {
    o85 <- remap_race(fx[fx$year == 1985, c("year", "race")])
    expect_true(all(o85$race[!is.na(o85$race)] %in% c(1:7, 99)))

    o90 <- remap_race(fx[fx$year == 1990, c("year", "race")])
    expect_true(all(o90$race[!is.na(o90$race)] %in% c(1:7, 99)))
})

test_that("remap_race maps real 2023 single-race (racer5) to codes 101-106 with a warning", {
    s <- fx[fx$year == 2023, c("year", "racer5")]
    expect_warning(out <- remap_race(s), "single-race")
    ## real 2023 racer5 1,2,3,4,6 -> 101,102,103,104,106
    expect_setequal(unique(out$race[!is.na(out$race)]), c(101, 102, 103, 104, 106))
    expect_true(all(out$race[s$racer5 == 6] == 106))
})

test_that("remap_race sets race to NA for the 2021 transition gap (with warning)", {
    s <- fx[fx$year == 2021, c("year", "race")]
    expect_warning(out <- remap_race(s), "2021")
    expect_true(all(is.na(out$race)))
})

test_that("remap_race auto-extracts the year, including the pre-1996 datayear name", {
    df <- data.frame(datayear = 1985, race = c(0, 1, 8))
    out <- remap_race(df)
    expect_equal(out$race, c(99, 1, 7))
})

test_that("remap_race preserves legacy standardization exactly (backward compat)", {
    df <- data.frame(year = 2000, race = c(1, 2, 3, 4, 5, 6, 7, 18, 78))
    expect_equal(remap_race(df)$race, c(1, 2, 3, 4, 5, 6, 7, 99, 99))
})

test_that("remap_race errors on 2022+ data lacking racer5", {
    expect_error(remap_race(data.frame(year = 2022, race = c(1, 2))), "racer5")
})
