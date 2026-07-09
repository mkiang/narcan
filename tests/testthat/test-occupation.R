test_that("add_coded_occupation harmonizes the 4-digit (2020+) scheme", {
    df <- tibble::tibble(
        occupation = c("1010", "2205"),
        occupationr = c("01", "22"),
        industry = c("8680", "7890"),
        industryr = c("18", "15")
    )
    out <- add_coded_occupation(df, 2023)
    expect_equal(unique(out$occ_scheme), "4digit_niosh")
    expect_equal(out$occ_coded, c("1010", "2205"))
    expect_equal(out$ind_coded, c("8680", "7890"))
    expect_equal(out$occ_recode, c("01", "22"))
    expect_true(all(out$occ_available))
})

test_that("add_coded_occupation harmonizes the 3-digit (1985-1999) scheme", {
    df <- tibble::tibble(occup = c("019", "804"), industry = c("841", "760"))
    out <- add_coded_occupation(df, 1990)
    expect_equal(unique(out$occ_scheme), "3digit_census")
    expect_equal(out$occ_coded, c("019", "804"))
    expect_equal(out$ind_coded, c("841", "760"))
    expect_true(all(is.na(out$occ_recode)))
    expect_true(all(out$occ_available))
})

test_that("add_coded_occupation reports no scheme for the 2000-2019 gap", {
    df <- tibble::tibble(sex = c("M", "F"))
    out <- add_coded_occupation(df, 2010)
    expect_true(all(is.na(out$occ_scheme)))
    expect_true(all(is.na(out$occ_coded)))
    expect_false(unique(out$occ_available))
})

test_that("occ_available is FALSE when the scheme applies but data is absent (restricted 2020)", {
    df <- tibble::tibble(
        occupation = c(NA_character_, NA_character_),
        occupationr = c(NA_character_, NA_character_),
        industry = c(NA_character_, NA_character_),
        industryr = c(NA_character_, NA_character_)
    )
    out <- add_coded_occupation(df, 2020)
    expect_equal(unique(out$occ_scheme), "4digit_niosh")
    expect_false(unique(out$occ_available))
})
