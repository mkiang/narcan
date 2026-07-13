# state_abbrev_to_fips() now returns ZERO-PADDED fips (Phase 3 fix; MK ruled the
# prior unpadded "6" a bug at the Phase 2 checkpoint), matching add_county_fips().

test_that("state_abbrev_to_fips() returns zero-padded fips", {
    expect_equal(state_abbrev_to_fips("CA"), "06")
    expect_equal(state_abbrev_to_fips(c("CA", "NY")), c("06", "36"))
})

test_that("st_fips_map is the US 50 states + DC (territories dropped, US-only)", {
    expect_equal(nrow(st_fips_map), 51L)
    expect_false(anyNA(st_fips_map$nchs))
    expect_false(any(duplicated(st_fips_map$nchs)))
    expect_false(any(duplicated(st_fips_map$fips)))
    expect_true(all(st_fips_map$fips <= 56))        # no territory FIPS (>= 60)
    expect_true("DC" %in% st_fips_map$abbrev)
    expect_false(any(c("PR", "GU", "AS", "VI", "MP") %in% st_fips_map$abbrev))
})

test_that("state_abbrev_to_fips() returns NA for territory abbreviations", {
    expect_warning(out <- state_abbrev_to_fips(c("CA", "PR", "GU", "AS")),
                   "Unrecognized")
    expect_equal(out, c("06", NA, NA, NA))
})
