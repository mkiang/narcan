## categorize_hispanic_origin() vs the frozen primary-source oracle
## (fixtures/hspanicr_origin_oracle.csv; authoritative copy in the private
## review wrapper 81_hspanicr_origin_oracle). Asserts against the oracle's
## `origin` column only -- never its provenance `source_label`.

oracle <- readr::read_csv(
    testthat::test_path("fixtures", "hspanicr_origin_oracle.csv"),
    comment = "#", show_col_types = FALSE
)
rep_year <- c("9cat" = 2019L, "14cat" = 2023L)

test_that("every oracle code maps to the expected origin, both schemes", {
    for (sch in unique(oracle$scheme)) {
        o <- oracle[oracle$scheme == sch, ]
        got <- categorize_hispanic_origin(o$code, year = rep_year[[sch]])
        expect_equal(got, o$origin, info = sch)
    }
})

test_that("only hispanic/non_hispanic/unknown are ever produced", {
    got9 <- categorize_hispanic_origin(1:9, year = 2019)
    got14 <- categorize_hispanic_origin(1:14, year = 2023)
    expect_true(all(got9 %in% c("hispanic", "non_hispanic", "unknown")))
    expect_true(all(got14 %in% c("hispanic", "non_hispanic", "unknown")))
})

test_that("2021, pre-1989, and NA year are silent NA (no warning, no crash)", {
    expect_no_warning(a <- categorize_hispanic_origin(c(1, 6, 9), year = 2021))
    expect_true(all(is.na(a)))
    expect_no_warning(b <- categorize_hispanic_origin(c(1, 6, 9), year = 1985))
    expect_true(all(is.na(b)))
    expect_no_warning(d <- categorize_hispanic_origin(c(1, 6), year = c(NA, NA)))
    expect_true(all(is.na(d)))
})

test_that("out-of-range codes in a valid scheme year warn and return NA", {
    expect_warning(a <- categorize_hispanic_origin(c(1, 10), year = 2019),
                   "outside the valid code range")
    expect_equal(a, c("hispanic", NA))
    expect_warning(b <- categorize_hispanic_origin(c(1, 15), year = 2023),
                   "outside the valid code range")
    expect_equal(b, c("hispanic", NA))
    expect_warning(categorize_hispanic_origin(0, year = 2019),
                   "outside the valid code range")
})

test_that("out-of-range warn does NOT fire for 2021 / pre-1989 / NA year", {
    expect_no_warning(categorize_hispanic_origin(10, year = 2021))
    expect_no_warning(categorize_hispanic_origin(10, year = 1985))
    expect_no_warning(categorize_hispanic_origin(10, year = NA))
})

test_that("`year` is required", {
    expect_error(categorize_hispanic_origin(1:9), "`year` is required")
})

test_that("mixed-era call is string-keyed, not integer-position (regression)", {
    ## categorize_hspanicr()'s factor levels REORDER across eras; code 7@2000 and
    ## code 9@2023 both label `nonhispanic_black` -> non_hispanic. An
    ## integer-position lookup would mis-map (union-level indices 10/12 -> NA).
    got <- categorize_hispanic_origin(c(7, 9), year = c(2000, 2023))
    expect_equal(got, c("non_hispanic", "non_hispanic"))
    ## code 5@2019 (Other/unknown Hispanic) vs code 7@2023 (Other/Unknown
    ## Hispanic): both -> hispanic despite different codes/schemes.
    got2 <- categorize_hispanic_origin(c(5, 7), year = c(2019, 2023))
    expect_equal(got2, c("hispanic", "hispanic"))
})

test_that("an unclassified recode label fails loud (lookup drift guard)", {
    testthat::local_mocked_bindings(
        categorize_hspanicr = function(hspanicr_column, year = NULL) {
            factor(rep("bogus_new_level", length(hspanicr_column)))
        }
    )
    expect_error(categorize_hispanic_origin(1, year = 2019),
                 "unclassified hspanicr label")
})

test_that("a factor hspanicr_column is coerced by value, not level position", {
    ## as.integer(factor("9")) is the level position (3), not 9. Guard the whole
    ## delegation path: the label AND the out-of-range calc must see code 9.
    got <- categorize_hispanic_origin(factor(c("1", "6", "9")), year = 2019)
    expect_equal(got, c("hispanic", "non_hispanic", "unknown"))
})

test_that("a mismatched year length errors", {
    expect_error(categorize_hispanic_origin(1:3, year = c(2019, 2023)),
                 "length 1 or the same length")
})

test_that("empty and all-NA code inputs return silently", {
    expect_no_warning(e <- categorize_hispanic_origin(integer(0), year = 2019))
    expect_equal(length(e), 0L)
    expect_no_warning(a <- categorize_hispanic_origin(c(NA, NA), year = 2019))
    expect_true(all(is.na(a)))
})

test_that("a character year is accepted", {
    got <- categorize_hispanic_origin(c(1, 6), year = "2019")
    expect_equal(got, c("hispanic", "non_hispanic"))
})

test_that("out-of-range warn counts only valid-scheme rows on a mixed valid/NA year", {
    ## Row 1 (code 10 @ 2019) is out of the 9-cat range and must warn; row 2
    ## (NA year) is in no scheme and must NOT add to the count -- the whole point
    ## of the NA-safe `in_scheme` guard.
    expect_warning(got <- categorize_hispanic_origin(c(10, 10), year = c(2019, NA)),
                   "1 hspanicr value")
    expect_equal(got, c(NA_character_, NA_character_))
})
