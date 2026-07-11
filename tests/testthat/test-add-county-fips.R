# Smoke test for the Phase 2 edit that removes the whole-namespace `import(dplyr)`.
# The bare (unqualified) transmute() in add_county_fips lives ONLY in the NCHS-
# state-code branch, so this test deliberately drives that branch. Today it passes
# trivially (transmute resolves via import(dplyr)); it only becomes a real guard
# once import(dplyr) is removed and replaced by importFrom(dplyr, transmute). The
# authoritative clean-room guard remains R CMD check (Phase 5).

test_that("add_county_fips() runs the NCHS-code branch (guards the bare transmute)", {
    # county codes whose first two chars are NCHS state codes incl. 03/07/14/43
    df <- tibble::tibble(
        countyoc = c("03001", "07001", "14001", "43001", "03002")
    )
    out <- suppressWarnings(add_county_fips(df, countyoc))
    expect_true(all(c("st_fips", "county_fips") %in% names(out)))
    expect_equal(nrow(out), nrow(df))
    expect_false(anyNA(out$st_fips))          # all four NCHS codes resolve
    expect_equal(out$county_fips, paste0(out$st_fips, out$county_substr))
})

test_that("add_county_fips() runs the FIPS-passthrough branch", {
    df <- tibble::tibble(countyoc = c("53001", "54001", "55001", "56001"))
    out <- suppressWarnings(add_county_fips(df, countyoc))
    expect_equal(out$st_fips, c("53", "54", "55", "56"))
})

test_that("add_county_fips() errors on the ambiguous NCHS code 62 (#1)", {
    # nchs 62 maps to BOTH American Samoa and the N. Mariana Islands, so the
    # many-to-one join must error rather than silently duplicate the row.
    df <- tibble::tibble(countyoc = c("03001", "07001", "14001", "43001", "62001"))
    expect_error(add_county_fips(df, countyoc))
})

test_that("add_county_fips() preserves row count on NCHS input without code 62 (#1)", {
    df <- tibble::tibble(countyoc = c("03001", "07001", "14001", "43001"))
    out <- add_county_fips(df, countyoc)
    expect_equal(nrow(out), nrow(df))
})

test_that("add_county_fips() resolves realistic abbreviation subsets (#3)", {
    out1 <- add_county_fips(tibble::tibble(countyoc = c("CA001", "CA003")), countyoc)
    expect_equal(unique(out1$st_fips), "06")
    out2 <- add_county_fips(tibble::tibble(countyoc = c("CA001", "NY001")), countyoc)
    expect_false(anyNA(out2$st_fips))
    expect_equal(nrow(out2), 2L)
})

test_that("add_county_fips() errors informatively on an unrecognized scheme (#3)", {
    df <- tibble::tibble(countyoc = c("ZZ001", "QQ002"))
    expect_error(add_county_fips(df, countyoc), "Unrecognized state coding system")
})
