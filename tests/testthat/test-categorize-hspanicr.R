## Fixtures are a small random sample of REAL public MCOD data spanning every
## Hispanic-origin coding era (built by verify_fwf/scripts/70_build_recode_fixtures.R).
fx <- readRDS(test_path("fixtures", "recode_public_sample.rds"))

test_that("categorize_hspanicr labels real 2023 data with the 14-category scheme", {
    s <- fx[fx$year == 2023, ]
    lab <- categorize_hspanicr(s$hspanicr, year = 2023)
    map <- c("1" = "mexican", "8" = "nonhispanic_white", "9" = "nonhispanic_black",
             "10" = "nonhispanic_aian", "11" = "nonhispanic_asian",
             "13" = "nonhispanic_multi")
    for (code in names(map)) {
        got <- unique(as.character(lab[s$hspanicr == as.integer(code)]))
        expect_equal(got, unname(map[code]))
    }
})

test_that("categorize_hspanicr labels real pre-2021 data with the 9-category scheme", {
    s <- fx[fx$year == 2020, ]
    lab <- categorize_hspanicr(s$hspanicr, year = 2020)
    map <- c("1" = "mexican", "6" = "nonhispanic_white", "7" = "nonhispanic_black",
             "8" = "nonhispanic_other", "9" = "hispanic_unknown")
    for (code in names(map)) {
        got <- unique(as.character(lab[s$hspanicr == as.integer(code)]))
        expect_equal(got, unname(map[code]))
    }
})

test_that("categorize_hspanicr labels a mixed-year stacked column by each row's year", {
    ## The real failure mode: the same code means different things across 2022.
    ## In real data, code 8 = Non-Hispanic other (2020) vs Non-Hispanic White (2023);
    ## code 9 = Hispanic unknown (2020) vs Non-Hispanic Black (2023).
    mixed <- rbind(fx[fx$year == 2020, ], fx[fx$year == 2023, ])
    lab <- categorize_hspanicr(mixed$hspanicr, year = mixed$year)

    expect_equal(unique(as.character(lab[mixed$year == 2020 & mixed$hspanicr == 8])),
                 "nonhispanic_other")
    expect_equal(unique(as.character(lab[mixed$year == 2023 & mixed$hspanicr == 8])),
                 "nonhispanic_white")
    expect_equal(unique(as.character(lab[mixed$year == 2020 & mixed$hspanicr == 9])),
                 "hispanic_unknown")
    expect_equal(unique(as.character(lab[mixed$year == 2023 & mixed$hspanicr == 9])),
                 "nonhispanic_black")
})

test_that("categorize_hspanicr returns NA for the 2021 reserved gap (with warning)", {
    s <- fx[fx$year == 2021, ]
    expect_warning(lab <- categorize_hspanicr(s$hspanicr, year = 2021), "reserved")
    expect_true(all(is.na(lab)))
})

test_that("categorize_hspanicr returns NA before 1989 (not recorded)", {
    s <- fx[fx$year == 1985, ]
    lab <- categorize_hspanicr(s$hspanicr, year = 1985)
    expect_true(all(is.na(lab)))
})

test_that("categorize_hspanicr preserves the legacy 9-category factor (backward compat)", {
    lab <- categorize_hspanicr(1:9, year = 2000)
    expect_equal(levels(lab),
                 c("mexican", "puerto_rican", "cuban", "central_south_america",
                   "other_hispanic", "nonhispanic_white", "nonhispanic_black",
                   "nonhispanic_other", "hispanic_unknown"))
    expect_true(is.ordered(lab))
})

test_that("categorize_hspanicr warns and assumes the legacy scheme when year is omitted", {
    expect_warning(lab <- categorize_hspanicr(1:9), "year")
    expect_equal(as.character(lab)[1], "mexican")
})

test_that("categorize_hspanicr returns NA for out-of-domain codes, with a warning", {
    expect_warning(
        r1 <- categorize_hspanicr(c(0, 10, NA, 15), year = 2000), "outside")
    expect_true(all(is.na(r1)))
    expect_warning(
        r2 <- categorize_hspanicr(c(0, 15, NA), year = 2023), "outside")
    expect_true(all(is.na(r2)))
})

test_that("categorize_hspanicr errors on a mismatched year length", {
    expect_error(categorize_hspanicr(1:3, year = c(2000, 2023)), "length")
})

test_that("categorize_hspanicr reads a factor `year` by value, not level position", {
    ## as.integer(factor("2023")) is the level position (1), not 2023 -> would
    ## silently select the wrong era. Value-coercion must pick the 14-cat scheme.
    lab <- categorize_hspanicr(c(1, 10, 14), year = factor(c(2023, 2023, 2023)))
    expect_equal(as.character(lab),
                 c("mexican", "nonhispanic_aian", "hispanic_unknown"))
    ## mixed factor years, position != value: 6@2019 (9-cat) and 8@2023 (14-cat)
    ## both label nonhispanic_white.
    lab2 <- categorize_hspanicr(c(6, 8), year = factor(c(2019, 2023)))
    expect_equal(as.character(lab2), c("nonhispanic_white", "nonhispanic_white"))
})

test_that("categorize_hspanicr reads a factor hspanicr by value, not level position", {
    ## as.integer(factor(...)) would return the level's ordinal position. For
    ## 2022+ codes 10-14 alphabetical level order diverges from numeric
    ## (levels(factor(c("10","9","2"))) == "10","2","9"), so a position lookup
    ## would map 10/9/2 -> positions 1/3/2 -> codes 1/3/2 (mexican/cuban/
    ## puerto_rican). Value-coercion must give the true codes.
    lab <- categorize_hspanicr(factor(c("10", "9", "2")), year = 2023)
    expect_equal(as.character(lab),
                 c("nonhispanic_aian", "nonhispanic_black", "puerto_rican"))
})

test_that("categorize_hspanicr covers every 2022+ 14-category code (synthetic, codebook-keyed)", {
    ## The real-data fixture only exercises codes 1, 8, 9, 10, 11, 13, leaving
    ## dominican / central_american / south_american / other_hispanic and
    ## nonhispanic_nhopi / hispanic_unknown (plus puerto_rican / cuban) untested.
    ## This synthetic case pins the codebook label to EVERY code, so a transposed
    ## pair in the source label vector would fail here.
    codebook <- c(
        "1"  = "mexican",
        "2"  = "puerto_rican",
        "3"  = "cuban",
        "4"  = "dominican",
        "5"  = "central_american",
        "6"  = "south_american",
        "7"  = "other_hispanic",
        "8"  = "nonhispanic_white",
        "9"  = "nonhispanic_black",
        "10" = "nonhispanic_aian",
        "11" = "nonhispanic_asian",
        "12" = "nonhispanic_nhopi",
        "13" = "nonhispanic_multi",
        "14" = "hispanic_unknown"
    )
    codes <- as.integer(names(codebook))
    lab <- categorize_hspanicr(codes, year = 2023)

    expect_false(anyNA(lab))
    expect_equal(as.character(lab), unname(codebook))
    ## per-code assertion so a failure names the offending code, not just the vector
    for (code in names(codebook)) {
        expect_equal(as.character(lab[codes == as.integer(code)]),
                     unname(codebook[code]))
    }
})
